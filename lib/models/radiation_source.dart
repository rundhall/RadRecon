import 'isotope.dart';

/// Egy sugárforrás a globális forrás-nyilvántartásban (a műszerekhez
/// hasonlóan egyszer felvéve, utána bármelyik mérési ponthoz hozzárendelhető
/// — lásd [PointSourceLink]).
///
/// A gyártáskori aktivitásból és a nuklid felezési idejéből bármely later
/// időpontra visszaszámolható az aktuális aktivitás.
class RadiationSource {
  final int? id;

  final String identifier; // gyártói/leltári egyedi azonosító
  final String nuclideName; // pl. "Co-60", vagy kézzel megadott név

  final double activityAtManufactureMBq;
  final double? activityErrorPercent; // a gyártói aktivitás-adat hibája (±%)

  final DateTime manufactureDate;
  final DateTime? serviceLifeExpiryDate;
  final DateTime? nextInspectionDate;

  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RadiationSource({
    this.id,
    required this.identifier,
    required this.nuclideName,
    required this.activityAtManufactureMBq,
    this.activityErrorPercent,
    required this.manufactureDate,
    this.serviceLifeExpiryDate,
    this.nextInspectionDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Az ismert izotóp-adatok (gamma-állandó, felezési idő), ha a nuklid neve
  /// egyezik egy ismert izotóppal. Null egyedi/kézzel megadott nuklidnál.
  Isotope? get knownIsotope => Isotope.findByName(nuclideName);

  bool isExpiredAt(DateTime asOf) =>
      serviceLifeExpiryDate != null && serviceLifeExpiryDate!.isBefore(asOf);

  /// Az aktuális aktivitás (MBq) `asOf` időpontban, exponenciális bomlással
  /// számolva. Null, ha a nuklid felezési ideje nem ismert.
  double? decayedActivityMBqAt(DateTime asOf) {
    final isotope = knownIsotope;
    if (isotope == null) return null;
    final elapsedDays = asOf.difference(manufactureDate).inHours / 24.0;
    return isotope.decayedActivityMBq(
      initialActivityMBq: activityAtManufactureMBq,
      elapsedDays: elapsedDays,
    );
  }

  RadiationSource copyWith({
    int? id,
    String? identifier,
    String? nuclideName,
    double? activityAtManufactureMBq,
    double? activityErrorPercent,
    DateTime? manufactureDate,
    DateTime? serviceLifeExpiryDate,
    DateTime? nextInspectionDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RadiationSource(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      nuclideName: nuclideName ?? this.nuclideName,
      activityAtManufactureMBq:
          activityAtManufactureMBq ?? this.activityAtManufactureMBq,
      activityErrorPercent: activityErrorPercent ?? this.activityErrorPercent,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      serviceLifeExpiryDate:
          serviceLifeExpiryDate ?? this.serviceLifeExpiryDate,
        nextInspectionDate: nextInspectionDate ?? this.nextInspectionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'identifier': identifier,
      'nuclide_name': nuclideName,
      'activity_at_manufacture_mbq': activityAtManufactureMBq,
      'activity_error_percent': activityErrorPercent,
      'manufacture_date': manufactureDate.toIso8601String(),
      'service_life_expiry_date': serviceLifeExpiryDate?.toIso8601String(),
      'next_inspection_date': nextInspectionDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RadiationSource.fromMap(Map<String, Object?> map) {
    return RadiationSource(
      id: map['id'] as int?,
      identifier: map['identifier'] as String,
      nuclideName: map['nuclide_name'] as String,
      activityAtManufactureMBq:
          (map['activity_at_manufacture_mbq'] as num).toDouble(),
      activityErrorPercent:
          (map['activity_error_percent'] as num?)?.toDouble(),
      manufactureDate: DateTime.parse(map['manufacture_date'] as String),
      serviceLifeExpiryDate: map['service_life_expiry_date'] == null
          ? null
          : DateTime.parse(map['service_life_expiry_date'] as String),
        nextInspectionDate: map['next_inspection_date'] == null
          ? null
          : DateTime.parse(map['next_inspection_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
