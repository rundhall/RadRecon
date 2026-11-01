import 'quantity_unit.dart';

/// A dózisteljesítmény mennyisége (szabvány szerint). Alapértelmezett: H*(10).
enum DoseQuantity {
  h10('h10', 'H*(10)'),
  hp('hp', 'Hp(d)'),
  hprime('hprime', "H'(d,Ω)"),
  kerma('kerma', 'K');

  const DoseQuantity(this.dbValue, this.symbol);

  final String dbValue;
  final String symbol;

  static DoseQuantity fromDbValue(String? value) => values.firstWhere(
        (q) => q.dbValue == value,
        orElse: () => DoseQuantity.h10,
      );

  /// Választható mélység (mm): Hp(d): 10, 3, 0,07; H'(d,Ω): 3, 0,07. Egyébként nincs.
  List<double> get depthOptionsMm => switch (this) {
        DoseQuantity.hp => const [10, 3, 0.07],
        DoseQuantity.hprime => const [3, 0.07],
        _ => const [],
      };

  /// Alapértelmezett mélység: Hp(d) 10 mm, H'(d,Ω) 3 mm.
  double? get defaultDepthMm => switch (this) {
        DoseQuantity.hp => 10,
        DoseQuantity.hprime => 3,
        _ => null,
      };

  /// A K (légkerma) nem dózisegyenérték: nem adódik össze dózisba.
  bool get isDoseEquivalent => this != DoseQuantity.kerma;
}

/// Légkerma-teljesítmény egysége (Gy/h család). A K-t nem váltjuk át H-ra.
enum KermaRateUnit implements QuantityUnit {
  nanoGy('nGy/h', 0.001),
  microGy('µGy/h', 1),
  milliGy('mGy/h', 1000),
  gray('Gy/h', 1000000);

  const KermaRateUnit(this.symbol, this.baseFactor);

  @override
  final String symbol;

  /// Alapegység: µGy/h.
  @override
  final double baseFactor;

  static const defaultUnit = KermaRateUnit.microGy;

  static KermaRateUnit fromSymbol(String? symbol) => values.firstWhere(
        (u) => u.symbol == symbol,
        orElse: () => defaultUnit,
      );
}
