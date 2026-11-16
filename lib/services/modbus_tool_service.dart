import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

import '../models/instrument.dart';
import '../models/modbus_register.dart';

/// Egy kézi Modbus-művelet eredménye.
class ModbusToolResult {
  const ModbusToolResult.ok(Object this.value)
      : errorCode = null,
        exception = null;

  const ModbusToolResult.code(String this.errorCode)
      : value = null,
        exception = null;

  const ModbusToolResult.exception(String this.exception)
      : value = null,
        errorCode = null;

  /// Bitnél `bool`, egész típusnál `int`, float32-nél `double` (nyers érték).
  final Object? value;

  /// A Modbus válaszkód neve (pl. `illegalDataAddress`, `requestTimeout`).
  final String? errorCode;

  /// Kapcsolódási vagy egyéb kivétel szövege.
  final String? exception;

  bool get ok => value != null;
}

/// A Modbus segéd kapcsolata: az első kérésnél kapcsolódik, és a lezárásig
/// (`close()`) nyitva tartja a Modbus/TCP kapcsolatot.
class ModbusToolSession {
  ModbusToolSession(this.instrument);

  final Instrument instrument;
  ModbusClientTcp? _client;

  /// Megvan-e minden a kapcsolódáshoz (IP-cím és Unit ID).
  bool get isConfigured {
    final host = instrument.modbusHost;
    return host != null && host.isNotEmpty && instrument.modbusUnitId != null;
  }

  ModbusClientTcp _ensureClient() => _client ??= ModbusClientTcp(
        instrument.modbusHost!,
        serverPort: instrument.modbusPort ?? 502,
        unitId: instrument.modbusUnitId,
        connectionMode: ModbusConnectionMode.autoConnectAndKeepConnected,
        connectionTimeout: const Duration(seconds: 3),
        responseTimeout: const Duration(seconds: 3),
      );

  ModbusElement _element(ModbusRegisterDef d) {
    final type = switch (d.kind) {
      ModbusRegisterKind.holding => ModbusElementType.holdingRegister,
      ModbusRegisterKind.input => ModbusElementType.inputRegister,
      ModbusRegisterKind.coil => ModbusElementType.coil,
      ModbusRegisterKind.discrete => ModbusElementType.discreteInput,
    };
    if (d.isBit) {
      return ModbusBitElement(name: d.name, address: d.address, type: type);
    }
    // A bájtsorrend csak 32 bites értéknél számít; 16 bitnél mindig ABCD.
    final order = d.dataType.is32Bit
        ? ModbusEndianness.values.firstWhere(
            (e) => e.name == d.byteOrder,
            orElse: () => ModbusEndianness.ABCD,
          )
        : ModbusEndianness.ABCD;
    switch (d.dataType) {
      case ModbusDataType.uint16:
        return ModbusUint16Register(
            name: d.name, address: d.address, type: type, endianness: order);
      case ModbusDataType.int16:
        return ModbusInt16Register(
            name: d.name, address: d.address, type: type, endianness: order);
      case ModbusDataType.uint32:
        return ModbusUint32Register(
            name: d.name, address: d.address, type: type, endianness: order);
      case ModbusDataType.int32:
        return ModbusInt32Register(
            name: d.name, address: d.address, type: type, endianness: order);
      case ModbusDataType.float32:
        return ModbusFloatRegister(
            name: d.name, address: d.address, type: type, endianness: order);
    }
  }

  ModbusToolResult _resultOf(
    ModbusRegisterDef d,
    ModbusElement element,
    ModbusResponseCode code,
  ) {
    if (code != ModbusResponseCode.requestSucceed) {
      return ModbusToolResult.code(code.name);
    }
    final Object? value = element.value;
    if (value is bool) return ModbusToolResult.ok(value);
    if (value is num) {
      return ModbusToolResult.ok(
          d.dataType.isFloat ? value.toDouble() : value.round());
    }
    return ModbusToolResult.code(ModbusResponseCode.requestRxFailed.name);
  }

  Future<ModbusToolResult> _send(
    ModbusRegisterDef d,
    ModbusElement element,
    ModbusRequest request,
  ) async {
    try {
      final code = await _ensureClient().send(request);
      return _resultOf(d, element, code);
    } catch (e) {
      return ModbusToolResult.exception(e.toString());
    }
  }

  /// Egy regiszter vagy bit kiolvasása.
  Future<ModbusToolResult> read(ModbusRegisterDef d) async {
    final element = _element(d);
    return _send(d, element, element.getReadRequest());
  }

  /// Egy holding regiszter vagy coil írása. A [rawValue] bitnél `bool`,
  /// egész típusnál `int`, float32-nél `double` — a szorzó nélküli érték.
  Future<ModbusToolResult> write(ModbusRegisterDef d, Object rawValue) async {
    final element = _element(d);
    try {
      final ModbusRequest request;
      if (d.isBit) {
        request = element.getWriteRequest(rawValue == true);
      } else if (d.dataType.isFloat) {
        request = element.getWriteRequest((rawValue as num).toDouble(),
            rawValue: true);
      } else if (d.dataType.is32Bit) {
        request =
            element.getWriteRequest((rawValue as num).round(), rawValue: true);
      } else {
        // 16 bit: a negatív int16 kettes komplemensben megy ki.
        request = element.getWriteRequest((rawValue as num).round() & 0xFFFF,
            rawValue: true);
      }
      return await _send(d, element, request);
    } catch (e) {
      return ModbusToolResult.exception(e.toString());
    }
  }

  Future<void> close() async {
    final client = _client;
    _client = null;
    try {
      await client?.disconnect();
    } catch (_) {
      // A lezárás hibája nem érdekes.
    }
  }
}
