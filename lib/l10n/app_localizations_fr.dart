// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'RadRecon';

  @override
  String get instrumentsTooltip => 'Instruments';

  @override
  String get searchHint => 'Rechercher';

  @override
  String get searchNoResults => 'Aucun résultat correspondant';

  @override
  String get alertThresholdsTooltip => 'Seuils d\'alerte';

  @override
  String get noSurveysYet =>
      'Aucune campagne pour l\'instant. Démarrez-en une avec le bouton +.';

  @override
  String get newSurveyButton => 'Nouvelle campagne';

  @override
  String get newSurveyDialogTitle => 'Nouvelle campagne';

  @override
  String get surveyNameLabel => 'Nom';

  @override
  String get surveyLocationLabel => 'Lieu (facultatif)';

  @override
  String get editSurveyDetailsTooltip => 'Modifier le nom et le lieu';

  @override
  String get editSurveyDetailsTitle => 'Modifier les détails de la campagne';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get startButton => 'Démarrer';

  @override
  String surveyDefaultTitle(String date) {
    return 'Campagne – $date';
  }

  @override
  String get noLocationPlaceholder => '—';

  @override
  String get doseUnitSectionTitle => 'Unité par défaut du débit de dose';

  @override
  String get doseUnitSectionHint =>
      'Ces unités sont présélectionnées pour les nouvelles mesures. Lors de l\'enregistrement, une autre peut être choisie dans une liste, sans saisie, et le nombre saisi est converti automatiquement lors du changement d\'unité. Le seuil d\'alerte du débit de dose est converti lui aussi.';

  @override
  String get unitsSectionTitle => 'Unités';

  @override
  String get activityUnitLabel => 'Unité par défaut de l\'activité';

  @override
  String get distanceUnitLabel => 'Unité par défaut de la distance';

  @override
  String get activityPlainLabel => 'Activité';

  @override
  String get measuredDoseRatePlainLabel => 'Débit de dose mesuré';

  @override
  String get distanceFromSourcePlainLabel => 'Distance à la source';

  @override
  String get sourceDistancePlainLabel => 'Distance au point de mesure';

  @override
  String get activityAtManufacturePlainLabel => 'Activité à la fabrication';

  @override
  String get invalidDistancePlainError =>
      'Saisissez une distance valide et positive.';

  @override
  String get invalidActivityPlainError => 'Saisissez une activité valide.';

  @override
  String get invalidDoseRatePlainError => 'Saisissez un débit de dose valide.';

  @override
  String get distanceFromSourceShortLabel => 'Distance à la source';

  @override
  String get calculatedActivityResultLabel => 'Activité calculée';

  @override
  String get distanceIntervalPlainLabel => 'Intervalle de distance';

  @override
  String get modbusQuantityLabel => 'Ce que renvoie le registre';

  @override
  String get modbusRegisterUnitLabel => 'Unité du registre';

  @override
  String get modbusQuantityHelper =>
      'Lors de l\'enregistrement, l\'app convertit la valeur dans l\'unité par défaut choisie dans les Réglages.';

  @override
  String get autoLogTypeFromInstrument =>
      'L\'enregistrement automatique saisit la grandeur configurée pour l\'instrument.';

  @override
  String get nuclideIdSectionTitle => 'Identification du nucléide';

  @override
  String get nuclideStatusNone => 'Non précisé';

  @override
  String get nuclideStatusIdentified => 'Nucléide(s) identifié(s)';

  @override
  String get nuclideStatusUnknown => 'Inconnu';

  @override
  String get nuclideStatusOther => 'Autre (hors liste)';

  @override
  String get nuclideStatusMixture => 'Probablement plusieurs sources (mélange)';

  @override
  String get nuclideKnownListLabel => 'Nucléides de la liste';

  @override
  String get nuclideCustomLabel => 'Nom d\'un autre nucléide';

  @override
  String get nuclideAddButton => 'Ajouter';

  @override
  String get nuclideRequiredError =>
      'Saisissez au moins un nucléide ou choisissez Inconnu.';

  @override
  String get csvHeaderNuclides => 'Identification du nucléide';

  @override
  String get nuclideDoneButton => 'Terminé';

  @override
  String get unshieldedActivityLabel => 'Activité (sans blindage)';

  @override
  String get shieldingSectionTitle => 'Blindage (facultatif)';

  @override
  String get shieldingHint =>
      'Si la source est derrière un blindage, saisissez son matériau et son épaisseur : l\'app estimera aussi l\'activité réelle de la source blindée.';

  @override
  String get shieldingMaterialLabel => 'Matériau du blindage';

  @override
  String get shieldingNoneOption => 'Pas de blindage';

  @override
  String get shieldingThicknessLabel => 'Épaisseur du blindage';

  @override
  String get shieldingThicknessError => 'Saisissez une épaisseur positive';

  @override
  String get shieldedActivityLabel => 'Activité estimée de la source blindée';

  @override
  String get shieldingDisclaimer =>
      'Estimation approchée : l\'atténuation est modélisée par des épaisseurs moitié (chaque épaisseur moitié divise le débit de dose par deux) avec des valeurs indicatives. Le rayonnement diffusé (build-up), la géométrie de la source et le spectre sont simplifiés ; le résultat tend donc à surestimer l\'activité. Pour les protocoles officiels, vérifiez auprès d\'une source faisant autorité.';

  @override
  String get shieldingMaterialLead => 'Plomb';

  @override
  String get shieldingMaterialSteel => 'Acier (fer)';

  @override
  String get shieldingMaterialConcrete => 'Béton';

  @override
  String get shieldingMaterialTungsten => 'Tungstène';

  @override
  String get shieldingMaterialAluminium => 'Aluminium';

  @override
  String get shieldingMaterialWater => 'Eau';

  @override
  String get csvUnshieldedNote => 'sans blindage';

  @override
  String get csvShieldedSourceNote => 'source blindée';

  @override
  String get shieldingAddLayer => 'Ajouter une couche';

  @override
  String get shieldingLayerLabel => 'Couche';

  @override
  String get shieldingRemoveLayer => 'Supprimer la couche';

  @override
  String get doseRateUnshieldedLabel => 'Débit de dose (sans blindage)';

  @override
  String get doseRateShieldedLabel => 'Débit de dose derrière le blindage';

  @override
  String get calibrationSectionTitle => 'Vérification et étalonnage';

  @override
  String get calibrationKindVerification => 'Vérification';

  @override
  String get calibrationKindCalibration => 'Étalonnage';

  @override
  String get calibrationAddButton => 'Ajouter un enregistrement';

  @override
  String get calibrationDialogTitle =>
      'Enregistrement de vérification / étalonnage';

  @override
  String get calibrationKindLabel => 'Type';

  @override
  String get calibrationPerformedOnLabel => 'Date de réalisation';

  @override
  String get calibrationValidUntilLabel => 'Valable jusqu\'au';

  @override
  String get calibrationCertificateLabel => 'Numéro de certificat';

  @override
  String get calibrationPerformedByLabel =>
      'Réalisé par (laboratoire / autorité)';

  @override
  String get calibrationAttachFile => 'Joindre le certificat';

  @override
  String get calibrationRemoveFile => 'Supprimer la pièce jointe';

  @override
  String get calibrationOpenFile => 'Ouvrir / partager le certificat';

  @override
  String get calibrationEmptyList => 'Aucun enregistrement pour l\'instant.';

  @override
  String get calibrationStatusValid => 'Valable';

  @override
  String get calibrationStatusSoon => 'Expire bientôt';

  @override
  String get calibrationStatusExpired => 'EXPIRÉ';

  @override
  String get calibrationStatusUnknown => 'Aucune donnée';

  @override
  String get calibrationExpiredWarning =>
      'Attention : la vérification/l\'étalonnage de l\'instrument sélectionné a expiré. Valable jusqu\'au :';

  @override
  String get calibrationSoonWarning =>
      'Attention : la vérification/l\'étalonnage de l\'instrument sélectionné expire bientôt. Valable jusqu\'au :';

  @override
  String get calibrationUnknownWarning =>
      'L\'instrument sélectionné n\'a aucune donnée de vérification/étalonnage.';

  @override
  String get calibrationSaveAnywayTitle => 'Vérification/étalonnage expiré';

  @override
  String get calibrationSaveAnywayBody =>
      'La mesure a été faite avec un instrument dont la vérification/l\'étalonnage a expiré ; le protocole le signalera. Enregistrer quand même ?';

  @override
  String get calibrationSaveAnywayConfirm => 'Enregistrer quand même';

  @override
  String get calibrationValidUntilBeforeError =>
      'La validité ne peut pas précéder la date de réalisation';

  @override
  String get csvHeaderInstrumentCalibration =>
      'Vérification/étalonnage de l\'instrument';

  @override
  String get personPhoneLabel => 'Numéro de téléphone';

  @override
  String get personEmailLabel => 'Adresse e-mail';

  @override
  String get personAddEmail => 'Ajouter une adresse e-mail';

  @override
  String get personRemoveEmail => 'Supprimer l\'e-mail';

  @override
  String get personEmailInvalidError => 'Adresse e-mail invalide';

  @override
  String get personCertificatesTitle => 'Certificats';

  @override
  String get personCertificateAdd => 'Ajouter un certificat';

  @override
  String get personCertificateDialogTitle => 'Certificat';

  @override
  String get personCertificateNameLabel =>
      'Intitulé (p. ex. examen de radioprotection)';

  @override
  String get personCertificateNumberLabel => 'Numéro de certificat';

  @override
  String get personCertificateIssuerLabel => 'Émetteur';

  @override
  String get personCertificateIssuedLabel => 'Date d\'émission';

  @override
  String get personCertificateNameRequired =>
      'Saisissez l\'intitulé du certificat';

  @override
  String get personCertificateValidBeforeError =>
      'La validité ne peut pas précéder la date d\'émission';

  @override
  String get personCertificatesEmpty => 'Aucun certificat pour l\'instant.';

  @override
  String get sourceCertificateTitle => 'Certificat de la source';

  @override
  String get sourceCertificateAttach => 'Joindre le certificat';

  @override
  String get sourceCertificateEmpty => 'Aucun certificat joint.';

  @override
  String get companyDocumentsTooltip =>
      'Documents et autorisations de l\'entreprise';

  @override
  String get companyDocumentNew => 'Nouveau document';

  @override
  String get companyDocumentEdit => 'Modifier le document';

  @override
  String get companyDocumentTitleLabel => 'Nom du document';

  @override
  String get companyDocumentIdentifierLabel =>
      'Identifiant (n° de dossier / d\'autorisation)';

  @override
  String get companyDocumentIssuerLabel => 'Émetteur / autorité';

  @override
  String get companyDocumentIssuedLabel =>
      'Date d\'émission / d\'entrée en vigueur';

  @override
  String get companyDocumentValidUntilLabel => 'Valable / à réviser jusqu\'au';

  @override
  String get companyDocumentFilesTitle => 'Fichiers joints';

  @override
  String get companyDocumentAttach => 'Joindre un fichier';

  @override
  String get companyDocumentsEmpty => 'Aucun document pour l\'instant.';

  @override
  String get companyDocumentDeleteTitle => 'Supprimer le document';

  @override
  String get companyDocumentDeleteConfirm => 'Supprimer ce document ?';

  @override
  String get companyDocSuggestionsLabel => 'Documents courants';

  @override
  String get companyDocSuggestRadiationPolicy =>
      'Règlement de radioprotection du lieu de travail';

  @override
  String get companyDocSuggestRadiationDescription =>
      'Description de la radioprotection';

  @override
  String get companyDocSuggestPhysicalProtection =>
      'Plan de protection physique';

  @override
  String get companyDocSuggestEmergencyPlan =>
      'Plan d\'intervention d\'urgence';

  @override
  String get nuclideEditButton => 'Modifier les nucléides';

  @override
  String get languageSectionTitle => 'Langue';

  @override
  String get languageSystemOption => 'Langue du téléphone';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get appearanceSectionTitle => 'Apparence';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get alertThresholdExplanation =>
      'Si une mesure enregistrée atteint ou dépasse le seuil défini ici, l\'app vous alerte (son + fenêtre). Laissez vide pour ne pas avoir d\'alerte pour ce type.';

  @override
  String get noThresholdSetHint => 'Aucun seuil défini';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get settingsSavedMessage => 'Réglages enregistrés.';

  @override
  String get measurementTypeDoseRate => 'Débit de dose';

  @override
  String get measurementTypeSurfaceContamination => 'Contamination surfacique';

  @override
  String get measurementTypeCps => 'Taux de comptage (cps)';

  @override
  String get measurementTypeNeutronCps => 'Taux de comptage neutronique (cps)';

  @override
  String get measurementTypeSample => 'Prélèvement';

  @override
  String get instrumentDeleteTitle => 'Supprimer l\'instrument';

  @override
  String instrumentDeleteConfirm(String name) {
    return 'Supprimer « $name » ? Les mesures passées qui lui sont liées sont conservées ; seule la référence à l\'instrument est supprimée.';
  }

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get noInstrumentsYet =>
      'Aucun instrument pour l\'instant. Ajoutez-en un avec le bouton +.';

  @override
  String get noCalibrationData => 'Aucune donnée d\'étalonnage';

  @override
  String nextCalibrationOn(String date) {
    return 'Prochain étalonnage : $date';
  }

  @override
  String get noSerialNumber => 'pas de numéro de série';

  @override
  String get newInstrumentButton => 'Nouvel instrument';

  @override
  String get editInstrumentTitle => 'Modifier l\'instrument';

  @override
  String get instrumentNameLabel => 'Nom / type de l\'instrument';

  @override
  String get requiredFieldError => 'Obligatoire';

  @override
  String get serialNumberLabel => 'Numéro de série';

  @override
  String get nextCalibrationLabel => 'Date du prochain étalonnage';

  @override
  String get notSetLabel => 'Non défini';

  @override
  String get calibrationFactorLabel => 'Facteur d\'étalonnage';

  @override
  String get modbusConnectedLabel => 'Accessible en WiFi via Modbus/TCP';

  @override
  String get modbusHostLabel => 'Adresse IP / hôte';

  @override
  String get modbusPortLabel => 'Port (p. ex. 502)';

  @override
  String get modbusUnitIdLabel => 'ID d\'unité Modbus (adresse esclave)';

  @override
  String get modbusRegisterAddressLabel => 'Adresse du registre (p. ex. 294)';

  @override
  String get modbusRegisterAddressHelper =>
      'Registre de maintien initial de la valeur mesurée (float32)';

  @override
  String get modbusGpsEnabledLabel => 'Lire la position GPS via Modbus';

  @override
  String get modbusGpsLatAddressLabel =>
      'Registre de latitude (float32, 426 par défaut)';

  @override
  String get modbusGpsLonAddressLabel =>
      'Registre de longitude (float32, 428 par défaut)';

  @override
  String get pickPositionTitle => 'Choisir une position';

  @override
  String get confirmPositionButton => 'Confirmer la position';

  @override
  String get isotopeCalculatorTitle => 'Calculateur d\'isotopes';

  @override
  String get gammaConstantsDisclaimer =>
      'Les constantes Γ sont données à titre indicatif. Pour un protocole officiel, vérifiez-les auprès d\'une source faisant autorité avant de documenter le résultat.';

  @override
  String get isotopeLabel => 'Isotope';

  @override
  String get modeDoseFromActivity => 'Activité vers\ndébit de dose';

  @override
  String get modeActivityFromDose => 'Débit de dose vers\nactivité';

  @override
  String get distanceFromSourceLabel => 'Distance à la source (m)';

  @override
  String get activityLabel => 'Activité (MBq)';

  @override
  String get measuredDoseRateLabel => 'Débit de dose mesuré (µSv/h)';

  @override
  String get calculateButton => 'Calculer';

  @override
  String get invalidDistanceError =>
      'Saisissez une distance (m) valide et positive.';

  @override
  String get invalidActivityError => 'Saisissez une activité (MBq) valide.';

  @override
  String get invalidDoseRateError =>
      'Saisissez un débit de dose (µSv/h) valide.';

  @override
  String calculationErrorMessage(String error) {
    return 'Erreur de calcul : $error';
  }

  @override
  String calculatedDoseRateResult(String uSvH, String nSvH) {
    return 'Débit de dose calculé : $uSvH µSv/h\n($nSvH nSv/h)';
  }

  @override
  String calculatedActivityResult(String mbq, String gbq) {
    return 'Activité calculée : $mbq MBq\n($gbq GBq)';
  }

  @override
  String get distanceToolTitle => 'Mesure de distance';

  @override
  String get locationServiceDisabledError =>
      'Les services de localisation sont désactivés.';

  @override
  String get locationPermissionDeniedError =>
      'Autorisation de localisation refusée.';

  @override
  String gpsErrorMessage(String error) {
    return 'Erreur GPS : $error';
  }

  @override
  String get selectTargetFirstError => 'Choisissez d\'abord le point cible.';

  @override
  String get noGpsPositionError =>
      'Aucune position GPS. Actualisez ou choisissez un point de départ.';

  @override
  String get selectStartPointError => 'Choisissez un point de départ.';

  @override
  String get selectTargetPointError => 'Choisissez le point cible.';

  @override
  String get startFromCurrentPositionLabel => 'Départ : ma position actuelle';

  @override
  String get noPositionFetchedYet => 'Pas encore obtenue';

  @override
  String get refreshGpsButton => 'Actualiser le GPS';

  @override
  String get startPointLabel => 'Point de départ';

  @override
  String get targetPointLabel => 'Point cible';

  @override
  String get liveTrackingLabel => 'Suivi en direct';

  @override
  String get liveTrackingSubtitle =>
      'Met à jour en continu la distance et le relèvement pendant la marche.';

  @override
  String get calculateDistanceButton => 'Calculer';

  @override
  String get liveTrackingRunningHint =>
      'Le suivi en direct est actif : marchez dans la direction de la flèche.';

  @override
  String get sourceSearchTitle => 'Recherche de source';

  @override
  String get measurementTypeLabel => 'Type de mesure';

  @override
  String pointsRecordedForType(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points enregistrés',
      one: '$count point enregistré',
    );
    return '$_temp0 pour ce type dans cette campagne.';
  }

  @override
  String get lowConfidenceWarning =>
      'Peu de points (< 4) : l\'estimation n\'est pas fiable ; effectuez davantage de mesures à différents endroits de la zone de recherche.';

  @override
  String gradientEstimateLabel(String value, String unit) {
    return 'Gradient estimé : $value $unit/m';
  }

  @override
  String get directionEstimateHint =>
      'La valeur mesurée devrait augmenter dans cette direction.';

  @override
  String get sourceSearchDisclaimer =>
      'La direction suggérée repose sur une simple estimation linéaire du gradient à partir des points enregistrés jusqu\'ici dans cette campagne. Elle peut être inexacte avec des données de terrain bruitées, peu de points, ou lorsque la vraie source est éloignée par rapport à la taille de la zone relevée. À titre indicatif uniquement : elle ne remplace pas le jugement d\'un professionnel.';

  @override
  String get newMeasurementButton => 'Nouvelle mesure';

  @override
  String get mapTitle => 'Carte';

  @override
  String get noPointsRecordedYet =>
      'Aucun point de mesure enregistré pour l\'instant.';

  @override
  String get saveScreenshotTooltip =>
      'Enregistrer une capture pour le protocole';

  @override
  String get screenshotSavedMessage =>
      'Carte enregistrée : elle sera jointe lors de l\'export du protocole.';

  @override
  String screenshotErrorMessage(String error) {
    return 'Erreur de capture : $error';
  }

  @override
  String valueLabel(String value, String unit) {
    return 'Valeur : $value $unit';
  }

  @override
  String distanceFromSourceValue(String value) {
    return 'Distance à la source : $value m';
  }

  @override
  String timestampLabel(String value) {
    return 'Heure : $value';
  }

  @override
  String get sourcePositionLabel => 'Position de la source';

  @override
  String get editButton => 'Modifier';

  @override
  String get closeSurveyTitle => 'Clôturer la campagne';

  @override
  String get closeSurveyConfirm =>
      'Une fois clôturée, le protocole affichera la date du jour comme heure de fin. Les points ne sont pas verrouillés : vous pourrez encore les modifier.';

  @override
  String get closeSurveyButton => 'Clôturer';

  @override
  String get surveyClosedMessage => 'Campagne clôturée.';

  @override
  String get listScreenshotSavedMessage =>
      'Capture de la liste enregistrée : elle sera jointe lors de l\'export du protocole.';

  @override
  String exportErrorMessage(String error) {
    return 'Erreur d\'export : $error';
  }

  @override
  String importErrorMessage(String error) {
    return 'Erreur d\'import : $error';
  }

  @override
  String protocolShareSubject(String title) {
    return 'Protocole – $title';
  }

  @override
  String dataExportSubject(String title) {
    return 'Points de mesure (données) – $title';
  }

  @override
  String csvExportSubject(String title) {
    return 'Points de mesure (CSV) – $title';
  }

  @override
  String get importDoneTitle => 'Import terminé';

  @override
  String importedPointsMessage(int points, int instruments, int sources) {
    return '$points points importés.\n$instruments nouveaux instruments créés.\n$sources nouvelles sources radioactives créées.';
  }

  @override
  String get okButton => 'OK';

  @override
  String get toolsTooltip => 'Outils';

  @override
  String get autoLogMenuItem => 'Enregistrement automatique';

  @override
  String get captureListScreenshotMenuItem =>
      'Enregistrer une capture de la liste';

  @override
  String get exportProtocolMenuItem => 'Exporter le protocole';

  @override
  String get exportJsonMenuItem => 'Exporter les points (données, JSON)';

  @override
  String get exportCsvMenuItem => 'Exporter les points (tableau, CSV)';

  @override
  String get importJsonMenuItem => 'Importer des points (JSON)';

  @override
  String get newPointButton => 'Nouveau point';

  @override
  String sampleTakenListLabel(String date) {
    return 'Prélèvement · $date';
  }

  @override
  String get unknownModbusError => 'Erreur Modbus inconnue.';

  @override
  String get noValidPositionError => 'Aucune position valide indiquée.';

  @override
  String get thresholdExceededTitle => 'Seuil d\'alerte dépassé';

  @override
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  ) {
    return 'La valeur mesurée ($value $unit) atteint ou dépasse le seuil défini pour $type ($threshold $unit).';
  }

  @override
  String get newPointTitle => 'Nouveau point de mesure';

  @override
  String get editPointTitle => 'Modifier le point';

  @override
  String get locationLabelFieldLabel => 'Nom du lieu';

  @override
  String get measuredValueLabel => 'Valeur mesurée';

  @override
  String get numberRequiredError => 'Saisissez un nombre';

  @override
  String get unitLabel => 'Unité';

  @override
  String get instrumentLabel => 'Instrument';

  @override
  String get addInstrumentTooltip => 'Ajouter un nouvel instrument';

  @override
  String get queryingLabel => 'Interrogation...';

  @override
  String modbusQueryButton(String name) {
    return 'Requête Modbus ($name)';
  }

  @override
  String get sourcePositionSwitchLabel =>
      'C\'est la position de la source (valeur maximale)';

  @override
  String get sampleTakenSwitchLabel =>
      'Un échantillon physique a été prélevé ici';

  @override
  String get sampleContainerLabel => 'ID du conteneur';

  @override
  String get sampleAmountLabel => 'Quantité';

  @override
  String get sampleMethodLabel => 'Méthode de prélèvement';

  @override
  String get notesLabel => 'Notes';

  @override
  String get takePhotoLabel => 'Prendre une photo';

  @override
  String get retakePhotoLabel => 'Remplacer la photo';

  @override
  String get chooseFromGalleryLabel => 'Choisir dans la galerie';

  @override
  String get positionLabel => 'Position';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get invalidValueError => 'Invalide';

  @override
  String get liveGpsButton => 'GPS en direct';

  @override
  String get onMapButton => 'Sur la carte';

  @override
  String get autoLogDisclaimer =>
      'L\'enregistrement ne fonctionne que tant que cet écran est ouvert. Si le téléphone se verrouille ou si vous changez d\'app, la mesure se met en pause : il faudra la relancer à votre retour.';

  @override
  String get noModbusInstrumentMessage =>
      'Aucun instrument accessible via Modbus/TCP n\'est configuré. Ajoutez-en un dans la liste des Instruments (interrupteur WiFi Modbus/TCP activé, IP, ID d\'unité et adresse de registre renseignés).';

  @override
  String get triggerModeTime => 'Selon le temps';

  @override
  String get triggerModeDistance => 'Selon la distance';

  @override
  String get intervalSecondsLabel => 'Intervalle (secondes)';

  @override
  String get distanceIntervalLabel => 'Intervalle de distance (mètres)';

  @override
  String get connectingLabel => 'Connexion...';

  @override
  String get stopButton => 'Arrêter';

  @override
  String get loggingRunningLabel => 'Enregistrement en cours...';

  @override
  String get loggingStoppedLabel => 'Enregistrement arrêté';

  @override
  String capturedPointsLabel(int count) {
    return 'Points enregistrés : $count';
  }

  @override
  String lastValueLabel(String value, String unit) {
    return 'Dernière valeur : $value $unit';
  }

  @override
  String failedReadingsLabel(int count) {
    return 'Lectures échouées : $count';
  }

  @override
  String lastErrorSuffix(String error) {
    return ' (dernière erreur : $error)';
  }

  @override
  String get intervalMinError =>
      'L\'intervalle doit être d\'au moins 1 seconde.';

  @override
  String get distanceMinError => 'La distance doit être d\'au moins 1 mètre.';

  @override
  String modbusConnectErrorMessage(String error) {
    return 'Erreur de connexion Modbus : $error';
  }

  @override
  String get csvHeaderSerialNumber => 'N°';

  @override
  String get csvHeaderLocation => 'Lieu';

  @override
  String get csvHeaderType => 'Type';

  @override
  String get csvHeaderValue => 'Valeur';

  @override
  String get csvHeaderUnit => 'Unité';

  @override
  String get csvHeaderDistanceFromSource => 'Distance à la source';

  @override
  String get csvHeaderInstrument => 'Instrument';

  @override
  String get csvHeaderGpsLatitude => 'Latitude GPS';

  @override
  String get csvHeaderGpsLongitude => 'Longitude GPS';

  @override
  String get csvHeaderGpsAccuracy => 'Précision GPS';

  @override
  String get csvHeaderTimestamp => 'Horodatage';

  @override
  String get csvHeaderSample => 'Prélèvement';

  @override
  String get csvHeaderNotes => 'Notes';

  @override
  String get csvHeaderEstimatedActivity =>
      'Activité estimée (à partir de la mesure)';

  @override
  String get csvHeaderAttachedSources => 'Source(s) associée(s)';

  @override
  String get csvHeaderCalculatedDoseRate => 'Débit de dose calculé';

  @override
  String get csvHeaderDoseRateDifference => 'Écart';

  @override
  String get csvYes => 'oui';

  @override
  String get csvNo => 'non';

  @override
  String get importUnknownTypeWarning =>
      'Type de mesure inconnu ignoré pour un point.';

  @override
  String get importMissingGpsWarning =>
      'Un point a été ignoré faute de coordonnée GPS.';

  @override
  String get manageSourcesLabel => 'Gérer la ou les source(s) radioactive(s)';

  @override
  String sourcesCountLabel(int count) {
    return '$count source(s)';
  }

  @override
  String get radiationSourcesTitle => 'Sources';

  @override
  String get newSourceButton => 'Ajouter une source';

  @override
  String get newSourceTitle => 'Nouvelle source';

  @override
  String get editSourceTitle => 'Modifier la source';

  @override
  String get noSourcesRecordedYet =>
      'Aucune source associée à ce point pour l\'instant.';

  @override
  String get sourcesTooltip => 'Sources';

  @override
  String get pointSourcesTitle => 'Source(s) à ce point';

  @override
  String get attachSourceButton => 'Associer une source';

  @override
  String get pickSourceTitle => 'Choisir une source';

  @override
  String get noSourcesToAttach =>
      'Aucune source disponible pour l\'instant : ajoutez-en d\'abord une dans la liste principale des Sources.';

  @override
  String get noSourcesYet =>
      'Aucune source ajoutée pour l\'instant. Ajoutez-en une avec le bouton +.';

  @override
  String get enterDistanceDialogTitle => 'Saisir la distance';

  @override
  String get detachSourceConfirmTitle => 'Dissocier la source';

  @override
  String detachSourceConfirmMessage(String identifier) {
    return 'Dissocier la source « $identifier » de ce point ? La source reste dans le registre ; seul ce lien est supprimé.';
  }

  @override
  String get detachButton => 'Dissocier';

  @override
  String get totalCalculatedDoseRateLabel =>
      'Débit de dose total calculé (toutes les sources)';

  @override
  String sourcesUnknownNuclideSkippedNote(int count) {
    return '$count source(s) ont un nucléide inconnu et sont exclues du total.';
  }

  @override
  String get sourceIdentifierLabel => 'Identifiant unique';

  @override
  String get nuclideLabel => 'Nucléide';

  @override
  String get customNuclideOption => 'Autre (saisie manuelle)';

  @override
  String get customNuclideNameLabel => 'Nom du nucléide';

  @override
  String get activityAtManufactureLabel => 'Activité à la fabrication (MBq)';

  @override
  String get activityErrorPercentLabel => 'Erreur sur l\'activité (±%)';

  @override
  String get manufactureDateLabel => 'Date de fabrication';

  @override
  String get serviceLifeExpiryDateLabel => 'Fin de la durée de vie';

  @override
  String get nextInspectionDateLabel => 'Date du prochain contrôle';

  @override
  String get sourceDistanceLabel => 'Distance au point de mesure (m)';

  @override
  String get asOfDateLabel => 'Date de référence de l\'activité';

  @override
  String get currentActivityResultLabel => 'Activité actuelle';

  @override
  String get calculatedDoseRateResultLabel => 'Débit de dose calculé';

  @override
  String get measuredDoseRateResultLabel => 'Débit de dose mesuré (au point)';

  @override
  String get doseRateDifferenceResultLabel => 'Écart (mesuré − calculé)';

  @override
  String get unknownNuclideDecayWarning =>
      'Nucléide inconnu : aucune période ni constante gamma enregistrée, l\'activité actuelle et le débit de dose calculé ne peuvent donc pas être déterminés. Les données de la source peuvent quand même être enregistrées, mais la comparaison est ignorée.';

  @override
  String get noMeasuredValueForComparisonNote =>
      'Aucune valeur mesurée enregistrée pour ce point : la comparaison est impossible.';

  @override
  String unrecognizedUnitForComparisonNote(String unit) {
    return 'L\'unité de mesure ($unit) ne peut pas être convertie automatiquement : la comparaison est impossible.';
  }

  @override
  String get sourceExpiredWarning => 'La durée de vie de la source a expiré.';

  @override
  String get deleteSourceConfirmTitle => 'Supprimer la source';

  @override
  String deleteSourceConfirmMessage(String identifier) {
    return 'Supprimer la source « $identifier » du registre ? Elle sera aussi retirée de tous les points auxquels elle est associée. Cette action est irréversible.';
  }

  @override
  String get sourceCalculationDisclaimer =>
      'Les valeurs calculées sont données à titre indicatif et reposent sur des constantes gamma et des périodes standard. Pour les enregistrements officiels, vérifiez auprès d\'une source faisant autorité.';

  @override
  String get estimatedActivityFromMeasurementLabel =>
      'Activité estimée (à partir de la valeur mesurée)';

  @override
  String get personsTooltip => 'Personnes';

  @override
  String get personsTitle => 'Personnes';

  @override
  String get newPersonButton => 'Ajouter une personne';

  @override
  String get newPersonTitle => 'Nouvelle personne';

  @override
  String get editPersonTitle => 'Modifier la personne';

  @override
  String get noPersonsYet =>
      'Aucune personne ajoutée pour l\'instant. Ajoutez-en une avec le bouton +.';

  @override
  String get personNameLabel => 'Nom';

  @override
  String get medicalExamExpiryDateLabel => 'Expiration de la visite médicale';

  @override
  String get trainingExpiryDateLabel => 'Expiration de la formation';

  @override
  String get deletePersonConfirmTitle => 'Supprimer la personne';

  @override
  String deletePersonConfirmMessage(String name) {
    return 'Supprimer « $name » du registre ? Elle sera aussi retirée de toutes les campagnes auxquelles elle est affectée. Cette action est irréversible.';
  }

  @override
  String get sessionPersonsTitle => 'Personnel de cette campagne';

  @override
  String get noPersonsAttachedYet =>
      'Aucune personne affectée à cette campagne pour l\'instant.';

  @override
  String get attachPersonButton => 'Affecter une personne';

  @override
  String get pickPersonTitle => 'Choisir une personne';

  @override
  String get noPersonsToAttach =>
      'Aucune personne disponible pour l\'instant : ajoutez-en d\'abord une dans la liste principale des Personnes.';

  @override
  String get detachPersonConfirmTitle => 'Retirer la personne';

  @override
  String detachPersonConfirmMessage(String name) {
    return 'Retirer « $name » de cette campagne ? La personne reste dans le registre ; seule cette affectation est supprimée.';
  }

  @override
  String get expiryNotificationsSectionTitle => 'Notifications d\'expiration';

  @override
  String get expiryNotificationsSwitchTitle =>
      'Notifier les dates d\'expiration';

  @override
  String get expiryNotificationsSwitchSubtitle =>
      'Pour les prochaines expirations des sources (durée de vie, contrôle) et des personnes (visite médicale, formation), envoyées à 8 h du matin.';

  @override
  String get expiryLeadTimeLabel => 'Délai de notification';

  @override
  String get expiryLeadSameDay => 'Le jour même';

  @override
  String get expiryLeadOneDay => '1 jour avant';

  @override
  String get expiryLeadTwoDays => '2 jours avant';

  @override
  String get expiryLeadOneWeek => '1 semaine avant';

  @override
  String get expiryNotificationsPermissionDenied =>
      'Les notifications sont bloquées dans les réglages du téléphone. Autorisez-y les notifications de RadRecon.';

  @override
  String get expiryNotificationTitleToday => 'Expire aujourd\'hui';

  @override
  String get expiryNotificationTitleUpcoming => 'Expire bientôt';

  @override
  String get expiryNotificationChannelName => 'Notifications d\'expiration';

  @override
  String get expiryNotificationChannelDescription =>
      'Prochaines expirations des sources et des personnes';

  @override
  String get importRegistryCsv => 'Importer un CSV';

  @override
  String get exportRegistryCsv => 'Exporter en CSV';

  @override
  String get registryCsvExportSubject => 'Données du registre RadRecon (CSV)';

  @override
  String get duplicatePolicyTitle =>
      'Si un enregistrement correspondant existe';

  @override
  String get duplicateReplace => 'Remplacer l\'enregistrement existant';

  @override
  String get duplicateSkip => 'Ignorer l\'enregistrement correspondant';

  @override
  String get duplicateKeep => 'Importer comme doublon';

  @override
  String registryImportSummary(int imported, int replaced, int skipped) {
    return 'Importés : $imported, remplacés : $replaced, ignorés : $skipped';
  }

  @override
  String get modbusTestConnectionButton => 'Tester la connexion';

  @override
  String get modbusTestingLabel => 'Test en cours...';

  @override
  String get modbusTestSuccessTitle => 'Connexion réussie';

  @override
  String get modbusTestFailureTitle => 'Échec de la connexion';

  @override
  String modbusTestValue(String value) {
    return 'Valeur : $value';
  }

  @override
  String modbusTestPosition(String lat, String lon) {
    return 'Lat : $lat, Lon : $lon';
  }

  @override
  String missingFieldMessage(String field) {
    return 'Veuillez renseigner : $field';
  }

  @override
  String get errorTitle => 'Erreur';

  @override
  String modbusReadErrorWithCode(String code) {
    return 'Erreur Modbus pendant la lecture : $code';
  }

  @override
  String get instrumentDidNotSendValidValue =>
      'L\'instrument n\'a pas envoyé de valeur valide.';

  @override
  String get gpsPositionReadFailed =>
      'Impossible de lire la position GPS depuis l\'instrument.';

  @override
  String get instrumentIPAddressNotSet =>
      'Adresse IP de l\'instrument non définie.';

  @override
  String get modbusUnitIdNotSet => 'ID d\'unité Modbus non défini.';

  @override
  String get registerAddressNotSet => 'Adresse du registre non définie.';

  @override
  String get failedToConnectToInstrument =>
      'Impossible de se connecter à l\'instrument.';

  @override
  String connectionErrorWithDetails(String error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get modbusAccessIncomplete =>
      'Les paramètres d\'accès Modbus de l\'instrument sont incomplets (IP, ID d\'unité, adresse du registre).';

  @override
  String get noDisplayableContentForScreenshot =>
      'Aucun contenu affichable pour la capture.';

  @override
  String get failedToConvertScreenshotToPng =>
      'Impossible de convertir la capture en PNG.';

  @override
  String get doseSourceOnline => 'En ligne (depuis le détecteur)';

  @override
  String get doseSourceManual => 'Manuelle';

  @override
  String get doseSourcePassive => 'Dosimétrie passive';

  @override
  String annualDoseLabel(int year) {
    return 'Dose en $year';
  }

  @override
  String get doseYearLabel => 'Année';

  @override
  String doseBreakdownLabel(String online, String manual, String passive) {
    return 'en ligne $online · manuelle $manual · passive $passive';
  }

  @override
  String personDosesTitle(String name) {
    return 'Doses – $name';
  }

  @override
  String get personDosesTooltip => 'Gérer les doses';

  @override
  String get noDosesYet => 'Aucune dose enregistrée pour cette année.';

  @override
  String get addPassiveDoseButton => 'Ajouter une dosimétrie passive';

  @override
  String get newPassiveDoseTitle => 'Nouvelle dosimétrie passive';

  @override
  String get editDoseTitle => 'Modifier la dose';

  @override
  String get doseValueLabel => 'Dose';

  @override
  String get dosePeriodStartLabel => 'Début de la période d\'évaluation';

  @override
  String get dosePeriodEndLabel => 'Fin de la période d\'évaluation';

  @override
  String get dosePeriodEndBeforeStartError =>
      'La fin ne peut pas précéder le début.';

  @override
  String get doseTotalLabel => 'Total';

  @override
  String get doseDeleteConfirmTitle => 'Supprimer l\'enregistrement de dose';

  @override
  String get doseDeleteConfirmMessage =>
      'Supprimer cet enregistrement de dose ? Cette action est irréversible.';

  @override
  String sessionDoseDialogTitle(String name) {
    return 'Dose de $name';
  }

  @override
  String get onlineDoseLabel => 'Dose en ligne';

  @override
  String get manualDoseLabel => 'Dose manuelle';

  @override
  String get closeSurveyDosesTitle => 'Vérifier les doses';

  @override
  String get closeSurveyDosesHint =>
      'Avant de clôturer, vérifiez ou corrigez la dose de chaque participant.';

  @override
  String autoLogDoseSaved(int count, String dose) {
    return 'Dose enregistrée pour $count personne(s) : $dose';
  }

  @override
  String autoLogDoseNoPersons(String dose) {
    return 'La dose mesurée ($dose) n\'a pas été enregistrée car aucune personne n\'est affectée à cette campagne.';
  }

  @override
  String autoLogDoseLabel(String dose) {
    return 'Dose intégrée : $dose';
  }

  @override
  String autoLogDoseGaps(int count) {
    return '$count trou(s) de données plus long(s) pendant la mesure';
  }

  @override
  String get autoLogDoseOnlyDoseRate =>
      'La dose ne peut être calculée et enregistrée qu\'à partir de mesures de débit de dose.';

  @override
  String get importPersonDosesCsv => 'Importer les doses (CSV)';

  @override
  String get exportPersonDosesCsv => 'Exporter les doses (CSV)';

  @override
  String get dataManagementSectionTitle => 'Gestion des données';

  @override
  String get saveDatabaseButton =>
      'Enregistrer la base de données dans un fichier';

  @override
  String get loadDatabaseButton =>
      'Charger la base de données depuis un fichier';

  @override
  String get clearDatabaseButton => 'Effacer la base de données';

  @override
  String get companySwitchButton => 'Changer d\'entreprise';

  @override
  String get dataManagementHint =>
      'Le fichier de sauvegarde contient toutes les données, photos comprises ; il permet de passer à un nouveau téléphone ou de séparer les données de plusieurs entreprises.';

  @override
  String get saveDatabaseSubject => 'Sauvegarde de la base de données RadRecon';

  @override
  String databaseSavedMessage(String path) {
    return 'Base de données enregistrée : $path';
  }

  @override
  String get loadDatabaseConfirmTitle => 'Charger la base de données';

  @override
  String get loadDatabaseConfirmBody =>
      'Le chargement écrase toutes les données actuellement présentes sur cet appareil. Sauvegardez-les d\'abord si vous en avez encore besoin. Continuer ?';

  @override
  String get loadButton => 'Charger';

  @override
  String databaseLoadedMessage(String name) {
    return 'Chargé : $name';
  }

  @override
  String get clearDatabaseConfirmTitle => 'Effacer la base de données';

  @override
  String get clearDatabaseConfirmBody =>
      'Toutes les campagnes, tous les points de mesure, instruments, sources, personnes et photos seront définitivement supprimés de cet appareil. Cette action est irréversible : faites d\'abord une sauvegarde !';

  @override
  String get databaseClearedMessage => 'Base de données effacée.';

  @override
  String get companySwitchTitle => 'Changer d\'entreprise';

  @override
  String get activeCompanyLabel => 'Entreprise active';

  @override
  String get companiesFolderLabel => 'Dossier des entreprises';

  @override
  String get chooseFolderButton => 'Choisir un dossier';

  @override
  String get resetFolderButton => 'Revenir au dossier par défaut';

  @override
  String get noCompaniesYet =>
      'Aucune entreprise enregistrée dans ce dossier pour l\'instant. L\'entreprise active est enregistrée automatiquement au premier changement, ou créez-en une nouvelle / ajoutez un fichier de sauvegarde avec les boutons ci-dessus.';

  @override
  String companyBackupInfo(String date) {
    return 'Enregistré : $date';
  }

  @override
  String get newCompanyButton => 'Nouvelle entreprise';

  @override
  String get newCompanyDialogTitle => 'Créer une nouvelle entreprise';

  @override
  String get companyNameLabel => 'Nom de l\'entreprise';

  @override
  String get companyNameExistsMessage =>
      'Une entreprise portant ce nom existe déjà.';

  @override
  String get createButton => 'Créer';

  @override
  String get addCompanyFromFileButton =>
      'Ajouter une entreprise depuis un fichier de sauvegarde';

  @override
  String get companySwitchConfirmTitle => 'Changer d\'entreprise';

  @override
  String companySwitchConfirmBody(String company, String active) {
    return 'Passer à $company ? Les données actuelles sont enregistrées automatiquement sous $active.';
  }

  @override
  String get companySwitchAction => 'Changer';

  @override
  String companySwitchedMessage(String name) {
    return 'Entreprise active : $name';
  }

  @override
  String get deleteCompanyBackupTitle => 'Supprimer la sauvegarde';

  @override
  String deleteCompanyBackupBody(String name) {
    return 'Supprimer du dossier la sauvegarde de $name ? Les données actuellement chargées ne sont pas affectées.';
  }

  @override
  String get importPersonCsv => 'Importer les personnes (CSV)';

  @override
  String get exportPersonCsv => 'Exporter les personnes (CSV)';

  @override
  String get privateFolderHint =>
      'L\'app utilise actuellement son propre dossier privé, inaccessible aux autres apps. Choisissez un dossier (p. ex. Téléchargements ou Google Drive) pour accéder aux sauvegardes depuis votre gestionnaire de fichiers.';

  @override
  String get contributorsTitle => 'Contributeurs';

  @override
  String get contributorsThanks =>
      'Merci à toutes les personnes qui aident à tester, développer, traduire et relire RadRecon. RadRecon est une initiative citoyenne à but non lucratif réalisée par des bénévoles.';

  @override
  String get contributorsOrganizationsTitle => 'Organisations et entreprises';

  @override
  String get contributorsPeopleTitle => 'Personnes';

  @override
  String get contributorsEmpty =>
      'La liste est encore vide. Soyez le premier !';

  @override
  String get contributorsLoadError => 'Impossible de charger la liste.';

  @override
  String get contributorsJoinHint =>
      'Vous souhaitez figurer dans la liste ? Inscrivez-vous comme bénévole et indiquez-nous comment vous voulez apparaître :';

  @override
  String get contributorsCopyLink => 'Copier le lien';

  @override
  String get contributorsLinkCopied => 'Lien copié.';

  @override
  String get contributorRoleTesting => 'Tests';

  @override
  String get contributorRoleDevelopment => 'Développement';

  @override
  String get contributorRoleReview => 'Relecture experte';

  @override
  String get contributorRoleTranslation => 'Traduction';

  @override
  String get contributorRoleOther => 'Autre';

  @override
  String get regulatoryProfileLabel => 'Profil réglementaire';

  @override
  String get regulatoryProfileInternational => 'International (AIEA)';

  @override
  String get regulatoryProfileHungary => 'Hongrie (OAH)';

  @override
  String get classificationTitle => 'Classement (D, R, exemption)';

  @override
  String get classificationDisclaimer =>
      'Calcul indicatif à partir des tables de nucléides et de l\'activité actuelle (corrigée de la décroissance). Le classement officiel est déterminé par la loi applicable et l\'autorité. La classe de laboratoire selon MSZ 62-7 est une valeur indicative dérivée de l\'activité.';

  @override
  String get classificationUnsealedWork =>
      'Travail régulier avec des sources non scellées';

  @override
  String get classificationOutsideWorkplace =>
      'Utilisation en dehors du lieu de travail sous rayonnements';

  @override
  String get classificationTotal => 'Total (sources sélectionnées)';

  @override
  String get classificationPhysCat => 'Catégorie de protection physique';

  @override
  String get classificationProtCat => 'Catégorie de radioprotection';

  @override
  String get classificationUnknownCount => 'Sources sans R (nucléide inconnu)';

  @override
  String get classificationActivity => 'Activité';

  @override
  String get classificationNotDecayCorrected =>
      'non corrigée de la décroissance';

  @override
  String get classificationDInfinite => 'D = ∞ (ne contribue pas à R)';

  @override
  String get classificationDUnknown =>
      'Pas de valeur D pour ce nucléide, R ne peut pas être calculé';

  @override
  String get classificationExemptUnknown =>
      'Pas de valeurs d\'exemption pour ce nucléide';

  @override
  String get classificationExemptActivity => 'Activité exemptée';

  @override
  String get classificationSpecificConc =>
      'Concentration d\'exemption spécifique';

  @override
  String get classificationGeneralConc => 'générale';

  @override
  String get classificationBelowExempt =>
      'L\'activité est inférieure ou égale à l\'activité exemptée';

  @override
  String get classificationAboveExempt =>
      'L\'activité dépasse l\'activité exemptée';

  @override
  String get classificationProtLevel => 'Niveau de protection physique';

  @override
  String get classificationAdrConsignmentLimit => 'limite du colis exempté';

  @override
  String get classificationAdrBelow =>
      'l\'activité est inférieure (pas de Classe 7)';

  @override
  String get classificationAdrAbove =>
      'l\'activité est supérieure (la concentration compte aussi)';

  @override
  String get classificationLabIndustrial => 'Laboratoire industriel';

  @override
  String get classificationLabMedical => 'Laboratoire médical';

  @override
  String get classificationLabAboveIII => '> III';

  @override
  String get classificationLabOps => 'Types d\'opérations autorisés';

  @override
  String get classificationLabUnknown =>
      'MSZ 62-7 : pas de valeur AM pour ce nucléide';

  @override
  String get autoLogChartTitle => 'Valeur mesurée dans le temps';

  @override
  String get gpsAverageButton => 'GPS moyenné';

  @override
  String get gpsAverageTitle => 'Moyennage de la position';

  @override
  String get gpsAverageHint =>
      'Restez immobile au même endroit pendant la mesure. Un temps de moyennage plus long donne un résultat plus fiable ; le ciel dégagé est idéal. Les échantillons sont pondérés selon leur précision et les positions aberrantes sont écartées.';

  @override
  String get gpsAverageStart => 'Démarrer';

  @override
  String get gpsAverageUse => 'Utiliser';

  @override
  String get gpsAverageSamples => 'Échantillons';

  @override
  String get gpsAverageCurrent => 'Précision actuelle';

  @override
  String get gpsAverageResult => 'Précision estimée de la moyenne';

  @override
  String get modbusAverageButton => 'Mesure moyennée';

  @override
  String get modbusAverageRunning => 'Moyennage en cours';

  @override
  String get modbusAverageDone => 'Terminé';

  @override
  String get modbusAverageTooFew =>
      'Il faut au moins 2 échantillons valides pour calculer l\'erreur ; seule la valeur a été saisie.';

  @override
  String get measurementErrorLabel => 'Erreur (±)';

  @override
  String get measurementErrorHelper =>
      'Pour une mesure moyennée, c\'est l\'erreur standard de la moyenne (1σ) ; elle peut aussi être saisie à la main pour des valeurs saisies manuellement. Elle figure dans le protocole.';

  @override
  String get measurementAveragedLabel => 'Mesure moyennée';

  @override
  String get csvHeaderValueError => 'Erreur (±)';

  @override
  String get csvHeaderAveraging => 'Moyennage (échantillons ; s)';

  @override
  String get helpManualTitle => 'Aide (manuel d\'utilisation)';

  @override
  String get helpManualOpenError => 'Impossible d\'ouvrir le manuel.';

  @override
  String get appVersionLabel => 'Version';
}
