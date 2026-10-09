/// Egy módosítás nyoma egy mérési ponton — a jegyzőkönyvi hitelesség miatt
/// az eredeti érték soha nem tűnik el nyomtalanul, csak új audit sor jön létre.
class MeasurementAuditEntry {
  final int? id;
  final int measurementPointId;
  final String fieldName; // pl. "value", "distance_from_source_meters"
  final String? oldValue;
  final String? newValue;
  final DateTime changedAt;

  const MeasurementAuditEntry({
    this.id,
    required this.measurementPointId,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.changedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'measurement_point_id': measurementPointId,
      'field_name': fieldName,
      'old_value': oldValue,
      'new_value': newValue,
      'changed_at': changedAt.toIso8601String(),
    };
  }

  factory MeasurementAuditEntry.fromMap(Map<String, Object?> map) {
    return MeasurementAuditEntry(
      id: map['id'] as int?,
      measurementPointId: map['measurement_point_id'] as int,
      fieldName: map['field_name'] as String,
      oldValue: map['old_value'] as String?,
      newValue: map['new_value'] as String?,
      changedAt: DateTime.parse(map['changed_at'] as String),
    );
  }
}