import 'quantity_unit.dart';

/// Választható távolság-egységek. Alapegység (tárolás): méter.
enum DistanceUnit implements QuantityUnit {
  m('m', 'm', 1),
  cm('cm', 'cm', 0.01),
  inch('inch', 'inch', 0.0254),
  feet('feet', 'feet', 0.3048);

  const DistanceUnit(this.symbol, this.storageValue, this.meterFactor);

  @override
  final String symbol;
  final String storageValue;
  final double meterFactor;

  @override
  double get baseFactor => meterFactor;

  static const defaultUnit = DistanceUnit.m;

  double toMeters(double value) => value * meterFactor;
  double fromMeters(double meters) => meters / meterFactor;
  double convertTo(DistanceUnit target, double value) =>
      target.fromMeters(toMeters(value));

  static DistanceUnit fromStorage(String? value) => DistanceUnit.values
      .firstWhere((u) => u.storageValue == value, orElse: () => defaultUnit);
}
