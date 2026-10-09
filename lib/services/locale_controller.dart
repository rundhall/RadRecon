import 'package:flutter/material.dart';

import 'settings_service.dart';

/// Globális, app-szintű nyelv-állapot. `null` = kövesse a telefon nyelvét —
/// a `MaterialApp.locale`-nek `null`-t adva a Flutter automatikusan a
/// rendszer nyelvét próbálja feloldani a támogatott nyelvek közül.
///
/// Ugyanaz a `ValueNotifier`-alapú minta, mint a `ThemeController`-nél: a
/// `main.dart`-ban egy `ValueListenableBuilder` azonnal újraépíti a
/// `MaterialApp`-ot, amikor bárhol vált a nyelv, és a választás
/// `SharedPreferences`-be is kiírásra kerül (lásd `SettingsService`), hogy
/// alkalmazás-újraindítás után is megmaradjon.
class LocaleController {
  LocaleController._();

  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  /// Az elmentett nyelv-beállítás betöltése — a `main()`-ben, még a
  /// `runApp()` előtt hívandó.
  static Future<void> load() async {
    locale.value = await SettingsService().getLocale();
  }

  static Future<void> setLocale(Locale? value) async {
    locale.value = value;
    await SettingsService().setLocale(value);
  }
}
