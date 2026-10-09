import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'locale_controller.dart';
import 'settings_service.dart';

/// Lejárati értesítések: a források (szolgálati idő lejárata, következő
/// ellenőrzés) és a személyek (orvosi vizsgálat, oktatás) jövőbeli lejárati
/// dátumaira ütemez helyi értesítést, a beállított előrehozással, reggel
/// [notificationHour] órára.
///
/// Az ütemezés mindig "tiszta lappal" történik: minden korábbi értesítést
/// töröl, majd az aktuális adatokból újra felépíti — így nem maradhat
/// árva értesítés egy módosított vagy törölt dátum után.
class ExpiryNotificationService {
  ExpiryNotificationService._();
  static final ExpiryNotificationService instance =
      ExpiryNotificationService._();

  /// Az értesítések napi időpontja (helyi idő szerint).
  static const notificationHour = 8;

  /// iOS legfeljebb 64 ütemezett értesítést tart meg, ezért a legkorábbiakat
  /// vesszük előre.
  static const _maxScheduled = 60;

  static const _channelId = 'expiry_notifications';

  /// Csak telefonon/táblagépen és Macen támogatott — Windows/Linux alatt
  /// nincs megbízható, az app zárt állapotában is működő ütemezés.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _rescheduling = false;
  bool _reschedulePending = false;

  Future<void> init() async {
    if (!isSupported || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[expiry-notif] időzóna lekérdezés sikertelen: $e');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Az engedélyt nem indításkor, hanem a kapcsoló bekapcsolásakor
        // kérjük el (lásd requestPermission).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;

    // Adatváltozás (felvétel/módosítás/törlés/import) és nyelvváltás után
    // újraépítjük az ütemezést.
    DatabaseHelper.onExpiryDataChanged = rescheduleAll;
    LocaleController.locale.addListener(rescheduleAll);
  }

  /// Értesítési engedély kérése. `true`, ha az értesítések megjeleníthetők.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    return await mac?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  /// Az összes lejárati értesítés újraütemezése az aktuális adatokból és
  /// beállításokból. Egyszerre csak egy futhat; ha közben újabb kérés jön,
  /// a futás végén még egyszer lefut.
  Future<void> rescheduleAll() async {
    if (!isSupported || !_initialized) return;
    if (_rescheduling) {
      _reschedulePending = true;
      return;
    }
    _rescheduling = true;
    try {
      do {
        _reschedulePending = false;
        await _rescheduleOnce();
      } while (_reschedulePending);
    } catch (e, st) {
      debugPrint('[expiry-notif] notification error: $e\n$st');
    } finally {
      _rescheduling = false;
    }
  }

  Future<void> _rescheduleOnce() async {
    await _plugin.cancelAll();

    final settings = SettingsService();
    if (!await settings.getExpiryNotificationsEnabled()) return;
    final lead = await settings.getExpiryLeadTime();

    final loc = _localizations();
    final dateFormat = DateFormat.yMd(loc.localeName);
    final now = tz.TZDateTime.now(tz.local);

    final db = DatabaseHelper.instance;
    final persons = await db.getPersons();
    final sources = await db.getRadiationSources();
    final instruments = await db.getInstruments();

    final candidates = <_Candidate>[];

    void add(String subject, String kind, DateTime? expiry) {
      if (expiry == null) return;
      final fireAt = tz.TZDateTime(
        tz.local,
        expiry.year,
        expiry.month,
        expiry.day - lead.days,
        notificationHour,
      );
      if (!fireAt.isAfter(now)) return;
      candidates.add(
        _Candidate(
          fireAt: fireAt,
          title: lead == ExpiryLeadTime.sameDay
              ? loc.expiryNotificationTitleToday
              : loc.expiryNotificationTitleUpcoming,
          body: '$subject – $kind: ${dateFormat.format(expiry)}',
        ),
      );
    }

    for (final s in sources) {
      add(s.identifier, loc.serviceLifeExpiryDateLabel, s.serviceLifeExpiryDate);
      add(s.identifier, loc.nextInspectionDateLabel, s.nextInspectionDate);
    }
    for (final p in persons) {
      add(p.name, loc.medicalExamExpiryDateLabel, p.medicalExamExpiryDate);
      add(p.name, loc.trainingExpiryDateLabel, p.trainingExpiryDate);
    }
    for (final i in instruments) {
      add(i.name, loc.nextCalibrationLabel, i.nextCalibrationDate);
    }

    candidates.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        loc.expiryNotificationChannelName,
        channelDescription: loc.expiryNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    var id = 0;
    for (final c in candidates.take(_maxScheduled)) {
      await _plugin.zonedSchedule(
        id: id++,
        title: c.title,
        body: c.body,
        scheduledDate: c.fireAt,
        notificationDetails: details,
        // Pontos ébresztés (külön engedély) helyett a rendszer által
        // csoportosított időzítés: a reggeli emlékeztetőhöz pár perc
        // csúszás nem számít.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  AppLocalizations _localizations() {
    final locale =
        LocaleController.locale.value ?? PlatformDispatcher.instance.locale;
    try {
      return lookupAppLocalizations(Locale(locale.languageCode));
    } catch (_) {
      return lookupAppLocalizations(const Locale('hu'));
    }
  }
}

class _Candidate {
  final tz.TZDateTime fireAt;
  final String title;
  final String body;
  const _Candidate({
    required this.fireAt,
    required this.title,
    required this.body,
  });
}
