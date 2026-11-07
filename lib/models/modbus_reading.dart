import 'activity_unit.dart';
import 'count_rate_unit.dart';
import 'dose_rate_unit.dart';
import 'measurement_type.dart';

/// Mit olvashat Modbus-regiszterből a műszer: sugárzási mennyiségek mellett
/// meteorológia és gázmérés is (mennyiségenként egy regiszter).
const kModbusMeasurableTypes = <MeasurementType>[
  MeasurementType.doseRate,
  MeasurementType.surfaceContamination,
  MeasurementType.countRate,
  MeasurementType.meteorology,
  MeasurementType.gasMeasurement,
];

/// Meteorológiai mennyiségek: a Meteorology JSON-kulcsa és a választható
/// egységek. Az első egység az alapegység.
const kModbusMeteoUnits = <String, List<String>>{
  'air_temperature_c': ['°C', '°F'],
  'relative_humidity_pct': ['%'],
  'pressure_hpa': ['hPa', 'kPa'],
  'wind_speed_ms': ['m/s', 'km/h', 'kn'],
  'wind_direction_deg': ['°'],
  'gust_ms': ['m/s', 'km/h', 'kn'],
  'precipitation_mm_h': ['mm/h'],
  'solar_wm2': ['W/m²'],
  'cloud_okta': ['okta'],
  'visibility_m': ['m'],
  'soil_moisture_pct': ['%'],
  'aerosol_ug_m3': ['µg/m³'],
};

/// Gázkoncentráció egységei; a ConcentrationUnit jelöléseivel egyeznek.
const kModbusGasUnits = <String>['ppm', 'ppb', 'vol%', '%', 'mg/m³', 'µg/m³'];

/// Meteorológiai érték átváltása a Meteorology mezők egységére (°C, hPa,
/// m/s, %, ...). Ismeretlen egységnél a nyers értéket adja vissza.
double meteoValueToStored(String key, String unit, double raw) {
  switch (key) {
    case 'air_temperature_c':
      return unit == '°F' ? (raw - 32) * 5 / 9 : raw;
    case 'pressure_hpa':
      return unit == 'kPa' ? raw * 10 : raw;
    case 'wind_speed_ms':
    case 'gust_ms':
      if (unit == 'km/h') return raw / 3.6;
      if (unit == 'kn') return raw * 0.514444;
      return raw;
    default:
      return raw;
  }
}

/// A regiszterben visszaadott érték választható mértékegységei.
List<String> modbusUnitsFor(MeasurementType type, [String? quantity]) {
  switch (type) {
    case MeasurementType.doseRate:
      return [for (final u in DoseRateUnit.values) u.symbol];
    case MeasurementType.surfaceContamination:
      return const ['Bq/cm²'];
    case MeasurementType.activity:
      return [for (final u in ActivityUnit.values) u.symbol];
    case MeasurementType.countRate:
      return [
        for (final u in CountRateUnit.values) u.base,
        for (final u in CountRateUnit.values) 'n${u.base}',
      ];
    case MeasurementType.meteorology:
      return kModbusMeteoUnits[quantity] ?? const [];
    case MeasurementType.gasMeasurement:
      return kModbusGasUnits;
    case MeasurementType.activityConcentration:
    case MeasurementType.spectrum:
    case MeasurementType.sample:
    case MeasurementType.biological:
      return const [];
  }
}

/// Egy Modbus-csatorna: a műszer ezen a regiszteren adja vissza a megadott
/// mennyiséget, a megadott egységben.
class ModbusChannel {
  const ModbusChannel({
    required this.type,
    required this.address,
    required this.unit,
    this.quantity,
  });

  final MeasurementType type;

  /// Meteorológiánál a Meteorology JSON-kulcs (pl. 'wind_speed_ms'),
  /// gázmérésnél a vegyület neve; más típusnál null.
  final String? quantity;
  final int address;
  final String unit;

  /// Ugyanazt a mennyiséget írja-e le (típus és mennyiség).
  bool isSameQuantity(ModbusChannel other) =>
      type == other.type && quantity == other.quantity;

  Map<String, Object> toJson() => {
        'type': type.dbValue,
        'quantity': ?quantity,
        'address': address,
        'unit': unit,
      };

  static ModbusChannel? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final address = raw['address'];
    final unit = raw['unit'];
    final quantity = raw['quantity'];
    if (address is! int || unit is! String) return null;
    if (quantity != null && quantity is! String) return null;
    final q = quantity as String?;
    for (final t in kModbusMeasurableTypes) {
      if (t.dbValue != raw['type']) continue;
      switch (t) {
        case MeasurementType.meteorology:
          if (q == null || !kModbusMeteoUnits.containsKey(q)) return null;
          return ModbusChannel(
            type: t,
            address: address,
            unit: unit,
            quantity: q,
          );
        case MeasurementType.gasMeasurement:
          if (q == null || q.isEmpty) return null;
          return ModbusChannel(
            type: t,
            address: address,
            unit: unit,
            quantity: q,
          );
        default:
          return ModbusChannel(type: t, address: address, unit: unit);
      }
    }
    return null;
  }

  /// Csatornák listája JSON-ból; a hibás elemeket kihagyja.
  static List<ModbusChannel> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    final result = <ModbusChannel>[];
    for (final e in raw) {
      final c = fromJson(e);
      if (c != null) result.add(c);
    }
    return result;
  }
}

/// Alapértelmezett regiszter-egység. Dózisteljesítménynél nSv/h, mert a
/// korábban felvett műszerek is így működtek.
String defaultModbusUnitFor(MeasurementType type, [String? quantity]) {
  if (type == MeasurementType.doseRate) {
    return DoseRateUnit.instrumentNative.symbol;
  }
  final units = modbusUnitsFor(type, quantity);
  return units.isEmpty ? '' : units.first;
}
