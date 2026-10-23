import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/widgets/measurement_kind_icon.dart';

void main() {
  test('mintavétel ikonja a jelző alapján', () {
    expect(measurementKindIcon(isSample: true, type: MeasurementType.doseRate),
        Icons.science_outlined);
  });

  test('dózisteljesítmény és egyéb típusok saját ikont kapnak', () {
    expect(measurementKindIcon(isSample: false, type: MeasurementType.doseRate),
        Icons.place);
    expect(measurementKindIcon(isSample: false, type: MeasurementType.cps),
        Icons.flash_on);
    expect(
        measurementKindIcon(isSample: false, type: MeasurementType.neutronCps),
        Icons.blur_circular);
    expect(
        measurementKindIcon(isSample: false, type: MeasurementType.surfaceContamination),
        Icons.texture);
  });
}
