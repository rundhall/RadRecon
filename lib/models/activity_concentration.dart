import 'activity_unit.dart';

/// Az aktivitáskoncentráció nevezőjének típusa: a minta tömege, térfogata
/// vagy felülete.
enum BasisKind { mass, volume, area }

/// A minta mennyiségének egysége. `baseFactor`: hány alapegység (g, l vagy m²)
/// egy ilyen egység.
enum BasisUnit {
  microgram('µg', BasisKind.mass, 1e-6),
  milligram('mg', BasisKind.mass, 1e-3),
  gram('g', BasisKind.mass, 1),
  kilogram('kg', BasisKind.mass, 1e3),
  tonne('t', BasisKind.mass, 1e6),
  millilitre('ml', BasisKind.volume, 1e-3),
  cubicCentimetre('cm³', BasisKind.volume, 1e-3),
  decilitre('dl', BasisKind.volume, 1e-1),
  litre('l', BasisKind.volume, 1),
  cubicDecimetre('dm³', BasisKind.volume, 1),
  cubicMetre('m³', BasisKind.volume, 1e3),
  squareMillimetre('mm²', BasisKind.area, 1e-6),
  squareCentimetre('cm²', BasisKind.area, 1e-4),
  squareDecimetre('dm²', BasisKind.area, 1e-2),
  squareMetre('m²', BasisKind.area, 1),
  ounce('oz', BasisKind.mass, 28.349523125),
  pound('lb', BasisKind.mass, 453.59237),
  stone('st', BasisKind.mass, 6350.29318),
  usFluidOunce('US fl oz', BasisKind.volume, 0.0295735295625),
  usGallon('US gal', BasisKind.volume, 3.785411784),
  impFluidOunce('imp fl oz', BasisKind.volume, 0.0284130625),
  impGallon('imp gal', BasisKind.volume, 4.54609),
  squareInch('in²', BasisKind.area, 0.00064516),
  squareFoot('ft²', BasisKind.area, 0.09290304),
  squareYard('yd²', BasisKind.area, 0.83612736);

  const BasisUnit(this.symbol, this.kind, this.baseFactor);

  final String symbol;
  final BasisKind kind;
  final double baseFactor;

  static List<BasisUnit> ofKind(BasisKind k) =>
      [for (final u in values) if (u.kind == k) u];

  static BasisUnit defaultFor(BasisKind k) => switch (k) {
        BasisKind.mass => kilogram,
        BasisKind.volume => litre,
        BasisKind.area => squareMetre,
      };

  static BasisUnit? fromSymbol(String? symbol) {
    if (symbol == null) return null;
    for (final u in values) {
      if (u.symbol == symbol) return u;
    }
    return null;
  }
}

/// Az aktivitáskoncentráció egysége, pl. "kBq/kg".
String concentrationSymbol(ActivityUnit activity, BasisUnit basis) =>
    '${activity.symbol}/${basis.symbol}';

/// Szorzó, amellyel a régi egységben megadott koncentráció az új egységbe
/// váltható: C_új = C_régi × szorzó.
double concentrationConversionFactor({
  required ActivityUnit fromActivity,
  required BasisUnit fromBasis,
  required ActivityUnit toActivity,
  required BasisUnit toBasis,
}) =>
    (fromActivity.mbqFactor / toActivity.mbqFactor) *
    (toBasis.baseFactor / fromBasis.baseFactor);

/// Koncentráció = összes aktivitás ÷ minta mennyisége. Az eredmény a
/// `resultActivity` / `resultBasis` egységben lesz.
double concentrationFrom({
  required double totalActivity,
  required ActivityUnit activityUnit,
  required double amount,
  required BasisUnit basisUnit,
  required ActivityUnit resultActivity,
  required BasisUnit resultBasis,
}) {
  final activityInResult =
      totalActivity * activityUnit.mbqFactor / resultActivity.mbqFactor;
  final amountInResult = amount * basisUnit.baseFactor / resultBasis.baseFactor;
  return activityInResult / amountInResult;
}
