import 'activity_concentration.dart';

/// Arányszámok: nem tömeg / alap típusúak.
enum RatioUnit {
  ppm('ppm'),
  ppb('ppb'),
  volPercent('vol%'),
  percent('%'),
  lelPercent('%LEL');

  const RatioUnit(this.symbol);

  final String symbol;

  /// Az alsó robbanási határ (%LEL) csak gázra és gőzre értelmes.
  bool get gasOnly => this == RatioUnit.lelPercent;
}

/// Mennyiségi egység: arányszám (ppm, vol% …), vagy tömeg / alap (pl. mg/l,
/// mg/kg, µg/cm²). A tömeg- és az alapegységet külön lehet választani; az
/// egységek listája és az alapértékek a Beállítások mintaegységei.
class ConcentrationUnit {
  const ConcentrationUnit.ratio(this.ratio)
      : massUnit = null,
        basisUnit = null;

  const ConcentrationUnit.perBasis({
    required BasisUnit mass,
    required BasisUnit basis,
  })  : ratio = null,
        massUnit = mass,
        basisUnit = basis;

  final RatioUnit? ratio;
  final BasisUnit? massUnit; // tömeg-egység
  final BasisUnit? basisUnit; // nevező: térfogat, tömeg vagy felület

  /// A tárolt jelölés, pl. "ppm", "mg/m³", "mg/l".
  String get symbol =>
      ratio?.symbol ?? '${massUnit!.symbol}/${basisUnit!.symbol}';

  @override
  bool operator ==(Object other) =>
      other is ConcentrationUnit && other.symbol == symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => symbol;

  /// Az eltárolt jelölésből. Régi adatnál az µ (U+00B5) és a μ (U+03BC) is
  /// elfogadott. Ismeretlen jelölésnél null.
  static ConcentrationUnit? fromSymbol(String? raw) {
    if (raw == null) return null;
    final s = _normalize(raw.trim());
    for (final r in RatioUnit.values) {
      if (r.symbol == s) return ConcentrationUnit.ratio(r);
    }
    final parts = s.split('/');
    if (parts.length != 2) return null;
    final mass = _basisOf(parts[0], BasisKind.mass);
    final basis = _basisOf(parts[1], null);
    if (mass == null || basis == null) return null;
    return ConcentrationUnit.perBasis(mass: mass, basis: basis);
  }

  static BasisUnit? _basisOf(String part, BasisKind? kind) {
    for (final u in BasisUnit.values) {
      final kindOk = kind == null || u.kind == kind;
      if (kindOk && _normalize(u.symbol) == part) return u;
    }
    return null;
  }

  static String _normalize(String s) => s.replaceAll('\u03bc', '\u00b5');
}
