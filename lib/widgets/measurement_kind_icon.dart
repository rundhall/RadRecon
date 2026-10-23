import 'package:flutter/material.dart';

import '../models/measurement_type.dart';

/// A mérési pont típus-ikonja (szín nélkül). A mintavétel a `isSample` jelzőből
/// adódik, minden más a típusából. A forrás-pozíció figyelmeztetést a hívó kezeli.
IconData measurementKindIcon({required bool isSample, required MeasurementType type}) {
  final kind = isSample ? MeasurementType.sample : type;
  return switch (kind) {
    MeasurementType.doseRate => Icons.place,
    MeasurementType.surfaceContamination => Icons.texture,
    MeasurementType.cps => Icons.flash_on,
    MeasurementType.neutronCps => Icons.blur_circular,
    MeasurementType.sample => Icons.science_outlined,
    MeasurementType.meteorology => Icons.thermostat_outlined,
    MeasurementType.gasMeasurement => Icons.air_outlined,
  };
}
