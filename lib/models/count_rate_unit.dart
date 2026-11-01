import 'quantity_unit.dart';

/// Beütésszám alapegysége: másodpercenként, kilo-másodpercenként, percenként,
/// óránként.
enum CountRateUnit {
  perSecond('cps', 1),
  kiloPerSecond('kcps', 1000),
  perMinute('cpm', 1 / 60),
  perHour('cph', 1 / 3600);

  const CountRateUnit(this.base, this.perSecondFactor);

  /// A jelölés neutron-előtag nélkül (pl. "cps").
  final String base;

  /// Hány beütés/s egy egység (cps = 1).
  final double perSecondFactor;
}

/// Beütésszám-egység a sugárzás szerint: neutronnál "n" előtag (ncps, ncpm…).
/// A példányok konstansok, így a legördülő lista és a kiválasztott érték
/// azonos objektum (a Dropdown ezt igényli).
class CountRateOption implements QuantityUnit {
  const CountRateOption(this.unit, this.neutron);

  final CountRateUnit unit;
  final bool neutron;

  @override
  String get symbol => neutron ? 'n${unit.base}' : unit.base;

  /// Az alapegység: beütés/s.
  @override
  double get baseFactor => unit.perSecondFactor;

  static const _standard = [
    CountRateOption(CountRateUnit.perSecond, false),
    CountRateOption(CountRateUnit.kiloPerSecond, false),
    CountRateOption(CountRateUnit.perMinute, false),
    CountRateOption(CountRateUnit.perHour, false),
  ];

  static const _neutron = [
    CountRateOption(CountRateUnit.perSecond, true),
    CountRateOption(CountRateUnit.kiloPerSecond, true),
    CountRateOption(CountRateUnit.perMinute, true),
    CountRateOption(CountRateUnit.perHour, true),
  ];

  static List<CountRateOption> forRadiation({required bool neutron}) =>
      neutron ? _neutron : _standard;

  static CountRateOption? fromSymbol(String? symbol) {
    for (final o in _standard) {
      if (o.symbol == symbol) return o;
    }
    for (final o in _neutron) {
      if (o.symbol == symbol) return o;
    }
    return null;
  }
}
