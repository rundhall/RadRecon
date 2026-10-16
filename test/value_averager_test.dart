import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/value_averager.dart';

void main() {
  test('stats of known sample', () {
    final s = valueStats([2, 4, 4, 4, 5, 5, 7, 9])!;
    expect(s.n, 8);
    expect(s.mean, 5);
    expect(s.stdDev, closeTo(2.13809, 1e-4));
    expect(s.standardError, closeTo(2.13809 / 2.8284271, 1e-4));
  });

  test('single value has no error', () {
    final s = valueStats([3.2])!;
    expect(s.standardError, isNull);
    expect(valueStats([]), isNull);
  });

  test('formatValueWithError rounds to 2 significant digits of the error', () {
    expect(formatValueWithError(0.123456, 0.00412), '0.1235 ± 0.0041');
    expect(formatValueWithError(123.456, 4.2), '123.5 ± 4.2');
    expect(formatValueWithError(1234.0, 120.0), '1234 ± 120');
    expect(formatValueWithError(0.123456, null), '0.1235');
  });
}
