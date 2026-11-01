import 'dart:convert';

/// Biológiai anyag fajtája. Nincs előre megadott kórokozó-lista: a név
/// szabad szöveg, a típus csak a csoportosításhoz kell.
enum BioKind {
  bacterium('bacterium'),
  virus('virus'),
  toxin('toxin'),
  fungus('fungus'),
  other('other');

  const BioKind(this.dbValue);

  final String dbValue;

  static BioKind fromStorage(String? value) => BioKind.values.firstWhere(
        (k) => k.dbValue == value,
        orElse: () => BioKind.other,
      );
}

/// Egy rögzített biológiai anyag egy mérési ponton.
class BioAgentReading {
  final String name;
  final BioKind kind;
  final String quantity; // szabad szöveg, például "2 törlet, felület"

  const BioAgentReading({
    required this.name,
    required this.kind,
    this.quantity = '',
  });

  Map<String, Object?> toJson() => {
        'name': name,
        'kind': kind.dbValue,
        'quantity': quantity,
      };

  factory BioAgentReading.fromJson(Map<String, Object?> m) => BioAgentReading(
        name: m['name'] as String,
        kind: BioKind.fromStorage(m['kind'] as String?),
        quantity: (m['quantity'] as String?) ?? '',
      );

  static List<BioAgentReading> listFromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list) BioAgentReading.fromJson(e as Map<String, Object?>),
    ];
  }

  static String listToJsonString(List<BioAgentReading> items) =>
      jsonEncode([for (final b in items) b.toJson()]);
}

/// A mérési pont biológiai anyagainak összefoglaló neve (lista-nézethez).
String bioAgentsSummary(List<BioAgentReading> items) =>
    items.map((b) => b.name).where((n) => n.isNotEmpty).join(', ');
