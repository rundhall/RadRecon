import '../models/dose_rate_unit.dart';
import '../models/instrument.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import 'dose_unit_controller.dart';

/// Dózisteljesítmény-egységek átalakítása közös alapra (µSv/h), hogy a mért
/// és a számított érték összevethető legyen — az app maga nem konvertál
/// típusok/egységek között máshol, de az összehasonlításhoz szükséges.
///
/// Ismeretlen/nem felismert egységnél `null`-t ad vissza, ekkor az
/// összehasonlítás nem végezhető el.
double? toMicroSievertPerHour(double value, String unit) {
  final parsed = DoseRateUnit.fromSymbol(unit);
  return parsed?.toMicroSvPerHour(value);
}

/// A dózisteljesítmény-pontot az aktuális alapegységre váltja (megjelenítéshez,
/// színezéshez, gradiens-számításhoz), hogy a régebben más egységben (pl.
/// nSv/h) rögzített pontok ne keveredjenek az újakkal. Más típust, vagy nem
/// felismerhető egységet érintetlenül hagy; az adatbázisban nem módosít semmit.
MeasurementPoint withCurrentDoseUnit(MeasurementPoint p) {
  if (p.type != MeasurementType.doseRate || p.value == null) return p;
  final from = DoseRateUnit.fromSymbol(p.unit);
  if (from == null) return p;
  final target = DoseUnitController.current;
  if (from == target) return p;
  return p.copyWith(
    value: from.convertTo(target, p.value!),
    valueError: p.valueError == null
        ? null
        : from.convertTo(target, p.valueError!),
    unit: target.symbol,
  );
}

/// A műszer Modbus regiszterében kiolvasott nyers értéket az app alapegységére
/// váltja. Dózisteljesítménynél a műszerhez beállított regiszter-egységből
/// (pl. nSv/h) a Beállításokban választott alapegységre; a többi típusnál
/// (Bq/cm², cps) nincs átváltás.
double instrumentReadingInAppUnit(Instrument instrument, double raw) {
  if (instrument.modbusMeasurementType != MeasurementType.doseRate) return raw;
  final from = DoseRateUnit.fromSymbol(instrument.modbusUnit) ??
      DoseRateUnit.instrumentNative;
  return from.convertTo(DoseUnitController.current, raw);
}
