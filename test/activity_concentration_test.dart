import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/activity_concentration.dart';
import 'package:rad_recon/models/activity_unit.dart';

void main() {
  test('2 MBq / 4 kg = 0,5 MBq/kg', () {
    final c = concentrationFrom(
      totalActivity: 2,
      activityUnit: ActivityUnit.megaBq,
      amount: 4,
      basisUnit: BasisUnit.kilogram,
      resultActivity: ActivityUnit.megaBq,
      resultBasis: BasisUnit.kilogram,
    );
    expect(c, closeTo(0.5, 1e-12));
  });

  test('1 Ci / 1 kg = 37000 kBq/g', () {
    final c = concentrationFrom(
      totalActivity: 1,
      activityUnit: ActivityUnit.ci,
      amount: 1,
      basisUnit: BasisUnit.kilogram,
      resultActivity: ActivityUnit.kiloBq,
      resultBasis: BasisUnit.gram,
    );
    expect(c, closeTo(37000, 1e-6));
  });

  test('1 MBq/kg átváltás kBq/g-ba: szorzó 1', () {
    final f = concentrationConversionFactor(
      fromActivity: ActivityUnit.megaBq,
      fromBasis: BasisUnit.kilogram,
      toActivity: ActivityUnit.kiloBq,
      toBasis: BasisUnit.gram,
    );
    expect(f, closeTo(1.0, 1e-12));
  });

  test('amerikai és angol egységek a megfelelő családban', () {
    expect(BasisUnit.fromSymbol('oz')!.kind, BasisKind.mass);
    expect(BasisUnit.fromSymbol('oz')!.baseFactor, closeTo(28.349523125, 1e-9));
    expect(BasisUnit.fromSymbol('US gal')!.kind, BasisKind.volume);
    expect(BasisUnit.fromSymbol('imp gal')!.baseFactor, closeTo(4.54609, 1e-9));
    expect(BasisUnit.fromSymbol('ft²')!.kind, BasisKind.area);
    expect(BasisUnit.ofKind(BasisKind.mass).map((u) => u.symbol), contains('lb'));
  });

  test('alapértelmezett egységek és a jelölés', () {
    expect(BasisUnit.defaultFor(BasisKind.mass), BasisUnit.kilogram);
    expect(concentrationSymbol(ActivityUnit.kiloBq, BasisUnit.squareCentimetre), 'kBq/cm²');
    expect(BasisUnit.fromSymbol('nincs ilyen'), isNull);
  });
}
