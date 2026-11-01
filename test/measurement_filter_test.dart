import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_point.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/models/survey_source_placement.dart';
import 'package:rad_recon/services/measurement_filter.dart';

MeasurementPoint _p({
  String? label,
  MeasurementType type = MeasurementType.doseRate,
  double? value,
  bool isSample = false,
  bool isSourcePosition = false,
  String? notes,
  DateTime? at,
}) =>
    MeasurementPoint(
      surveySessionId: 1,
      locationLabel: label,
      latitude: 47.5,
      longitude: 19.0,
      type: type,
      value: value,
      unit: 'µSv/h',
      isSample: isSample,
      isSourcePosition: isSourcePosition,
      notes: notes,
      timestamp: at ?? DateTime(2026, 10, 1),
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    );

void main() {
  test('a mintavétel a jelzőből kategória sample, különben a típus', () {
    expect(measurementKindOf(_p(isSample: true)), MeasurementType.sample);
    expect(measurementKindOf(_p(type: MeasurementType.spectrum)), MeasurementType.spectrum);
    expect(measurementMatchesKind(_p(), null), isTrue);
    expect(measurementMatchesKind(_p(), MeasurementType.doseRate), isTrue);
    expect(measurementMatchesKind(_p(), MeasurementType.sample), isFalse);
  });

  test('a csak forrás-pozíció szűrő', () {
    expect(measurementMatchesSourceOnly(_p(isSourcePosition: true), true), isTrue);
    expect(measurementMatchesSourceOnly(_p(), true), isFalse);
    expect(measurementMatchesSourceOnly(_p(), false), isTrue);
  });

  test('keresés helyszínre és megjegyzésre, ékezetmentesen', () {
    final p = _p(label: 'Üllői út 12.', notes: 'vasúti sín mellett');
    expect(measurementMatchesQuery(p, 'ullői'), isTrue);
    expect(measurementMatchesQuery(p, 'VASUTI'), isTrue);
    expect(measurementMatchesQuery(p, 'debrecen'), isFalse);
    expect(measurementMatchesQuery(p, ''), isTrue);
  });

  test('érték szerinti rendezés, a hiányzó érték a végére kerül', () {
    final list = [_p(value: 1.0), _p(value: 5.0), _p(value: null)];
    final high = sortMeasurements(list, MeasurementSort.valueHighest);
    expect(high.map((p) => p.value).toList(), [5.0, 1.0, null]);
    final low = sortMeasurements(list, MeasurementSort.valueLowest);
    expect(low.first.value, isNull);
  });

  test('idő és név szerinti rendezés', () {
    final list = [
      _p(label: 'Zöld', at: DateTime(2026, 1, 1)),
      _p(label: 'Ábel', at: DateTime(2026, 6, 1)),
      _p(label: 'Béla', at: DateTime(2026, 3, 1)),
    ];
    expect(sortMeasurements(list, MeasurementSort.timeNewest).first.locationLabel, 'Ábel');
    expect(sortMeasurements(list, MeasurementSort.timeOldest).first.locationLabel, 'Zöld');
    expect(
      sortMeasurements(list, MeasurementSort.nameAsc).map((p) => p.locationLabel).toList(),
      ['Ábel', 'Béla', 'Zöld'],
    );
  });

  test('a térképen elhelyezett forrás a listában is megjelenik és szűrhető', () {
    final placement = SurveySourcePlacement(
      surveySessionId: 1,
      radiationSourceId: 2,
      mapLat: 47.5,
      mapLon: 19.0,
      createdAt: DateTime(2026, 10, 2),
    );
    final src = SurveyListItem.source(placement, 'T-20260101-120000', const ['Cs-137']);
    final pt = SurveyListItem.point(_p(label: 'Folyosó'));
    expect(itemMatchesSourceOnly(src, true), isTrue);
    expect(itemMatchesSourceOnly(pt, true), isFalse);
    expect(itemMatchesKind(src, MeasurementType.doseRate), isFalse);
    expect(itemMatchesQuery(src, 'cs137'), isTrue);
    expect(itemMatchesQuery(src, 'T-2026'), isTrue);
    final sorted = sortItems([pt, src], MeasurementSort.timeNewest);
    expect(sorted.first.isSourceRow, isTrue);
  });
}
