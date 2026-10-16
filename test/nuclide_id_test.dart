import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_point.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/models/nuclide_id.dart';

MeasurementPoint _point({
  NuclideIdStatus status = NuclideIdStatus.notSpecified,
  List<String> nuclides = const [],
}) {
  final now = DateTime(2026, 10, 16);
  return MeasurementPoint(
    surveySessionId: 1,
    latitude: 47,
    longitude: 19,
    type: MeasurementType.doseRate,
    unit: 'µSv/h',
    nuclideStatus: status,
    nuclides: nuclides,
    timestamp: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('régi pontok: nincs megadva, nincs nuklid', () {
    final p = _point();
    expect(p.nuclideStatus, NuclideIdStatus.notSpecified);
    expect(p.nuclides, isEmpty);
    expect(p.toMap()['nuclides'], isNull);
  });

  test('nuklid-azonosítás mentés → olvasás körút', () {
    final p = _point(
      status: NuclideIdStatus.mixture,
      nuclides: ['Cs-137', 'Co-60', 'Saját-1'],
    );
    final back = MeasurementPoint.fromMap(p.toMap());
    expect(back.nuclideStatus, NuclideIdStatus.mixture);
    expect(back.nuclides, ['Cs-137', 'Co-60', 'Saját-1']);
  });

  test('ismeretlen állapot-érték a régi viselkedésre esik vissza', () {
    expect(NuclideIdStatus.fromDb('valami'), NuclideIdStatus.notSpecified);
    expect(NuclideIdStatus.fromDb(null), NuclideIdStatus.notSpecified);
  });

  test('összefoglaló szöveg', () {
    String label(NuclideIdStatus s) => s.name;
    expect(
      nuclideSummaryText(
        status: NuclideIdStatus.identified,
        nuclides: ['Cs-137', 'Co-60'],
        statusLabel: label,
      ),
      'identified: Cs-137, Co-60',
    );
    expect(
      nuclideSummaryText(
        status: NuclideIdStatus.unknown,
        nuclides: ['Cs-137'],
        statusLabel: label,
      ),
      'unknown',
    );
    expect(
      nuclideSummaryText(
        status: NuclideIdStatus.notSpecified,
        nuclides: const [],
        statusLabel: label,
      ),
      '',
    );
  });

  test('aktivitás-becsléshez csak egyetlen azonosított nuklid használható', () {
    expect(_point().estimationNuclide, isNull);
    expect(
      _point(status: NuclideIdStatus.identified, nuclides: ['Cs-137'])
          .estimationNuclide,
      'Cs-137',
    );
    expect(
      _point(status: NuclideIdStatus.identified, nuclides: ['Cs-137', 'Co-60'])
          .estimationNuclide,
      isNull,
    );
    expect(
      _point(status: NuclideIdStatus.mixture, nuclides: ['Cs-137'])
          .estimationNuclide,
      isNull,
    );
    expect(
      _point(status: NuclideIdStatus.unknown).estimationNuclide,
      isNull,
    );
  });
}
