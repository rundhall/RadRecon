import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/position_averager.dart';

void main() {
  test('empty list gives null', () {
    expect(averagePositions([]), isNull);
  });

  test('averages and drops an outlier', () {
    final base = 47.5;
    final samples = [
      for (var i = 0; i < 20; i++)
        GpsSample(base + (i.isEven ? 0.00001 : -0.00001), 19.0, 8),
      const GpsSample(47.51, 19.0, 8), // ~1 km-es kiugró
    ];
    final r = averagePositions(samples)!;
    expect(r.used, 20);
    expect(r.total, 21);
    expect(r.latitude, closeTo(base, 0.00002));
  });

  test('more accurate samples weigh more', () {
    final r = averagePositions([
      const GpsSample(47.0, 19.0, 2),
      const GpsSample(47.0002, 19.0, 20),
    ])!;
    expect(r.latitude, lessThan(47.00005));
  });
}
