/// A mintavétel mennyiségének egysége. A tárolt érték a rövidítés (pl. "ml").
/// Az `other` választásnál a felhasználó saját szövege kerül a mezőbe
/// (pl. "csepp"), így bármilyen egység megadható.
enum SampleUnit {
  piece('db'),
  millilitre('ml'),
  cubicCentimetre('cm³'),
  cubicMetre('m³'),
  squareCentimetre('cm²'),
  squareMetre('m²'),
  litre('l'),
  gram('g'),
  milligram('mg'),
  kilogram('kg'),
  other('');

  const SampleUnit(this.symbol);
  final String symbol;

  bool get isCustom => this == SampleUnit.other;

  /// Mentett szövegből egység: ismert rövidítés → az egység, minden más
  /// szöveg → `other` (a szöveg a saját mezőbe kerül). Üres → `null`.
  static SampleUnit? matchStored(String? stored) {
    final t = stored?.trim() ?? '';
    if (t.isEmpty) return null;
    for (final u in values) {
      if (!u.isCustom && u.symbol == t) return u;
    }
    return SampleUnit.other;
  }
}
