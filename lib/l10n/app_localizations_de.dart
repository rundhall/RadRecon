// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'RadRecon';

  @override
  String get instrumentsTooltip => 'Messgeräte';

  @override
  String get searchHint => 'Suchen';

  @override
  String get searchNoResults => 'Keine passenden Ergebnisse';

  @override
  String get alertThresholdsTooltip => 'Alarmschwellen';

  @override
  String get noSurveysYet =>
      'Noch keine Begehungen. Mit der Schaltfläche + starten.';

  @override
  String get newSurveyButton => 'Neue Begehung';

  @override
  String get newSurveyDialogTitle => 'Neue Begehung';

  @override
  String get surveyNameLabel => 'Name';

  @override
  String get surveyLocationLabel => 'Ort (optional)';

  @override
  String get editSurveyDetailsTooltip => 'Name und Ort bearbeiten';

  @override
  String get editSurveyDetailsTitle => 'Begehungsdaten bearbeiten';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get startButton => 'Start';

  @override
  String surveyDefaultTitle(String date) {
    return 'Begehung – $date';
  }

  @override
  String get noLocationPlaceholder => '—';

  @override
  String get doseUnitSectionTitle => 'Standardeinheit der Dosisleistung';

  @override
  String get doseUnitSectionHint =>
      'Diese Einheiten sind für neue Messungen vorausgewählt. Bei der Erfassung kann aus einer Liste eine andere gewählt werden, ohne Tippen; die eingegebene Zahl wird beim Wechsel der Einheit automatisch umgerechnet. Auch die Alarmschwelle der Dosisleistung wird umgerechnet.';

  @override
  String get unitsSectionTitle => 'Einheiten';

  @override
  String get activityUnitLabel => 'Standardeinheit der Aktivität';

  @override
  String get distanceUnitLabel => 'Standardeinheit der Entfernung';

  @override
  String get activityPlainLabel => 'Aktivität';

  @override
  String get measuredDoseRatePlainLabel => 'Gemessene Dosisleistung';

  @override
  String get distanceFromSourcePlainLabel => 'Entfernung von der Quelle';

  @override
  String get sourceDistancePlainLabel => 'Entfernung vom Messpunkt';

  @override
  String get activityAtManufacturePlainLabel => 'Aktivität bei der Herstellung';

  @override
  String get invalidDistancePlainError =>
      'Eine gültige, positive Entfernung eingeben.';

  @override
  String get invalidActivityPlainError => 'Eine gültige Aktivität eingeben.';

  @override
  String get invalidDoseRatePlainError =>
      'Eine gültige Dosisleistung eingeben.';

  @override
  String get distanceFromSourceShortLabel => 'Entfernung von der Quelle';

  @override
  String get calculatedActivityResultLabel => 'Berechnete Aktivität';

  @override
  String get distanceIntervalPlainLabel => 'Entfernungsintervall';

  @override
  String get modbusQuantityLabel => 'Was das Register liefert';

  @override
  String get modbusRegisterUnitLabel => 'Einheit des Registers';

  @override
  String get modbusQuantityHelper =>
      'Bei der Erfassung rechnet die App den Wert in die in den Einstellungen gewählte Standardeinheit um.';

  @override
  String get autoLogTypeFromInstrument =>
      'Die automatische Aufzeichnung erfasst die für das Messgerät eingestellte Größe.';

  @override
  String get nuclideIdSectionTitle => 'Nuklididentifikation';

  @override
  String get nuclideStatusNone => 'Nicht angegeben';

  @override
  String get nuclideStatusIdentified => 'Identifizierte(s) Nuklid(e)';

  @override
  String get nuclideStatusUnknown => 'Unbekannt';

  @override
  String get nuclideStatusOther => 'Anderes (nicht in der Liste)';

  @override
  String get nuclideStatusMixture => 'Vermutlich mehrere Quellen (Gemisch)';

  @override
  String get nuclideKnownListLabel => 'Nuklide aus der Liste';

  @override
  String get nuclideCustomLabel => 'Name eines anderen Nuklids';

  @override
  String get nuclideAddButton => 'Hinzufügen';

  @override
  String get nuclideRequiredError =>
      'Mindestens ein Nuklid eingeben oder „Unbekannt“ wählen.';

  @override
  String get csvHeaderNuclides => 'Nuklididentifikation';

  @override
  String get nuclideDoneButton => 'Fertig';

  @override
  String get unshieldedActivityLabel => 'Aktivität (ohne Abschirmung)';

  @override
  String get shieldingSectionTitle => 'Abschirmung (optional)';

  @override
  String get shieldingHint =>
      'Befindet sich die Quelle hinter einer Abschirmung, Material und Dicke eingeben – die App schätzt dann auch die tatsächliche Aktivität der abgeschirmten Quelle.';

  @override
  String get shieldingMaterialLabel => 'Abschirmmaterial';

  @override
  String get shieldingNoneOption => 'Keine Abschirmung';

  @override
  String get shieldingThicknessLabel => 'Dicke der Abschirmung';

  @override
  String get shieldingThicknessError => 'Eine positive Dicke eingeben';

  @override
  String get shieldedActivityLabel =>
      'Geschätzte Aktivität der abgeschirmten Quelle';

  @override
  String get shieldingDisclaimer =>
      'Näherungsschätzung: Die Abschwächung wird mit Halbwertsschichten modelliert (jede Halbwertsschicht halbiert die Dosisleistung) und verwendet Richtwerte. Streustrahlung (Aufbaufaktor), Quellengeometrie und Spektrum sind vereinfacht, daher überschätzt das Ergebnis die Aktivität tendenziell. Für amtliche Protokolle anhand einer maßgeblichen Quelle prüfen.';

  @override
  String get shieldingMaterialLead => 'Blei';

  @override
  String get shieldingMaterialSteel => 'Stahl (Eisen)';

  @override
  String get shieldingMaterialConcrete => 'Beton';

  @override
  String get shieldingMaterialTungsten => 'Wolfram';

  @override
  String get shieldingMaterialAluminium => 'Aluminium';

  @override
  String get shieldingMaterialWater => 'Wasser';

  @override
  String get csvUnshieldedNote => 'ohne Abschirmung';

  @override
  String get csvShieldedSourceNote => 'abgeschirmte Quelle';

  @override
  String get shieldingAddLayer => 'Schicht hinzufügen';

  @override
  String get shieldingLayerLabel => 'Schicht';

  @override
  String get shieldingRemoveLayer => 'Schicht entfernen';

  @override
  String get doseRateUnshieldedLabel => 'Dosisleistung (ohne Abschirmung)';

  @override
  String get doseRateShieldedLabel => 'Dosisleistung hinter der Abschirmung';

  @override
  String get calibrationSectionTitle => 'Prüfung und Kalibrierung';

  @override
  String get calibrationKindVerification => 'Prüfung';

  @override
  String get calibrationKindCalibration => 'Kalibrierung';

  @override
  String get calibrationAddButton => 'Eintrag hinzufügen';

  @override
  String get calibrationDialogTitle => 'Prüf-/Kalibriereintrag';

  @override
  String get calibrationKindLabel => 'Typ';

  @override
  String get calibrationPerformedOnLabel => 'Durchführungsdatum';

  @override
  String get calibrationValidUntilLabel => 'Gültig bis';

  @override
  String get calibrationCertificateLabel => 'Zertifikatsnummer';

  @override
  String get calibrationPerformedByLabel =>
      'Durchgeführt von (Labor / Behörde)';

  @override
  String get calibrationAttachFile => 'Zertifikat anhängen';

  @override
  String get calibrationRemoveFile => 'Anhang entfernen';

  @override
  String get calibrationOpenFile => 'Zertifikat öffnen / teilen';

  @override
  String get calibrationEmptyList => 'Noch keine Einträge.';

  @override
  String get calibrationStatusValid => 'Gültig';

  @override
  String get calibrationStatusSoon => 'Läuft bald ab';

  @override
  String get calibrationStatusExpired => 'ABGELAUFEN';

  @override
  String get calibrationStatusUnknown => 'Keine Daten';

  @override
  String get calibrationExpiredWarning =>
      'Achtung: Die Prüfung/Kalibrierung des gewählten Messgeräts ist abgelaufen. Gültig bis:';

  @override
  String get calibrationSoonWarning =>
      'Achtung: Die Prüfung/Kalibrierung des gewählten Messgeräts läuft bald ab. Gültig bis:';

  @override
  String get calibrationUnknownWarning =>
      'Für das gewählte Messgerät liegen keine Prüf-/Kalibrierdaten vor.';

  @override
  String get calibrationSaveAnywayTitle => 'Abgelaufene Prüfung/Kalibrierung';

  @override
  String get calibrationSaveAnywayBody =>
      'Die Messung wurde mit einem Messgerät durchgeführt, dessen Prüfung/Kalibrierung abgelaufen ist; das Protokoll kennzeichnet dies. Trotzdem speichern?';

  @override
  String get calibrationSaveAnywayConfirm => 'Trotzdem speichern';

  @override
  String get calibrationValidUntilBeforeError =>
      'Die Gültigkeit darf nicht vor dem Durchführungsdatum liegen';

  @override
  String get csvHeaderInstrumentCalibration =>
      'Prüfung/Kalibrierung des Messgeräts';

  @override
  String get personPhoneLabel => 'Telefonnummer';

  @override
  String get personEmailLabel => 'E-Mail-Adresse';

  @override
  String get personAddEmail => 'E-Mail-Adresse hinzufügen';

  @override
  String get personRemoveEmail => 'E-Mail entfernen';

  @override
  String get personEmailInvalidError => 'Ungültige E-Mail-Adresse';

  @override
  String get personCertificatesTitle => 'Zertifikate';

  @override
  String get personCertificateAdd => 'Zertifikat hinzufügen';

  @override
  String get personCertificateDialogTitle => 'Zertifikat';

  @override
  String get personCertificateNameLabel =>
      'Bezeichnung (z. B. Strahlenschutzprüfung)';

  @override
  String get personCertificateNumberLabel => 'Zertifikatsnummer';

  @override
  String get personCertificateIssuerLabel => 'Aussteller';

  @override
  String get personCertificateIssuedLabel => 'Ausstellungsdatum';

  @override
  String get personCertificateNameRequired =>
      'Die Bezeichnung des Zertifikats eingeben';

  @override
  String get personCertificateValidBeforeError =>
      'Die Gültigkeit darf nicht vor dem Ausstellungsdatum liegen';

  @override
  String get personCertificatesEmpty => 'Noch keine Zertifikate.';

  @override
  String get sourceCertificateTitle => 'Quellenzertifikat';

  @override
  String get sourceCertificateAttach => 'Zertifikat anhängen';

  @override
  String get sourceCertificateEmpty => 'Kein Zertifikat angehängt.';

  @override
  String get companyDocumentsTooltip => 'Firmendokumente und Genehmigungen';

  @override
  String get companyDocumentNew => 'Neues Dokument';

  @override
  String get companyDocumentEdit => 'Dokument bearbeiten';

  @override
  String get companyDocumentTitleLabel => 'Name des Dokuments';

  @override
  String get companyDocumentIdentifierLabel =>
      'Kennung (Aktenzeichen / Genehmigungsnummer)';

  @override
  String get companyDocumentIssuerLabel => 'Aussteller / Behörde';

  @override
  String get companyDocumentIssuedLabel => 'Ausstellungs-/Inkrafttretensdatum';

  @override
  String get companyDocumentValidUntilLabel =>
      'Gültig / Überprüfung fällig bis';

  @override
  String get companyDocumentFilesTitle => 'Angehängte Dateien';

  @override
  String get companyDocumentAttach => 'Datei anhängen';

  @override
  String get companyDocumentsEmpty => 'Noch keine Dokumente.';

  @override
  String get companyDocumentDeleteTitle => 'Dokument löschen';

  @override
  String get companyDocumentDeleteConfirm => 'Dieses Dokument löschen?';

  @override
  String get companyDocSuggestionsLabel => 'Häufige Dokumente';

  @override
  String get companyDocSuggestRadiationPolicy =>
      'Strahlenschutzordnung des Arbeitsplatzes';

  @override
  String get companyDocSuggestRadiationDescription =>
      'Strahlenschutzbeschreibung';

  @override
  String get companyDocSuggestPhysicalProtection =>
      'Plan für den physischen Schutz';

  @override
  String get companyDocSuggestEmergencyPlan => 'Notfallplan';

  @override
  String get nuclideEditButton => 'Nuklide bearbeiten';

  @override
  String get languageSectionTitle => 'Sprache';

  @override
  String get languageSystemOption => 'Sprache des Telefons';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get appearanceSectionTitle => 'Darstellung';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get alertThresholdExplanation =>
      'Erreicht oder überschreitet eine erfasste Messung die hier eingestellte Schwelle, warnt die App (Ton + Pop-up). Leer lassen für keinen Alarm bei diesem Typ.';

  @override
  String get noThresholdSetHint => 'Keine Schwelle festgelegt';

  @override
  String get saveButton => 'Speichern';

  @override
  String get settingsSavedMessage => 'Einstellungen gespeichert.';

  @override
  String get measurementTypeDoseRate => 'Dosisleistung';

  @override
  String get measurementTypeSurfaceContamination => 'Oberflächenkontamination';

  @override
  String get measurementTypeCps => 'Zählrate (cps)';

  @override
  String get measurementTypeNeutronCps => 'Neutronenzählrate (cps)';

  @override
  String get measurementTypeSample => 'Probenahme';

  @override
  String get instrumentDeleteTitle => 'Messgerät löschen';

  @override
  String instrumentDeleteConfirm(String name) {
    return '„$name“ löschen? Frühere Messungen, die damit verknüpft sind, bleiben erhalten – nur der Verweis auf das Messgerät wird entfernt.';
  }

  @override
  String get deleteButton => 'Löschen';

  @override
  String get noInstrumentsYet =>
      'Noch keine Messgeräte. Mit der Schaltfläche + hinzufügen.';

  @override
  String get noCalibrationData => 'Keine Kalibrierdaten';

  @override
  String nextCalibrationOn(String date) {
    return 'Nächste Kalibrierung: $date';
  }

  @override
  String get noSerialNumber => 'keine Seriennummer';

  @override
  String get newInstrumentButton => 'Neues Messgerät';

  @override
  String get editInstrumentTitle => 'Messgerät bearbeiten';

  @override
  String get instrumentNameLabel => 'Name / Typ des Messgeräts';

  @override
  String get requiredFieldError => 'Pflichtfeld';

  @override
  String get serialNumberLabel => 'Seriennummer';

  @override
  String get nextCalibrationLabel => 'Datum der nächsten Kalibrierung';

  @override
  String get notSetLabel => 'Nicht festgelegt';

  @override
  String get calibrationFactorLabel => 'Kalibrierfaktor';

  @override
  String get modbusConnectedLabel => 'Über WLAN per Modbus/TCP erreichbar';

  @override
  String get modbusHostLabel => 'IP-Adresse / Host';

  @override
  String get modbusPortLabel => 'Port (z. B. 502)';

  @override
  String get modbusUnitIdLabel => 'Modbus-Unit-ID (Slave-Adresse)';

  @override
  String get modbusRegisterAddressLabel => 'Registeradresse (z. B. 294)';

  @override
  String get modbusRegisterAddressHelper =>
      'Start-Holding-Register des Messwerts (float32)';

  @override
  String get modbusGpsEnabledLabel => 'GPS-Position über Modbus lesen';

  @override
  String get modbusGpsLatAddressLabel =>
      'Breitengrad-Register (float32, Standard 426)';

  @override
  String get modbusGpsLonAddressLabel =>
      'Längengrad-Register (float32, Standard 428)';

  @override
  String get pickPositionTitle => 'Position wählen';

  @override
  String get confirmPositionButton => 'Position bestätigen';

  @override
  String get isotopeCalculatorTitle => 'Isotopenrechner';

  @override
  String get gammaConstantsDisclaimer =>
      'Die Γ-Konstanten dienen nur als Orientierung. Für ein amtliches Protokoll vor der Dokumentation des Ergebnisses anhand einer maßgeblichen Quelle prüfen.';

  @override
  String get isotopeLabel => 'Isotop';

  @override
  String get modeDoseFromActivity => 'Aktivität zu\nDosisleistung';

  @override
  String get modeActivityFromDose => 'Dosisleistung zu\nAktivität';

  @override
  String get distanceFromSourceLabel => 'Entfernung von der Quelle (m)';

  @override
  String get activityLabel => 'Aktivität (MBq)';

  @override
  String get measuredDoseRateLabel => 'Gemessene Dosisleistung (µSv/h)';

  @override
  String get calculateButton => 'Berechnen';

  @override
  String get invalidDistanceError =>
      'Eine gültige, positive Entfernung (m) eingeben.';

  @override
  String get invalidActivityError => 'Eine gültige Aktivität (MBq) eingeben.';

  @override
  String get invalidDoseRateError =>
      'Eine gültige Dosisleistung (µSv/h) eingeben.';

  @override
  String calculationErrorMessage(String error) {
    return 'Berechnungsfehler: $error';
  }

  @override
  String calculatedDoseRateResult(String uSvH, String nSvH) {
    return 'Berechnete Dosisleistung: $uSvH µSv/h\n($nSvH nSv/h)';
  }

  @override
  String calculatedActivityResult(String mbq, String gbq) {
    return 'Berechnete Aktivität: $mbq MBq\n($gbq GBq)';
  }

  @override
  String get distanceToolTitle => 'Entfernungsmessung';

  @override
  String get locationServiceDisabledError =>
      'Die Ortungsdienste sind ausgeschaltet.';

  @override
  String get locationPermissionDeniedError =>
      'Standortberechtigung verweigert.';

  @override
  String gpsErrorMessage(String error) {
    return 'GPS-Fehler: $error';
  }

  @override
  String get selectTargetFirstError => 'Zuerst den Zielpunkt wählen.';

  @override
  String get noGpsPositionError =>
      'Keine GPS-Position. Aktualisieren oder einen Startpunkt wählen.';

  @override
  String get selectStartPointError => 'Einen Startpunkt wählen.';

  @override
  String get selectTargetPointError => 'Den Zielpunkt wählen.';

  @override
  String get startFromCurrentPositionLabel => 'Start: meine aktuelle Position';

  @override
  String get noPositionFetchedYet => 'Noch nicht abgerufen';

  @override
  String get refreshGpsButton => 'GPS aktualisieren';

  @override
  String get startPointLabel => 'Startpunkt';

  @override
  String get targetPointLabel => 'Zielpunkt';

  @override
  String get liveTrackingLabel => 'Live-Verfolgung';

  @override
  String get liveTrackingSubtitle =>
      'Aktualisiert Entfernung und Peilung laufend beim Gehen.';

  @override
  String get calculateDistanceButton => 'Berechnen';

  @override
  String get liveTrackingRunningHint =>
      'Live-Verfolgung läuft – in Pfeilrichtung gehen.';

  @override
  String get sourceSearchTitle => 'Quellensuche';

  @override
  String get measurementTypeLabel => 'Messtyp';

  @override
  String pointsRecordedForType(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Punkte erfasst',
      one: '$count Punkt erfasst',
    );
    return '$_temp0 für diesen Typ in dieser Begehung.';
  }

  @override
  String get lowConfidenceWarning =>
      'Wenige Punkte (< 4) – die Schätzung ist unzuverlässig; weitere Messungen an verschiedenen Stellen im Suchgebiet durchführen.';

  @override
  String gradientEstimateLabel(String value, String unit) {
    return 'Geschätzter Gradient: $value $unit/m';
  }

  @override
  String get directionEstimateHint =>
      'Der Messwert steigt voraussichtlich in dieser Richtung.';

  @override
  String get sourceSearchDisclaimer =>
      'Die vorgeschlagene Richtung beruht auf einer einfachen linearen Gradientenschätzung aus den bisher in dieser Begehung erfassten Punkten. Bei verrauschten Felddaten, wenigen Punkten oder wenn die tatsächliche Quelle im Verhältnis zur Größe des Messgebiets weit entfernt ist, kann sie ungenau sein. Nur als Orientierung – sie ersetzt nicht die fachliche Beurteilung.';

  @override
  String get newMeasurementButton => 'Neue Messung';

  @override
  String get mapTitle => 'Karte';

  @override
  String get noPointsRecordedYet => 'Noch keine Messpunkte erfasst.';

  @override
  String get saveScreenshotTooltip => 'Screenshot für das Protokoll speichern';

  @override
  String get screenshotSavedMessage =>
      'Karte gespeichert – sie wird beim Export des Protokolls angehängt.';

  @override
  String screenshotErrorMessage(String error) {
    return 'Screenshot-Fehler: $error';
  }

  @override
  String valueLabel(String value, String unit) {
    return 'Wert: $value $unit';
  }

  @override
  String distanceFromSourceValue(String value) {
    return 'Entfernung von der Quelle: $value m';
  }

  @override
  String timestampLabel(String value) {
    return 'Zeit: $value';
  }

  @override
  String get sourcePositionLabel => 'Quellenposition';

  @override
  String get editButton => 'Bearbeiten';

  @override
  String get closeSurveyTitle => 'Begehung abschließen';

  @override
  String get closeSurveyConfirm =>
      'Nach dem Abschluss zeigt das Protokoll das heutige Datum als Endzeit. Die Punkte werden dadurch nicht gesperrt – sie können später noch bearbeitet werden.';

  @override
  String get closeSurveyButton => 'Abschließen';

  @override
  String get surveyClosedMessage => 'Begehung abgeschlossen.';

  @override
  String get listScreenshotSavedMessage =>
      'Listen-Screenshot gespeichert – er wird beim Export des Protokolls angehängt.';

  @override
  String exportErrorMessage(String error) {
    return 'Exportfehler: $error';
  }

  @override
  String importErrorMessage(String error) {
    return 'Importfehler: $error';
  }

  @override
  String protocolShareSubject(String title) {
    return 'Protokoll – $title';
  }

  @override
  String dataExportSubject(String title) {
    return 'Messpunkte (Daten) – $title';
  }

  @override
  String csvExportSubject(String title) {
    return 'Messpunkte (CSV) – $title';
  }

  @override
  String get importDoneTitle => 'Import abgeschlossen';

  @override
  String importedPointsMessage(int points, int instruments, int sources) {
    return '$points Punkte importiert.\n$instruments neue Messgeräte angelegt.\n$sources neue Strahlenquellen angelegt.';
  }

  @override
  String get okButton => 'OK';

  @override
  String get toolsTooltip => 'Werkzeuge';

  @override
  String get autoLogMenuItem => 'Automatische Aufzeichnung';

  @override
  String get captureListScreenshotMenuItem => 'Listen-Screenshot speichern';

  @override
  String get exportProtocolMenuItem => 'Protokoll exportieren';

  @override
  String get exportJsonMenuItem => 'Punkte exportieren (Daten, JSON)';

  @override
  String get exportCsvMenuItem => 'Punkte exportieren (Tabelle, CSV)';

  @override
  String get importJsonMenuItem => 'Punkte importieren (JSON)';

  @override
  String get newPointButton => 'Neuer Punkt';

  @override
  String sampleTakenListLabel(String date) {
    return 'Probenahme · $date';
  }

  @override
  String get unknownModbusError => 'Unbekannter Modbus-Fehler.';

  @override
  String get noValidPositionError => 'Keine gültige Position angegeben.';

  @override
  String get thresholdExceededTitle => 'Alarmschwelle überschritten';

  @override
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  ) {
    return 'Der Messwert ($value $unit) erreicht oder überschreitet die für $type eingestellte Schwelle ($threshold $unit).';
  }

  @override
  String get newPointTitle => 'Neuer Messpunkt';

  @override
  String get editPointTitle => 'Punkt bearbeiten';

  @override
  String get locationLabelFieldLabel => 'Ortsname';

  @override
  String get measuredValueLabel => 'Messwert';

  @override
  String get numberRequiredError => 'Eine Zahl eingeben';

  @override
  String get unitLabel => 'Einheit';

  @override
  String get instrumentLabel => 'Messgerät';

  @override
  String get addInstrumentTooltip => 'Neues Messgerät hinzufügen';

  @override
  String get queryingLabel => 'Abfrage läuft...';

  @override
  String modbusQueryButton(String name) {
    return 'Modbus-Abfrage ($name)';
  }

  @override
  String get sourcePositionSwitchLabel =>
      'Dies ist die Quellenposition (Maximalwert)';

  @override
  String get sampleTakenSwitchLabel =>
      'Hier wurde eine physische Probe genommen';

  @override
  String get sampleContainerLabel => 'Behälter-ID';

  @override
  String get sampleAmountLabel => 'Menge';

  @override
  String get sampleMethodLabel => 'Probenahmeverfahren';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get takePhotoLabel => 'Foto aufnehmen';

  @override
  String get retakePhotoLabel => 'Foto ersetzen';

  @override
  String get chooseFromGalleryLabel => 'Aus der Galerie wählen';

  @override
  String get positionLabel => 'Position';

  @override
  String get latitudeLabel => 'Breitengrad';

  @override
  String get longitudeLabel => 'Längengrad';

  @override
  String get invalidValueError => 'Ungültig';

  @override
  String get liveGpsButton => 'Live-GPS';

  @override
  String get onMapButton => 'Auf der Karte';

  @override
  String get autoLogDisclaimer =>
      'Die Aufzeichnung läuft nur, solange dieser Bildschirm geöffnet ist. Sperrt das Telefon oder wechselt man die App, pausiert die Messung – nach der Rückkehr muss sie neu gestartet werden.';

  @override
  String get noModbusInstrumentMessage =>
      'Es ist kein über Modbus/TCP erreichbares Messgerät eingerichtet. In der Messgeräteliste eines hinzufügen (Schalter WLAN Modbus/TCP an, IP, Unit-ID und Registeradresse ausgefüllt).';

  @override
  String get triggerModeTime => 'Zeitbasiert';

  @override
  String get triggerModeDistance => 'Entfernungsbasiert';

  @override
  String get intervalSecondsLabel => 'Intervall (Sekunden)';

  @override
  String get distanceIntervalLabel => 'Entfernungsintervall (Meter)';

  @override
  String get connectingLabel => 'Verbindung wird hergestellt...';

  @override
  String get stopButton => 'Stopp';

  @override
  String get loggingRunningLabel => 'Aufzeichnung läuft...';

  @override
  String get loggingStoppedLabel => 'Aufzeichnung gestoppt';

  @override
  String capturedPointsLabel(int count) {
    return 'Erfasste Punkte: $count';
  }

  @override
  String lastValueLabel(String value, String unit) {
    return 'Letzter Wert: $value $unit';
  }

  @override
  String failedReadingsLabel(int count) {
    return 'Fehlgeschlagene Messwerte: $count';
  }

  @override
  String lastErrorSuffix(String error) {
    return ' (letzter Fehler: $error)';
  }

  @override
  String get intervalMinError =>
      'Das Intervall muss mindestens 1 Sekunde betragen.';

  @override
  String get distanceMinError =>
      'Die Entfernung muss mindestens 1 Meter betragen.';

  @override
  String modbusConnectErrorMessage(String error) {
    return 'Modbus-Verbindungsfehler: $error';
  }

  @override
  String get csvHeaderSerialNumber => 'Nr.';

  @override
  String get csvHeaderLocation => 'Ort';

  @override
  String get csvHeaderType => 'Typ';

  @override
  String get csvHeaderValue => 'Wert';

  @override
  String get csvHeaderUnit => 'Einheit';

  @override
  String get csvHeaderDistanceFromSource => 'Entfernung von der Quelle';

  @override
  String get csvHeaderInstrument => 'Messgerät';

  @override
  String get csvHeaderGpsLatitude => 'GPS-Breitengrad';

  @override
  String get csvHeaderGpsLongitude => 'GPS-Längengrad';

  @override
  String get csvHeaderGpsAccuracy => 'GPS-Genauigkeit';

  @override
  String get csvHeaderTimestamp => 'Zeitstempel';

  @override
  String get csvHeaderSample => 'Probenahme';

  @override
  String get csvHeaderNotes => 'Notizen';

  @override
  String get csvHeaderEstimatedActivity =>
      'Geschätzte Aktivität (aus der Messung)';

  @override
  String get csvHeaderAttachedSources => 'Zugeordnete Quelle(n)';

  @override
  String get csvHeaderCalculatedDoseRate => 'Berechnete Dosisleistung';

  @override
  String get csvHeaderDoseRateDifference => 'Differenz';

  @override
  String get csvYes => 'ja';

  @override
  String get csvNo => 'nein';

  @override
  String get importUnknownTypeWarning =>
      'Unbekannter Messtyp bei einem Punkt übersprungen.';

  @override
  String get importMissingGpsWarning =>
      'Ein Punkt wurde wegen fehlender GPS-Koordinate übersprungen.';

  @override
  String get manageSourcesLabel => 'Radioaktive Quelle(n) verwalten';

  @override
  String sourcesCountLabel(int count) {
    return '$count Quelle(n)';
  }

  @override
  String get radiationSourcesTitle => 'Quellen';

  @override
  String get newSourceButton => 'Quelle hinzufügen';

  @override
  String get newSourceTitle => 'Neue Quelle';

  @override
  String get editSourceTitle => 'Quelle bearbeiten';

  @override
  String get noSourcesRecordedYet =>
      'Diesem Punkt sind noch keine Quellen zugeordnet.';

  @override
  String get sourcesTooltip => 'Quellen';

  @override
  String get pointSourcesTitle => 'Quelle(n) an diesem Punkt';

  @override
  String get attachSourceButton => 'Quelle zuordnen';

  @override
  String get pickSourceTitle => 'Quelle wählen';

  @override
  String get noSourcesToAttach =>
      'Noch keine Quellen verfügbar – zuerst in der Quellenliste des Hauptbildschirms eine hinzufügen.';

  @override
  String get noSourcesYet =>
      'Noch keine Quellen hinzugefügt. Mit der Schaltfläche + hinzufügen.';

  @override
  String get enterDistanceDialogTitle => 'Entfernung eingeben';

  @override
  String get detachSourceConfirmTitle => 'Quelle lösen';

  @override
  String detachSourceConfirmMessage(String identifier) {
    return 'Quelle „$identifier“ von diesem Punkt lösen? Die Quelle bleibt im Register – nur diese Verknüpfung wird entfernt.';
  }

  @override
  String get detachButton => 'Lösen';

  @override
  String get totalCalculatedDoseRateLabel =>
      'Berechnete Gesamtdosisleistung (alle Quellen)';

  @override
  String sourcesUnknownNuclideSkippedNote(int count) {
    return '$count Quelle(n) haben ein unbekanntes Nuklid und sind in der Summe nicht enthalten.';
  }

  @override
  String get sourceIdentifierLabel => 'Eindeutige Kennung';

  @override
  String get nuclideLabel => 'Nuklid';

  @override
  String get customNuclideOption => 'Anderes (manuelle Eingabe)';

  @override
  String get customNuclideNameLabel => 'Nuklidname';

  @override
  String get activityAtManufactureLabel =>
      'Aktivität bei der Herstellung (MBq)';

  @override
  String get activityErrorPercentLabel => 'Aktivitätsfehler (±%)';

  @override
  String get manufactureDateLabel => 'Herstellungsdatum';

  @override
  String get serviceLifeExpiryDateLabel => 'Ablauf der Nutzungsdauer';

  @override
  String get nextInspectionDateLabel => 'Nächster Prüftermin';

  @override
  String get sourceDistanceLabel => 'Entfernung vom Messpunkt (m)';

  @override
  String get asOfDateLabel => 'Stichtag der Aktivität';

  @override
  String get currentActivityResultLabel => 'Aktuelle Aktivität';

  @override
  String get calculatedDoseRateResultLabel => 'Berechnete Dosisleistung';

  @override
  String get measuredDoseRateResultLabel =>
      'Gemessene Dosisleistung (am Punkt)';

  @override
  String get doseRateDifferenceResultLabel =>
      'Differenz (gemessen − berechnet)';

  @override
  String get unknownNuclideDecayWarning =>
      'Unbekanntes Nuklid: Halbwertszeit und Gammakonstante sind nicht gespeichert, daher können aktuelle Aktivität und berechnete Dosisleistung nicht bestimmt werden. Die Quellendaten können trotzdem gespeichert werden, der Vergleich entfällt.';

  @override
  String get noMeasuredValueForComparisonNote =>
      'Für diesen Punkt ist kein Messwert erfasst – ein Vergleich ist nicht möglich.';

  @override
  String unrecognizedUnitForComparisonNote(String unit) {
    return 'Die Messeinheit ($unit) kann nicht automatisch umgerechnet werden – ein Vergleich ist nicht möglich.';
  }

  @override
  String get sourceExpiredWarning =>
      'Die Nutzungsdauer der Quelle ist abgelaufen.';

  @override
  String get deleteSourceConfirmTitle => 'Quelle löschen';

  @override
  String deleteSourceConfirmMessage(String identifier) {
    return 'Die Quelle „$identifier“ aus dem Register löschen? Sie wird dadurch auch von allen Punkten entfernt, denen sie zugeordnet ist. Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get sourceCalculationDisclaimer =>
      'Die berechneten Werte dienen nur als Orientierung und beruhen auf Standard-Gammakonstanten und Halbwertszeiten. Für amtliche Unterlagen anhand einer maßgeblichen Quelle prüfen.';

  @override
  String get estimatedActivityFromMeasurementLabel =>
      'Geschätzte Aktivität (aus dem Messwert)';

  @override
  String get personsTooltip => 'Personen';

  @override
  String get personsTitle => 'Personen';

  @override
  String get newPersonButton => 'Person hinzufügen';

  @override
  String get newPersonTitle => 'Neue Person';

  @override
  String get editPersonTitle => 'Person bearbeiten';

  @override
  String get noPersonsYet =>
      'Noch keine Personen hinzugefügt. Mit der Schaltfläche + hinzufügen.';

  @override
  String get personNameLabel => 'Name';

  @override
  String get medicalExamExpiryDateLabel => 'Ablauf der ärztlichen Untersuchung';

  @override
  String get trainingExpiryDateLabel => 'Ablauf der Unterweisung';

  @override
  String get deletePersonConfirmTitle => 'Person löschen';

  @override
  String deletePersonConfirmMessage(String name) {
    return '„$name“ aus dem Register löschen? Die Person wird dadurch auch aus allen Begehungen entfernt, denen sie zugeordnet ist. Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get sessionPersonsTitle => 'Personal dieser Begehung';

  @override
  String get noPersonsAttachedYet =>
      'Dieser Begehung sind noch keine Personen zugeordnet.';

  @override
  String get attachPersonButton => 'Person zuordnen';

  @override
  String get pickPersonTitle => 'Person wählen';

  @override
  String get noPersonsToAttach =>
      'Noch keine Person zum Hinzufügen verfügbar – zuerst in der Personenliste des Hauptbildschirms eine anlegen.';

  @override
  String get detachPersonConfirmTitle => 'Person entfernen';

  @override
  String detachPersonConfirmMessage(String name) {
    return '„$name“ aus dieser Begehung entfernen? Die Person bleibt im Register – nur diese Zuordnung wird entfernt.';
  }

  @override
  String get expiryNotificationsSectionTitle => 'Ablaufbenachrichtigungen';

  @override
  String get expiryNotificationsSwitchTitle =>
      'Über Ablaufdaten benachrichtigen';

  @override
  String get expiryNotificationsSwitchSubtitle =>
      'Für bevorstehende Ablaufdaten von Quellen (Nutzungsdauer, Prüfung) und Personen (ärztliche Untersuchung, Unterweisung), gesendet um 8:00 Uhr morgens.';

  @override
  String get expiryLeadTimeLabel => 'Wie weit im Voraus benachrichtigen';

  @override
  String get expiryLeadSameDay => 'Am selben Tag';

  @override
  String get expiryLeadOneDay => '1 Tag vorher';

  @override
  String get expiryLeadTwoDays => '2 Tage vorher';

  @override
  String get expiryLeadOneWeek => '1 Woche vorher';

  @override
  String get expiryNotificationsPermissionDenied =>
      'Benachrichtigungen sind in den Telefoneinstellungen blockiert. Dort Benachrichtigungen für RadRecon erlauben.';

  @override
  String get expiryNotificationTitleToday => 'Läuft heute ab';

  @override
  String get expiryNotificationTitleUpcoming => 'Läuft bald ab';

  @override
  String get expiryNotificationChannelName => 'Ablaufbenachrichtigungen';

  @override
  String get expiryNotificationChannelDescription =>
      'Bevorstehende Ablaufdaten von Quellen und Personen';

  @override
  String get importRegistryCsv => 'CSV importieren';

  @override
  String get exportRegistryCsv => 'CSV exportieren';

  @override
  String get registryCsvExportSubject => 'RadRecon-Registerdaten (CSV)';

  @override
  String get duplicatePolicyTitle => 'Wenn ein passender Datensatz existiert';

  @override
  String get duplicateReplace => 'Vorhandenen Datensatz ersetzen';

  @override
  String get duplicateSkip => 'Passenden Datensatz überspringen';

  @override
  String get duplicateKeep => 'Als Duplikat importieren';

  @override
  String registryImportSummary(int imported, int replaced, int skipped) {
    return 'Importiert: $imported, ersetzt: $replaced, übersprungen: $skipped';
  }

  @override
  String get modbusTestConnectionButton => 'Verbindung testen';

  @override
  String get modbusTestingLabel => 'Test läuft...';

  @override
  String get modbusTestSuccessTitle => 'Verbindung erfolgreich';

  @override
  String get modbusTestFailureTitle => 'Verbindung fehlgeschlagen';

  @override
  String modbusTestValue(String value) {
    return 'Wert: $value';
  }

  @override
  String modbusTestPosition(String lat, String lon) {
    return 'Breite: $lat, Länge: $lon';
  }

  @override
  String missingFieldMessage(String field) {
    return 'Bitte ausfüllen: $field';
  }

  @override
  String get errorTitle => 'Fehler';

  @override
  String modbusReadErrorWithCode(String code) {
    return 'Modbus-Fehler beim Lesen: $code';
  }

  @override
  String get instrumentDidNotSendValidValue =>
      'Das Messgerät hat keinen gültigen Wert gesendet.';

  @override
  String get gpsPositionReadFailed =>
      'Die GPS-Position konnte nicht vom Messgerät gelesen werden.';

  @override
  String get instrumentIPAddressNotSet =>
      'IP-Adresse des Messgeräts nicht festgelegt.';

  @override
  String get modbusUnitIdNotSet => 'Modbus-Unit-ID nicht festgelegt.';

  @override
  String get registerAddressNotSet => 'Registeradresse nicht festgelegt.';

  @override
  String get failedToConnectToInstrument =>
      'Verbindung zum Messgerät fehlgeschlagen.';

  @override
  String connectionErrorWithDetails(String error) {
    return 'Verbindungsfehler: $error';
  }

  @override
  String get modbusAccessIncomplete =>
      'Die Modbus-Zugangsdaten des Messgeräts sind unvollständig (IP, Unit-ID, Registeradresse).';

  @override
  String get noDisplayableContentForScreenshot =>
      'Kein darstellbarer Inhalt für den Screenshot.';

  @override
  String get failedToConvertScreenshotToPng =>
      'Der Screenshot konnte nicht in PNG umgewandelt werden.';

  @override
  String get doseSourceOnline => 'Online (vom Detektor)';

  @override
  String get doseSourceManual => 'Manuell';

  @override
  String get doseSourcePassive => 'Passive Dosimetrie';

  @override
  String annualDoseLabel(int year) {
    return 'Dosis $year';
  }

  @override
  String get doseYearLabel => 'Jahr';

  @override
  String doseBreakdownLabel(String online, String manual, String passive) {
    return 'online $online · manuell $manual · passiv $passive';
  }

  @override
  String personDosesTitle(String name) {
    return 'Dosen – $name';
  }

  @override
  String get personDosesTooltip => 'Dosen verwalten';

  @override
  String get noDosesYet => 'Für dieses Jahr noch keine Dosiseinträge.';

  @override
  String get addPassiveDoseButton => 'Passive Dosimetrie hinzufügen';

  @override
  String get newPassiveDoseTitle => 'Neue passive Dosimetrie';

  @override
  String get editDoseTitle => 'Dosis bearbeiten';

  @override
  String get doseValueLabel => 'Dosis';

  @override
  String get dosePeriodStartLabel => 'Beginn des Auswertezeitraums';

  @override
  String get dosePeriodEndLabel => 'Ende des Auswertezeitraums';

  @override
  String get dosePeriodEndBeforeStartError =>
      'Das Ende darf nicht vor dem Beginn liegen.';

  @override
  String get doseTotalLabel => 'Gesamt';

  @override
  String get doseDeleteConfirmTitle => 'Dosiseintrag löschen';

  @override
  String get doseDeleteConfirmMessage =>
      'Diesen Dosiseintrag löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String sessionDoseDialogTitle(String name) {
    return 'Dosis von $name';
  }

  @override
  String get onlineDoseLabel => 'Online-Dosis';

  @override
  String get manualDoseLabel => 'Manuelle Dosis';

  @override
  String get closeSurveyDosesTitle => 'Dosen prüfen';

  @override
  String get closeSurveyDosesHint =>
      'Vor dem Abschluss die Dosis jedes Teilnehmers prüfen oder korrigieren.';

  @override
  String autoLogDoseSaved(int count, String dose) {
    return 'Dosis für $count Person(en) gespeichert: $dose';
  }

  @override
  String autoLogDoseNoPersons(String dose) {
    return 'Die gemessene Dosis ($dose) wurde nicht gespeichert, da dieser Begehung keine Person zugeordnet ist.';
  }

  @override
  String autoLogDoseLabel(String dose) {
    return 'Integrierte Dosis: $dose';
  }

  @override
  String autoLogDoseGaps(int count) {
    return '$count längere Datenlücke(n) während der Messung';
  }

  @override
  String get autoLogDoseOnlyDoseRate =>
      'Die Dosis kann nur aus Dosisleistungsmessungen berechnet und gespeichert werden.';

  @override
  String get importPersonDosesCsv => 'Dosen importieren (CSV)';

  @override
  String get exportPersonDosesCsv => 'Dosen exportieren (CSV)';

  @override
  String get dataManagementSectionTitle => 'Datenverwaltung';

  @override
  String get saveDatabaseButton => 'Datenbank in Datei speichern';

  @override
  String get loadDatabaseButton => 'Datenbank aus Datei laden';

  @override
  String get clearDatabaseButton => 'Datenbank löschen';

  @override
  String get companySwitchButton => 'Firma wechseln';

  @override
  String get dataManagementHint =>
      'Die Sicherungsdatei enthält alle Daten einschließlich Fotos, sodass man damit auf ein neues Telefon umziehen oder die Daten mehrerer Firmen getrennt halten kann.';

  @override
  String get saveDatabaseSubject => 'RadRecon-Datenbanksicherung';

  @override
  String databaseSavedMessage(String path) {
    return 'Datenbank gespeichert: $path';
  }

  @override
  String get loadDatabaseConfirmTitle => 'Datenbank laden';

  @override
  String get loadDatabaseConfirmBody =>
      'Beim Laden werden alle aktuell auf diesem Gerät vorhandenen Daten überschrieben. Zuerst sichern, falls sie noch gebraucht werden. Fortfahren?';

  @override
  String get loadButton => 'Laden';

  @override
  String databaseLoadedMessage(String name) {
    return 'Geladen: $name';
  }

  @override
  String get clearDatabaseConfirmTitle => 'Datenbank löschen';

  @override
  String get clearDatabaseConfirmBody =>
      'Alle Begehungen, Messpunkte, Messgeräte, Quellen, Personen und Fotos werden dauerhaft von diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden – zuerst eine Sicherung erstellen!';

  @override
  String get databaseClearedMessage => 'Datenbank gelöscht.';

  @override
  String get companySwitchTitle => 'Firma wechseln';

  @override
  String get activeCompanyLabel => 'Aktive Firma';

  @override
  String get companiesFolderLabel => 'Firmenordner';

  @override
  String get chooseFolderButton => 'Ordner wählen';

  @override
  String get resetFolderButton => 'Zurück zum Standardordner';

  @override
  String get noCompaniesYet =>
      'In diesem Ordner sind noch keine Firmen gespeichert. Die aktive Firma wird beim ersten Wechsel automatisch gespeichert, oder mit den Schaltflächen oben eine neue anlegen / eine Sicherungsdatei hinzufügen.';

  @override
  String companyBackupInfo(String date) {
    return 'Gespeichert: $date';
  }

  @override
  String get newCompanyButton => 'Neue Firma';

  @override
  String get newCompanyDialogTitle => 'Neue Firma anlegen';

  @override
  String get companyNameLabel => 'Firmenname';

  @override
  String get companyNameExistsMessage =>
      'Eine Firma mit diesem Namen existiert bereits.';

  @override
  String get createButton => 'Anlegen';

  @override
  String get addCompanyFromFileButton => 'Firma aus Sicherungsdatei hinzufügen';

  @override
  String get companySwitchConfirmTitle => 'Firma wechseln';

  @override
  String companySwitchConfirmBody(String company, String active) {
    return 'Zu $company wechseln? Die aktuellen Daten werden automatisch unter $active gespeichert.';
  }

  @override
  String get companySwitchAction => 'Wechseln';

  @override
  String companySwitchedMessage(String name) {
    return 'Aktive Firma: $name';
  }

  @override
  String get deleteCompanyBackupTitle => 'Sicherung löschen';

  @override
  String deleteCompanyBackupBody(String name) {
    return 'Die Sicherung von $name aus dem Ordner löschen? Die aktuell geladenen Daten sind nicht betroffen.';
  }

  @override
  String get importPersonCsv => 'Personen importieren (CSV)';

  @override
  String get exportPersonCsv => 'Personen exportieren (CSV)';

  @override
  String get privateFolderHint =>
      'Die App verwendet derzeit ihren eigenen privaten Ordner, auf den andere Apps nicht zugreifen können. Einen Ordner (z. B. Downloads oder Google Drive) wählen, um die Sicherungen über den Dateimanager zu erreichen.';

  @override
  String get contributorsTitle => 'Mitwirkende';

  @override
  String get contributorsThanks =>
      'Vielen Dank an alle, die beim Testen, Entwickeln, Übersetzen und Prüfen von RadRecon helfen. RadRecon ist eine gemeinnützige Bürgerinitiative, die von Freiwilligen entwickelt wird.';

  @override
  String get contributorsOrganizationsTitle => 'Organisationen und Unternehmen';

  @override
  String get contributorsPeopleTitle => 'Personen';

  @override
  String get contributorsEmpty => 'Die Liste ist noch leer. Sei der Erste!';

  @override
  String get contributorsLoadError => 'Die Liste konnte nicht geladen werden.';

  @override
  String get contributorsJoinHint =>
      'Du möchtest aufgeführt werden? Melde dich als Freiwilliger an und teile uns mit, wie du erscheinen möchtest:';

  @override
  String get contributorsCopyLink => 'Link kopieren';

  @override
  String get contributorsLinkCopied => 'Link kopiert.';

  @override
  String get contributorRoleTesting => 'Testen';

  @override
  String get contributorRoleDevelopment => 'Entwicklung';

  @override
  String get contributorRoleReview => 'Fachliche Prüfung';

  @override
  String get contributorRoleTranslation => 'Übersetzung';

  @override
  String get contributorRoleOther => 'Sonstiges';

  @override
  String get regulatoryProfileLabel => 'Regulatorisches Profil';

  @override
  String get regulatoryProfileInternational => 'International (IAEA)';

  @override
  String get regulatoryProfileHungary => 'Ungarn (OAH)';

  @override
  String get classificationTitle => 'Einstufung (D, R, Freigrenze)';

  @override
  String get classificationDisclaimer =>
      'Richtwertberechnung aus Nuklidtabellen und der aktuellen (zerfallskorrigierten) Aktivität. Die amtliche Einstufung bestimmen das geltende Recht und die Behörde. Die Laborklasse nach MSZ 62-7 ist ein aus der Aktivität abgeleiteter Richtwert.';

  @override
  String get classificationUnsealedWork =>
      'Regelmäßige Arbeit mit offenen Quellen';

  @override
  String get classificationOutsideWorkplace =>
      'Verwendung außerhalb des Strahlenarbeitsplatzes';

  @override
  String get classificationTotal => 'Summe (gewählte Quellen)';

  @override
  String get classificationPhysCat => 'Kategorie des physischen Schutzes';

  @override
  String get classificationProtCat => 'Strahlenschutzkategorie';

  @override
  String get classificationUnknownCount =>
      'Quellen ohne R (unbekanntes Nuklid)';

  @override
  String get classificationActivity => 'Aktivität';

  @override
  String get classificationNotDecayCorrected => 'nicht zerfallskorrigiert';

  @override
  String get classificationDInfinite => 'D = ∞ (trägt nicht zu R bei)';

  @override
  String get classificationDUnknown =>
      'Kein D-Wert für dieses Nuklid, R kann nicht berechnet werden';

  @override
  String get classificationExemptUnknown =>
      'Keine Freigrenzen für dieses Nuklid';

  @override
  String get classificationExemptActivity => 'Freigestellte Aktivität';

  @override
  String get classificationSpecificConc =>
      'Spezifische Freigrenzenkonzentration';

  @override
  String get classificationGeneralConc => 'allgemein';

  @override
  String get classificationBelowExempt =>
      'Die Aktivität liegt bei oder unter der freigestellten Aktivität';

  @override
  String get classificationAboveExempt =>
      'Die Aktivität liegt über der freigestellten Aktivität';

  @override
  String get classificationProtLevel => 'Stufe des physischen Schutzes';

  @override
  String get classificationAdrConsignmentLimit =>
      'Grenze für freigestellte Versandstücke';

  @override
  String get classificationAdrBelow =>
      'die Aktivität liegt darunter (nicht Klasse 7)';

  @override
  String get classificationAdrAbove =>
      'die Aktivität liegt darüber (auch die Konzentration ist relevant)';

  @override
  String get classificationLabIndustrial => 'Industrielabor';

  @override
  String get classificationLabMedical => 'Medizinisches Labor';

  @override
  String get classificationLabAboveIII => '> III';

  @override
  String get classificationLabOps => 'Zulässige Arbeitsarten';

  @override
  String get classificationLabUnknown =>
      'MSZ 62-7: kein AM-Wert für dieses Nuklid';

  @override
  String get autoLogChartTitle => 'Messwert über die Zeit';

  @override
  String get gpsAverageButton => 'Gemitteltes GPS';

  @override
  String get gpsAverageTitle => 'Positionsmittelung';

  @override
  String get gpsAverageHint =>
      'Während der Messung an einer Stelle ruhig stehen bleiben. Eine längere Mittelungszeit liefert ein verlässlicheres Ergebnis; unter freiem Himmel ist es am besten. Die Messwerte werden nach ihrer Genauigkeit gewichtet, Ausreißer werden verworfen.';

  @override
  String get gpsAverageStart => 'Start';

  @override
  String get gpsAverageUse => 'Übernehmen';

  @override
  String get gpsAverageSamples => 'Messwerte';

  @override
  String get gpsAverageCurrent => 'Aktuelle Genauigkeit';

  @override
  String get gpsAverageResult => 'Geschätzte Genauigkeit des Mittelwerts';

  @override
  String get modbusAverageButton => 'Mittelwertmessung';

  @override
  String get modbusAverageRunning => 'Mittelung läuft';

  @override
  String get modbusAverageDone => 'Fertig';

  @override
  String get modbusAverageTooFew =>
      'Für die Fehlerberechnung sind mindestens 2 gültige Messwerte nötig; nur der Wert wurde übernommen.';

  @override
  String get measurementErrorLabel => 'Fehler (±)';

  @override
  String get measurementErrorHelper =>
      'Bei einer Mittelwertmessung ist dies der Standardfehler des Mittelwerts (1σ); bei manuell eingegebenen Werten kann er auch von Hand eingetragen werden. Er erscheint im Protokoll.';

  @override
  String get measurementAveragedLabel => 'Mittelwertmessung';

  @override
  String get csvHeaderValueError => 'Fehler (±)';

  @override
  String get csvHeaderAveraging => 'Mittelung (Messwerte; s)';

  @override
  String get helpManualTitle => 'Hilfe (Benutzerhandbuch)';

  @override
  String get helpManualOpenError =>
      'Das Handbuch konnte nicht geöffnet werden.';

  @override
  String get appVersionLabel => 'Version';
}
