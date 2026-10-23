import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/number_input.dart';

void main() {
  test('magyar és nemzetközi tizedesjel is elfogadott', () {
    expect(parseDecimal('2,5'), 2.5);
    expect(parseDecimal('2.5'), 2.5);
    expect(parseDecimal(' 3 '), 3.0);
  });

  test('ezres-elválasztó mindkét formában', () {
    expect(parseDecimal('1.234,5'), 1234.5);
    expect(parseDecimal('1,234.5'), 1234.5);
    expect(parseDecimal('1 000'), 1000.0);
  });

  test('üres, nem szám és nem véges bemenet null', () {
    expect(parseDecimal(''), isNull);
    expect(parseDecimal('abc'), isNull);
    expect(parseDecimal('1.2.3'), isNull);
    expect(parseDecimal('NaN'), isNull);
  });
}
