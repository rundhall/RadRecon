import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../services/dose_unit_controller.dart';

/// A rögzíthető mérési bejegyzések típusai.
///
/// Ez dönti el, mely mezők jelennek meg a rögzítő képernyőn, és hogyan kerül
/// fel a pont a térképre / a jegyzőkönyvbe.
enum MeasurementType {
  doseRate, // gamma dózisteljesítmény, egysége a Beállításokban választható
  surfaceContamination, // felületi szennyezettség, Bq/cm²
  cps, // nyers beütésszám, cps
  neutronCps, // neutron beütésszám, cps
  sample, // fizikai mintavétel (nem élő mérés)
  meteorology, // meteorológiai megfigyelés (nincs mérési érték)
  gasMeasurement, // gázmérés, vegyületenként (nincs mérési érték)
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
      case MeasurementType.meteorology:
        return 'meteorology';
      case MeasurementType.gasMeasurement:
        return 'gas_measurement';
    }
  }

  /// Alapértelmezett mértékegység az adott típushoz (megjelenítési segédlet;
  /// az app nem konvertál típusok/egységek között, minden natív egységben
  /// tárolódik).
  String get defaultUnit {
    switch (this) {
      case MeasurementType.doseRate:
        return DoseUnitController.current.symbol;
      case MeasurementType.surfaceContamination:
        return 'Bq/cm²';
      case MeasurementType.cps:
        return 'cps';
      case MeasurementType.neutronCps:
        return 'cps';
      case MeasurementType.sample:
      case MeasurementType.meteorology:
      case MeasurementType.gasMeasurement:
        return '';
    }
  }

  /// A típus rögzít-e mérési értéket (dózis, felületi szennyezettség, beütés).
  /// A mintavétel, a meteorológia és a gázmérés nem.
  bool get hasValue =>
      this != MeasurementType.sample &&
      this != MeasurementType.meteorology &&
      this != MeasurementType.gasMeasurement;

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
      case MeasurementType.meteorology:
        return loc.measurementTypeMeteorology;
      case MeasurementType.gasMeasurement:
        return loc.measurementTypeGasMeasurement;

    }
  }

  static MeasurementType fromDbValue(String value) {
    return MeasurementType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => throw ArgumentError('Ismeretlen mérési típus: $value'),
    );
  }
}