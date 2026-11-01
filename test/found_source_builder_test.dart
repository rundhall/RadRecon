import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/activity_origin.dart';
import 'package:rad_recon/services/found_source_builder.dart';

void main() {
  final now = DateTime(2026, 11, 1, 14, 5, 9);

  test('azonosító formátuma', () {
    expect(foundSourceIdentifier(now), 'T-20261101-140509');
  });

  test('nuklid-sorok: normalizálás, üres név kimarad, eredet megmarad', () {
    final rows = buildFoundNuclideRows(
      drafts: [
        FoundNuclideDraft(
            nuclide: 'co60', activityMBq: 12, origin: ActivityOrigin.measurement),
        FoundNuclideDraft(
            nuclide: '  ', activityMBq: null, origin: ActivityOrigin.manual),
        FoundNuclideDraft(
            nuclide: 'cs137', activityMBq: null, origin: ActivityOrigin.spectrum),
      ],
      referenceDate: now,
      now: now,
    );
    expect(rows.length, 2);
    expect(rows[0].nuclide, 'Co-60');
    expect(rows[0].activityMBq, 12);
    expect(rows[1].nuclide, 'Cs-137');
    expect(rows[1].activityMBq, isNull);
    expect(rows[1].origin, ActivityOrigin.spectrum);
  });

  test('talált forrás: gyártási adat nélkül, origin found', () {
    final rows = buildFoundNuclideRows(
      drafts: [
        FoundNuclideDraft(
            nuclide: 'Am-241', activityMBq: 0.5, origin: ActivityOrigin.measurement),
      ],
      referenceDate: now,
      now: now,
    );
    final s = buildFoundSource(identifier: 'T-1', nuclides: rows, now: now);
    expect(s.origin, 'found');
    expect(s.manufactureDate, isNull);
    expect(s.nuclideName, 'Am-241');
    expect(s.activityAtManufactureMBq, 0.5);
  });

  test('ismeretlen összetétel: üres nuklidnév és nincs aktivitás', () {
    final s = buildFoundSource(identifier: 'T-2', nuclides: const [], now: now);
    expect(s.nuclideName, '');
    expect(s.activityAtManufactureMBq, isNull);
  });
}
