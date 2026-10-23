import 'session_dosimeter.dart';
import '../services/display_units.dart';

/// A dózis forrása. A felmérési dózis a pontokból számolt vagy kézzel
/// rögzített érték (a korábbi online és manuális forrás összevonva).
enum DoseSource {
  /// Felméréshez kötött dózis: pontokból integrálva vagy kézzel megadva.
  session,

  /// Felmérésektől független, utólag kiértékelt passzív dozimetria
  /// (havi / kéthavi kiértékelés).
  passive,
}

extension DoseSourceX on DoseSource {
  /// Adatbázisban tárolt, stabil azonosító.
  String get dbValue => name;

  /// A régi `online` és `manual` értékeket (v22 előtti adatok, régi CSV-k)
  /// a `session` forrásba soroljuk.
  static DoseSource fromDbValue(String value) => switch (value) {
        'session' || 'online' || 'manual' => DoseSource.session,
        'passive' => DoseSource.passive,
        _ => throw ArgumentError('Ismeretlen dózisforrás: $value'),
      };
}

/// Egy személyhez rendelt dózis-bejegyzés. A dózis mindig µSv-ben tárolódik.
///
/// - [session]: felméréshez kötött, személyenként és felmérésenként legfeljebb egy.
/// - [passive]: felmérés nélküli, [periodStart]–[periodEnd] kiértékelési időszakkal;
///   az éves összegben a [doseDate] (= időszak vége) éve számít.
/// - [includeAnnual]: beszámít-e az éves dózisba (a felhasználó jelöli).
class PersonDose {
  final int? id;
  final int personId;
  final int? surveySessionId;
  final DoseSource source;
  final double doseMicroSv;

  /// Az a dátum, amely alapján a dózis az évhez tartozik.
  final DateTime doseDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool includeAnnual;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Csak JOIN-nál töltődik: a felmérés neve a listázáshoz.
  final String? surveyTitle;

  const PersonDose({
    this.id,
    required this.personId,
    this.surveySessionId,
    required this.source,
    required this.doseMicroSv,
    required this.doseDate,
    this.periodStart,
    this.periodEnd,
    this.includeAnnual = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.surveyTitle,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'person_id': personId,
        'survey_session_id': surveySessionId,
        'source': source.dbValue,
        'dose_usv': doseMicroSv,
        'dose_date': doseDate.toIso8601String(),
        'period_start': periodStart?.toIso8601String(),
        'period_end': periodEnd?.toIso8601String(),
        'include_annual': includeAnnual ? 1 : 0,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PersonDose.fromMap(Map<String, Object?> map) {
    DateTime? parse(Object? v) =>
        v == null ? null : DateTime.parse(v as String);
    return PersonDose(
      id: map['id'] as int?,
      personId: map['person_id'] as int,
      surveySessionId: map['survey_session_id'] as int?,
      source: DoseSourceX.fromDbValue(map['source'] as String),
      doseMicroSv: (map['dose_usv'] as num).toDouble(),
      doseDate: DateTime.parse(map['dose_date'] as String),
      periodStart: parse(map['period_start']),
      periodEnd: parse(map['period_end']),
      includeAnnual: (map['include_annual'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      surveyTitle: map['survey_title'] as String?,
    );
  }
}

/// Egy személy dózisa összegzve, µSv-ben, három csoportban.
class DoseTotals {
  /// Felmérési dózis (pontokból számolt vagy kézzel megadott).
  final double session;

  /// Doziméterek dózisa.
  final double dosimeter;

  /// Passzív (felmérésektől független) dózis.
  final double passive;

  const DoseTotals({this.session = 0, this.dosimeter = 0, this.passive = 0});

  static const zero = DoseTotals();

  double get total => session + dosimeter + passive;

  double of(DoseSource source) => switch (source) {
        DoseSource.session => session,
        DoseSource.passive => passive,
      };

  DoseTotals add(DoseSource source, double value) => DoseTotals(
        session: session + (source == DoseSource.session ? value : 0),
        dosimeter: dosimeter,
        passive: passive + (source == DoseSource.passive ? value : 0),
      );

  DoseTotals addDosimeter(double value) => DoseTotals(
        session: session,
        dosimeter: dosimeter + value,
        passive: passive,
      );
}

/// Egy felmérés dózisai: személyenként a felmérési dózis-bejegyzés és a
/// felmérés doziméterei. Az összesítés csak a beszámító tételeket veszi.
class SessionDoseSnapshot {
  const SessionDoseSnapshot({
    required this.sessionDoses,
    required this.dosimeters,
  });

  static const empty = SessionDoseSnapshot(
    sessionDoses: <int, PersonDose>{},
    dosimeters: <SessionDosimeter>[],
  );

  /// Személy-id → felmérési dózis-bejegyzés (felmérésenként legfeljebb egy).
  final Map<int, PersonDose> sessionDoses;
  final List<SessionDosimeter> dosimeters;

  PersonDose? sessionDoseOf(int personId) => sessionDoses[personId];

  List<SessionDosimeter> dosimetersOf(int personId) =>
      dosimeters.where((d) => d.personId == personId).toList();

  /// Az éves összesítésbe beszámító összegek személyenként.
  DoseTotals totalsFor(int personId) {
    final session = sessionDoses[personId];
    var dosimeterSum = 0.0;
    for (final d in dosimetersOf(personId)) {
      if (d.includeAnnual) dosimeterSum += d.resolvedDoseUsv ?? 0;
    }
    return DoseTotals(
      session: (session != null && session.includeAnnual)
          ? session.doseMicroSv
          : 0,
      dosimeter: dosimeterSum,
    );
  }
}

/// Dózis szövegesen (magyar tizedesvesszővel), 1 mSv fölött mSv-ben —
/// BuildContext nélküli helyekre (pl. jegyzőkönyv-export).
String formatDoseText(double microSv) {
  final target = DisplayUnits.dose.value;
  if (target.isNotEmpty) {
    return '${_trim(DisplayUnits.doseFromMicroSv(microSv, target), 3)} $target';
  }
  final abs = microSv.abs();
  final String text;
  if (abs >= 1000) {
    text = '${_trim(microSv / 1000, 3)} mSv';
  } else {
    text = '${_trim(microSv, abs < 1 ? 3 : 2)} µSv';
  }
  return text;
}

String _trim(double v, int decimals) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}
