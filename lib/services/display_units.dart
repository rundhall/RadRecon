import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/unit_catalog.dart';

/// A tárolt (kanonikus) mértékegységek. Az adatbázisban, a CSV/JSON
/// exportban és a mentésben mindig ezek szerepelnek; a megjelenítési egység
/// csak a kijelzésnél és a bevitelnél érvényesül.
const kDoseCanonicalUnit = 'µSv';
const kSurfaceCanonicalUnit = 'Bq/cm²';
const kTemperatureCanonicalUnit = '°C';
const kPressureCanonicalUnit = 'hPa';
const kWindCanonicalUnit = 'm/s';

/// Beállítható megjelenítési egységek (dózis, felületi szennyezettség,
/// hőmérséklet, nyomás, szél). Ugyanaz a minta, mint a többi egységvezérlő.
class DisplayUnits {
  DisplayUnits._();

  static const _keyDose = 'display_unit_dose';
  static const _keySurface = 'display_unit_surface';
  static const _keyTemperature = 'display_unit_temperature';
  static const _keyPressure = 'display_unit_pressure';
  static const _keyWind = 'display_unit_wind';

  /// Üres: automatikus (µSv, 1 mSv felett mSv).
  static final ValueNotifier<String> dose = ValueNotifier<String>('');
  static final ValueNotifier<String> surface =
      ValueNotifier<String>(kSurfaceCanonicalUnit);
  static final ValueNotifier<String> temperature =
      ValueNotifier<String>(kTemperatureCanonicalUnit);
  static final ValueNotifier<String> pressure =
      ValueNotifier<String>(kPressureCanonicalUnit);
  static final ValueNotifier<String> wind =
      ValueNotifier<String>(kWindCanonicalUnit);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dose.value = prefs.getString(_keyDose) ?? '';
    surface.value = prefs.getString(_keySurface) ?? kSurfaceCanonicalUnit;
    temperature.value =
        prefs.getString(_keyTemperature) ?? kTemperatureCanonicalUnit;
    pressure.value = prefs.getString(_keyPressure) ?? kPressureCanonicalUnit;
    wind.value = prefs.getString(_keyWind) ?? kWindCanonicalUnit;
  }

  static Future<void> _set(
      ValueNotifier<String> notifier, String key, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, symbol);
    notifier.value = symbol;
  }

  static Future<void> setDose(String symbol) =>
      _set(dose, _keyDose, symbol);
  static Future<void> setSurface(String symbol) =>
      _set(surface, _keySurface, symbol);
  static Future<void> setTemperature(String symbol) =>
      _set(temperature, _keyTemperature, symbol);
  static Future<void> setPressure(String symbol) =>
      _set(pressure, _keyPressure, symbol);
  static Future<void> setWind(String symbol) =>
      _set(wind, _keyWind, symbol);

  static UnitDef _def(UnitCategory c, String symbol) {
    final list = UnitCatalog.unitsOf(c);
    for (final u in list) {
      if (u.symbol == symbol) return u;
    }
    return list.first;
  }

  static double _conv(UnitCategory c, String from, String to, double v) =>
      UnitCatalog.convert(from: _def(c, from), to: _def(c, to), value: v) ?? v;

  // Dózis (tárolt µSv).
  static double doseFromMicroSv(double microSv, String target) =>
      _conv(UnitCategory.dose, kDoseCanonicalUnit, target, microSv);

  // Felületi szennyezettség (tárolt Bq/cm²).
  static double surfaceFromCanonical(double v) => _conv(
      UnitCategory.surfaceContamination,
      kSurfaceCanonicalUnit,
      surface.value,
      v);
  static double surfaceToCanonical(double v) => _conv(
      UnitCategory.surfaceContamination,
      surface.value,
      kSurfaceCanonicalUnit,
      v);

  // Meteorológia (tárolt °C, hPa, m/s).
  static double? tempFromC(double? v) => v == null
      ? null
      : _conv(UnitCategory.temperature, kTemperatureCanonicalUnit,
          temperature.value, v);
  static double? tempToC(double? v) => v == null
      ? null
      : _conv(UnitCategory.temperature, temperature.value,
          kTemperatureCanonicalUnit, v);
  static double? pressureFromHpa(double? v) => v == null
      ? null
      : _conv(UnitCategory.pressure, kPressureCanonicalUnit, pressure.value, v);
  static double? pressureToHpa(double? v) => v == null
      ? null
      : _conv(UnitCategory.pressure, pressure.value, kPressureCanonicalUnit, v);
  static double? windFromMs(double? v) => v == null
      ? null
      : _conv(UnitCategory.speed, kWindCanonicalUnit, wind.value, v);
  static double? windToMs(double? v) => v == null
      ? null
      : _conv(UnitCategory.speed, wind.value, kWindCanonicalUnit, v);
}

/// Mérési pont értéke a megjelenítési egységben: érték, hibasáv, egység.
typedef DisplayValue = ({double? value, double? error, String unit});

DisplayValue displayValueOf(MeasurementPoint p) {
  if (p.type != MeasurementType.surfaceContamination) {
    return (value: p.value, error: p.valueError, unit: p.unit);
  }
  return (
    value: p.value == null ? null : DisplayUnits.surfaceFromCanonical(p.value!),
    error: p.valueError == null
        ? null
        : DisplayUnits.surfaceFromCanonical(p.valueError!),
    unit: DisplayUnits.surface.value,
  );
}

/// Érték és egység a listában (4 tizedesig).
String displayValueText(MeasurementPoint p) {
  final shown = displayValueOf(p);
  final v = shown.value == null
      ? '—'
      : '${double.parse(shown.value!.toStringAsFixed(4))}';
  return '$v ${shown.unit}';
}
