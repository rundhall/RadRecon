import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/activity_origin.dart';
import 'package:rad_recon/models/source_nuclide.dart';
import 'package:rad_recon/models/survey_source_placement.dart';

void main() {
  test('SourceNuclide: toMap / fromMap körbeér', () {
    final n = SourceNuclide(
      id: 3,
      radiationSourceId: 7,
      nuclide: 'Am-241',
      activityMBq: 0.5,
      referenceDate: DateTime(2026, 10, 1),
      origin: ActivityOrigin.shieldedMeasurement,
      createdAt: DateTime(2026, 10, 2),
    );
    final back = SourceNuclide.fromMap(n.toMap());
    expect(back.nuclide, 'Am-241');
    expect(back.activityMBq, 0.5);
    expect(back.origin, ActivityOrigin.shieldedMeasurement);
    expect(back.referenceDate, DateTime(2026, 10, 1));
  });

  test('SourceNuclide: ismeretlen aktivitás null marad', () {
    final n = SourceNuclide(
      radiationSourceId: 1,
      nuclide: 'Cs-137',
      activityMBq: null,
      referenceDate: DateTime(2026, 10, 1),
      origin: ActivityOrigin.manual,
      createdAt: DateTime(2026, 10, 1),
    );
    expect(SourceNuclide.fromMap(n.toMap()).activityMBq, isNull);
  });

  test('SurveySourcePlacement: kizárás és számítás-dátum megmarad', () {
    final p = SurveySourcePlacement(
      id: 1,
      surveySessionId: 2,
      radiationSourceId: 3,
      planX: 1.5,
      planY: 2.5,
      included: false,
      calcDateOverride: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 10, 1),
    );
    final back = SurveySourcePlacement.fromMap(p.toMap());
    expect(back.included, isFalse);
    expect(back.planX, 1.5);
    expect(back.calcDateOverride, DateTime(2026, 9, 1));
  });

  test('SurveySourcePlacement: copyWith törli a dátum-felülírást', () {
    final p = SurveySourcePlacement(
      surveySessionId: 2,
      radiationSourceId: 3,
      calcDateOverride: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 10, 1),
    );
    expect(p.copyWith(clearCalcDateOverride: true).calcDateOverride, isNull);
  });
}
