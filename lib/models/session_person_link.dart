import 'person.dart';

/// Egy személy hozzárendelése egy felméréshez — ugyanaz a személy több
/// felméréshez is rendelhető, egy felméréshez pedig több személy is
/// tartozhat.
class SessionPersonLink {
  final int? id;
  final int surveySessionId;
  final int personId;
  final DateTime createdAt;

  const SessionPersonLink({
    this.id,
    required this.surveySessionId,
    required this.personId,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'survey_session_id': surveySessionId,
      'person_id': personId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionPersonLink.fromMap(Map<String, Object?> map) {
    return SessionPersonLink(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      personId: map['person_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
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
