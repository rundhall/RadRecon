/// Egy felméréshez tartozó kiegészítő jegyzőkönyv-mező.
///
/// Kétfajta van: a cél által meghatározott beépített mezők (kulcsuk a
/// [ProtocolFieldKeys]-ben) és a felhasználó által felvett egyedi mezők
/// ([ProtocolFieldKeys.custom], saját címkével).
class ProtocolField {
  const ProtocolField({
    this.id,
    required this.surveySessionId,
    required this.key,
    this.customLabel,
    this.value,
    this.sortOrder = 0,
  });

  final int? id;
  final int surveySessionId;
  final String key;
  final String? customLabel;
  final String? value;
  final int sortOrder;

  bool get isCustom => key == ProtocolFieldKeys.custom;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'survey_session_id': surveySessionId,
      'field_key': key,
      'custom_label': customLabel,
      'value': value,
      'sort_order': sortOrder,
    };
  }

  factory ProtocolField.fromMap(Map<String, Object?> map) {
    return ProtocolField(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      key: map['field_key'] as String,
      customLabel: map['custom_label'] as String?,
      value: map['value'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}

/// A mezőkulcsok. Az egyedi mezők kulcsa [custom]; a többi beépített.
abstract final class ProtocolFieldKeys {
  static const custom = 'custom';
  static const packageId = 'package_id';
  static const massKg = 'mass_kg';
  static const origin = 'origin';
  static const halfLifeClass = 'half_life_class';
  static const containerType = 'container_type';
  static const storageLocation = 'storage_location';
  static const betaWork = 'beta_work';
  static const wipeResult = 'wipe_result';
  static const wasteCategory = 'waste_category';
  static const measuredBy = 'measured_by';
  // Nuklidlista (JSON): WasteIsotope-ok, nem egyszerű mező.
  static const isotopes = 'isotopes';
  // 10. melléklet: inaktívvá nyilvánítás adatai (a melléklet pontjai szerint).
  static const decomWorkplaceName = 'dec_workplace_name';
  static const decomWorkplaceAddress = 'dec_workplace_address';
  static const decomUsePermit = 'dec_use_permit';
  static const decomDeconPermit = 'dec_decon_permit';
  static const decomUseEndDate = 'dec_use_end_date';
  static const decomWorkplaceDescription = 'dec_workplace_description';
  static const decomDeconMethod = 'dec_decon_method';
  static const decomDismantledEquipment = 'dec_dismantled_equipment';
  static const decomWasteRemoved = 'dec_waste_removed';
  static const decomReleasedMaterials = 'dec_released_materials';
  static const decomTransferredMaterials = 'dec_transferred_materials';
  static const decomSurfaceMethod = 'dec_surface_method';
  static const decomSurfaceInstruments = 'dec_surface_instruments';
  static const decomDoseInstruments = 'dec_dose_instruments';
  static const decomSoilMethod = 'dec_soil_method';
  static const decomMeasuringOrg = 'dec_measuring_org';
  static const decomMeasurers = 'dec_measurers';
  static const decomSummary = 'dec_summary';
  static const decomAssessor = 'dec_assessor';
  static const decomNoSources = 'dec_no_sources';
  static const decomResidualMaterials = 'dec_residual_materials';
}

/// A hulladék-célú felmérés beépített mezői, a jegyzőkönyvi sorrendben.
const wasteProtocolFieldKeys = <String>[
  ProtocolFieldKeys.packageId,
  ProtocolFieldKeys.massKg,
  ProtocolFieldKeys.origin,
  ProtocolFieldKeys.halfLifeClass,
  ProtocolFieldKeys.containerType,
  ProtocolFieldKeys.storageLocation,
  ProtocolFieldKeys.betaWork,
  ProtocolFieldKeys.wipeResult,
  ProtocolFieldKeys.wasteCategory,
  ProtocolFieldKeys.measuredBy,
];

/// A felezési idő kategória tárolt kódjai (a feliratot a domain_labels adja).
const halfLifeClassValues = <String>['very_short', 'short_medium', 'long'];

/// Igen/nem válasz tárolt kódjai.
const yesNoValues = <String>['yes', 'no'];

/// Inaktívvá nyilvánítás (10. melléklet) beépített mezői, a melléklet sorrendjében.
const decommissioningProtocolFieldKeys = <String>[
  ProtocolFieldKeys.decomWorkplaceName,
  ProtocolFieldKeys.decomWorkplaceAddress,
  ProtocolFieldKeys.decomUsePermit,
  ProtocolFieldKeys.decomDeconPermit,
  ProtocolFieldKeys.decomUseEndDate,
  ProtocolFieldKeys.decomWorkplaceDescription,
  ProtocolFieldKeys.decomDeconMethod,
  ProtocolFieldKeys.decomDismantledEquipment,
  ProtocolFieldKeys.decomWasteRemoved,
  ProtocolFieldKeys.decomReleasedMaterials,
  ProtocolFieldKeys.decomTransferredMaterials,
  ProtocolFieldKeys.decomSurfaceMethod,
  ProtocolFieldKeys.decomSurfaceInstruments,
  ProtocolFieldKeys.decomDoseInstruments,
  ProtocolFieldKeys.decomSoilMethod,
  ProtocolFieldKeys.decomMeasuringOrg,
  ProtocolFieldKeys.decomMeasurers,
  ProtocolFieldKeys.decomSummary,
  ProtocolFieldKeys.decomAssessor,
  ProtocolFieldKeys.decomNoSources,
  ProtocolFieldKeys.decomResidualMaterials,
];

/// Minden beépített mező (cél-váltáskor sem vesznek el az értékek).
const allBuiltinProtocolFieldKeys = <String>[
  ...wasteProtocolFieldKeys,
  ...decommissioningProtocolFieldKeys,
];
