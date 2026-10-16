import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/instrument_calibration.dart';

void main() {
  final cal = InstrumentCalibration(
    kind: CalibrationKind.calibration,
    performedOn: DateTime(2025, 3, 1),
    validUntil: DateTime(2026, 3, 1),
  );
  final ver = InstrumentCalibration(
    kind: CalibrationKind.verification,
    performedOn: DateTime(2025, 6, 1),
    validUntil: DateTime(2027, 6, 1),
  );

  test('a legkorábban lejáró típus számít', () {
    expect(effectiveValidUntil([cal, ver]), DateTime(2026, 3, 1));
  });

  test('csak a típus legutolsó bejegyzése számít', () {
    final newer = InstrumentCalibration(
      kind: CalibrationKind.calibration,
      performedOn: DateTime(2026, 2, 1),
      validUntil: DateTime(2027, 2, 1),
    );
    expect(effectiveValidUntil([cal, newer, ver]), DateTime(2027, 2, 1));
  });

  test('állapot: lejárt / hamarosan / érvényes / ismeretlen', () {
    final now = DateTime(2026, 10, 16);
    expect(calibrationStatusFor(DateTime(2026, 10, 1), now: now),
        CalibrationStatus.expired);
    expect(calibrationStatusFor(DateTime(2026, 10, 16), now: now),
        CalibrationStatus.expiringSoon);
    expect(calibrationStatusFor(DateTime(2026, 11, 10), now: now),
        CalibrationStatus.expiringSoon);
    expect(calibrationStatusFor(DateTime(2027, 5, 1), now: now),
        CalibrationStatus.valid);
    expect(calibrationStatusFor(null, now: now), CalibrationStatus.unknown);
  });

  test('latestOfKind az időpontig elvégzettek közül választ', () {
    final r = latestOfKind([cal], CalibrationKind.calibration,
        at: DateTime(2025, 1, 1));
    expect(r, isNull);
  });
}
