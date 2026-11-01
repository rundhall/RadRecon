import '../models/bio_agent.dart';
import '../models/gas_reading.dart';
import '../models/dose_quantity.dart';
import '../models/radiation_kind.dart';
import '../services/dose_unit_controller.dart';
import '../services/unit_format.dart';
import '../models/activity_concentration.dart';
import '../models/measurement_point.dart';
import '../models/spectrum.dart';
import 'app_localizations.dart';
import '../models/measurement_type.dart';
import '../models/meteorology.dart';
import '../models/person_condition.dart';
import '../models/session_dosimeter.dart';
import '../models/session_person_link.dart';
import '../models/protocol_field.dart';
import '../models/survey_purpose.dart';

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
        MeasurementType.countRate => loc.measurementTypeCountRate,
        MeasurementType.sample => loc.measurementTypeSample,
        MeasurementType.meteorology => loc.measurementTypeMeteorology,
        MeasurementType.gasMeasurement => loc.measurementTypeGasMeasurement,
        MeasurementType.biological => loc.measurementTypeBiological,
        MeasurementType.activity => loc.measurementTypeActivity,
        MeasurementType.activityConcentration =>
          loc.measurementTypeActivityConcentration,
        MeasurementType.spectrum => loc.measurementTypeSpectrum,
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

extension SpectrumKindText on SpectrumKind {
  String localized(AppLocalizations loc) => switch (this) {
        SpectrumKind.alpha => loc.spectrumKindAlpha,
        SpectrumKind.beta => loc.spectrumKindBeta,
        SpectrumKind.gamma => loc.spectrumKindGamma,
        SpectrumKind.neutron => loc.spectrumKindNeutron,
      };
}

extension BasisKindText on BasisKind {
  String localized(AppLocalizations loc) => switch (this) {
        BasisKind.mass => loc.basisMass,
        BasisKind.volume => loc.basisVolume,
        BasisKind.area => loc.basisArea,
      };
}

/// Spektrum-összegzés egy mentett ponthoz (lista, jegyzőkönyv), a nuklid-
/// aktivitásokkal együtt.
String spectrumSummaryLine(AppLocalizations loc, MeasurementPoint p) {
  if (p.spectrumChannels == null) return loc.spectrumNoFileLabel;
  final live = p.spectrumLiveSeconds == null
      ? '—'
      : '${p.spectrumLiveSeconds!.toStringAsFixed(1)} s';
  final base = loc.spectrumSummaryText(
    SpectrumKind.fromDbValue(p.spectrumKind).localized(loc),
    '${p.spectrumChannels}',
    live,
    '${p.spectrumTotalCounts ?? '—'}',
  );
  final acts = NuclideActivity.listFromJson(p.spectrumActivityJson);
  if (acts.isEmpty) return base;
  return '$base · ${acts.map(nuclideActivityText).join(', ')}';
}

/// Egy nuklid aktivitása a megjelenítési egységben: "Cs-137: 169.107 ± 14.714 MBq".
String nuclideActivityText(NuclideActivity a) {
  final unit = ActivityUnitController.current.symbol;
  final value = formatActivityNumberMBq(a.mbq);
  final err = a.uncertaintyMbq == null
      ? ''
      : ' ± ${formatActivityNumberMBq(a.uncertaintyMbq!)}';
  return '${a.nuclide}: $value$err $unit';
}

/// X-tengely felirata: csatorna, vagy energia (a fájl egységével, ha van).
String spectrumAxisLabel(AppLocalizations loc, Spectrum s) {
  if (s.energyCoefficients == null) return loc.spectrumChannelAxis;
  final unit = s.energyUnit;
  return (unit == null || unit.isEmpty)
      ? loc.spectrumEnergyAxis
      : '${loc.spectrumEnergyAxis} ($unit)';
}

extension BasisKindSettingText on BasisKind {
  String settingLabel(AppLocalizations loc) => switch (this) {
        BasisKind.mass => loc.basisMassSettingLabel,
        BasisKind.volume => loc.basisVolumeSettingLabel,
        BasisKind.area => loc.basisAreaSettingLabel,
      };
}

extension RadiationKindText on RadiationKind {
  String localized(AppLocalizations loc) => switch (this) {
        RadiationKind.alpha => loc.radiationAlpha,
        RadiationKind.beta => loc.radiationBeta,
        RadiationKind.gamma => loc.radiationGamma,
        RadiationKind.neutron => loc.radiationNeutron,
      };
}

extension DoseQuantityLabelText on DoseQuantity {
  String localized(AppLocalizations loc) => switch (this) {
        DoseQuantity.h10 => loc.doseQuantityH10,
        DoseQuantity.hp => loc.doseQuantityHp,
        DoseQuantity.hprime => loc.doseQuantityHprime,
        DoseQuantity.kerma => loc.doseQuantityKerma,
      };
}

extension SurveyPurposeText on SurveyPurpose {
  String localized(AppLocalizations loc) => switch (this) {
        SurveyPurpose.waste => loc.purposeWaste,
        SurveyPurpose.environmental => loc.purposeEnvironmental,
        SurveyPurpose.accident => loc.purposeAccident,
        SurveyPurpose.sampling => loc.purposeSampling,
        SurveyPurpose.decommissioning => loc.purposeDecommissioning,
      };
}

/// A beépített jegyzőkönyv-mező címkéje az aktuális nyelven.
String protocolBuiltinLabel(String key, AppLocalizations loc) =>
    switch (key) {
      ProtocolFieldKeys.packageId => loc.protocolFieldPackageId,
      ProtocolFieldKeys.massKg => loc.protocolFieldMassKg,
      ProtocolFieldKeys.origin => loc.protocolFieldOrigin,
      ProtocolFieldKeys.halfLifeClass => loc.protocolFieldHalfLife,
      ProtocolFieldKeys.containerType => loc.protocolFieldContainer,
      ProtocolFieldKeys.storageLocation => loc.protocolFieldStorage,
      ProtocolFieldKeys.betaWork => loc.protocolFieldBetaWork,
      ProtocolFieldKeys.wipeResult => loc.protocolFieldWipeResult,
      ProtocolFieldKeys.wasteCategory => loc.protocolFieldWasteCategory,
      ProtocolFieldKeys.measuredBy => loc.protocolFieldMeasuredBy,
      ProtocolFieldKeys.decomWorkplaceName => loc.decomWorkplaceName,
      ProtocolFieldKeys.decomWorkplaceAddress => loc.decomWorkplaceAddress,
      ProtocolFieldKeys.decomUsePermit => loc.decomUsePermit,
      ProtocolFieldKeys.decomDeconPermit => loc.decomDeconPermit,
      ProtocolFieldKeys.decomUseEndDate => loc.decomUseEndDate,
      ProtocolFieldKeys.decomWorkplaceDescription => loc.decomWorkplaceDescription,
      ProtocolFieldKeys.decomDeconMethod => loc.decomDeconMethod,
      ProtocolFieldKeys.decomDismantledEquipment => loc.decomDismantledEquipment,
      ProtocolFieldKeys.decomWasteRemoved => loc.decomWasteRemoved,
      ProtocolFieldKeys.decomReleasedMaterials => loc.decomReleasedMaterials,
      ProtocolFieldKeys.decomTransferredMaterials => loc.decomTransferredMaterials,
      ProtocolFieldKeys.decomSurfaceMethod => loc.decomSurfaceMethod,
      ProtocolFieldKeys.decomSurfaceInstruments => loc.decomSurfaceInstruments,
      ProtocolFieldKeys.decomDoseInstruments => loc.decomDoseInstruments,
      ProtocolFieldKeys.decomSoilMethod => loc.decomSoilMethod,
      ProtocolFieldKeys.decomMeasuringOrg => loc.decomMeasuringOrg,
      ProtocolFieldKeys.decomMeasurers => loc.decomMeasurers,
      ProtocolFieldKeys.decomSummary => loc.decomSummary,
      ProtocolFieldKeys.decomAssessor => loc.decomAssessor,
      ProtocolFieldKeys.decomNoSources => loc.decomNoSources,
      ProtocolFieldKeys.decomResidualMaterials => loc.decomResidualMaterials,
      _ => key,
    };

/// A beépített mező tárolt kódjának olvasható szövege.
String protocolFieldValueText(
  String key,
  String value,
  AppLocalizations loc,
) =>
    switch (key) {
      ProtocolFieldKeys.halfLifeClass => switch (value) {
          'very_short' => loc.halfLifeVeryShort,
          'short_medium' => loc.halfLifeShortMedium,
          'long' => loc.halfLifeLong,
          _ => value,
        },
      ProtocolFieldKeys.betaWork => switch (value) {
          'yes' => loc.answerYes,
          'no' => loc.answerNo,
          _ => value,
        },
      ProtocolFieldKeys.decomNoSources => switch (value) {
          'yes' => loc.answerYes,
          'no' => loc.answerNo,
          _ => value,
        },
      _ => value,
    };

extension PhysicalStateText on PhysicalState {
  String localized(AppLocalizations loc) => switch (this) {
        PhysicalState.gas => loc.physStateGas,
        PhysicalState.liquid => loc.physStateLiquid,
        PhysicalState.solid => loc.physStateSolid,
        PhysicalState.aerosol => loc.physStateAerosol,
      };
}

extension BioKindText on BioKind {
  String localized(AppLocalizations loc) => switch (this) {
        BioKind.bacterium => loc.bioKindBacterium,
        BioKind.virus => loc.bioKindVirus,
        BioKind.toxin => loc.bioKindToxin,
        BioKind.fungus => loc.bioKindFungus,
        BioKind.other => loc.bioKindOther,
      };
}
