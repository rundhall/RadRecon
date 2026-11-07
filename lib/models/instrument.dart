import 'dart:convert';

import 'measurement_type.dart';
import 'modbus_reading.dart';

/// Egy terepre vitt sugárzásmérő műszer.
///
/// A kalibrációs adatok (sorozatszám, dátum, tényező) minden hozzá rendelt
/// méréshez elérhetők maradnak, hogy a jegyzőkönyv hivatkozhasson rájuk.
class Instrument {
  final int? id;
  final String name; // pl. "Identifinder R400" vagy "RDS-31"
  final String? serialNumber;
  final DateTime? calibrationDate;
  final DateTime? nextCalibrationDate;
  final double? calibrationFactor;
  final bool isModbusConnected; // true: WiFi Modbus/TCP-n lekérdezhető
  final String? modbusHost;
  final int? modbusPort;
  final int? modbusUnitId; // a műszer Modbus slave/unit azonosítója
  final int? modbusRegisterAddress; // a mért érték (float32) kezdő regisztere
  final bool isModbusGpsEnabled; // true: a pozíció is Modbus regiszterből jön
  final int modbusGpsLatAddress; // float32, fok (É+, D-)
  final int modbusGpsLonAddress; // float32, fok (K+, Ny-)

  /// Mit ad vissza a műszer a Modbus regiszterben (dózisteljesítmény,
  /// felületi szennyezettség, beütésszám, neutron beütésszám)...
  final MeasurementType modbusMeasurementType;

  /// ...és milyen mértékegységben (pl. "nSv/h", "µR/h", "cps"). A régebben
  /// felvett műszerek alapértelmezése: dózisteljesítmény, nSv/h.
  final String modbusUnit;

  /// Több Modbus-csatorna: típusonként egy regiszter és egység. Üres, ha a
  /// régi, egyetlen regiszteres beállítás érvényes.
  final List<ModbusChannel> modbusChannels;

  const Instrument({
    this.id,
    required this.name,
    this.serialNumber,
    this.calibrationDate,
    this.nextCalibrationDate,
    this.calibrationFactor,
    this.isModbusConnected = false,
    this.modbusHost,
    this.modbusPort,
    this.modbusUnitId,
    this.modbusRegisterAddress,
    this.isModbusGpsEnabled = false,
    this.modbusGpsLatAddress = 426,
    this.modbusGpsLonAddress = 428,
    this.modbusMeasurementType = MeasurementType.doseRate,
    this.modbusUnit = 'nSv/h',
    this.modbusChannels = const [],
  });

  /// A műszer Modbus-csatornái. Ha nincs külön lista, a régi egyetlen
  /// regiszter az egyetlen csatorna.
  List<ModbusChannel> get effectiveModbusChannels {
    if (modbusChannels.isNotEmpty) return modbusChannels;
    final address = modbusRegisterAddress;
    if (address == null) return const [];
    return [
      ModbusChannel(
        type: modbusMeasurementType,
        address: address,
        unit: modbusUnit,
      ),
    ];
  }

  /// A megadott mérési típushoz tartozó csatorna, ha van.
  ModbusChannel? modbusChannelFor(MeasurementType type) {
    for (final c in effectiveModbusChannels) {
      if (c.type == type) return c;
    }
    return null;
  }

  /// A megadott típus összes csatornája (meteorológiánál és gázmérésnél több).
  List<ModbusChannel> modbusChannelsOf(MeasurementType type) => [
        for (final c in effectiveModbusChannels)
          if (c.type == type) c,
      ];

  Instrument copyWith({
    int? id,
    String? name,
    String? serialNumber,
    DateTime? calibrationDate,
    DateTime? nextCalibrationDate,
    double? calibrationFactor,
    bool? isModbusConnected,
    String? modbusHost,
    int? modbusPort,
    int? modbusUnitId,
    int? modbusRegisterAddress,
    bool? isModbusGpsEnabled,
    int? modbusGpsLatAddress,
    int? modbusGpsLonAddress,
    MeasurementType? modbusMeasurementType,
    String? modbusUnit,
    List<ModbusChannel>? modbusChannels,
  }) {
    return Instrument(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      calibrationDate: calibrationDate ?? this.calibrationDate,
      nextCalibrationDate: nextCalibrationDate ?? this.nextCalibrationDate,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      isModbusConnected: isModbusConnected ?? this.isModbusConnected,
      modbusHost: modbusHost ?? this.modbusHost,
      modbusPort: modbusPort ?? this.modbusPort,
      modbusUnitId: modbusUnitId ?? this.modbusUnitId,
      modbusRegisterAddress: modbusRegisterAddress ?? this.modbusRegisterAddress,
      isModbusGpsEnabled: isModbusGpsEnabled ?? this.isModbusGpsEnabled,
      modbusGpsLatAddress: modbusGpsLatAddress ?? this.modbusGpsLatAddress,
      modbusGpsLonAddress: modbusGpsLonAddress ?? this.modbusGpsLonAddress,
      modbusMeasurementType:
          modbusMeasurementType ?? this.modbusMeasurementType,
      modbusUnit: modbusUnit ?? this.modbusUnit,
      modbusChannels: modbusChannels ?? this.modbusChannels,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'serial_number': serialNumber,
      'calibration_date': calibrationDate?.toIso8601String(),
      'next_calibration_date': nextCalibrationDate?.toIso8601String(),
      'calibration_factor': calibrationFactor,
      'is_modbus_connected': isModbusConnected ? 1 : 0,
      'modbus_host': modbusHost,
      'modbus_port': modbusPort,
      'modbus_unit_id': modbusUnitId,
      'modbus_register_address': modbusRegisterAddress,
      'is_modbus_gps_enabled': isModbusGpsEnabled ? 1 : 0,
      'modbus_gps_lat_address': modbusGpsLatAddress,
      'modbus_gps_lon_address': modbusGpsLonAddress,
      'modbus_measurement_type': modbusMeasurementType.dbValue,
      'modbus_unit': modbusUnit,
      'modbus_channels': jsonEncode([for (final c in modbusChannels) c.toJson()]),
    };
  }

  factory Instrument.fromMap(Map<String, Object?> map) {
    return Instrument(
      id: map['id'] as int?,
      name: map['name'] as String,
      serialNumber: map['serial_number'] as String?,
      calibrationDate: map['calibration_date'] == null
          ? null
          : DateTime.parse(map['calibration_date'] as String),
      nextCalibrationDate: map['next_calibration_date'] == null
          ? null
          : DateTime.parse(map['next_calibration_date'] as String),
      calibrationFactor: (map['calibration_factor'] as num?)?.toDouble(),
      isModbusConnected: (map['is_modbus_connected'] as int? ?? 0) == 1,
      modbusHost: map['modbus_host'] as String?,
      modbusPort: map['modbus_port'] as int?,
      modbusUnitId: map['modbus_unit_id'] as int?,
      modbusRegisterAddress: map['modbus_register_address'] as int?,
      isModbusGpsEnabled: (map['is_modbus_gps_enabled'] as int? ?? 0) == 1,
      modbusGpsLatAddress: map['modbus_gps_lat_address'] as int? ?? 426,
      modbusGpsLonAddress: map['modbus_gps_lon_address'] as int? ?? 428,
      modbusMeasurementType: _typeFromDb(map['modbus_measurement_type']),
      modbusUnit: map['modbus_unit'] as String? ?? 'nSv/h',
      modbusChannels: _channelsFromDb(map['modbus_channels']),
    );
  }

  static List<ModbusChannel> _channelsFromDb(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      return ModbusChannel.listFromJson(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  /// Ismeretlen/hiányzó értéknél a régi viselkedés: dózisteljesítmény.
  static MeasurementType _typeFromDb(Object? value) {
    for (final t in kModbusMeasurableTypes) {
      if (t.dbValue == value) return t;
    }
    return MeasurementType.doseRate;
  }
}
