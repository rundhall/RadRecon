import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// A rögzíthető mérési bejegyzések típusai.
///
/// Ez dönti el, mely mezők jelennek meg a rögzítő képernyőn, és hogyan kerül
/// fel a pont a térképre / a jegyzőkönyvbe.
enum MeasurementType {
  doseRate, // gamma dózisteljesítmény, pl. nSv/h
  surfaceContamination, // felületi szennyezettség, Bq/cm²
  cps, // nyers beütésszám, cps
  neutronCps, // neutron beütésszám, cps
  sample, // fizikai mintavétel (nem élő mérés)
}

extension MeasurementTypeX on MeasurementType {
  /// Adatbázisban tárolt, stabil azonosító (soha ne változtasd meg utólag).
  String get dbValue {
    switch (this) {
      case MeasurementType.doseRate:
        return 'dose_rate';
      case MeasurementType.surfaceContamination:
        return 'surface_contamination';
      case MeasurementType.cps:
        return 'cps';
      case MeasurementType.neutronCps:
        return 'neutron_cps';
      case MeasurementType.sample:
        return 'sample';
    }
  }

  /// Alapértelmezett mértékegység az adott típushoz (megjelenítési segédlet;
  /// az app nem konvertál típusok/egységek között, minden natív egységben
  /// tárolódik).
  String get defaultUnit {
    switch (this) {
      case MeasurementType.doseRate:
        return 'nSv/h';
      case MeasurementType.surfaceContamination:
        return 'Bq/cm²';
      case MeasurementType.cps:
        return 'cps';
      case MeasurementType.neutronCps:
        return 'cps';
      case MeasurementType.sample:
        return '';
    }
  }

  /// Nyelvfüggő megjelenítési név — `context` kell hozzá, mert a fordítás a
  /// generált `AppLocalizations`-on keresztül érhető el.
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case MeasurementType.doseRate:
        return loc.measurementTypeDoseRate;
      case MeasurementType.surfaceContamination:
        return loc.measurementTypeSurfaceContamination;
      case MeasurementType.cps:
        return loc.measurementTypeCps;
      case MeasurementType.neutronCps:
        return loc.measurementTypeNeutronCps;
      case MeasurementType.sample:
        return loc.measurementTypeSample;

    }
  }

  static MeasurementType fromDbValue(String value) {
    return MeasurementType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => throw ArgumentError('Ismeretlen mérési típus: $value'),
    );
  }
}