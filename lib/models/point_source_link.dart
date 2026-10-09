import 'radiation_source.dart';

/// Egy sugárforrás hozzárendelése egy mérési ponthoz, a ponton érvényes
/// távolsággal (ugyanaz a forrás más ponthoz más távolsággal is rendelhető).
class PointSourceLink {
  final int? id;
  final int measurementPointId;
  final int radiationSourceId;
  final double distanceMeters;
  final DateTime createdAt;

  const PointSourceLink({
    this.id,
    required this.measurementPointId,
    required this.radiationSourceId,
    required this.distanceMeters,
    required this.createdAt,
  });

  PointSourceLink copyWith({
    int? id,
    int? measurementPointId,
    int? radiationSourceId,
    double? distanceMeters,
    DateTime? createdAt,
  }) {
    return PointSourceLink(
      id: id ?? this.id,
      measurementPointId: measurementPointId ?? this.measurementPointId,
      radiationSourceId: radiationSourceId ?? this.radiationSourceId,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'measurement_point_id': measurementPointId,
      'radiation_source_id': radiationSourceId,
      'distance_meters': distanceMeters,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PointSourceLink.fromMap(Map<String, Object?> map) {
    return PointSourceLink(
      id: map['id'] as int?,
      measurementPointId: map['measurement_point_id'] as int,
      radiationSourceId: map['radiation_source_id'] as int,
      distanceMeters: (map['distance_meters'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Egy mérési ponthoz rendelt forrás, a hozzárendelés adataival és a
/// (globális nyilvántartásból betöltött) forrás-adatokkal együtt — ezt adja
/// vissza a `DatabaseHelper.getAttachedSources` JOIN-lekérdezése.
class AttachedSource {
  final PointSourceLink link;
  final RadiationSource source;

  const AttachedSource({required this.link, required this.source});
}
