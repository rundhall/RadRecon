import 'dart:ui';

import 'package:url_launcher/url_launcher.dart';

import 'locale_controller.dart';

/// A használati útmutató megnyitása a böngészőben, az app (vagy, ha az
/// nincs külön beállítva, a telefon) nyelvén. Nem támogatott nyelvnél angol.
class HelpLauncher {
  HelpLauncher._();

  static const _supported = {'hu', 'en', 'de', 'es', 'fr', 'it'};

  static Uri manualUri() {
    final code = (LocaleController.locale.value ??
            PlatformDispatcher.instance.locale)
        .languageCode;
    final lang = _supported.contains(code) ? code : 'en';
    return Uri.parse('https://radrecon.hu/user_manual/$lang/manual.html');
  }

  /// `true`, ha sikerült megnyitni.
  static Future<bool> openManual() async {
    try {
      return await launchUrl(manualUri(), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
