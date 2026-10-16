/// Közös felület a választható mértékegységekhez (dózisteljesítmény,
/// aktivitás, távolság). Az app minden értéket a saját alapegységében tárol
/// (µSv/h, MBq, m), a mértékegység csak a bevitel és a megjelenítés dolga.
abstract interface class QuantityUnit {
  String get symbol;

  /// Hány alapegység (µSv/h, MBq vagy m) egy ilyen egység.
  double get baseFactor;
}
