import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/sample_unit.dart';

void main() {
  test('ismert rövidítés visszaolvasása', () {
    expect(SampleUnit.matchStored('ml'), SampleUnit.millilitre);
    expect(SampleUnit.matchStored('cm³'), SampleUnit.cubicCentimetre);
  });

  test('ismeretlen szöveg az egyéb egységbe kerül', () {
    expect(SampleUnit.matchStored('csepp'), SampleUnit.other);
  });

  test('üres érték nincs egységhez rendelve', () {
    expect(SampleUnit.matchStored(null), isNull);
    expect(SampleUnit.matchStored('  '), isNull);
  });
}
