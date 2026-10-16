import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/shielding.dart';
import 'package:rad_recon/services/activity_estimate.dart';

void main() {
  test('nincs árnyékolás: csak az árnyékolás nélküli érték', () {
    final e = estimateActivity(
        nuclide: 'Cs-137', doseRateUSvH: 9, distanceM: 1)!;
    expect(e.unshieldedMBq, closeTo(100, 1e-9)); // 9 / 0.09
    expect(e.shieldedMBq, isNull);
  });

  test('1 HVL ólom kétszeres aktivitást ad', () {
    final e = estimateActivity(
      nuclide: 'Cs-137',
      doseRateUSvH: 9,
      distanceM: 1,
      layers: const [ShieldingLayer(ShieldingMaterial.lead, 0.65)],
    )!;
    expect(e.shieldedMBq, closeTo(200, 1e-6));
  });

  test('2 HVL = 4x, nulla vastagság nem számol árnyékolást', () {
    final e = estimateActivity(
      nuclide: 'Co-60',
      doseRateUSvH: 1,
      distanceM: 1,
      layers: const [ShieldingLayer(ShieldingMaterial.steel, 4.2)],
    )!;
    expect(e.shieldedMBq! / e.unshieldedMBq, closeTo(4, 1e-9));
    final z = estimateActivity(
      nuclide: 'Co-60',
      doseRateUSvH: 1,
      distanceM: 1,
      layers: const [],
    )!;
    expect(z.shieldedMBq, isNull);
  });

  test('több réteg: az áteresztések szorzódnak', () {
    final e = estimateActivity(
      nuclide: 'Cs-137',
      doseRateUSvH: 9,
      distanceM: 1,
      layers: const [
        ShieldingLayer(ShieldingMaterial.lead, 0.65), // 1 HVL
        ShieldingLayer(ShieldingMaterial.steel, 3.2), // 2 HVL
      ],
    )!;
    expect(e.shieldedMBq! / e.unshieldedMBq, closeTo(8, 1e-9));
  });

  test('minden izotóp x anyag párra van HVL', () {
    for (final n in kHalfValueLayersCm.keys) {
      for (final m in ShieldingMaterial.values) {
        expect(halfValueLayerCm(n, m), isNotNull, reason: '$n $m');
      }
    }
  });
}
