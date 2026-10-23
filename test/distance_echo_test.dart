import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/distance_unit.dart';
import 'package:rad_recon/widgets/distance_echo.dart';

void main() {
  test('cm bevitelnél méterben mutatja', () {
    expect(DistanceEcho.meterText('30', DistanceUnit.cm), '= 0.3 m');
  });

  test('vesszős cm bevitel is', () {
    expect(DistanceEcho.meterText('30,5', DistanceUnit.cm), '= 0.305 m');
  });

  test('méter bevitelnél nincs visszajelzés', () {
    expect(DistanceEcho.meterText('30', DistanceUnit.m), isNull);
  });

  test('üres vagy érvénytelen bevitelnél nincs visszajelzés', () {
    expect(DistanceEcho.meterText('', DistanceUnit.cm), isNull);
    expect(DistanceEcho.meterText('abc', DistanceUnit.cm), isNull);
  });
}
