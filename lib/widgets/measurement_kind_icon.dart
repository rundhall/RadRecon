import 'package:flutter/material.dart';

import '../models/measurement_type.dart';

/// A mérési pont típus-ikonja (szín nélkül). A mintavétel a `isSample` jelzőből
/// adódik, minden más a típusából. A forrás-pozíció figyelmeztetést a hívó kezeli.
IconData measurementKindIcon({required bool isSample, required MeasurementType type}) {
  final kind = isSample ? MeasurementType.sample : type;
  return switch (kind) {
    MeasurementType.doseRate => Icons.place,
    MeasurementType.surfaceContamination => Icons.texture,
    MeasurementType.activity => Icons.radio_button_checked,
    MeasurementType.activityConcentration => Icons.water_drop_outlined,
    MeasurementType.countRate => Icons.flash_on,
    MeasurementType.spectrum => Icons.show_chart,
    MeasurementType.sample => Icons.science_outlined,
    MeasurementType.meteorology => Icons.thermostat_outlined,
    MeasurementType.gasMeasurement => Icons.air_outlined,
    MeasurementType.biological => Icons.coronavirus_outlined,
  };
}
