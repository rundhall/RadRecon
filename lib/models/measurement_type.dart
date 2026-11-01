import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../services/dose_unit_controller.dart';
import 'activity_concentration.dart';
import 'radiation_kind.dart';

/// A rögzíthető mérési bejegyzések típusai.
///
/// Ez dönti el, mely mezők jelennek meg a rögzítő képernyőn, és hogyan kerül
/// fel a pont a térképre / a jegyzőkönyvbe.
enum MeasurementType {
  doseRate, // dózisteljesítmény: sugárzás típusa és mennyiség (H*(10), Hp(d), H'(d,Ω), K)
  surfaceContamination, // felületi szennyezettség, Bq/cm²
  activity, // aktivitás, alapértelmezett egység a Beállításokban
  activityConcentration, // aktivitás / (tömeg|térfogat|felület)
  countRate, // beütésszám: cps, cpm, cph; neutronnál ncps…
  spectrum, // alfa/béta/gamma/neutron spektrum N42 fájlból (nincs mérési érték)
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
      case MeasurementType.activity:
        return 'activity';
      case MeasurementType.activityConcentration:
        return 'activity_concentration';
      case MeasurementType.countRate:
        return 'count_rate';
      case MeasurementType.spectrum:
        return 'spectrum';
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
      case MeasurementType.activity:
        return ActivityUnitController.current.symbol;
      case MeasurementType.activityConcentration:
        return concentrationSymbol(
          ActivityUnitController.current,
          BasisUnit.kilogram,
        );
      case MeasurementType.countRate:
        return 'cps';
      case MeasurementType.spectrum:
      case MeasurementType.sample:
      case MeasurementType.meteorology:
      case MeasurementType.gasMeasurement:
        return '';
    }
  }

  /// A típus rögzít-e mérési értéket.
  bool get hasValue =>
      this != MeasurementType.sample &&
      this != MeasurementType.meteorology &&
      this != MeasurementType.gasMeasurement &&
      this != MeasurementType.spectrum;

  /// Nyelvfüggő megjelenítési név — `context` kell hozzá, mert a fordítás a
  /// generált `AppLocalizations`-on keresztül érhető el.
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case MeasurementType.doseRate:
        return loc.measurementTypeDoseRate;
      case MeasurementType.surfaceContamination:
        return loc.measurementTypeSurfaceContamination;
      case MeasurementType.activity:
        return loc.measurementTypeActivity;
      case MeasurementType.activityConcentration:
        return loc.measurementTypeActivityConcentration;
      case MeasurementType.countRate:
        return loc.measurementTypeCountRate;
      case MeasurementType.spectrum:
        return loc.measurementTypeSpectrum;
      case MeasurementType.sample:
        return loc.measurementTypeSample;
      case MeasurementType.meteorology:
        return loc.measurementTypeMeteorology;
      case MeasurementType.gasMeasurement:
        return loc.measurementTypeGasMeasurement;
    }
  }

  /// Régi típusnevek: a `cps` és a `neutron_cps` mostantól a beütésszám típus.
  static MeasurementType fromDbValue(String value) {
    if (value == 'cps' || value == 'neutron_cps') {
      return MeasurementType.countRate;
    }
    return MeasurementType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => throw ArgumentError('Ismeretlen mérési típus: $value'),
    );
  }

  /// A régi neutron-beütésszám típusnévből a sugárzás típusa.
  static RadiationKind? legacyRadiationKind(String dbValue) =>
      dbValue == 'neutron_cps' ? RadiationKind.neutron : null;
}
