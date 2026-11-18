import 'dart:async';
import 'dart:io';

import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

/// A „Ping” gomb eredménye: TCP-kapcsolódás a Modbus-porton.
class TcpPingResult {
  const TcpPingResult.reachable(Duration this.latency)
      : error = null,
        timedOut = false;

  const TcpPingResult.timeout()
      : latency = null,
        error = null,
        timedOut = true;

  const TcpPingResult.failed(String this.error)
      : latency = null,
        timedOut = false;

  final Duration? latency;
  final String? error;
  final bool timedOut;

  bool get ok => latency != null;
  int get latencyMs => latency?.inMilliseconds ?? 0;
}

/// Ping helyett TCP-kapcsolódást mér a Modbus-porton. A mobilos app natív
/// kód nélkül nem küldhet ICMP-csomagot, a Modbus-port nyitottsága viszont
/// pontosan azt mutatja, amire a mérésnek szüksége van.
Future<TcpPingResult> tcpPing(String host, int port) async {
  const timeout = Duration(seconds: 2);
  final watch = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    watch.stop();
    socket.destroy();
    return TcpPingResult.reachable(watch.elapsed);
  } on TimeoutException {
    return const TcpPingResult.timeout();
  } on SocketException catch (e) {
    final message = e.osError?.message ?? e.message;
    if (message.toLowerCase().contains('timed out')) {
      return const TcpPingResult.timeout();
    }
    return TcpPingResult.failed(message);
  } catch (e) {
    return TcpPingResult.failed('$e');
  }
}

/// Egy unit ID keresés eredménye.
class ModbusScanResult {
  const ModbusScanResult({required this.found, required this.cancelled})
      : connectionFailed = false;

  const ModbusScanResult.noConnection()
      : found = const [],
        cancelled = false,
        connectionFailed = true;

  final List<int> found;
  final bool cancelled;
  final bool connectionFailed;
}

/// Egy kérdezési próba: melyik tábla (holding, input, coil, discrete) és
/// melyik cím. A keresés ezeket sorban próbálja egy unit ID-n.
class ModbusProbe {
  const ModbusProbe(this.type, this.address);

  /// A mérési csatorna regisztere: a mérés is holding regisztert olvas.
  static ModbusProbe holdingChannel(int address) =>
      ModbusProbe(ModbusElementType.holdingRegister, address);

  final ModbusElementType type;
  final int address;
}

/// Modbus unit ID keresés: egy TCP-kapcsolaton végigpróbálja a tartományt.
/// Minden ID-ra a próbákat sorban küldi, az első válaszig. A per-kérés
/// unit ID-val a kapcsolat egyszer épül fel.
class ModbusUnitScanner {
  ModbusUnitScanner({
    required this.host,
    required this.port,
    List<ModbusProbe>? probes,
  }) : probes = probes == null || probes.isEmpty ? defaultProbes : probes;

  /// Ha nincs mérési csatorna megadva: holding 0 és coil 0.
  static const List<ModbusProbe> defaultProbes = [
    ModbusProbe(ModbusElementType.holdingRegister, 0),
    ModbusProbe(ModbusElementType.coil, 0),
  ];

  final String host;
  final int port;
  final List<ModbusProbe> probes;

  /// Érvényes Modbus slave-címek (0 a broadcast, 248 felett fenntartott).
  static const int minUnitId = 1;
  static const int maxUnitId = 247;

  static const Duration _probeTimeout = Duration(milliseconds: 1000);

  ModbusClientTcp? _client;
  bool _closed = false;

  ModbusClientTcp _clientOrCreate() => _client ??= ModbusClientTcp(
        host,
        serverPort: port,
        connectionMode: ModbusConnectionMode.autoConnectAndKeepConnected,
        connectionTimeout: const Duration(seconds: 3),
        responseTimeout: _probeTimeout,
      );

  /// true, ha a kapcsolat létrejött.
  Future<bool> connect() async {
    if (_closed) return false;
    try {
      return await _clientOrCreate().connect();
    } catch (_) {
      return false;
    }
  }

  /// Egy unit ID próbája: a próbákat sorban, az első válaszig küldi.
  Future<bool> probe(int unitId) async {
    for (final p in probes) {
      if (_closed) return false;
      if (await _probeOnce(unitId, p)) return true;
    }
    return false;
  }

  Future<bool> _probeOnce(int unitId, ModbusProbe p) async {
    final ModbusElement element = p.type.isBit
        ? ModbusBitElement(name: 'probe', address: p.address, type: p.type)
        : ModbusUint16Register(
            name: 'probe',
            address: p.address,
            type: p.type,
          );
    final request = element.getReadRequest(
      unitId: unitId,
      responseTimeout: _probeTimeout,
    );
    try {
      final code = await _clientOrCreate().send(request);
      if (answered(code)) return true;
      // Időtúllépés után a késve érkező válasz a következő kérésnél rossz
      // tranzakció-azonosítóval jönne, és hibásan ahhoz párosulna. Ilyenkor
      // a socketet eldobjuk, a következő kérés újracsatlakozik.
      if (!code.isStandardModbusExceptionCode &&
          code != ModbusResponseCode.requestSucceed) {
        await _clientOrCreate().disconnect();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sikeres válasz, vagy a műszer saját Modbus-kivétele már bizonyítja,
  /// hogy az ID-n eszköz van. A gateway-hibák (nincs ilyen eszköz) nem.
  static bool answered(ModbusResponseCode code) {
    if (code == ModbusResponseCode.requestSucceed) return true;
    if (!code.isStandardModbusExceptionCode) return false;
    return code != ModbusResponseCode.gatewayPathUnavailable &&
        code != ModbusResponseCode.gatewayTargetDeviceFailedToRespond;
  }

  /// [from]..[to] végigpróbálása. [onStep] minden ID után hívódik.
  Future<ModbusScanResult> scan({
    required int from,
    required int to,
    required bool Function() isCancelled,
    required void Function(int done, int unitId, bool found) onStep,
  }) async {
    if (!await connect()) return const ModbusScanResult.noConnection();
    final found = <int>[];
    for (var id = from; id <= to; id++) {
      if (_closed || isCancelled()) {
        return ModbusScanResult(found: found, cancelled: true);
      }
      final ok = await probe(id);
      if (ok) found.add(id);
      onStep(id - from + 1, id, ok);
    }
    return ModbusScanResult(found: found, cancelled: false);
  }

  Future<void> close() async {
    _closed = true;
    final client = _client;
    _client = null;
    try {
      await client?.disconnect();
    } catch (_) {
      // A lezárás hibája nem érdekes, a kapcsolat úgyis megszakad.
    }
  }
}
