/// Doziméter típusa. Az elektronikus (EPD) doziméternél a kezdő- és záróállás
/// adja a dózist; a passzív (TL) doziméternél a kiértékelt dózist kell megadni.
enum DosimeterKind {
  epdGamma('epd_gamma', electronic: true),
  epdNeutron('epd_neutron', electronic: true),
  tlOfficial('tl_official', electronic: false),
  tlWorkplace('tl_workplace', electronic: false);

  const DosimeterKind(this.dbValue, {required this.electronic});

  /// Adatbázisban tárolt, stabil azonosító.
  final String dbValue;

  /// Elektronikus-e (kezdő/záró állás), vagy passzív (kiértékelt dózis).
  final bool electronic;

  static DosimeterKind fromDbValue(String value) =>
      DosimeterKind.values.firstWhere(
        (k) => k.dbValue == value,
        orElse: () => throw ArgumentError('Ismeretlen doziméter-típus: $value'),
      );
}

/// Egy felméréshez rendelt doziméter. Egy felmérésnél tetszőleges számú lehet.
class SessionDosimeter {
  final int? id;
  final int surveySessionId;
  final DosimeterKind kind;
  final String identifier;

  /// A viselő személy; lehet üres, ha még nincs hozzárendelve.
  final int? personId;

  /// Csak JOIN-nál töltődik: a viselő neve a listázáshoz.
  final String? personName;

  /// Elektronikus doziméter kezdő és záró állása (µSv).
  final double? startUsv;
  final double? endUsv;

  /// Passzív doziméter kiértékelt dózisa (µSv).
  final double? doseUsv;

  /// Beszámít-e az éves dózisba.
  final bool includeAnnual;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SessionDosimeter({
    this.id,
    required this.surveySessionId,
    required this.kind,
    required this.identifier,
    this.personId,
    this.personName,
    this.startUsv,
    this.endUsv,
    this.doseUsv,
    this.includeAnnual = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// A doziméter dózisa µSv-ben: elektronikusnál a záró - kezdő állás (ha
  /// mindkettő megvan), passzívnál a megadott dózis. Null, ha még nincs adat.
  double? get resolvedDoseUsv {
    if (kind.electronic) {
      final start = startUsv;
      final end = endUsv;
      if (start == null || end == null) return null;
      final diff = end - start;
      return diff < 0 ? 0 : diff;
    }
    return doseUsv;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'survey_session_id': surveySessionId,
        'kind': kind.dbValue,
        'identifier': identifier,
        'person_id': personId,
        'start_usv': startUsv,
        'end_usv': endUsv,
        'dose_usv': doseUsv,
        'include_annual': includeAnnual ? 1 : 0,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SessionDosimeter.fromMap(Map<String, Object?> map) =>
      SessionDosimeter(
        id: map['id'] as int?,
        surveySessionId: map['survey_session_id'] as int,
        kind: DosimeterKind.fromDbValue(map['kind'] as String),
        identifier: map['identifier'] as String,
        personId: map['person_id'] as int?,
        personName: map['person_name'] as String?,
        startUsv: (map['start_usv'] as num?)?.toDouble(),
        endUsv: (map['end_usv'] as num?)?.toDouble(),
        doseUsv: (map['dose_usv'] as num?)?.toDouble(),
        includeAnnual: (map['include_annual'] as int? ?? 1) == 1,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
