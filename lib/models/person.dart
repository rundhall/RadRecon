import 'victim_details.dart';
import 'dart:convert';

import 'person_certificate.dart';

/// Egy felmérésben résztvevő személy a globális nyilvántartásban (a
/// műszerekhez/forrásokhoz hasonlóan egyszer felvéve, utána bármelyik
/// felméréshez hozzárendelhető — lásd [SessionPersonLink]).
class Person {
  final int? id;

  final String name;

  final DateTime? medicalExamExpiryDate;
  final DateTime? trainingExpiryDate;

  final String? notes;

  final String? phone;

  /// Fontos e-mail címek (tetszőleges számú).
  final List<String> emails;

  /// Tetszőleges bizonyítványok lejárattal (nem az `persons` táblában tárolt).
  final List<PersonCertificate> certificates;

  /// Testi adatok (sérült esetén): nem, kor (év), súly és magasság.
  final VictimSex? sex;
  final int? ageYears;
  final double? weightKg; // közelítő
  final double? heightCm;

  /// Azonosító (pl. belső törzsszám) és lakcím / tartózkodási hely.
  final String? identifier;
  final String? address;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Person({
    this.id,
    required this.name,
    this.medicalExamExpiryDate,
    this.trainingExpiryDate,
    this.notes,
    this.phone,
    this.emails = const [],
    this.certificates = const [],
    this.sex,
    this.ageYears,
    this.weightKg,
    this.heightCm,
    this.identifier,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isMedicalExamExpiredAt(DateTime asOf) =>
      medicalExamExpiryDate != null && medicalExamExpiryDate!.isBefore(asOf);

  bool isTrainingExpiredAt(DateTime asOf) =>
      trainingExpiryDate != null && trainingExpiryDate!.isBefore(asOf);

  bool isExpiredAt(DateTime asOf) =>
      isMedicalExamExpiredAt(asOf) ||
      isTrainingExpiredAt(asOf) ||
      certificates.any((c) => c.isExpiredAt(asOf));

  Person copyWith({
    int? id,
    String? name,
    DateTime? medicalExamExpiryDate,
    DateTime? trainingExpiryDate,
    String? notes,
    String? phone,
    List<String>? emails,
    List<PersonCertificate>? certificates,
    VictimSex? sex,
    int? ageYears,
    double? weightKg,
    double? heightCm,
    String? identifier,
    String? address,
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
      phone: phone ?? this.phone,
      emails: emails ?? this.emails,
      certificates: certificates ?? this.certificates,
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      identifier: identifier ?? this.identifier,
      address: address ?? this.address,
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
      'phone': phone,
      'emails': emails.isEmpty ? null : jsonEncode(emails),
      'sex': sex?.dbValue,
      'age_years': ageYears,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'identifier': identifier,
      'address': address,
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
      phone: map['phone'] as String?,
      emails: _decodeEmails(map['emails']),
      sex: VictimSex.fromDbValue(map['sex'] as String?),
      ageYears: map['age_years'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      identifier: map['identifier'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static List<String> _decodeEmails(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final d = jsonDecode(raw);
      if (d is List) return d.whereType<String>().toList();
    } catch (_) {}
    return const [];
  }
}
