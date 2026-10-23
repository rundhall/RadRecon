import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/widgets/quantity_field.dart';

void main() {
  test('kézzel beírt számnál a szám marad (30 m → cm: 30 cm)', () {
    expect(
      unitChangeText(text: '30', typedByUser: true, fromBase: 1, toBase: 0.01),
      '30',
    );
  });

  test('programmal kitöltött értéknél a fizikai mennyiség marad (0,3 m → 30 cm)', () {
    expect(
      unitChangeText(text: '0.3', typedByUser: false, fromBase: 1, toBase: 0.01),
      '30',
    );
  });

  test('programmal kitöltött 30 m → 3000 cm', () {
    expect(
      unitChangeText(text: '30', typedByUser: false, fromBase: 1, toBase: 0.01),
      '3000',
    );
  });

  test('vesszős bevitel is átszámolódik programmal kitöltött értéknél', () {
    expect(
      unitChangeText(text: '0,3', typedByUser: false, fromBase: 1, toBase: 0.01),
      '30',
    );
  });
}
