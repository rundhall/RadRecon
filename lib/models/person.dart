/// Egy felmérésben résztvevő személy a globális nyilvántartásban (a
/// műszerekhez/forrásokhoz hasonlóan egyszer felvéve, utána bármelyik
/// felméréshez hozzárendelhető — lásd [SessionPersonLink]).
class Person {
  final int? id;

  final String name;

  final DateTime? medicalExamExpiryDate;
  final DateTime? trainingExpiryDate;

  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Person({
    this.id,
    required this.name,
    this.medicalExamExpiryDate,
    this.trainingExpiryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isMedicalExamExpiredAt(DateTime asOf) =>
      medicalExamExpiryDate != null && medicalExamExpiryDate!.isBefore(asOf);

  bool isTrainingExpiredAt(DateTime asOf) =>
      trainingExpiryDate != null && trainingExpiryDate!.isBefore(asOf);

  bool isExpiredAt(DateTime asOf) =>
      isMedicalExamExpiredAt(asOf) || isTrainingExpiredAt(asOf);

  Person copyWith({
    int? id,
    String? name,
    DateTime? medicalExamExpiryDate,
    DateTime? trainingExpiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      medicalExamExpiryDate:
          medicalExamExpiryDate ?? this.medicalExamExpiryDate,
      trainingExpiryDate: trainingExpiryDate ?? this.trainingExpiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'medical_exam_expiry_date': medicalExamExpiryDate?.toIso8601String(),
      'training_expiry_date': trainingExpiryDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, Object?> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      medicalExamExpiryDate: map['medical_exam_expiry_date'] == null
          ? null
          : DateTime.parse(map['medical_exam_expiry_date'] as String),
      trainingExpiryDate: map['training_expiry_date'] == null
          ? null
          : DateTime.parse(map['training_expiry_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
