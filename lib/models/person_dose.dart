/// A dózis forrása — a személy éves dózisában külön jelezzük, mert más a
/// megbízhatóságuk és más a kiértékelési ciklusuk.
enum DoseSource {
  /// Modbus detektor dózisteljesítményéből az app által integrált dózis
  /// (felméréshez kötött).
  online,

  /// Felméréshez kötött, kézzel rögzített (vagy a lezáráskor korrigált) dózis.
  manual,

  /// Felmérésektől független, utólag kiértékelt passzív dozimetria
  /// (havi / kéthavi kiértékelés).
  passive,
}

extension DoseSourceX on DoseSource {
  /// Adatbázisban tárolt, stabil azonosító.
  String get dbValue => name;

  static DoseSource fromDbValue(String value) => DoseSource.values.firstWhere(
        (s) => s.name == value,
        orElse: () => throw ArgumentError('Ismeretlen dózisforrás: $value'),
      );
}

/// Egy személyhez rendelt dózis-bejegyzés. A dózis mindig µSv-ben tárolódik.
///
/// - [online] / [manual]: felméréshez kötött ([surveySessionId] kitöltött),
///   személyenként és felmérésenként legfeljebb egy-egy.
/// - [passive]: felmérés nélküli, [periodStart]–[periodEnd] kiértékelési
///   időszakkal; az éves összegben a [doseDate] (= időszak vége) éve számít.
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
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      surveyTitle: map['survey_title'] as String?,
    );
  }
}

/// Egy személy egy évre összegzett dózisa forrásonkénti bontásban (µSv).
class DoseTotals {
  final double online;
  final double manual;
  final double passive;

  const DoseTotals({this.online = 0, this.manual = 0, this.passive = 0});

  static const zero = DoseTotals();

  double get total => online + manual + passive;

  double of(DoseSource source) => switch (source) {
        DoseSource.online => online,
        DoseSource.manual => manual,
        DoseSource.passive => passive,
      };

  DoseTotals add(DoseSource source, double value) => DoseTotals(
        online: online + (source == DoseSource.online ? value : 0),
        manual: manual + (source == DoseSource.manual ? value : 0),
        passive: passive + (source == DoseSource.passive ? value : 0),
      );
}

/// Dózis szövegesen (magyar tizedesvesszővel), 1 mSv fölött mSv-ben —
/// BuildContext nélküli helyekre (pl. jegyzőkönyv-export).
String formatDoseText(double microSv) {
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
