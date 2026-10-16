import 'package:flutter/foundation.dart';

import '../models/activity_unit.dart';
import '../models/distance_unit.dart';
import '../models/dose_rate_unit.dart';
import 'settings_service.dart';

/// Globális, app-szintű dózisteljesítmény-alapegység (a Beállításokban
/// választható). Ugyanaz a minta, mint a `LocaleController`-nél.
class DoseUnitController {
  DoseUnitController._();

  static final ValueNotifier<DoseRateUnit> unit =
      ValueNotifier<DoseRateUnit>(DoseRateUnit.defaultUnit);

  static DoseRateUnit get current => unit.value;

  /// A `main()`-ben, a `runApp()` előtt hívandó.
  static Future<void> load() async {
    unit.value = await SettingsService().getDoseRateUnit();
    ActivityUnitController.unit.value =
        await SettingsService().getActivityUnit();
    DistanceUnitController.unit.value =
        await SettingsService().getDistanceUnit();
  }

  /// Egységváltás: a mentett dózisteljesítmény-riasztási küszöböt is átváltja,
  /// hogy ugyanazt a fizikai értéket jelentse az új egységben.
  static Future<void> setUnit(DoseRateUnit value) async {
    final old = unit.value;
    if (old == value) return;
    final service = SettingsService();
    final threshold = await service.getDoseRateThreshold();
    if (threshold != null) {
      await service.setDoseRateThreshold(old.convertTo(value, threshold));
    }
    await service.setDoseRateUnit(value);
    unit.value = value;
  }
}

/// Aktivitás alapegysége (Beállításokban választható).
class ActivityUnitController {
  ActivityUnitController._();

  static final ValueNotifier<ActivityUnit> unit =
      ValueNotifier<ActivityUnit>(ActivityUnit.defaultUnit);

  static ActivityUnit get current => unit.value;

  static Future<void> setUnit(ActivityUnit value) async {
    await SettingsService().setActivityUnit(value);
    unit.value = value;
  }
}

/// Távolság alapegysége (Beállításokban választható).
class DistanceUnitController {
  DistanceUnitController._();

  static final ValueNotifier<DistanceUnit> unit =
      ValueNotifier<DistanceUnit>(DistanceUnit.defaultUnit);

  static DistanceUnit get current => unit.value;

  static Future<void> setUnit(DistanceUnit value) async {
    await SettingsService().setDistanceUnit(value);
    unit.value = value;
  }
}
