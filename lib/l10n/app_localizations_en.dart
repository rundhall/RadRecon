// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RadRecon';

  @override
  String get instrumentsTooltip => 'Instruments';

  @override
  String get searchHint => 'Search';

  @override
  String get searchNoResults => 'No matching results';

  @override
  String get alertThresholdsTooltip => 'Alert thresholds';

  @override
  String get noSurveysYet => 'No surveys yet. Start one with the + button.';

  @override
  String get newSurveyButton => 'New survey';

  @override
  String get newSurveyDialogTitle => 'New survey';

  @override
  String get surveyNameLabel => 'Name';

  @override
  String get surveyLocationLabel => 'Location (optional)';

  @override
  String get editSurveyDetailsTooltip => 'Edit name and location';

  @override
  String get editSurveyDetailsTitle => 'Edit survey details';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get startButton => 'Start';

  @override
  String surveyDefaultTitle(String date) {
    return 'Survey – $date';
  }

  @override
  String get noLocationPlaceholder => '—';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystemOption => 'Phone language';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get alertThresholdExplanation =>
      'If a recorded measurement reaches or exceeds the threshold set here, the app will alert you (sound + pop-up). Leave empty for no alert on that type.';

  @override
  String get noThresholdSetHint => 'No threshold set';

  @override
  String get saveButton => 'Save';

  @override
  String get settingsSavedMessage => 'Settings saved.';

  @override
  String get measurementTypeDoseRate => 'Dose rate';

  @override
  String get measurementTypeSurfaceContamination => 'Surface contamination';

  @override
  String get measurementTypeCps => 'Count rate (cps)';

  @override
  String get measurementTypeNeutronCps => 'Neutron count rate (cps)';

  @override
  String get measurementTypeSample => 'Sampling';

  @override
  String get instrumentDeleteTitle => 'Delete instrument';

  @override
  String instrumentDeleteConfirm(String name) {
    return 'Delete \"$name\"? Past measurements linked to it are kept — only the instrument reference is removed from them.';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get noInstrumentsYet =>
      'No instruments yet. Add one with the + button.';

  @override
  String get noCalibrationData => 'No calibration data';

  @override
  String nextCalibrationOn(String date) {
    return 'Next calibration: $date';
  }

  @override
  String get noSerialNumber => 'no serial number';

  @override
  String get newInstrumentButton => 'New instrument';

  @override
  String get editInstrumentTitle => 'Edit instrument';

  @override
  String get instrumentNameLabel => 'Instrument name / type';

  @override
  String get requiredFieldError => 'Required';

  @override
  String get serialNumberLabel => 'Serial number';

  @override
  String get nextCalibrationLabel => 'Next calibration date';

  @override
  String get notSetLabel => 'Not set';

  @override
  String get calibrationFactorLabel => 'Calibration factor';

  @override
  String get modbusConnectedLabel => 'Reachable over WiFi Modbus/TCP';

  @override
  String get modbusHostLabel => 'IP address / host';

  @override
  String get modbusPortLabel => 'Port (e.g. 502)';

  @override
  String get modbusUnitIdLabel => 'Modbus Unit ID (slave address)';

  @override
  String get modbusRegisterAddressLabel => 'Register address (e.g. 294)';

  @override
  String get modbusRegisterAddressHelper =>
      'Starting holding register of the measured value (float32)';

  @override
  String get modbusGpsEnabledLabel => 'Read GPS position over Modbus';

  @override
  String get modbusGpsLatAddressLabel =>
      'Latitude register (float32, default 426)';

  @override
  String get modbusGpsLonAddressLabel =>
      'Longitude register (float32, default 428)';

  @override
  String get pickPositionTitle => 'Pick a position';

  @override
  String get confirmPositionButton => 'Confirm position';

  @override
  String get isotopeCalculatorTitle => 'Isotope calculator';

  @override
  String get gammaConstantsDisclaimer =>
      'The Γ-constants are for reference only. For an official protocol, verify them against an authoritative source before documenting the result.';

  @override
  String get isotopeLabel => 'Isotope';

  @override
  String get modeDoseFromActivity => 'Activity to\ndose rate';

  @override
  String get modeActivityFromDose => 'Dose rate to\nactivity';

  @override
  String get distanceFromSourceLabel => 'Distance from source (m)';

  @override
  String get activityLabel => 'Activity (MBq)';

  @override
  String get measuredDoseRateLabel => 'Measured dose rate (µSv/h)';

  @override
  String get calculateButton => 'Calculate';

  @override
  String get invalidDistanceError => 'Enter a valid, positive distance (m).';

  @override
  String get invalidActivityError => 'Enter a valid activity (MBq).';

  @override
  String get invalidDoseRateError => 'Enter a valid dose rate (µSv/h).';

  @override
  String calculationErrorMessage(String error) {
    return 'Calculation error: $error';
  }

  @override
  String calculatedDoseRateResult(String uSvH, String nSvH) {
    return 'Calculated dose rate: $uSvH µSv/h\n($nSvH nSv/h)';
  }

  @override
  String calculatedActivityResult(String mbq, String gbq) {
    return 'Calculated activity: $mbq MBq\n($gbq GBq)';
  }

  @override
  String get distanceToolTitle => 'Distance measurement';

  @override
  String get locationServiceDisabledError =>
      'Location services are turned off.';

  @override
  String get locationPermissionDeniedError => 'Location permission denied.';

  @override
  String gpsErrorMessage(String error) {
    return 'GPS error: $error';
  }

  @override
  String get selectTargetFirstError => 'Select the target point first.';

  @override
  String get noGpsPositionError =>
      'No GPS position. Refresh, or choose a starting point.';

  @override
  String get selectStartPointError => 'Choose a starting point.';

  @override
  String get selectTargetPointError => 'Choose the target point.';

  @override
  String get startFromCurrentPositionLabel => 'Start from: my current position';

  @override
  String get noPositionFetchedYet => 'Not fetched yet';

  @override
  String get refreshGpsButton => 'Refresh GPS';

  @override
  String get startPointLabel => 'Starting point';

  @override
  String get targetPointLabel => 'Target point';

  @override
  String get liveTrackingLabel => 'Live tracking';

  @override
  String get liveTrackingSubtitle =>
      'Continuously updates distance and bearing as you walk.';

  @override
  String get calculateDistanceButton => 'Calculate';

  @override
  String get liveTrackingRunningHint =>
      'Live tracking is running — walk in the direction of the arrow.';

  @override
  String get sourceSearchTitle => 'Source search';

  @override
  String get measurementTypeLabel => 'Measurement type';

  @override
  String pointsRecordedForType(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points recorded',
      one: '$count point recorded',
    );
    return '$_temp0 for this type within this survey.';
  }

  @override
  String get lowConfidenceWarning =>
      'Few points (< 4) — the estimate is unreliable; take more measurements at different spots in the search area.';

  @override
  String gradientEstimateLabel(String value, String unit) {
    return 'Estimated gradient: $value $unit/m';
  }

  @override
  String get directionEstimateHint =>
      'The measured value is estimated to increase in this direction.';

  @override
  String get sourceSearchDisclaimer =>
      'The suggested direction is based on a simple linear gradient estimate from the points recorded so far in this survey. It can be inaccurate with noisy field data, few points, or when the real source is far relative to the surveyed area\'s size. For guidance only — it does not replace professional judgment.';

  @override
  String get newMeasurementButton => 'New measurement';

  @override
  String get mapTitle => 'Map';

  @override
  String get noPointsRecordedYet => 'No measurement points recorded yet.';

  @override
  String get saveScreenshotTooltip => 'Save screenshot for the protocol';

  @override
  String get screenshotSavedMessage =>
      'Map saved — it will be attached when exporting the protocol.';

  @override
  String screenshotErrorMessage(String error) {
    return 'Screenshot error: $error';
  }

  @override
  String valueLabel(String value, String unit) {
    return 'Value: $value $unit';
  }

  @override
  String distanceFromSourceValue(String value) {
    return 'Distance from source: $value m';
  }

  @override
  String timestampLabel(String value) {
    return 'Time: $value';
  }

  @override
  String get sourcePositionLabel => 'Source position';

  @override
  String get editButton => 'Edit';

  @override
  String get closeSurveyTitle => 'Close survey';

  @override
  String get closeSurveyConfirm =>
      'Once closed, the protocol will show today\'s date as the end time. Points aren\'t locked by this — you can still edit them later.';

  @override
  String get closeSurveyButton => 'Close';

  @override
  String get surveyClosedMessage => 'Survey closed.';

  @override
  String get listScreenshotSavedMessage =>
      'List screenshot saved — it will be attached when exporting the protocol.';

  @override
  String exportErrorMessage(String error) {
    return 'Export error: $error';
  }

  @override
  String importErrorMessage(String error) {
    return 'Import error: $error';
  }

  @override
  String protocolShareSubject(String title) {
    return 'Protocol – $title';
  }

  @override
  String dataExportSubject(String title) {
    return 'Measurement points (data) – $title';
  }

  @override
  String csvExportSubject(String title) {
    return 'Measurement points (CSV) – $title';
  }

  @override
  String get importDoneTitle => 'Import complete';

  @override
  String importedPointsMessage(int points, int instruments, int sources) {
    return '$points points imported.\n$instruments new instruments created.\n$sources new radiation sources created.';
  }

  @override
  String get okButton => 'OK';

  @override
  String get toolsTooltip => 'Tools';

  @override
  String get autoLogMenuItem => 'Automatic logging';

  @override
  String get captureListScreenshotMenuItem => 'Save list screenshot';

  @override
  String get exportProtocolMenuItem => 'Export protocol';

  @override
  String get exportJsonMenuItem => 'Export points (data, JSON)';

  @override
  String get exportCsvMenuItem => 'Export points (table, CSV)';

  @override
  String get importJsonMenuItem => 'Import points (JSON)';

  @override
  String get newPointButton => 'New point';

  @override
  String sampleTakenListLabel(String date) {
    return 'Sampling · $date';
  }

  @override
  String get unknownModbusError => 'Unknown Modbus error.';

  @override
  String get noValidPositionError => 'No valid position given.';

  @override
  String get thresholdExceededTitle => 'Alert threshold exceeded';

  @override
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  ) {
    return 'The measured value ($value $unit) reaches or exceeds the threshold set for $type ($threshold $unit).';
  }

  @override
  String get newPointTitle => 'New measurement point';

  @override
  String get editPointTitle => 'Edit point';

  @override
  String get locationLabelFieldLabel => 'Location name';

  @override
  String get measuredValueLabel => 'Measured value';

  @override
  String get numberRequiredError => 'Enter a number';

  @override
  String get unitLabel => 'Unit';

  @override
  String get instrumentLabel => 'Instrument';

  @override
  String get addInstrumentTooltip => 'Add new instrument';

  @override
  String get queryingLabel => 'Querying...';

  @override
  String modbusQueryButton(String name) {
    return 'Modbus query ($name)';
  }

  @override
  String get sourcePositionSwitchLabel =>
      'This is the source position (max value)';

  @override
  String get sampleTakenSwitchLabel => 'A physical sample was taken here';

  @override
  String get sampleContainerLabel => 'Container ID';

  @override
  String get sampleAmountLabel => 'Amount';

  @override
  String get sampleMethodLabel => 'Sampling method';

  @override
  String get notesLabel => 'Notes';

  @override
  String get takePhotoLabel => 'Take photo';

  @override
  String get retakePhotoLabel => 'Replace photo';

  @override
  String get chooseFromGalleryLabel => 'Choose from gallery';

  @override
  String get positionLabel => 'Position';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get invalidValueError => 'Invalid';

  @override
  String get liveGpsButton => 'Live GPS';

  @override
  String get onMapButton => 'On the map';

  @override
  String get autoLogDisclaimer =>
      'Logging only runs while this screen is open. If the phone locks or you switch apps, the measurement pauses — you\'ll need to restart it when you come back.';

  @override
  String get noModbusInstrumentMessage =>
      'No instrument reachable over Modbus/TCP is set up. Add one in the Instruments list (WiFi Modbus/TCP switch on, IP, Unit ID and register address filled in).';

  @override
  String get triggerModeTime => 'Time-based';

  @override
  String get triggerModeDistance => 'Distance-based';

  @override
  String get intervalSecondsLabel => 'Interval (seconds)';

  @override
  String get distanceIntervalLabel => 'Distance interval (meters)';

  @override
  String get connectingLabel => 'Connecting...';

  @override
  String get stopButton => 'Stop';

  @override
  String get loggingRunningLabel => 'Logging running...';

  @override
  String get loggingStoppedLabel => 'Logging stopped';

  @override
  String capturedPointsLabel(int count) {
    return 'Points recorded: $count';
  }

  @override
  String lastValueLabel(String value, String unit) {
    return 'Last value: $value $unit';
  }

  @override
  String failedReadingsLabel(int count) {
    return 'Failed readings: $count';
  }

  @override
  String lastErrorSuffix(String error) {
    return ' (last error: $error)';
  }

  @override
  String get intervalMinError => 'The interval must be at least 1 second.';

  @override
  String get distanceMinError => 'The distance must be at least 1 meter.';

  @override
  String modbusConnectErrorMessage(String error) {
    return 'Modbus connection error: $error';
  }

  @override
  String get csvHeaderSerialNumber => 'No.';

  @override
  String get csvHeaderLocation => 'Location';

  @override
  String get csvHeaderType => 'Type';

  @override
  String get csvHeaderValue => 'Value';

  @override
  String get csvHeaderUnit => 'Unit';

  @override
  String get csvHeaderDistanceFromSource => 'Distance from source (m)';

  @override
  String get csvHeaderInstrument => 'Instrument';

  @override
  String get csvHeaderGpsLatitude => 'GPS latitude';

  @override
  String get csvHeaderGpsLongitude => 'GPS longitude';

  @override
  String get csvHeaderGpsAccuracy => 'GPS accuracy (m)';

  @override
  String get csvHeaderTimestamp => 'Timestamp';

  @override
  String get csvHeaderSample => 'Sampling';

  @override
  String get csvHeaderNotes => 'Notes';

  @override
  String get csvHeaderEstimatedActivity =>
      'Estimated activity (from measurement)';

  @override
  String get csvHeaderAttachedSources => 'Attached source(s)';

  @override
  String get csvHeaderCalculatedDoseRate => 'Calculated dose rate (µSv/h)';

  @override
  String get csvHeaderDoseRateDifference => 'Difference (µSv/h)';

  @override
  String get csvYes => 'yes';

  @override
  String get csvNo => 'no';

  @override
  String get importUnknownTypeWarning =>
      'Unknown measurement type skipped for one point.';

  @override
  String get importMissingGpsWarning =>
      'A point was skipped due to a missing GPS coordinate.';

  @override
  String get manageSourcesLabel => 'Manage radioactive source(s)';

  @override
  String sourcesCountLabel(int count) {
    return '$count source(s)';
  }

  @override
  String get radiationSourcesTitle => 'Sources';

  @override
  String get newSourceButton => 'Add source';

  @override
  String get newSourceTitle => 'New source';

  @override
  String get editSourceTitle => 'Edit source';

  @override
  String get noSourcesRecordedYet => 'No sources attached to this point yet.';

  @override
  String get sourcesTooltip => 'Sources';

  @override
  String get pointSourcesTitle => 'Source(s) at this point';

  @override
  String get attachSourceButton => 'Attach source';

  @override
  String get pickSourceTitle => 'Select source';

  @override
  String get noSourcesToAttach =>
      'No sources available yet — add one first in the main Sources list.';

  @override
  String get noSourcesYet => 'No sources added yet. Add one with the + button.';

  @override
  String get enterDistanceDialogTitle => 'Enter distance';

  @override
  String get detachSourceConfirmTitle => 'Detach source';

  @override
  String detachSourceConfirmMessage(String identifier) {
    return 'Detach source \"$identifier\" from this point? The source stays in your registry — only this link is removed.';
  }

  @override
  String get detachButton => 'Detach';

  @override
  String get totalCalculatedDoseRateLabel =>
      'Total calculated dose rate (all sources)';

  @override
  String sourcesUnknownNuclideSkippedNote(int count) {
    return '$count source(s) have an unknown nuclide and are excluded from the total.';
  }

  @override
  String get sourceIdentifierLabel => 'Unique identifier';

  @override
  String get nuclideLabel => 'Nuclide';

  @override
  String get customNuclideOption => 'Other (manual entry)';

  @override
  String get customNuclideNameLabel => 'Nuclide name';

  @override
  String get activityAtManufactureLabel => 'Activity at manufacture (MBq)';

  @override
  String get activityErrorPercentLabel => 'Activity error (±%)';

  @override
  String get manufactureDateLabel => 'Manufacture date';

  @override
  String get serviceLifeExpiryDateLabel => 'Service life expiry';

  @override
  String get nextInspectionDateLabel => 'Next inspection date';

  @override
  String get sourceDistanceLabel => 'Distance from measurement point (m)';

  @override
  String get asOfDateLabel => 'Activity as-of date';

  @override
  String get currentActivityResultLabel => 'Current activity';

  @override
  String get calculatedDoseRateResultLabel => 'Calculated dose rate';

  @override
  String get measuredDoseRateResultLabel => 'Measured dose rate (at point)';

  @override
  String get doseRateDifferenceResultLabel =>
      'Difference (measured − calculated)';

  @override
  String get unknownNuclideDecayWarning =>
      'Unknown nuclide: no stored half-life or gamma constant, so current activity and calculated dose rate can\'t be determined. The source data can still be saved, but the comparison is skipped.';

  @override
  String get noMeasuredValueForComparisonNote =>
      'No measured value recorded for this point — comparison isn\'t possible.';

  @override
  String unrecognizedUnitForComparisonNote(String unit) {
    return 'The measurement unit ($unit) can\'t be converted automatically — comparison isn\'t possible.';
  }

  @override
  String get sourceExpiredWarning => 'The source\'s service life has expired.';

  @override
  String get deleteSourceConfirmTitle => 'Delete source';

  @override
  String deleteSourceConfirmMessage(String identifier) {
    return 'Delete the source \"$identifier\" from the registry? This also removes it from every point it\'s attached to. This can\'t be undone.';
  }

  @override
  String get sourceCalculationDisclaimer =>
      'Calculated values are for reference only, based on standard gamma constants and half-lives. Verify against an authoritative source for official records.';

  @override
  String get estimatedActivityFromMeasurementLabel =>
      'Estimated activity (from measured value)';

  @override
  String get personsTooltip => 'Persons';

  @override
  String get personsTitle => 'Persons';

  @override
  String get newPersonButton => 'Add person';

  @override
  String get newPersonTitle => 'New person';

  @override
  String get editPersonTitle => 'Edit person';

  @override
  String get noPersonsYet => 'No persons added yet. Add one with the + button.';

  @override
  String get personNameLabel => 'Name';

  @override
  String get medicalExamExpiryDateLabel => 'Medical exam expiry';

  @override
  String get trainingExpiryDateLabel => 'Training expiry';

  @override
  String get deletePersonConfirmTitle => 'Delete person';

  @override
  String deletePersonConfirmMessage(String name) {
    return 'Delete \"$name\" from the registry? This also removes them from every survey they\'re attached to. This can\'t be undone.';
  }

  @override
  String get sessionPersonsTitle => 'Personnel on this survey';

  @override
  String get noPersonsAttachedYet => 'No persons assigned to this survey yet.';

  @override
  String get attachPersonButton => 'Assign person';

  @override
  String get pickPersonTitle => 'Select person';

  @override
  String get noPersonsToAttach =>
      'No person available to add yet — add one first in the main Persons list.';

  @override
  String get detachPersonConfirmTitle => 'Remove person';

  @override
  String detachPersonConfirmMessage(String name) {
    return 'Remove \"$name\" from this survey? The person stays in your registry — only this assignment is removed.';
  }

  @override
  String get expiryNotificationsSectionTitle => 'Expiry notifications';

  @override
  String get expiryNotificationsSwitchTitle => 'Notify about expiry dates';

  @override
  String get expiryNotificationsSwitchSubtitle =>
      'For upcoming expiry dates of sources (service life, inspection) and persons (medical exam, training), sent at 8:00 in the morning.';

  @override
  String get expiryLeadTimeLabel => 'How far ahead to notify';

  @override
  String get expiryLeadSameDay => 'On the day';

  @override
  String get expiryLeadOneDay => '1 day before';

  @override
  String get expiryLeadTwoDays => '2 days before';

  @override
  String get expiryLeadOneWeek => '1 week before';

  @override
  String get expiryNotificationsPermissionDenied =>
      'Notifications are blocked in your phone settings. Allow RadRecon notifications there.';

  @override
  String get expiryNotificationTitleToday => 'Expires today';

  @override
  String get expiryNotificationTitleUpcoming => 'Expires soon';

  @override
  String get expiryNotificationChannelName => 'Expiry notifications';

  @override
  String get expiryNotificationChannelDescription =>
      'Upcoming expiry dates of sources and persons';

  @override
  String get importRegistryCsv => 'Import CSV';

  @override
  String get exportRegistryCsv => 'Export CSV';

  @override
  String get registryCsvExportSubject => 'RadRecon registry data (CSV)';

  @override
  String get duplicatePolicyTitle => 'When a matching record exists';

  @override
  String get duplicateReplace => 'Replace existing record';

  @override
  String get duplicateSkip => 'Skip matching record';

  @override
  String get duplicateKeep => 'Import as a duplicate';

  @override
  String registryImportSummary(int imported, int replaced, int skipped) {
    return 'Imported: $imported, replaced: $replaced, skipped: $skipped';
  }

  @override
  String get modbusTestConnectionButton => 'Test connection';

  @override
  String get modbusTestingLabel => 'Testing...';

  @override
  String get modbusTestSuccessTitle => 'Connection successful';

  @override
  String get modbusTestFailureTitle => 'Connection failed';

  @override
  String modbusTestValue(String value) {
    return 'Value: $value';
  }

  @override
  String modbusTestPosition(String lat, String lon) {
    return 'Lat: $lat, Lon: $lon';
  }

  @override
  String missingFieldMessage(String field) {
    return 'Please fill in: $field';
  }

  @override
  String get errorTitle => 'Error';

  @override
  String modbusReadErrorWithCode(String code) {
    return 'Modbus error during reading: $code';
  }

  @override
  String get instrumentDidNotSendValidValue =>
      'The instrument did not send a valid value.';

  @override
  String get gpsPositionReadFailed =>
      'Failed to read GPS position from the instrument.';

  @override
  String get instrumentIPAddressNotSet => 'Instrument IP address not set.';

  @override
  String get modbusUnitIdNotSet => 'Modbus Unit ID not set.';

  @override
  String get registerAddressNotSet => 'Register address not set.';

  @override
  String get failedToConnectToInstrument =>
      'Failed to connect to the instrument.';

  @override
  String connectionErrorWithDetails(String error) {
    return 'Connection error: $error';
  }

  @override
  String get modbusAccessIncomplete =>
      'Modbus access details for the instrument are incomplete (IP, Unit ID, register address).';

  @override
  String get noDisplayableContentForScreenshot =>
      'No displayable content for the screenshot.';

  @override
  String get failedToConvertScreenshotToPng =>
      'Failed to convert the screenshot to PNG.';

  @override
  String get doseSourceOnline => 'Online (from detector)';

  @override
  String get doseSourceManual => 'Manual';

  @override
  String get doseSourcePassive => 'Passive dosimetry';

  @override
  String annualDoseLabel(int year) {
    return 'Dose in $year';
  }

  @override
  String get doseYearLabel => 'Year';

  @override
  String doseBreakdownLabel(String online, String manual, String passive) {
    return 'online $online · manual $manual · passive $passive';
  }

  @override
  String personDosesTitle(String name) {
    return 'Doses – $name';
  }

  @override
  String get personDosesTooltip => 'Manage doses';

  @override
  String get noDosesYet => 'No dose entries for this year yet.';

  @override
  String get addPassiveDoseButton => 'Add passive dosimetry';

  @override
  String get newPassiveDoseTitle => 'New passive dosimetry';

  @override
  String get editDoseTitle => 'Edit dose';

  @override
  String get doseValueLabel => 'Dose';

  @override
  String get dosePeriodStartLabel => 'Evaluation period start';

  @override
  String get dosePeriodEndLabel => 'Evaluation period end';

  @override
  String get dosePeriodEndBeforeStartError => 'End cannot be before start.';

  @override
  String get doseTotalLabel => 'Total';

  @override
  String get doseDeleteConfirmTitle => 'Delete dose entry';

  @override
  String get doseDeleteConfirmMessage =>
      'Delete this dose entry? This cannot be undone.';

  @override
  String sessionDoseDialogTitle(String name) {
    return 'Dose of $name';
  }

  @override
  String get onlineDoseLabel => 'Online dose';

  @override
  String get manualDoseLabel => 'Manual dose';

  @override
  String get closeSurveyDosesTitle => 'Review doses';

  @override
  String get closeSurveyDosesHint =>
      'Before closing, review or correct each participant dose.';

  @override
  String autoLogDoseSaved(int count, String dose) {
    return 'Dose saved for $count person(s): $dose';
  }

  @override
  String autoLogDoseNoPersons(String dose) {
    return 'Measured dose ($dose) was not saved because no person is attached to this survey.';
  }

  @override
  String autoLogDoseLabel(String dose) {
    return 'Integrated dose: $dose';
  }

  @override
  String autoLogDoseGaps(int count) {
    return '$count longer data gap(s) during measurement';
  }

  @override
  String get autoLogDoseOnlyDoseRate =>
      'Dose can only be calculated and saved from dose rate measurements.';

  @override
  String get importPersonDosesCsv => 'Import doses (CSV)';

  @override
  String get exportPersonDosesCsv => 'Export doses (CSV)';

  @override
  String get dataManagementSectionTitle => 'Data management';

  @override
  String get saveDatabaseButton => 'Save database to file';

  @override
  String get loadDatabaseButton => 'Load database from file';

  @override
  String get clearDatabaseButton => 'Clear database';

  @override
  String get companySwitchButton => 'Switch company';

  @override
  String get dataManagementHint =>
      'The backup file contains all data including photos, so it can be used to move to a new phone or to keep several companies\' data separate.';

  @override
  String get saveDatabaseSubject => 'RadRecon database backup';

  @override
  String databaseSavedMessage(String path) {
    return 'Database saved: $path';
  }

  @override
  String get loadDatabaseConfirmTitle => 'Load database';

  @override
  String get loadDatabaseConfirmBody =>
      'Loading overwrites all data currently on this device. Save it first if you still need it. Continue?';

  @override
  String get loadButton => 'Load';

  @override
  String databaseLoadedMessage(String name) {
    return 'Loaded: $name';
  }

  @override
  String get clearDatabaseConfirmTitle => 'Clear database';

  @override
  String get clearDatabaseConfirmBody =>
      'All surveys, measurement points, instruments, sources, people and photos will be permanently deleted from this device. This cannot be undone — make a backup first!';

  @override
  String get databaseClearedMessage => 'Database cleared.';

  @override
  String get companySwitchTitle => 'Switch company';

  @override
  String get activeCompanyLabel => 'Active company';

  @override
  String get companiesFolderLabel => 'Companies folder';

  @override
  String get chooseFolderButton => 'Choose folder';

  @override
  String get resetFolderButton => 'Back to default folder';

  @override
  String get noCompaniesYet =>
      'No saved companies in this folder yet. The active company is saved automatically on the first switch, or create a new one / add a backup file with the buttons above.';

  @override
  String companyBackupInfo(String date) {
    return 'Saved: $date';
  }

  @override
  String get newCompanyButton => 'New company';

  @override
  String get newCompanyDialogTitle => 'Create new company';

  @override
  String get companyNameLabel => 'Company name';

  @override
  String get companyNameExistsMessage =>
      'A company with this name already exists.';

  @override
  String get createButton => 'Create';

  @override
  String get addCompanyFromFileButton => 'Add company from backup file';

  @override
  String get companySwitchConfirmTitle => 'Switch company';

  @override
  String companySwitchConfirmBody(String company, String active) {
    return 'Switch to $company? Current data is saved automatically under $active.';
  }

  @override
  String get companySwitchAction => 'Switch';

  @override
  String companySwitchedMessage(String name) {
    return 'Active company: $name';
  }

  @override
  String get deleteCompanyBackupTitle => 'Delete backup';

  @override
  String deleteCompanyBackupBody(String name) {
    return 'Delete the backup of $name from the folder? Data currently loaded is not affected.';
  }

  @override
  String get importPersonCsv => 'Import persons (CSV)';

  @override
  String get exportPersonCsv => 'Export persons (CSV)';

  @override
  String get privateFolderHint =>
      'The app is currently using its own private folder, which other apps cannot access. Choose a folder (e.g. Downloads or Google Drive) to reach the backups from your file manager.';

  @override
  String get contributorsTitle => 'Contributors';

  @override
  String get contributorsThanks =>
      'Thank you to everyone who helps test, develop, translate and review RadRecon. RadRecon is a nonprofit civic initiative built by volunteers.';

  @override
  String get contributorsOrganizationsTitle => 'Organizations and companies';

  @override
  String get contributorsPeopleTitle => 'People';

  @override
  String get contributorsEmpty => 'The list is still empty. Be the first!';

  @override
  String get contributorsLoadError => 'The list could not be loaded.';

  @override
  String get contributorsJoinHint =>
      'Want to be listed? Sign up as a volunteer and tell us how you want to appear:';

  @override
  String get contributorsCopyLink => 'Copy link';

  @override
  String get contributorsLinkCopied => 'Link copied.';

  @override
  String get contributorRoleTesting => 'Testing';

  @override
  String get contributorRoleDevelopment => 'Development';

  @override
  String get contributorRoleReview => 'Expert review';

  @override
  String get contributorRoleTranslation => 'Translation';

  @override
  String get contributorRoleOther => 'Other';
}
