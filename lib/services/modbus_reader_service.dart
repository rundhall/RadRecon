import 'dart:async';

import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument.dart';

/// Egyszeri Modbus/TCP kiolvasás eredménye.
class ModbusReadResult {
  final bool success;
  final double? value;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  const ModbusReadResult.ok(double this.value, {this.latitude, this.longitude})
      : success = true,
        errorMessage = null;

  const ModbusReadResult.error(String message)
      : success = false,
        value = null,
        latitude = null,
        longitude = null,
        errorMessage = message;

  bool get hasGps => latitude != null && longitude != null;
}

ModbusFloatRegister _floatRegister(int address) => ModbusFloatRegister(
      name: 'value',
      type: ModbusElementType.holdingRegister,
      address: address,
      uom: '',
      endianness: ModbusEndianness.ABCD,
    );

/// A mért érték, és ha engedélyezett, a GPS szélesség/hosszúság kiolvasása
/// egy már csatlakozott kliensen.
Future<ModbusReadResult> _readAll(
  ModbusClientTcp client,
  ModbusFloatRegister valueRegister,
  Instrument instrument,
  AppLocalizations l10n,
) async {
  final code = await client.send(valueRegister.getReadRequest());
  if (code != ModbusResponseCode.requestSucceed) {
    return ModbusReadResult.error(
      l10n.modbusReadErrorWithCode(code.toString()),
    );
  }
  final value = valueRegister.value;
  if (value == null) {
    return ModbusReadResult.error(
      l10n.instrumentDidNotSendValidValue,
    );
  }
  if (!instrument.isModbusGpsEnabled) {
    return ModbusReadResult.ok((value as num).toDouble());
  }

  final latReg = _floatRegister(instrument.modbusGpsLatAddress);
  final lonReg = _floatRegister(instrument.modbusGpsLonAddress);
  final latCode = await client.send(latReg.getReadRequest());
  final lonCode = await client.send(lonReg.getReadRequest());
  if (latCode != ModbusResponseCode.requestSucceed ||
      lonCode != ModbusResponseCode.requestSucceed ||
      latReg.value == null ||
      lonReg.value == null) {
    return ModbusReadResult.error(
      l10n.gpsPositionReadFailed,
    );
  }
  return ModbusReadResult.ok(
    (value as num).toDouble(),
    latitude: (latReg.value as num).toDouble(),
    longitude: (lonReg.value as num).toDouble(),
  );
}

/// Egyszeri (connect → read → disconnect) Modbus/TCP kiolvasás egy
/// float32 holding regiszterből.
///
/// A regiszter-elrendezés a felhasználó Python referenciájával egyezik meg:
/// `BinaryPayloadDecoder.fromRegisters(..., byteorder=Endian.Big,
/// wordorder=Endian.Big)` egy 32 bites lebegőpontos értéket dekódol két
/// egymást követő holding regiszterből, nagy-endián bájt- és szósorrenddel.
/// Ennek a `modbus_client` csomagban a `ModbusEndianness.ABCD` felel meg
/// (ez az alapértelmezett is).
///
/// Instabil terepi WiFi miatt egyetlen automatikus újrapróbálkozást végez
/// sikertelen kapcsolódás esetén.
class ModbusReaderService {
  static Future<ModbusReadResult> readFloatRegister(
    Instrument instrument,
    AppLocalizations l10n,
  ) async {
    final host = instrument.modbusHost;
    final port = instrument.modbusPort;
    final unitId = instrument.modbusUnitId;
    final address = instrument.modbusRegisterAddress;

    if (host == null || host.isEmpty) {
      return ModbusReadResult.error(l10n.instrumentIPAddressNotSet);
    }
    if (unitId == null) {
      return ModbusReadResult.error(l10n.modbusUnitIdNotSet);
    }
    if (address == null) {
      return ModbusReadResult.error(l10n.registerAddressNotSet);
    }

    for (var attempt = 1; attempt <= 2; attempt++) {
      final result = await _attemptRead(
        instrument: instrument,
        host: host,
        port: port ?? 502,
        unitId: unitId,
        address: address,
        l10n: l10n,
      );
      if (result.success) return result;
      if (attempt == 2) return result;
      // Rövid várakozás az újrapróbálkozás előtt instabil terepi WiFi esetén.
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return const ModbusReadResult.error('Ismeretlen hiba.');
  }

  static Future<ModbusReadResult> _attemptRead({
    required Instrument instrument,
    required String host,
    required int port,
    required int unitId,
    required int address,
    required AppLocalizations l10n,
  }) async {
    final register = _floatRegister(address);

    final client = ModbusClientTcp(
      host,
      serverPort: port,
      unitId: unitId,
      connectionMode: ModbusConnectionMode.autoConnectAndKeepConnected,
      connectionTimeout: const Duration(seconds: 3),
      responseTimeout: const Duration(seconds: 3),
    );

    try {
      final connected = await client.connect();
      if (!connected) {
        return ModbusReadResult.error(l10n.failedToConnectToInstrument);
      }

      return await _readAll(client, register, instrument, l10n);
    } catch (e) {
      return ModbusReadResult.error(
        l10n.connectionErrorWithDetails(e.toString()),
      );
    } finally {
      client.disconnect();
    }
  }
}

/// Nyitva tartott Modbus/TCP kapcsolat folyamatos (automatikus)
/// mintavételezéshez.
///
/// Az egyszeri [ModbusReaderService] minden olvasáshoz újra kapcsolódik és
/// bontja a kapcsolatot — ez percenkénti/óránkénti lekérdezésnél rendben
/// van, de másodperces gyakoriságnál túl lassú és instabil lenne. Ez az
/// osztály egyszer kapcsolódik, és a lezárásig (`close()`) ugyanazon a
/// kapcsolaton ismétli az olvasást.
class ModbusLiveSession {
  final ModbusClientTcp _client;
  final ModbusFloatRegister _register;
  final Instrument _instrument;
  final AppLocalizations _l10n;

  ModbusLiveSession._(
    this._client,
    this._register,
    this._instrument,
    this._l10n,
  );

  static Future<ModbusLiveSession> connect(
    Instrument instrument,
    AppLocalizations l10n,
  ) async {
    final host = instrument.modbusHost;
    final port = instrument.modbusPort;
    final unitId = instrument.modbusUnitId;
    final address = instrument.modbusRegisterAddress;

    if (host == null || host.isEmpty || unitId == null || address == null) {
      throw StateError(l10n.modbusAccessIncomplete);
    }

    final register = _floatRegister(address);

    final client = ModbusClientTcp(
      host,
      serverPort: port ?? 502,
      unitId: unitId,
      connectionMode: ModbusConnectionMode.autoConnectAndKeepConnected,
      connectionTimeout: const Duration(seconds: 3),
      responseTimeout: const Duration(seconds: 3),
    );

    final connected = await client.connect();
    if (!connected) {
      throw StateError(l10n.failedToConnectToInstrument);
    }

    return ModbusLiveSession._(client, register, instrument, l10n);
  }

  /// Egy olvasás a már élő kapcsolaton. Hálózati hiba esetén az
  /// `autoConnectAndKeepConnected` mód automatikusan újra kapcsolódik a
  /// következő hívásnál.
  Future<ModbusReadResult> read() async {
    try {
      return await _readAll(_client, _register, _instrument, _l10n);
    } catch (e) {
      return ModbusReadResult.error(
        _l10n.connectionErrorWithDetails(e.toString()),
      );
    }
  }

  Future<void> close() async {
    await _client.disconnect();
  }
}