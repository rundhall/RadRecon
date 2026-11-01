import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/survey_source_placement.dart';

void main() {
  test('a térképi pozíció oda-vissza alakítás után megmarad', () {
    final p = SurveySourcePlacement(
      id: 3,
      surveySessionId: 1,
      radiationSourceId: 2,
      mapLat: 47.5,
      mapLon: 19.04,
      createdAt: DateTime(2026, 11, 1),
    );
    final back = SurveySourcePlacement.fromMap(p.toMap());
    expect(back.hasMapPosition, isTrue);
    expect(back.mapLat, 47.5);
    expect(back.mapLon, 19.04);
  });

  test('a pozíció törlése (clearMapPosition) eltünteti a koordinátát', () {
    final p = SurveySourcePlacement(
      id: 3,
      surveySessionId: 1,
      radiationSourceId: 2,
      mapLat: 1,
      mapLon: 2,
      createdAt: DateTime(2026),
    );
    expect(p.copyWith(clearMapPosition: true).hasMapPosition, isFalse);
  });
}
