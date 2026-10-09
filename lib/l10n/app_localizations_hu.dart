// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'RadRecon';

  @override
  String get instrumentsTooltip => 'Műszerek';

  @override
  String get searchHint => 'Keresés';

  @override
  String get searchNoResults => 'Nincs találat';

  @override
  String get alertThresholdsTooltip => 'Riasztási küszöbök';

  @override
  String get noSurveysYet => 'Még nincs felmérés. Indíts egyet a + gombbal.';

  @override
  String get newSurveyButton => 'Új felmérés';

  @override
  String get newSurveyDialogTitle => 'Új felmérés';

  @override
  String get surveyNameLabel => 'Megnevezés';

  @override
  String get surveyLocationLabel => 'Helyszín (opcionális)';

  @override
  String get editSurveyDetailsTooltip => 'Megnevezés és helyszín szerkesztése';

  @override
  String get editSurveyDetailsTitle => 'Felmérés adatainak szerkesztése';

  @override
  String get cancelButton => 'Mégse';

  @override
  String get startButton => 'Indítás';

  @override
  String surveyDefaultTitle(String date) {
    return 'Felmérés – $date';
  }

  @override
  String get noLocationPlaceholder => '—';

  @override
  String get languageSectionTitle => 'Nyelv';

  @override
  String get languageSystemOption => 'Telefon nyelve';

  @override
  String get settingsTitle => 'Beállítások';

  @override
  String get appearanceSectionTitle => 'Megjelenés';

  @override
  String get themeLight => 'Világos';

  @override
  String get themeDark => 'Sötét';

  @override
  String get themeSystem => 'Rendszer';

  @override
  String get alertThresholdExplanation =>
      'Ha egy mérési pont rögzítésekor a mért érték eléri vagy meghaladja az itt megadott küszöböt, az app figyelmeztet (hangjelzés + felugró üzenet). Üresen hagyva nincs riasztás az adott típusnál.';

  @override
  String get noThresholdSetHint => 'Nincs küszöb beállítva';

  @override
  String get saveButton => 'Mentés';

  @override
  String get settingsSavedMessage => 'Beállítások mentve.';

  @override
  String get measurementTypeDoseRate => 'Dózisteljesítmény';

  @override
  String get measurementTypeSurfaceContamination => 'Felületi szennyezettség';

  @override
  String get measurementTypeCps => 'Beütésszám (cps)';

  @override
  String get measurementTypeNeutronCps => 'Neutron beütésszám (cps)';

  @override
  String get measurementTypeSample => 'Mintavétel';

  @override
  String get instrumentDeleteTitle => 'Műszer törlése';

  @override
  String instrumentDeleteConfirm(String name) {
    return '\"$name\" törlése? A hozzá tartozó korábbi mérések megmaradnak, csak a műszer-hivatkozás törlődik róluk.';
  }

  @override
  String get deleteButton => 'Törlés';

  @override
  String get noInstrumentsYet =>
      'Még nincs felvéve műszer. Adj hozzá egyet a + gombbal.';

  @override
  String get noCalibrationData => 'Nincs kalibrációs adat';

  @override
  String nextCalibrationOn(String date) {
    return 'Következő kalibráció: $date';
  }

  @override
  String get noSerialNumber => 'sorozatszám nélkül';

  @override
  String get newInstrumentButton => 'Új műszer';

  @override
  String get editInstrumentTitle => 'Műszer szerkesztése';

  @override
  String get instrumentNameLabel => 'Műszer neve / típusa';

  @override
  String get requiredFieldError => 'Kötelező';

  @override
  String get serialNumberLabel => 'Sorozatszám';

  @override
  String get nextCalibrationLabel => 'Következő kalibráció dátuma';

  @override
  String get notSetLabel => 'Nincs megadva';

  @override
  String get calibrationFactorLabel => 'Kalibrációs tényező';

  @override
  String get modbusConnectedLabel => 'WiFi Modbus/TCP-n elérhető';

  @override
  String get modbusHostLabel => 'IP cím / host';

  @override
  String get modbusPortLabel => 'Port (pl. 502)';

  @override
  String get modbusUnitIdLabel => 'Modbus Unit ID (slave cím)';

  @override
  String get modbusRegisterAddressLabel => 'Regiszter cím (pl. 294)';

  @override
  String get modbusRegisterAddressHelper =>
      'A mért érték (float32) kezdő holding regisztere';

  @override
  String get modbusGpsEnabledLabel => 'GPS pozíció olvasása Modbuson';

  @override
  String get modbusGpsLatAddressLabel =>
      'Szélesség regiszter (float32, alap: 426)';

  @override
  String get modbusGpsLonAddressLabel =>
      'Hosszúság regiszter (float32, alap: 428)';

  @override
  String get pickPositionTitle => 'Pozíció kiválasztása';

  @override
  String get confirmPositionButton => 'Pozíció megerősítése';

  @override
  String get isotopeCalculatorTitle => 'Izotóp kalkulátor';

  @override
  String get gammaConstantsDisclaimer =>
      'A Γ-állandók tájékoztató referenciaértékek. Hatósági jegyzőkönyvhöz ellenőrizd őket hiteles forrásból, mielőtt dokumentálod az eredményt.';

  @override
  String get isotopeLabel => 'Izotóp';

  @override
  String get modeDoseFromActivity => 'Aktivitásból\ndózisteljesítmény';

  @override
  String get modeActivityFromDose => 'Dózisteljesítményből\naktivitás';

  @override
  String get distanceFromSourceLabel => 'Távolság a forrástól (m)';

  @override
  String get activityLabel => 'Aktivitás (MBq)';

  @override
  String get measuredDoseRateLabel => 'Mért dózisteljesítmény (µSv/h)';

  @override
  String get calculateButton => 'Számítás';

  @override
  String get invalidDistanceError =>
      'Adj meg egy érvényes, pozitív távolságot (m).';

  @override
  String get invalidActivityError => 'Adj meg egy érvényes aktivitást (MBq).';

  @override
  String get invalidDoseRateError =>
      'Adj meg egy érvényes dózisteljesítményt (µSv/h).';

  @override
  String calculationErrorMessage(String error) {
    return 'Számítási hiba: $error';
  }

  @override
  String calculatedDoseRateResult(String uSvH, String nSvH) {
    return 'Számított dózisteljesítmény: $uSvH µSv/h\n($nSvH nSv/h)';
  }

  @override
  String calculatedActivityResult(String mbq, String gbq) {
    return 'Számított aktivitás: $mbq MBq\n($gbq GBq)';
  }

  @override
  String get distanceToolTitle => 'Távolságmérés';

  @override
  String get locationServiceDisabledError =>
      'A helyszolgáltatás ki van kapcsolva.';

  @override
  String get locationPermissionDeniedError =>
      'Helymeghatározási jogosultság megtagadva.';

  @override
  String gpsErrorMessage(String error) {
    return 'GPS hiba: $error';
  }

  @override
  String get selectTargetFirstError => 'Előbb válaszd ki a célpontot.';

  @override
  String get noGpsPositionError =>
      'Nincs GPS pozíció. Frissítsd, vagy válassz kiindulópontot.';

  @override
  String get selectStartPointError => 'Válassz kiindulópontot.';

  @override
  String get selectTargetPointError => 'Válaszd ki a célpontot.';

  @override
  String get startFromCurrentPositionLabel =>
      'Kiindulópont: jelenlegi pozícióm';

  @override
  String get noPositionFetchedYet => 'Nincs lekérve';

  @override
  String get refreshGpsButton => 'GPS frissítése';

  @override
  String get startPointLabel => 'Kiindulópont';

  @override
  String get targetPointLabel => 'Célpont';

  @override
  String get liveTrackingLabel => 'Élő követés';

  @override
  String get liveTrackingSubtitle =>
      'Folyamatosan frissíti a távolságot és az irányt séta közben.';

  @override
  String get calculateDistanceButton => 'Kiszámítás';

  @override
  String get liveTrackingRunningHint =>
      'Élő követés fut — sétálj a nyíl irányába.';

  @override
  String get sourceSearchTitle => 'Forráskereső';

  @override
  String get measurementTypeLabel => 'Mérés típusa';

  @override
  String pointsRecordedForType(int count) {
    return '$count rögzített pont ehhez a típushoz ezen a felmérésen belül.';
  }

  @override
  String get lowConfidenceWarning =>
      'Kevés pont (< 4) — a becslés bizonytalan, vegyél fel több mérést a keresési terület más-más pontjain.';

  @override
  String gradientEstimateLabel(String value, String unit) {
    return 'Becsült gradiens: $value $unit/m';
  }

  @override
  String get directionEstimateHint => 'Erre nő a mért érték a becslés szerint.';

  @override
  String get sourceSearchDisclaimer =>
      'A javasolt irány egyszerű lineáris gradiens-becslésen alapul a felmérésen belül eddig rögzített pontokból. Zajos terepi adatoknál, kevés pontnál, vagy ha a valódi forrás a mért terület méretéhez képest messze van, pontatlan lehet. Csak tájékoztató jellegű, nem helyettesíti a szakmai megítélést.';

  @override
  String get newMeasurementButton => 'Új mérés felvétele';

  @override
  String get mapTitle => 'Térkép';

  @override
  String get noPointsRecordedYet => 'Még nincs rögzített mérési pont.';

  @override
  String get saveScreenshotTooltip => 'Képernyőkép mentése a jegyzőkönyvhöz';

  @override
  String get screenshotSavedMessage =>
      'Térkép elmentve — a jegyzőkönyv exportálásakor csatolva lesz.';

  @override
  String screenshotErrorMessage(String error) {
    return 'Képernyőkép hiba: $error';
  }

  @override
  String valueLabel(String value, String unit) {
    return 'Érték: $value $unit';
  }

  @override
  String distanceFromSourceValue(String value) {
    return 'Táv. forrástól: $value m';
  }

  @override
  String timestampLabel(String value) {
    return 'Időpont: $value';
  }

  @override
  String get sourcePositionLabel => 'Forrás pozíció';

  @override
  String get editButton => 'Szerkesztés';

  @override
  String get closeSurveyTitle => 'Felmérés lezárása';

  @override
  String get closeSurveyConfirm =>
      'Lezárás után a jegyzőkönyv a mai dátumot fogja mutatni befejezési időpontként. A pontokat ez nem zárolja, később is szerkesztheted őket.';

  @override
  String get closeSurveyButton => 'Lezárás';

  @override
  String get surveyClosedMessage => 'Felmérés lezárva.';

  @override
  String get listScreenshotSavedMessage =>
      'Lista képernyőkép elmentve — a jegyzőkönyv exportálásakor csatolva lesz.';

  @override
  String exportErrorMessage(String error) {
    return 'Export hiba: $error';
  }

  @override
  String importErrorMessage(String error) {
    return 'Import hiba: $error';
  }

  @override
  String protocolShareSubject(String title) {
    return 'Jegyzőkönyv – $title';
  }

  @override
  String dataExportSubject(String title) {
    return 'Mérési pontok (adat) – $title';
  }

  @override
  String csvExportSubject(String title) {
    return 'Mérési pontok (CSV) – $title';
  }

  @override
  String get importDoneTitle => 'Importálás kész';

  @override
  String importedPointsMessage(int points, int instruments, int sources) {
    return '$points pont importálva.\n$instruments új műszer létrehozva.\n$sources új sugárforrás létrehozva.';
  }

  @override
  String get okButton => 'Rendben';

  @override
  String get toolsTooltip => 'Eszközök';

  @override
  String get autoLogMenuItem => 'Automatikus mérés';

  @override
  String get captureListScreenshotMenuItem => 'Lista képernyőkép mentése';

  @override
  String get exportProtocolMenuItem => 'Jegyzőkönyv exportálása';

  @override
  String get exportJsonMenuItem => 'Pontok exportálása (adat, JSON)';

  @override
  String get exportCsvMenuItem => 'Pontok exportálása (táblázat, CSV)';

  @override
  String get importJsonMenuItem => 'Pontok importálása (JSON)';

  @override
  String get newPointButton => 'Új pont';

  @override
  String sampleTakenListLabel(String date) {
    return 'Mintavétel · $date';
  }

  @override
  String get unknownModbusError => 'Ismeretlen Modbus hiba.';

  @override
  String get noValidPositionError => 'Nincs érvényes pozíció megadva.';

  @override
  String get thresholdExceededTitle => 'Riasztási küszöb túllépve';

  @override
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  ) {
    return 'A mért érték ($value $unit) eléri vagy meghaladja a(z) $type típushoz beállított küszöböt ($threshold $unit).';
  }

  @override
  String get newPointTitle => 'Új mérési pont';

  @override
  String get editPointTitle => 'Pont szerkesztése';

  @override
  String get locationLabelFieldLabel => 'Helyszín megnevezése';

  @override
  String get measuredValueLabel => 'Mért érték';

  @override
  String get numberRequiredError => 'Számot adj meg';

  @override
  String get unitLabel => 'Egység';

  @override
  String get instrumentLabel => 'Műszer';

  @override
  String get addInstrumentTooltip => 'Új műszer felvétele';

  @override
  String get queryingLabel => 'Lekérdezés...';

  @override
  String modbusQueryButton(String name) {
    return 'Modbus lekérdezés ($name)';
  }

  @override
  String get sourcePositionSwitchLabel => 'Ez a forrás pozíció (max. érték)';

  @override
  String get sampleTakenSwitchLabel => 'Fizikai mintavétel történt itt';

  @override
  String get sampleContainerLabel => 'Edény azonosító';

  @override
  String get sampleAmountLabel => 'Mennyiség';

  @override
  String get sampleMethodLabel => 'Mintavétel módja';

  @override
  String get notesLabel => 'Megjegyzés';

  @override
  String get takePhotoLabel => 'Fotó készítése';

  @override
  String get retakePhotoLabel => 'Fotó cseréje';

  @override
  String get chooseFromGalleryLabel => 'Kiválasztás a galériából';

  @override
  String get positionLabel => 'Pozíció';

  @override
  String get latitudeLabel => 'Szélesség (lat)';

  @override
  String get longitudeLabel => 'Hosszúság (lon)';

  @override
  String get invalidValueError => 'Érvénytelen';

  @override
  String get liveGpsButton => 'Élő GPS';

  @override
  String get onMapButton => 'Térképen';

  @override
  String get autoLogDisclaimer =>
      'A rögzítés csak addig fut, amíg ez a képernyő nyitva van. Ha a telefon kikapcsol vagy másik appra váltasz, a mérés szünetel — visszatéréskor újra kell indítani.';

  @override
  String get noModbusInstrumentMessage =>
      'Nincs Modbus/TCP-n elérhető műszer beállítva. Vegyél fel egyet a Műszerek listában (WiFi Modbus/TCP kapcsoló be, IP, Unit ID és regiszter cím kitöltve).';

  @override
  String get triggerModeTime => 'Idő alapú';

  @override
  String get triggerModeDistance => 'Táv alapú';

  @override
  String get intervalSecondsLabel => 'Időköz (másodperc)';

  @override
  String get distanceIntervalLabel => 'Távolságköz (méter)';

  @override
  String get connectingLabel => 'Kapcsolódás...';

  @override
  String get stopButton => 'Leállítás';

  @override
  String get loggingRunningLabel => 'Rögzítés fut...';

  @override
  String get loggingStoppedLabel => 'Rögzítés leállítva';

  @override
  String capturedPointsLabel(int count) {
    return 'Rögzített pontok: $count';
  }

  @override
  String lastValueLabel(String value, String unit) {
    return 'Utolsó érték: $value $unit';
  }

  @override
  String failedReadingsLabel(int count) {
    return 'Sikertelen olvasások: $count';
  }

  @override
  String lastErrorSuffix(String error) {
    return ' (utolsó hiba: $error)';
  }

  @override
  String get intervalMinError =>
      'Az időköznek legalább 1 másodpercnek kell lennie.';

  @override
  String get distanceMinError =>
      'A távolságnak legalább 1 méternek kell lennie.';

  @override
  String modbusConnectErrorMessage(String error) {
    return 'Modbus kapcsolódási hiba: $error';
  }

  @override
  String get csvHeaderSerialNumber => 'Sorszám';

  @override
  String get csvHeaderLocation => 'Helyszín';

  @override
  String get csvHeaderType => 'Típus';

  @override
  String get csvHeaderValue => 'Érték';

  @override
  String get csvHeaderUnit => 'Egység';

  @override
  String get csvHeaderDistanceFromSource => 'Táv. forrástól (m)';

  @override
  String get csvHeaderInstrument => 'Műszer';

  @override
  String get csvHeaderGpsLatitude => 'GPS szélesség';

  @override
  String get csvHeaderGpsLongitude => 'GPS hosszúság';

  @override
  String get csvHeaderGpsAccuracy => 'GPS pontosság (m)';

  @override
  String get csvHeaderTimestamp => 'Időpont';

  @override
  String get csvHeaderSample => 'Mintavétel';

  @override
  String get csvHeaderNotes => 'Megjegyzés';

  @override
  String get csvHeaderEstimatedActivity => 'Becsült aktivitás (mérésből)';

  @override
  String get csvHeaderAttachedSources => 'Hozzárendelt forrás(ok)';

  @override
  String get csvHeaderCalculatedDoseRate =>
      'Számított dózisteljesítmény (µSv/h)';

  @override
  String get csvHeaderDoseRateDifference => 'Eltérés (µSv/h)';

  @override
  String get csvYes => 'igen';

  @override
  String get csvNo => 'nem';

  @override
  String get importUnknownTypeWarning =>
      'Ismeretlen mérés-típus kihagyva egy ponton.';

  @override
  String get importMissingGpsWarning =>
      'Hiányzó GPS-koordináta miatt kihagyva egy pont.';

  @override
  String get manageSourcesLabel => 'Radioaktív forrás(ok) kezelése';

  @override
  String sourcesCountLabel(int count) {
    return '$count forrás';
  }

  @override
  String get radiationSourcesTitle => 'Források';

  @override
  String get newSourceButton => 'Forrás hozzáadása';

  @override
  String get newSourceTitle => 'Új forrás';

  @override
  String get editSourceTitle => 'Forrás szerkesztése';

  @override
  String get noSourcesRecordedYet =>
      'Ehhez a ponthoz még nincs forrás hozzárendelve.';

  @override
  String get sourcesTooltip => 'Források';

  @override
  String get pointSourcesTitle => 'Forrás(ok) a ponton';

  @override
  String get attachSourceButton => 'Forrás hozzárendelése';

  @override
  String get pickSourceTitle => 'Forrás kiválasztása';

  @override
  String get noSourcesToAttach =>
      'Nincs még felvehető forrás — vedd fel előbb a főoldali Források listában.';

  @override
  String get noSourcesYet =>
      'Még nincs felvéve forrás. Adj hozzá egyet a + gombbal.';

  @override
  String get enterDistanceDialogTitle => 'Távolság megadása';

  @override
  String get detachSourceConfirmTitle => 'Forrás leválasztása';

  @override
  String detachSourceConfirmMessage(String identifier) {
    return 'Leválasztod a \"$identifier\" forrást erről a pontról? A forrás a nyilvántartásban megmarad, csak ez a hozzárendelés törlődik.';
  }

  @override
  String get detachButton => 'Leválasztás';

  @override
  String get totalCalculatedDoseRateLabel =>
      'Források összesített, számított dózisteljesítménye';

  @override
  String sourcesUnknownNuclideSkippedNote(int count) {
    return '$count forrás nuklidja ismeretlen — nem szerepel az összegben.';
  }

  @override
  String get sourceIdentifierLabel => 'Egyedi azonosító';

  @override
  String get nuclideLabel => 'Nuklid';

  @override
  String get customNuclideOption => 'Egyéb (kézi megadás)';

  @override
  String get customNuclideNameLabel => 'Nuklid neve';

  @override
  String get activityAtManufactureLabel => 'Aktivitás gyártáskor (MBq)';

  @override
  String get activityErrorPercentLabel => 'Aktivitás hibája (±%)';

  @override
  String get manufactureDateLabel => 'Gyártás dátuma';

  @override
  String get serviceLifeExpiryDateLabel => 'Szolgálati idő lejárata';

  @override
  String get nextInspectionDateLabel => 'Következő ellenőrzés dátuma';

  @override
  String get sourceDistanceLabel => 'Távolság a mérési ponttól (m)';

  @override
  String get asOfDateLabel => 'Aktivitás dátuma (számításhoz)';

  @override
  String get currentActivityResultLabel => 'Aktuális aktivitás';

  @override
  String get calculatedDoseRateResultLabel => 'Számított dózisteljesítmény';

  @override
  String get measuredDoseRateResultLabel => 'Mért dózisteljesítmény (a ponton)';

  @override
  String get doseRateDifferenceResultLabel => 'Eltérés (mért − számított)';

  @override
  String get unknownNuclideDecayWarning =>
      'Ismeretlen nuklid: nincs tárolt felezési idő és gamma-állandó, ezért az aktuális aktivitás és a számított dózisteljesítmény nem határozható meg. A forrás adatai elmenthetők, de az összehasonlítás kimarad.';

  @override
  String get noMeasuredValueForComparisonNote =>
      'A ponthoz nincs rögzített mért érték — az összehasonlítás nem végezhető el.';

  @override
  String unrecognizedUnitForComparisonNote(String unit) {
    return 'A mérési egység ($unit) nem alakítható át automatikusan — az összehasonlítás nem végezhető el.';
  }

  @override
  String get sourceExpiredWarning => 'A forrás szolgálati ideje lejárt.';

  @override
  String get deleteSourceConfirmTitle => 'Forrás törlése';

  @override
  String deleteSourceConfirmMessage(String identifier) {
    return 'Biztosan törlöd a \"$identifier\" azonosítójú forrást a nyilvántartásból? Minden ponthoz rendelt hozzárendelése is törlődik vele. A művelet nem vonható vissza.';
  }

  @override
  String get sourceCalculationDisclaimer =>
      'A számított értékek tájékoztató jellegűek, referencia gamma-állandók és felezési idők alapján. Hatósági jegyzőkönyvhöz ellenőrizd hiteles forrásból.';

  @override
  String get estimatedActivityFromMeasurementLabel =>
      'Becsült aktivitás (a mért értékből)';

  @override
  String get personsTooltip => 'Személyek';

  @override
  String get personsTitle => 'Személyek';

  @override
  String get newPersonButton => 'Személy hozzáadása';

  @override
  String get newPersonTitle => 'Új személy';

  @override
  String get editPersonTitle => 'Személy szerkesztése';

  @override
  String get noPersonsYet =>
      'Még nincs felvéve személy. Adj hozzá egyet a + gombbal.';

  @override
  String get personNameLabel => 'Név';

  @override
  String get medicalExamExpiryDateLabel => 'Orvosi vizsgálat érvényessége';

  @override
  String get trainingExpiryDateLabel => 'Oktatás érvényessége';

  @override
  String get deletePersonConfirmTitle => 'Személy törlése';

  @override
  String deletePersonConfirmMessage(String name) {
    return 'Biztosan törlöd \"$name\" nevű személyt a nyilvántartásból? Minden felméréshez rendelt hozzárendelése is törlődik vele. A művelet nem vonható vissza.';
  }

  @override
  String get sessionPersonsTitle => 'Felmérésen résztvevő személyek';

  @override
  String get noPersonsAttachedYet =>
      'Ehhez a felméréshez még nincs személy hozzárendelve.';

  @override
  String get attachPersonButton => 'Személy hozzárendelése';

  @override
  String get pickPersonTitle => 'Személy kiválasztása';

  @override
  String get noPersonsToAttach =>
      'Nincs még felvehető személy — vedd fel előbb a főoldali Személyek listában.';

  @override
  String get detachPersonConfirmTitle => 'Személy leválasztása';

  @override
  String detachPersonConfirmMessage(String name) {
    return 'Leválasztod \"$name\" nevű személyt erről a felmérésről? A személy a nyilvántartásban megmarad, csak ez a hozzárendelés törlődik.';
  }

  @override
  String get expiryNotificationsSectionTitle => 'Lejárati értesítések';

  @override
  String get expiryNotificationsSwitchTitle => 'Értesítés a lejáratokról';

  @override
  String get expiryNotificationsSwitchSubtitle =>
      'A források (szolgálati idő, ellenőrzés) és a személyek (orvosi vizsgálat, oktatás) jövőbeli lejárati dátumairól, reggel 8 órakor.';

  @override
  String get expiryLeadTimeLabel => 'Mennyivel előbb jöjjön az értesítés';

  @override
  String get expiryLeadSameDay => 'Aznap';

  @override
  String get expiryLeadOneDay => '1 nappal előtte';

  @override
  String get expiryLeadTwoDays => '2 nappal előtte';

  @override
  String get expiryLeadOneWeek => '1 héttel előtte';

  @override
  String get expiryNotificationsPermissionDenied =>
      'Az értesítések le vannak tiltva a telefon beállításaiban, engedélyezd ott a RadRecon értesítéseit.';

  @override
  String get expiryNotificationTitleToday => 'Ma lejár';

  @override
  String get expiryNotificationTitleUpcoming => 'Hamarosan lejár';

  @override
  String get expiryNotificationChannelName => 'Lejárati értesítések';

  @override
  String get expiryNotificationChannelDescription =>
      'Források és személyek közelgő lejárati dátumai';

  @override
  String get importRegistryCsv => 'CSV importálása';

  @override
  String get exportRegistryCsv => 'CSV exportálása';

  @override
  String get registryCsvExportSubject => 'RadRecon nyilvántartás (CSV)';

  @override
  String get duplicatePolicyTitle => 'Ha már létezik ilyen rekord';

  @override
  String get duplicateReplace => 'Meglévő rekord cseréje';

  @override
  String get duplicateSkip => 'Az egyező rekord kihagyása';

  @override
  String get duplicateKeep => 'Importálás duplikátumként';

  @override
  String registryImportSummary(int imported, int replaced, int skipped) {
    return 'Importálva: $imported, cserélve: $replaced, kihagyva: $skipped';
  }

  @override
  String get modbusTestConnectionButton => 'Kapcsolat tesztelése';

  @override
  String get modbusTestingLabel => 'Tesztelés...';

  @override
  String get modbusTestSuccessTitle => 'Kapcsolat sikeres';

  @override
  String get modbusTestFailureTitle => 'Kapcsolat meghiúsult';

  @override
  String modbusTestValue(String value) {
    return 'Érték: $value';
  }

  @override
  String modbusTestPosition(String lat, String lon) {
    return 'Szél: $lat, Hossz: $lon';
  }

  @override
  String missingFieldMessage(String field) {
    return 'Kérjük töltse ki: $field';
  }

  @override
  String get errorTitle => 'Hiba';

  @override
  String modbusReadErrorWithCode(String code) {
    return 'Modbus hiba a kiolvasás során: $code';
  }

  @override
  String get instrumentDidNotSendValidValue =>
      'A műszer nem küldött érvényes értéket.';

  @override
  String get gpsPositionReadFailed =>
      'A GPS pozíció kiolvasása a műszerből sikertelen.';

  @override
  String get instrumentIPAddressNotSet => 'Nincs megadva a műszer IP-címe.';

  @override
  String get modbusUnitIdNotSet => 'Nincs megadva a Modbus Unit ID.';

  @override
  String get registerAddressNotSet => 'Nincs megadva a regiszter cím.';

  @override
  String get failedToConnectToInstrument =>
      'Nem sikerült kapcsolódni a műszerhez.';

  @override
  String connectionErrorWithDetails(String error) {
    return 'Kapcsolódási hiba: $error';
  }

  @override
  String get modbusAccessIncomplete =>
      'A műszerhez nincs teljesen kitöltve a Modbus elérhetőség (IP, Unit ID, regiszter cím).';

  @override
  String get noDisplayableContentForScreenshot =>
      'Nincs megjeleníthető tartalom a képernyőképhez.';

  @override
  String get failedToConvertScreenshotToPng =>
      'Nem sikerült PNG-vé alakítani a képernyőképet.';

  @override
  String get doseSourceOnline => 'Online (detektorból)';

  @override
  String get doseSourceManual => 'Manuális';

  @override
  String get doseSourcePassive => 'Passzív dozimetria';

  @override
  String annualDoseLabel(int year) {
    return '$year. évi dózis';
  }

  @override
  String get doseYearLabel => 'Év';

  @override
  String doseBreakdownLabel(String online, String manual, String passive) {
    return 'online $online · manuális $manual · passzív $passive';
  }

  @override
  String personDosesTitle(String name) {
    return 'Dózisok – $name';
  }

  @override
  String get personDosesTooltip => 'Dózisok kezelése';

  @override
  String get noDosesYet => 'Ebben az évben még nincs dózis-bejegyzés.';

  @override
  String get addPassiveDoseButton => 'Passzív dozimetria rögzítése';

  @override
  String get newPassiveDoseTitle => 'Új passzív dozimetria';

  @override
  String get editDoseTitle => 'Dózis szerkesztése';

  @override
  String get doseValueLabel => 'Dózis';

  @override
  String get dosePeriodStartLabel => 'Kiértékelési időszak kezdete';

  @override
  String get dosePeriodEndLabel => 'Kiértékelési időszak vége';

  @override
  String get dosePeriodEndBeforeStartError => 'A vég nem lehet a kezdet előtt.';

  @override
  String get doseTotalLabel => 'Összesen';

  @override
  String get doseDeleteConfirmTitle => 'Dózis-bejegyzés törlése';

  @override
  String get doseDeleteConfirmMessage =>
      'Biztosan törlöd ezt a dózis-bejegyzést? A művelet nem vonható vissza.';

  @override
  String sessionDoseDialogTitle(String name) {
    return '$name dózisa';
  }

  @override
  String get onlineDoseLabel => 'Online dózis';

  @override
  String get manualDoseLabel => 'Manuális dózis';

  @override
  String get closeSurveyDosesTitle => 'Dózisok ellenőrzése';

  @override
  String get closeSurveyDosesHint =>
      'Lezárás előtt ellenőrizheted vagy korrigálhatod a résztvevők dózisát.';

  @override
  String autoLogDoseSaved(int count, String dose) {
    return 'Dózis rögzítve $count személynek: $dose';
  }

  @override
  String autoLogDoseNoPersons(String dose) {
    return 'A mért dózis ($dose) nem lett elmentve, mert a felméréshez nincs személy rendelve.';
  }

  @override
  String autoLogDoseLabel(String dose) {
    return 'Integrált dózis: $dose';
  }

  @override
  String autoLogDoseGaps(int count) {
    return '$count hosszabb adatkiesés a mérésben';
  }

  @override
  String get autoLogDoseOnlyDoseRate =>
      'A dózis csak dózisteljesítmény típusú mérésből számolható és menthető.';

  @override
  String get importPersonDosesCsv => 'Dózisok importálása (CSV)';

  @override
  String get exportPersonDosesCsv => 'Dózisok exportálása (CSV)';

  @override
  String get dataManagementSectionTitle => 'Adatkezelés';

  @override
  String get saveDatabaseButton => 'Adatbázis mentése fájlba';

  @override
  String get loadDatabaseButton => 'Adatbázis betöltése fájlból';

  @override
  String get clearDatabaseButton => 'Adatbázis törlése';

  @override
  String get companySwitchButton => 'Cégváltás';

  @override
  String get dataManagementHint =>
      'A mentésfájl tartalmazza az összes adatot a fotókkal együtt, így új telefonra költözéshez vagy több cég adatainak külön kezeléséhez is használható.';

  @override
  String get saveDatabaseSubject => 'RadRecon adatbázis mentés';

  @override
  String databaseSavedMessage(String path) {
    return 'Adatbázis elmentve: $path';
  }

  @override
  String get loadDatabaseConfirmTitle => 'Adatbázis betöltése';

  @override
  String get loadDatabaseConfirmBody =>
      'A betöltés felülírja az eszközön lévő összes jelenlegi adatot. Ha szükség van rájuk, előbb mentsd el őket. Folytatod?';

  @override
  String get loadButton => 'Betöltés';

  @override
  String databaseLoadedMessage(String name) {
    return 'Betöltve: $name';
  }

  @override
  String get clearDatabaseConfirmTitle => 'Adatbázis törlése';

  @override
  String get clearDatabaseConfirmBody =>
      'Az összes felmérés, mérési pont, műszer, forrás, személy és fotó véglegesen törlődik az eszközről. Ez nem vonható vissza — előbb készíts mentést!';

  @override
  String get databaseClearedMessage => 'Az adatbázis törölve.';

  @override
  String get companySwitchTitle => 'Cégváltás';

  @override
  String get activeCompanyLabel => 'Aktív cég';

  @override
  String get companiesFolderLabel => 'Cégek mappája';

  @override
  String get chooseFolderButton => 'Mappa kiválasztása';

  @override
  String get resetFolderButton => 'Vissza az alapértelmezett mappához';

  @override
  String get noCompaniesYet =>
      'Ebben a mappában még nincs mentett cég. Az aktív cég az első váltáskor automatikusan elmentődik, vagy hozz létre újat / adj hozzá mentésfájlt a felső gombokkal.';

  @override
  String companyBackupInfo(String date) {
    return 'Mentve: $date';
  }

  @override
  String get newCompanyButton => 'Új cég';

  @override
  String get newCompanyDialogTitle => 'Új cég létrehozása';

  @override
  String get companyNameLabel => 'Cég neve';

  @override
  String get companyNameExistsMessage => 'Ilyen nevű cég már létezik.';

  @override
  String get createButton => 'Létrehozás';

  @override
  String get addCompanyFromFileButton => 'Cég hozzáadása mentésfájlból';

  @override
  String get companySwitchConfirmTitle => 'Cégváltás';

  @override
  String companySwitchConfirmBody(String company, String active) {
    return 'Átváltasz erre: $company? A jelenlegi adatok automatikusan elmentődnek a(z) $active cég alatt.';
  }

  @override
  String get companySwitchAction => 'Váltás';

  @override
  String companySwitchedMessage(String name) {
    return 'Aktív cég: $name';
  }

  @override
  String get deleteCompanyBackupTitle => 'Mentés törlése';

  @override
  String deleteCompanyBackupBody(String name) {
    return 'Törlöd a(z) $name cég mentését a mappából? Az éppen betöltött adatot ez nem érinti.';
  }

  @override
  String get importPersonCsv => 'Személyek importálása (CSV)';

  @override
  String get exportPersonCsv => 'Személyek exportálása (CSV)';

  @override
  String get privateFolderHint =>
      'Az app jelenleg a saját, más appból nem elérhető mappáját használja. Válassz egy mappát (pl. Letöltések vagy Google Drive), hogy a mentéseket a fájlkezelőből is elérd.';

  @override
  String get contributorsTitle => 'Közreműködők';

  @override
  String get contributorsThanks =>
      'Köszönet mindenkinek, aki segít a RadRecon tesztelésében, fejlesztésében, fordításában és szakmai átnézésében. A RadRecon nonprofit civil kezdeményezés, önkéntesek munkájából épül.';

  @override
  String get contributorsOrganizationsTitle => 'Szervezetek és cégek';

  @override
  String get contributorsPeopleTitle => 'Személyek';

  @override
  String get contributorsEmpty => 'A lista még üres. Légy te az első!';

  @override
  String get contributorsLoadError => 'A lista nem tölthető be.';

  @override
  String get contributorsJoinHint =>
      'Szeretnél felkerülni a listára? Jelentkezz önkéntesnek, és írd meg, hogyan szeretnél megjelenni:';

  @override
  String get contributorsCopyLink => 'Link másolása';

  @override
  String get contributorsLinkCopied => 'Link másolva.';

  @override
  String get contributorRoleTesting => 'Tesztelés';

  @override
  String get contributorRoleDevelopment => 'Fejlesztés';

  @override
  String get contributorRoleReview => 'Szakmai átnézés';

  @override
  String get contributorRoleTranslation => 'Fordítás';

  @override
  String get contributorRoleOther => 'Egyéb';
}
