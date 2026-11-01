import 'activity_unit.dart';
import 'count_rate_unit.dart';
import 'dose_rate_unit.dart';
import 'measurement_type.dart';

/// Mit mérhet egy Modbus-műszer a megadott regiszterben.
const kModbusMeasurableTypes = <MeasurementType>[
  MeasurementType.doseRate,
  MeasurementType.surfaceContamination,
  MeasurementType.countRate,
];

/// A regiszterben visszaadott érték választható mértékegységei típusonként.
List<String> modbusUnitsFor(MeasurementType type) {
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
    case MeasurementType.activityConcentration:
    case MeasurementType.spectrum:
    case MeasurementType.sample:
    case MeasurementType.meteorology:
    case MeasurementType.gasMeasurement:
      return const [];
  }
}

/// Alapértelmezett regiszter-egység. Dózisteljesítménynél nSv/h, mert a
/// korábban felvett műszerek is így működtek.
String defaultModbusUnitFor(MeasurementType type) =>
    type == MeasurementType.doseRate
        ? DoseRateUnit.instrumentNative.symbol
        : modbusUnitsFor(type).first;
