import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/radiation_source.dart';
import 'package:rad_recon/services/source_classification.dart';

void main() {
  final now = DateTime(2026, 11, 1);

  test('talált forrás: gyártási mezők nélkül is körbeér a mentés', () {
    final s = RadiationSource(
      identifier: 'T-2026-001',
      nuclideName: '',
      createdAt: now,
      updatedAt: now,
      origin: 'found',
    );
    final map = s.toMap();
    expect(map['manufacture_date'], isNull);
    expect(map['activity_at_manufacture_mbq'], isNull);
    final back = RadiationSource.fromMap(map);
    expect(back.manufactureDate, isNull);
    expect(back.activityAtManufactureMBq, isNull);
    expect(back.nuclideName, '');
    expect(back.origin, 'own', reason: 'az origin nem íródik a mentésbe');
  });

  test('ismeretlen aktivitás vagy dátum: nincs bomlás, nincs R', () {
    final s = RadiationSource(
      identifier: 'T-2026-002',
      nuclideName: 'Co-60',
      createdAt: now,
      updatedAt: now,
    );
    expect(s.decayedActivityMBqAt(now), isNull);
    final c = classifySource(s, now);
    expect(c.rValue, isNull);
    expect(c.lab, isNull);
  });
}
