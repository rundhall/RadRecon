import 'app_localizations.dart';
import '../models/measurement_type.dart';
import '../models/meteorology.dart';
import '../models/person_condition.dart';
import '../models/session_dosimeter.dart';
import '../models/session_person_link.dart';

/// A jegyzőkönyv a magyar `label`-öket használja; a felület az aktuális
/// nyelv szövegét ezekkel a kiterjesztésekkel kéri le.
extension SessionPersonRoleText on SessionPersonRole {
  String localized(AppLocalizations loc) => switch (this) {
        SessionPersonRole.surveyor => loc.rrRoleSurveyor,
        SessionPersonRole.victim => loc.rrRoleVictim,
      };
}

extension TriageText on TriageCategory {
  String localized(AppLocalizations loc) => switch (this) {
        TriageCategory.immediate => loc.rrTriageRed,
        TriageCategory.delayed => loc.rrTriageYellow,
        TriageCategory.minor => loc.rrTriageGreen,
        TriageCategory.expectant => loc.rrTriageBlack,
      };
}

extension ConditionKindText on ConditionKind {
  String localized(AppLocalizations loc) => switch (this) {
        ConditionKind.injury => loc.rrConditionInjury,
        ConditionKind.illness => loc.rrConditionIllness,
      };
}

extension PrecipitationText on PrecipitationState {
  String localized(AppLocalizations loc) => switch (this) {
        PrecipitationState.none => loc.rrPrecipNone,
        PrecipitationState.drizzle => loc.rrPrecipDrizzle,
        PrecipitationState.rain => loc.rrPrecipRain,
        PrecipitationState.snow => loc.rrPrecipSnow,
        PrecipitationState.sleet => loc.rrPrecipSleet,
        PrecipitationState.hail => loc.rrPrecipHail,
      };
}

extension MeasurementTypeText on MeasurementType {
  String localized(AppLocalizations loc) => switch (this) {
        MeasurementType.doseRate => loc.measurementTypeDoseRate,
        MeasurementType.surfaceContamination =>
          loc.measurementTypeSurfaceContamination,
        MeasurementType.cps => loc.measurementTypeCps,
        MeasurementType.neutronCps => loc.measurementTypeNeutronCps,
        MeasurementType.sample => loc.measurementTypeSample,
        MeasurementType.meteorology => loc.measurementTypeMeteorology,
        MeasurementType.gasMeasurement => loc.measurementTypeGasMeasurement,
      };
}

extension DosimeterKindText on DosimeterKind {
  String localized(AppLocalizations loc) => switch (this) {
        DosimeterKind.epdGamma => loc.dosimeterKindEpdGamma,
        DosimeterKind.epdNeutron => loc.dosimeterKindEpdNeutron,
        DosimeterKind.tlOfficial => loc.dosimeterKindTlOfficial,
        DosimeterKind.tlWorkplace => loc.dosimeterKindTlWorkplace,
      };
}

/// A tárolt (magyar) vegyületnév nyelvi megfelelője. Ismeretlen név (pl. az
/// "Egyéb" menüpontnál megadott szöveg) változatlanul marad.
String localizedGasName(AppLocalizations loc, String storedName) {
  return switch (storedName) {
    'Ammónia' => loc.rrGasAmmonia,
    'Benzol' => loc.rrGasBenzene,
    'Foszfin' => loc.rrGasPhosphine,
    'Foszgén' => loc.rrGasPhosgene,
    'Hidrogén' => loc.rrGasHydrogen,
    'Hidrogén-cianid' => loc.rrGasHydrogenCyanide,
    'Illékony szerves vegyületek' => loc.rrGasVoc,
    'Kén-dioxid' => loc.rrGasSulfurDioxide,
    'Kén-hexafluorid' => loc.rrGasSulfurHexafluoride,
    'Kén-hidrogén' => loc.rrGasHydrogenSulfide,
    'Klór' => loc.rrGasChlorine,
    'Metán' => loc.rrGasMethane,
    'Metanol' => loc.rrGasMethanol,
    'Metil-szalicilát' => loc.rrGasMethylSalicylate,
    'Nitrogén-monoxid' => loc.rrGasNitricOxide,
    'Nitrogén-dioxid' => loc.rrGasNitrogenDioxide,
    'Nitrogén-oxidok' => loc.rrGasNitrogenOxides,
    'Oxigén' => loc.rrGasOxygen,
    'Ózon' => loc.rrGasOzone,
    'Propán' => loc.rrGasPropane,
    'Szén-dioxid' => loc.rrGasCarbonDioxide,
    'Szén-monoxid' => loc.rrGasCarbonMonoxide,
    'Toluol' => loc.rrGasToluene,
    'Tributil-foszfát' => loc.rrGasTributylPhosphate,
    _ => storedName,
  };
}
