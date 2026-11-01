import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_type.dart';

/// Az utoljára választott mérési típus. Az új mérési pont ezzel indul.
class LastMeasurementTypeController {
  LastMeasurementTypeController._();

  static const _key = 'last_measurement_type';

  static final ValueNotifier<MeasurementType> type =
      ValueNotifier<MeasurementType>(MeasurementType.doseRate);

  static MeasurementType get current => type.value;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null) return;
    for (final t in MeasurementType.values) {
      if (t.dbValue == stored) {
        type.value = t;
        return;
      }
    }
  }

  static Future<void> remember(MeasurementType t) async {
    type.value = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, t.dbValue);
  }
}
