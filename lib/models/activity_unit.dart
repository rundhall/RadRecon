import 'quantity_unit.dart';

/// Választható aktivitás-egységek. Alapegység (tárolás): MBq.
/// 1 Ci = 3,7·10^10 Bq (pontos definíció).
enum ActivityUnit implements QuantityUnit {
  bq('Bq', 'bq', 1e-6),
  kiloBq('kBq', 'kbq', 1e-3),
  megaBq('MBq', 'mbq', 1),
  gigaBq('GBq', 'gbq', 1e3),
  teraBq('TBq', 'tbq', 1e6),
  microCi('µCi', 'uci', 0.037),
  milliCi('mCi', 'mci', 37),
  ci('Ci', 'ci', 37000);

  const ActivityUnit(this.symbol, this.storageValue, this.mbqFactor);

  @override
  final String symbol;
  final String storageValue;
  final double mbqFactor;

  @override
  double get baseFactor => mbqFactor;

  static const defaultUnit = ActivityUnit.megaBq;

  double toMBq(double value) => value * mbqFactor;
  double fromMBq(double mbq) => mbq / mbqFactor;
  double convertTo(ActivityUnit target, double value) =>
      target.fromMBq(toMBq(value));

  static ActivityUnit fromStorage(String? value) => ActivityUnit.values
      .firstWhere((u) => u.storageValue == value, orElse: () => defaultUnit);
}
