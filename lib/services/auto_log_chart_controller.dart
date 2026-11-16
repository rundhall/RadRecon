import 'package:flutter/foundation.dart';

import 'settings_service.dart';

/// Az automatikus mérés idődiagramján megjelenített legutóbbi minták száma
/// (a Beállítások → Megjelenítés menüben állítható). `0` = mind.
class AutoLogChartController {
  AutoLogChartController._();

  static const int defaultPoints = 120;
  static const List<int> options = [60, 120, 300, 600, 1200, 0];

  static final ValueNotifier<int> points =
      ValueNotifier<int>(defaultPoints);

  /// A `main()`-ben, a `runApp()` előtt hívandó.
  static Future<void> load() async {
    final stored = await SettingsService().getAutoLogChartPoints();
    points.value = options.contains(stored) ? stored : defaultPoints;
  }

  static Future<void> setPoints(int value) async {
    await SettingsService().setAutoLogChartPoints(value);
    points.value = value;
  }
}
