/// Egy terepi felmérés (egy jegyzőkönyvnek megfelelő egység).
///
/// A hozzá tartozó összes [MeasurementPoint] közösen exportálható a
/// jegyzőkönyvbe és a térképre.
class SurveySession {
  final int? id;
  final String title; // pl. "2026-09-26 – Telephely X felmérés"
  final String? location;
  final String? notes;
  final DateTime startedAt;
  final DateTime? closedAt; // null amíg a felmérés folyamatban van

  const SurveySession({
    this.id,
    required this.title,
    this.location,
    this.notes,
    required this.startedAt,
    this.closedAt,
  });

  bool get isClosed => closedAt != null;

  SurveySession copyWith({
    int? id,
    String? title,
    String? location,
    String? notes,
    DateTime? startedAt,
    DateTime? closedAt,
  }) {
    return SurveySession(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'notes': notes,
      'started_at': startedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }

  factory SurveySession.fromMap(Map<String, Object?> map) {
    return SurveySession(
      id: map['id'] as int?,
      title: map['title'] as String,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      closedAt: map['closed_at'] == null
          ? null
          : DateTime.parse(map['closed_at'] as String),
    );
  }
}