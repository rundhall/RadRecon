import 'package:flutter/material.dart';

import 'settings_service.dart';

/// Globális, app-szintű téma-állapot (light / dark / rendszer).
///
/// A `ValueNotifier` a legegyszerűbb eszköz erre — nem igényel külön csomagot
/// (pl. `provider`), és a `main.dart`-ban egy `ValueListenableBuilder` elég,
/// hogy a `MaterialApp` azonnal újraépüljön, amikor a Beállításokban valaki
/// vált. A választás emellett `SharedPreferences`-be is kiírásra kerül
/// (lásd `SettingsService`), hogy alkalmazás-újraindítás után is megmaradjon.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  /// Az elmentett téma-beállítás betöltése — a `main()`-ben, még a
  /// `runApp()` előtt hívandó, hogy ne villanjon fel a rossz téma.
  static Future<void> load() async {
    themeMode.value = await SettingsService().getThemeMode();
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await SettingsService().setThemeMode(mode);
  }
}