import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/screens/survey_map_screen.dart';

void main() {
  test('mintavétel-jelző felülírja a típust', () {
    expect(mapKindOf(isSample: true, type: MeasurementType.doseRate),
        MeasurementType.sample);
  });

  test('egyéb mérés a saját típusát tartja meg', () {
    expect(mapKindOf(isSample: false, type: MeasurementType.cps),
        MeasurementType.cps);
    expect(mapKindOf(isSample: false, type: MeasurementType.neutronCps),
        MeasurementType.neutronCps);
  });

  test('dózisteljesítmény marad dózisteljesítmény (színskála)', () {
    expect(mapKindOf(isSample: false, type: MeasurementType.doseRate),
        MeasurementType.doseRate);
  });
}
