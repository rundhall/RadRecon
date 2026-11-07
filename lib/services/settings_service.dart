import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_unit.dart';
import '../models/decimal_separator.dart';
import '../models/distance_unit.dart';
import '../models/hardware_button.dart';
import '../models/dose_rate_unit.dart';
import '../models/measurement_type.dart';

/// Mennyivel a lejárat előtt jöjjön az értesítés.
/// Napos (days) vagy hónapos (months) előrehozás. A hónapos értékek 1–12 hónapig
/// terjedhetnek, hogy a hitelesítés/kalibrálás időben elintézhető legyen.
enum ExpiryLeadTime {
  sameDay(0, 0, 'same_day'),
  oneDay(1, 0, 'one_day'),
  twoDays(2, 0, 'two_days'),
  oneWeek(7, 0, 'one_week'),
  twoWeeks(14, 0, 'two_weeks'),
  oneMonth(0, 1, 'month_1'),
  twoMonths(0, 2, 'month_2'),
  threeMonths(0, 3, 'month_3'),
  fourMonths(0, 4, 'month_4'),
  fiveMonths(0, 5, 'month_5'),
  sixMonths(0, 6, 'month_6'),
  sevenMonths(0, 7, 'month_7'),
  eightMonths(0, 8, 'month_8'),
  nineMonths(0, 9, 'month_9'),
  tenMonths(0, 10, 'month_10'),
  elevenMonths(0, 11, 'month_11'),
  twelveMonths(0, 12, 'month_12');

  const ExpiryLeadTime(this.days, this.months, this.storageValue);
  final int days;
  final int months;
  final String storageValue;

  bool get isMonths => months > 0;

  /// Az a naptári nap, amelyen az értesítésnek meg kell jelennie.
  /// Hónapos előrehozásnál a lejárat napja megmarad a céldátumban; ha a
  /// céljhónap rövidebb, a hónap utolsó napjára szorul (pl. 31. → 28./29.).
  DateTime alertDayFor(DateTime expiry) {
    if (!isMonths) {
      return DateTime(expiry.year, expiry.month, expiry.day - days);
    }
    final firstOfTarget = DateTime(expiry.year, expiry.month - months, 1);
    final lastDay =
        DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
    final day = expiry.day > lastDay ? lastDay : expiry.day;
    return DateTime(firstOfTarget.year, firstOfTarget.month, day);
  }

  static ExpiryLeadTime fromStorage(String? value) => ExpiryLeadTime.values
      .firstWhere((e) => e.storageValue == value, orElse: () => sameDay);
}

/// Egyszerű, eszközön tárolt beállítások — típusonkénti riasztási
/// küszöbértékek, és a világos/sötét téma választás.
/// `null` küszöb = nincs beállítva riasztás az adott típushoz.
class SettingsService {
  static const _prefix = 'alert_threshold_';
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'app_locale';
  static const _doseUnitKey = 'dose_rate_unit';
  static const _activityUnitKey = 'activity_unit';
  static const _distanceUnitKey = 'distance_unit';
  static const _decimalSeparatorKey = 'decimal_separator';
  static const _expiryNotifEnabledKey = 'expiry_notifications_enabled';
  static const _expiryNotifLeadKey = 'expiry_notifications_lead';
  static const _bluetoothButtonsKey = 'bluetooth_buttons_enabled';
  static const _keepScreenOnKey = 'keep_screen_on';
  static const _buttonCommandPrefix = 'button_command_';

  /// Régi küszöbkulcs átvétele: a cps-küszöb a beütésszám típusé lesz. A
  /// neutron-beütésszám küszöbe nem kerül át (neutronnál nincs riasztás).
  Future<void> migrateLegacyCountRateThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('${_prefix}count_rate')) return;
    final legacy = prefs.getDouble('${_prefix}cps');
    if (legacy != null) await prefs.setDouble('${_prefix}count_rate', legacy);
  }

  Future<Map<MeasurementType, double?>> getAllThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final type in MeasurementType.values)
        type: prefs.getDouble('$_prefix${type.dbValue}'),
    };
  }

  Future<double?> getThreshold(MeasurementType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_prefix${type.dbValue}');
  }

  Future<void> setThreshold(MeasurementType type, double? value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${type.dbValue}';
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setDouble(key, value);
    }
  }

  /// Dózisteljesítmény alapegysége. Alapértelmezett: µSv/h.
  Future<DoseRateUnit> getDoseRateUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return DoseRateUnit.fromStorage(prefs.getString(_doseUnitKey));
  }

  Future<void> setDoseRateUnit(DoseRateUnit value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doseUnitKey, value.storageValue);
  }

  Future<ActivityUnit> getActivityUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return ActivityUnit.fromStorage(prefs.getString(_activityUnitKey));
  }

  Future<void> setActivityUnit(ActivityUnit value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activityUnitKey, value.storageValue);
  }

  Future<DistanceUnit> getDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return DistanceUnit.fromStorage(prefs.getString(_distanceUnitKey));
  }

  Future<void> setDistanceUnit(DistanceUnit value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_distanceUnitKey, value.storageValue);
  }

  Future<DecimalSeparatorMode> getDecimalSeparator() async {
    final prefs = await SharedPreferences.getInstance();
    return DecimalSeparatorMode.fromStorage(
      prefs.getString(_decimalSeparatorKey),
    );
  }

  Future<void> setDecimalSeparator(DecimalSeparatorMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_decimalSeparatorKey, value.storageValue);
  }

  Future<double?> getDoseRateThreshold() =>
      getThreshold(MeasurementType.doseRate);

  Future<void> setDoseRateThreshold(double? value) =>
      setThreshold(MeasurementType.doseRate, value);

  /// Elmentett téma-mód beolvasása. Alapértelmezett: a telefon rendszer-
  /// beállítása (`ThemeMode.system`), ha még nincs mentett érték, vagy a
  /// mentett szöveg valamiért ismeretlen.
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
  }

  /// Elmentett nyelv beolvasása. `null` = kövesse a telefon nyelvét — ez az
  /// alapértelmezett, ha még nincs mentett explicit választás.
  Future<Locale?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_localeKey);
    switch (stored) {
      case 'hu':
      case 'en':
      case 'de':
      case 'es':
      case 'fr':
      case 'it':
        return Locale(stored!);
      default:
        return null;
    }
  }

  Future<void> setLocale(Locale? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, value.languageCode);
    }
  }

  /// Lejárati értesítések ki/be kapcsolása. Alapértelmezett: kikapcsolva.
  Future<bool> getExpiryNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_expiryNotifEnabledKey) ?? false;
  }

  Future<void> setExpiryNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expiryNotifEnabledKey, value);
  }

  /// Az értesítés előrehozása. Alapértelmezett: a lejárat napján.
  Future<ExpiryLeadTime> getExpiryLeadTime() async {
    final prefs = await SharedPreferences.getInstance();
    return ExpiryLeadTime.fromStorage(prefs.getString(_expiryNotifLeadKey));
  }

  Future<void> setExpiryLeadTime(ExpiryLeadTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expiryNotifLeadKey, value.storageValue);
  }

  /// Bluetooth-gombvezérlés be/ki. Alapértelmezett: kikapcsolva.
  Future<bool> getBluetoothButtonsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bluetoothButtonsKey) ?? false;
  }

  Future<void> setBluetoothButtonsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bluetoothButtonsKey, value);
  }

  /// A képernyő folyamatos ébren tartása. Alapértelmezett: kikapcsolva.
  Future<bool> getKeepScreenOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepScreenOnKey) ?? false;
  }

  Future<void> setKeepScreenOn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepScreenOnKey, value);
  }

  /// Gombonkénti parancs. Ha még nincs mentett érték, a gomb alapértelmezése.
  static const _learnedKeysKey = 'button_learned_keys';

  Future<List<LearnedKey>> getLearnedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_learnedKeysKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final result = <LearnedKey>[];
      for (final e in decoded) {
        final k = LearnedKey.fromJson(e);
        if (k != null) result.add(k);
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> setLearnedKeys(List<LearnedKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _learnedKeysKey,
      jsonEncode([for (final k in keys) k.toJson()]),
    );
  }

  Future<ButtonCommand> getButtonCommand(HardwareButton button) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_buttonCommandPrefix${button.name}');
    if (stored == null) return button.defaultCommand;
    return ButtonCommand.fromStorage(stored);
  }

  Future<void> setButtonCommand(
    HardwareButton button,
    ButtonCommand command,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_buttonCommandPrefix${button.name}',
      command.storageValue,
    );
  }
}
