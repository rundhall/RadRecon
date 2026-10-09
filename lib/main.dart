import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/survey_session_screen.dart';
import 'services/app_reset.dart';
import 'services/expiry_notification_service.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';

import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // A mentett téma- és nyelv-választást még a runApp előtt be kell tölteni,
  // különben az app egy pillanatra a rossz témában/nyelven villanna fel.
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Diagnosztika: a Windows telepített változat néha örökre a runApp()
  // előtt akad el (nincs ablak, nincs konzol-kimenet dupla-kattintásra
  // indítva). Az alábbi debugPrint sorok és timeoutok azért kerültek be,
  // hogy egy `cmd`-ből indított .exe kimenetéből azonnal látható legyen,
  // melyik lépés nem tér vissza, és hogy az app ne fagyjon örökre, hanem
  // az alapértelmezett témával/nyelvvel induljon el hiba esetén.
  debugPrint('[startup] theme load: start');
  try {
    await ThemeController.load().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint(
          '[startup] theme load: TIMEOUT (5s) — folytatás alapértelmezett '
          'témával. Valószínű ok: a SharedPreferences plugin nem tud írni/'
          'olvasni az AppData mappában (jogosultság, OneDrive, vírusvédelem).',
        );
      },
    );
    debugPrint('[startup] theme load: done');
  } catch (e, st) {
    debugPrint('[startup] theme load: ERROR $e\n$st');
  }

  debugPrint('[startup] locale load: start');
  try {
    await LocaleController.load().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint(
          '[startup] locale load: TIMEOUT (5s) — continuation with system locale.',
        );
      },
    );
    debugPrint('[startup] locale load: done');
  } catch (e, st) {
    debugPrint('[startup] locale load: ERROR $e\n$st');
  }

  // Lejárati értesítések: init + az ütemezés felépítése az aktuális
  // adatokból (pl. időközben közelebb került dátumok miatt). Hiba esetén
  // az app ettől még elindul.
  try {
    await ExpiryNotificationService.instance.init().timeout(
      const Duration(seconds: 5),
    );
    ExpiryNotificationService.instance.rescheduleAll();
  } catch (e, st) {
    debugPrint('[startup] expiry notifications: ERROR $e\n$st');
  }

  debugPrint('[startup] runApp: calling');
  runApp(const AppResetScope(child: RadReconApp()));
  debugPrint('[startup] runApp: returned');
}

class RadReconApp extends StatelessWidget {
  const RadReconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'RadRecon',
              themeMode: mode,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepOrange,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              home: const SurveySessionScreen(),
              builder: (context, child) {
                return Stack(
                  children: [
                    ?child,
                    // Állandó, minden képernyőn megjelenő logó a bal alsó
                    // sarokban. IgnorePointer: nem foghatja el az
                    // érintéseket (pl. a mögötte lévő FAB vagy lista sem
                    // takarható el vele érdemben, mert a sarokban marad,
                    // kis mérettel).
                    /*Positioned(
                      left: 8,
                      bottom: 8,
                      child: IgnorePointer(
                        child: SafeArea(
                          child: Opacity(
                            opacity: 0.85,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ),
                      ),
                    ),*/
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
