import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/radiation_source.dart';
import 'package:rad_recon/services/source_classification.dart';

RadiationSource src(String nuclide, double mbq) => RadiationSource(
      identifier: 'x',
      nuclideName: nuclide,
      activityAtManufactureMBq: mbq,
      manufactureDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  test('normalizeNuclideName', () {
    expect(normalizeNuclideName('co60'), 'Co-60');
    expect(normalizeNuclideName(' CS-137 '), 'Cs-137');
    expect(normalizeNuclideName('Tc-99m'), 'Tc-99m');
  });

  test('physical category thresholds', () {
    expect(physicalProtectionCategory(1000), 1);
    expect(physicalProtectionCategory(999.9), 2);
    expect(physicalProtectionCategory(10), 2);
    expect(physicalProtectionCategory(1), 3);
    expect(physicalProtectionCategory(0.01), 4);
    expect(physicalProtectionCategory(0.0099), 5);
  });

  test('R for a Co-60 source uses D from the table', () {
    final c = classifySource(src('Co-60', 1e6), DateTime.now()); // 1 TBq
    expect(c.dTBq, isNotNull);
    expect(c.rValue, closeTo(1 / c.dTBq!, 1e-6));
  });

  test('D infinite gives R = 0, unknown nuclide gives null', () {
    expect(classifySource(src('K-40', 1e6), DateTime.now()).rValue, 0);
    expect(classifySource(src('Xx-1', 1e6), DateTime.now()).rValue, isNull);
  });

  test('physical protection level', () {
    expect(physicalProtectionLevel(1), 'B');
    expect(physicalProtectionLevel(2), 'C');
    expect(physicalProtectionLevel(3), 'C');
    expect(physicalProtectionLevel(4), 'D');
    expect(physicalProtectionLevel(5), 'D');
  });

  test('lab classification from AM', () {
    // Co-60: AM = 2.1 MBq
    final low = classifyLab('Co-60', 2.1)!; // A/AM = 1
    expect(low.industrial, 'C');
    expect(low.medical, 'II');
    expect(low.allowedOperations, ['A', 'B', 'C']);
    final mid = classifyLab('Co-60', 2.1 * 50)!;
    expect(mid.industrial, 'B');
    expect(mid.medical, 'II');
    expect(mid.allowedOperations, ['A']);
    expect(classifyLab('Co-60', 2.1 * 500)!.medical, 'III');
    expect(classifyLab('Co-60', 2.1 * 500)!.allowedOperations, isEmpty);
    expect(classifyLab('Co-60', 2.1 * 20000)!.industrial, 'A');
    expect(classifyLab('Co-60', 2.1 * 20000)!.medical, isNull);
    expect(classifyLab('Xx-1', 1), isNull);
  });

  test('ADR ratios and consignment limit', () {
    final c = classifySource(src('Co-60', 1e6), DateTime.now()); // 1 TBq
    expect(c.adr, isNotNull);
    expect(adrRatioA1(c), closeTo(1 / c.adr!.a1TBq!, 1e-9));
    expect(adrBelowConsignmentLimit(c), isFalse);
    final tiny = classifySource(src('Co-60', 0.01), DateTime.now()); // 10 kBq
    expect(adrBelowConsignmentLimit(tiny), isTrue);
  });

  test('protection category mapping', () {
    const none = ClassificationContext();
    expect(protectionCategoryFor(1, none), RadiationProtectionCategory.i);
    expect(protectionCategoryFor(2, none), RadiationProtectionCategory.ii);
    expect(
        protectionCategoryFor(
            2, const ClassificationContext(outsideWorkplace: true)),
        RadiationProtectionCategory.i);
    expect(protectionCategoryFor(4, none), RadiationProtectionCategory.iii);
    expect(
        protectionCategoryFor(
            4, const ClassificationContext(unsealedRegularWork: true)),
        RadiationProtectionCategory.ii);
    expect(protectionCategoryFor(5, none), RadiationProtectionCategory.iii);
  });
}
