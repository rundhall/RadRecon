import 'dose_rate_unit.dart';
import 'measurement_type.dart';

/// Mit mérhet egy Modbus-műszer a megadott regiszterben.
const kModbusMeasurableTypes = <MeasurementType>[
  MeasurementType.doseRate,
  MeasurementType.surfaceContamination,
  MeasurementType.cps,
  MeasurementType.neutronCps,
];

/// A regiszterben visszaadott érték választható mértékegységei típusonként.
/// Dózisteljesítménynél az összes támogatott egység, a többinél az egyetlen
/// értelmes egység (nincs mit elrontani).
List<String> modbusUnitsFor(MeasurementType type) {
  switch (type) {
    case MeasurementType.doseRate:
      return [for (final u in DoseRateUnit.values) u.symbol];
    case MeasurementType.surfaceContamination:
      return const ['Bq/cm²'];
    case MeasurementType.cps:
    case MeasurementType.neutronCps:
      return const ['cps'];
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
