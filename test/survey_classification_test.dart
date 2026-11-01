import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/radiation_source.dart';
import 'package:rad_recon/models/source_nuclide.dart';
import 'package:rad_recon/models/survey_source_placement.dart';
import 'package:rad_recon/services/source_composition.dart';
import 'package:rad_recon/services/survey_source_total.dart';

PlacementClassification row({required bool included, required double mbq}) {
  final now = DateTime(2026, 11, 1);
  return PlacementClassification(
    placement: SurveySourcePlacement(
      surveySessionId: 1,
      radiationSourceId: 1,
      included: included,
      createdAt: now,
    ),
    source: RadiationSource(
      id: 1,
      identifier: 'S-1',
      nuclideName: 'Co-60',
      activityAtManufactureMBq: mbq,
      createdAt: now,
      updatedAt: now,
    ),
    nuclides: [
      SourceNuclide(
        radiationSourceId: 1,
        nuclide: 'Co-60',
        activityMBq: mbq,
        referenceDate: now,
        origin: ActivityOrigin.manual,
        createdAt: now,
      ),
    ],
    asOf: now,
    composition: classifyComposition([
      CompositionRow(
        nuclide: 'Co-60',
        activityMBq: mbq,
        referenceDate: now,
        origin: ActivityOrigin.manual,
      ),
    ], now),
  );
}

void main() {
  test('csak a bekerülő elhelyezések számítanak az összegbe', () {
    final t = surveyTotalFromRows([
      row(included: true, mbq: 3e4),
      row(included: false, mbq: 1e6),
    ]);
    expect(t.sourceCount, 1);
    expect(t.rSum, closeTo(1.0, 1e-9));
    expect(t.isComplete, isTrue);
  });

  test('kizárt elhelyezés nélkül nincs R', () {
    final t = surveyTotalFromRows([row(included: false, mbq: 3e4)]);
    expect(t.rSum, isNull);
    expect(t.sourceCount, 0);
  });
}
