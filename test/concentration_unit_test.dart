import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/activity_concentration.dart';
import 'package:rad_recon/models/concentration_unit.dart';
import 'package:rad_recon/models/gas_reading.dart';

void main() {
  test('arányszámok beolvashatók', () {
    expect(ConcentrationUnit.fromSymbol('ppm')!.ratio, RatioUnit.ppm);
    expect(ConcentrationUnit.fromSymbol('%LEL')!.ratio, RatioUnit.lelPercent);
  });

  test('a régi gázegységek (mg/m³) tömeg / alap egységként is beolvasódnak', () {
    final u = ConcentrationUnit.fromSymbol('mg/m³')!;
    expect(u.massUnit, BasisUnit.milligram);
    expect(u.basisUnit, BasisUnit.cubicMetre);
    expect(u.symbol, 'mg/m³');
  });

  test('µ és μ ugyanúgy értelmeződik', () {
    expect(ConcentrationUnit.fromSymbol('\u00b5g/m³'),
        ConcentrationUnit.fromSymbol('\u03bcg/m³'));
    expect(ConcentrationUnit.fromSymbol('\u00b5g/m³')!.massUnit, BasisUnit.microgram);
  });

  test('mg és liter külön választva: mg/l', () {
    final u = ConcentrationUnit.perBasis(
      mass: BasisUnit.milligram,
      basis: BasisUnit.litre,
    );
    expect(u.symbol, 'mg/l');
    expect(ConcentrationUnit.fromSymbol('mg/l'), u);
  });

  test('ismeretlen jelölés null', () {
    expect(ConcentrationUnit.fromSymbol('xx/yy'), isNull);
    expect(ConcentrationUnit.fromSymbol('mg/xx'), isNull);
    expect(ConcentrationUnit.fromSymbol(null), isNull);
  });

  test('a halmazállapot határozza meg a nevezőt', () {
    expect(basisKindsFor(PhysicalState.gas), [BasisKind.volume]);
    expect(basisKindsFor(PhysicalState.liquid), [BasisKind.volume, BasisKind.mass]);
    expect(basisKindsFor(PhysicalState.solid), [BasisKind.mass, BasisKind.area]);
  });
}
