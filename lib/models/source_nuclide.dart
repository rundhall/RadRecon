import 'activity_origin.dart';

/// Egy forrás egy nuklidjának aktivitás-sora. Az aktivitás nuklidonként
/// adható meg; vegyes vagy ismeretlen összetételnél `activityMBq` null.
class SourceNuclide {
  final int? id;
  final int radiationSourceId;
  final String nuclide;
  final double? activityMBq;

  /// Az az időpont, amelyre az aktivitás vonatkozik.
  final DateTime referenceDate;
  final ActivityOrigin origin;
  final DateTime createdAt;

  const SourceNuclide({
    this.id,
    required this.radiationSourceId,
    required this.nuclide,
    required this.activityMBq,
    required this.referenceDate,
    required this.origin,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'radiation_source_id': radiationSourceId,
        'nuclide': nuclide,
        'activity_mbq': activityMBq,
        'reference_date': referenceDate.toIso8601String(),
        'origin': origin.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory SourceNuclide.fromMap(Map<String, Object?> map) {
    return SourceNuclide(
      id: map['id'] as int?,
      radiationSourceId: map['radiation_source_id'] as int,
      nuclide: map['nuclide'] as String,
      activityMBq: (map['activity_mbq'] as num?)?.toDouble(),
      referenceDate: DateTime.parse(map['reference_date'] as String),
      origin: ActivityOrigin.values.byName(map['origin'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
