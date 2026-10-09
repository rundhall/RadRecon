import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_type.dart';

/// Mennyivel a lejárat előtt jöjjön az értesítés.
enum ExpiryLeadTime {
  sameDay(0, 'same_day'),
  oneDay(1, 'one_day'),
  twoDays(2, 'two_days'),
  oneWeek(7, 'one_week');

  const ExpiryLeadTime(this.days, this.storageValue);
  final int days;
  final String storageValue;

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
  static const _expiryNotifEnabledKey = 'expiry_notifications_enabled';
  static const _expiryNotifLeadKey = 'expiry_notifications_lead';

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
        return const Locale('hu');
      case 'en':
        return const Locale('en');
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
}
