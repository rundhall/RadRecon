import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/radiation_source.dart';

void main() {
  final now = DateTime(2026, 11, 1);

  test('notifyEnabled körbeér a mentésben', () {
    final off = RadiationSource(
      identifier: 'S-1',
      nuclideName: 'Co-60',
      createdAt: now,
      updatedAt: now,
      notifyEnabled: false,
    );
    expect(off.toMap()['notify_enabled'], 0);
    expect(RadiationSource.fromMap(off.toMap()).notifyEnabled, isFalse);
  });

  test('hiányzó mező: értesítés be (a korábbi viselkedés)', () {
    final map = RadiationSource(
      identifier: 'S-2',
      nuclideName: 'Cs-137',
      createdAt: now,
      updatedAt: now,
    ).toMap()..remove('notify_enabled');
    expect(RadiationSource.fromMap(map).notifyEnabled, isTrue);
  });
}
