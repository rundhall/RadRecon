/// Egy érintett személy sérülésének vagy betegségének típusa.
enum ConditionKind {
  injury('injury', 'Sérülés'),
  illness('illness', 'Betegség');

  const ConditionKind(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ConditionKind fromDbValue(String? value) =>
      ConditionKind.values.firstWhere(
        (k) => k.dbValue == value,
        orElse: () => ConditionKind.injury,
      );
}

/// Egy érintett személy egy sérülése vagy betegsége a felmérésen belül.
/// A `linkId` a `survey_session_persons` hozzárendelés azonosítója.
class PersonCondition {
  final int? id;
  final int linkId;
  final ConditionKind kind;
  final String description;

  const PersonCondition({
    this.id,
    required this.linkId,
    required this.kind,
    required this.description,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'link_id': linkId,
      'kind': kind.dbValue,
      'description': description,
    };
  }

  factory PersonCondition.fromMap(Map<String, Object?> map) {
    return PersonCondition(
      id: map['id'] as int?,
      linkId: map['link_id'] as int,
      kind: ConditionKind.fromDbValue(map['kind'] as String?),
      description: map['description'] as String,
    );
  }
}
