import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_type.dart';

void main() {
  test('meteorológiai, vegyi és biológiai pontnál nincs forrás-szakasz', () {
    expect(MeasurementType.meteorology.usesRadioactiveSources, isFalse);
    expect(MeasurementType.gasMeasurement.usesRadioactiveSources, isFalse);
    expect(MeasurementType.biological.usesRadioactiveSources, isFalse);
  });

  test('a sugárzási típusoknál marad a forrás-szakasz', () {
    expect(MeasurementType.doseRate.usesRadioactiveSources, isTrue);
    expect(MeasurementType.countRate.usesRadioactiveSources, isTrue);
    expect(MeasurementType.sample.usesRadioactiveSources, isTrue);
  });
}
