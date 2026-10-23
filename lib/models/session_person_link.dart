import 'person.dart';

/// Egy felméréshez rendelt személy szerepe: felmérőként vagy érintettként
/// (áldozat, sérült) van jelen.
enum SessionPersonRole {
  surveyor('surveyor', 'Felmérő'),
  victim('victim', 'Érintett / áldozat');

  const SessionPersonRole(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static SessionPersonRole fromDbValue(String? value) =>
      SessionPersonRole.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => SessionPersonRole.surveyor,
      );
}

/// Az érintett személy triázs-besorolása (START-jellegű színkódok).
enum TriageCategory {
  immediate('red', 'Piros – azonnali ellátás'),
  delayed('yellow', 'Sárga – halasztható ellátás'),
  minor('green', 'Zöld – könnyű sérülés'),
  expectant('black', 'Fekete – elhunyt / nincs ellátás');

  const TriageCategory(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TriageCategory? fromDbValue(String? value) {
    if (value == null) return null;
    for (final t in TriageCategory.values) {
      if (t.dbValue == value) return t;
    }
    return null;
  }
}

/// Egy személy hozzárendelése egy felméréshez — ugyanaz a személy több
/// felméréshez is rendelhető, egy felméréshez pedig több személy is
/// tartozhat.
class SessionPersonLink {
  final int? id;
  final int surveySessionId;
  final int personId;
  final DateTime createdAt;
  final SessionPersonRole role;
  final TriageCategory? triage;

  const SessionPersonLink({
    this.id,
    required this.surveySessionId,
    required this.personId,
    required this.createdAt,
    this.role = SessionPersonRole.surveyor,
    this.triage,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'survey_session_id': surveySessionId,
      'person_id': personId,
      'created_at': createdAt.toIso8601String(),
      'role': role.dbValue,
      'triage': triage?.dbValue,
    };
  }

  factory SessionPersonLink.fromMap(Map<String, Object?> map) {
    return SessionPersonLink(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      personId: map['person_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      role: SessionPersonRole.fromDbValue(map['role'] as String?),
      triage: TriageCategory.fromDbValue(map['triage'] as String?),
    );
  }
}

/// Egy felméréshez rendelt személy, a hozzárendelés adataival és a
/// (globális nyilvántartásból betöltött) személy-adatokkal együtt — ezt
/// adja vissza a `DatabaseHelper.getAttachedPersons` JOIN-lekérdezése.
class AttachedPerson {
  final SessionPersonLink link;
  final Person person;

  const AttachedPerson({required this.link, required this.person});
}
