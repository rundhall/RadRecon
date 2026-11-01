import 'dart:convert';

/// Az érintett neme.
enum VictimSex {
  female('female'),
  male('male'),
  unknown('unknown');

  const VictimSex(this.dbValue);

  final String dbValue;

  static VictimSex? fromDbValue(String? value) {
    if (value == null) return null;
    return VictimSex.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => VictimSex.unknown,
    );
  }
}

/// A fantomrajz oldala.
enum BodySide {
  front('front'),
  back('back');

  const BodySide(this.dbValue);

  final String dbValue;

  static BodySide fromDbValue(String? value) => BodySide.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => BodySide.front,
      );
}

/// A jelölés típusa: sérülés vagy szennyezés. A szennyezők (izotóp, vegyi,
/// biológiai) bármelyik jelölésnél opcionálisan megadhatók.
enum MarkerKind {
  injury('injury'),
  contamination('contamination');

  const MarkerKind(this.dbValue);

  final String dbValue;

  static MarkerKind fromDbValue(String? value) => MarkerKind.values.firstWhere(
        (k) => k.dbValue == value,
        orElse: () => MarkerKind.injury,
      );
}

/// Egy jelölés a fantomrajzon. A koordináták (0..1) a rajz szélességéhez és
/// magasságához viszonyítottak.
class BodyMarker {
  final BodySide side;
  final double x;
  final double y;
  final MarkerKind kind;
  final String? isotope; // radioaktív szennyezés, pl. Cs-137
  final String? chemical; // vegyi szennyező (szabad szöveg)
  final String? biological; // biológiai szennyező (szabad szöveg)
  final String note; // sérülés leírása, pl. égés, törés

  const BodyMarker({
    required this.side,
    required this.x,
    required this.y,
    required this.kind,
    this.isotope,
    this.chemical,
    this.biological,
    this.note = '',
  });

  /// A szennyezők (izotóp, vegyi, biológiai) egy sorban, üresek nélkül.
  String get contaminantText => [isotope, chemical, biological]
      .where((s) => s != null && s.trim().isNotEmpty)
      .join(' + ');

  bool get hasContaminant => contaminantText.isNotEmpty;

  Map<String, Object?> toJson() => {
        'side': side.dbValue,
        'x': x,
        'y': y,
        'kind': kind.dbValue,
        'isotope': isotope,
        'chemical': chemical,
        'biological': biological,
        'note': note,
      };

  factory BodyMarker.fromJson(Map<String, Object?> m) => BodyMarker(
        side: BodySide.fromDbValue(m['side'] as String?),
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        kind: MarkerKind.fromDbValue(m['kind'] as String?),
        isotope: m['isotope'] as String?,
        chemical: m['chemical'] as String?,
        biological: m['biological'] as String?,
        note: (m['note'] as String?) ?? '',
      );
}

List<BodyMarker> bodyMarkersFromJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final list = jsonDecode(raw) as List<dynamic>;
  return [
    for (final e in list) BodyMarker.fromJson(e as Map<String, Object?>),
  ];
}

String? bodyMarkersToJson(List<BodyMarker> markers) =>
    markers.isEmpty ? null : jsonEncode([for (final m in markers) m.toJson()]);
