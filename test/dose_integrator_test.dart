import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/dose_integrator.dart';

void main() {
  test('állandó 1000 nSv/h 1 órán át = 1 µSv', () {
    final i = DoseIntegrator();
    final t0 = DateTime(2026, 1, 1, 8);
    for (var s = 0; s <= 3600; s += 10) {
      i.addSample(1000, 'nSv/h', t0.add(Duration(seconds: s)));
    }
    expect(i.doseMicroSv, closeTo(1.0, 1e-9));
    expect(i.gapCount, 0);
  });

  test('lineárisan növekvő ráta: trapéz', () {
    final i = DoseIntegrator();
    final t0 = DateTime(2026, 1, 1, 8);
    i.addSample(0, 'µSv/h', t0);
    i.addSample(10, 'µSv/h', t0.add(const Duration(hours: 1)));
    expect(i.doseMicroSv, closeTo(5.0, 1e-9));
  });

  test('ismeretlen egység figyelmen kívül marad', () {
    final i = DoseIntegrator();
    expect(i.addSample(5, 'cps', DateTime(2026)), isFalse);
    expect(i.hasData, isFalse);
  });

  test('hosszú rés számolva', () {
    final i = DoseIntegrator();
    final t0 = DateTime(2026, 1, 1);
    i.addSample(1, 'µSv/h', t0);
    i.addSample(1, 'µSv/h', t0.add(const Duration(minutes: 5)));
    expect(i.gapCount, 1);
  });
}
