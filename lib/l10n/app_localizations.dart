import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('hu'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In hu, this message translates to:
  /// **'RadRecon'**
  String get appTitle;

  /// No description provided for @instrumentsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Műszerek'**
  String get instrumentsTooltip;

  /// No description provided for @searchHint.
  ///
  /// In hu, this message translates to:
  /// **'Keresés'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In hu, this message translates to:
  /// **'Nincs találat'**
  String get searchNoResults;

  /// No description provided for @alertThresholdsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Riasztási küszöbök'**
  String get alertThresholdsTooltip;

  /// No description provided for @noSurveysYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs felmérés. Indíts egyet a + gombbal.'**
  String get noSurveysYet;

  /// No description provided for @newSurveyButton.
  ///
  /// In hu, this message translates to:
  /// **'Új felmérés'**
  String get newSurveyButton;

  /// No description provided for @newSurveyDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új felmérés'**
  String get newSurveyDialogTitle;

  /// No description provided for @surveyNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Megnevezés'**
  String get surveyNameLabel;

  /// No description provided for @surveyLocationLabel.
  ///
  /// In hu, this message translates to:
  /// **'Helyszín (opcionális)'**
  String get surveyLocationLabel;

  /// No description provided for @editSurveyDetailsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Megnevezés és helyszín szerkesztése'**
  String get editSurveyDetailsTooltip;

  /// No description provided for @editSurveyDetailsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés adatainak szerkesztése'**
  String get editSurveyDetailsTitle;

  /// No description provided for @cancelButton.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get cancelButton;

  /// No description provided for @startButton.
  ///
  /// In hu, this message translates to:
  /// **'Indítás'**
  String get startButton;

  /// No description provided for @surveyDefaultTitle.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés – {date}'**
  String surveyDefaultTitle(String date);

  /// No description provided for @noLocationPlaceholder.
  ///
  /// In hu, this message translates to:
  /// **'—'**
  String get noLocationPlaceholder;

  /// No description provided for @languageSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Nyelv'**
  String get languageSectionTitle;

  /// No description provided for @languageSystemOption.
  ///
  /// In hu, this message translates to:
  /// **'Telefon nyelve'**
  String get languageSystemOption;

  /// No description provided for @settingsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások'**
  String get settingsTitle;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Megjelenés'**
  String get appearanceSectionTitle;

  /// No description provided for @themeLight.
  ///
  /// In hu, this message translates to:
  /// **'Világos'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In hu, this message translates to:
  /// **'Sötét'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In hu, this message translates to:
  /// **'Rendszer'**
  String get themeSystem;

  /// No description provided for @alertThresholdExplanation.
  ///
  /// In hu, this message translates to:
  /// **'Ha egy mérési pont rögzítésekor a mért érték eléri vagy meghaladja az itt megadott küszöböt, az app figyelmeztet (hangjelzés + felugró üzenet). Üresen hagyva nincs riasztás az adott típusnál.'**
  String get alertThresholdExplanation;

  /// No description provided for @noThresholdSetHint.
  ///
  /// In hu, this message translates to:
  /// **'Nincs küszöb beállítva'**
  String get noThresholdSetHint;

  /// No description provided for @saveButton.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get saveButton;

  /// No description provided for @settingsSavedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások mentve.'**
  String get settingsSavedMessage;

  /// No description provided for @measurementTypeDoseRate.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítmény'**
  String get measurementTypeDoseRate;

  /// No description provided for @measurementTypeSurfaceContamination.
  ///
  /// In hu, this message translates to:
  /// **'Felületi szennyezettség'**
  String get measurementTypeSurfaceContamination;

  /// No description provided for @measurementTypeCps.
  ///
  /// In hu, this message translates to:
  /// **'Beütésszám (cps)'**
  String get measurementTypeCps;

  /// No description provided for @measurementTypeNeutronCps.
  ///
  /// In hu, this message translates to:
  /// **'Neutron beütésszám (cps)'**
  String get measurementTypeNeutronCps;

  /// No description provided for @measurementTypeSample.
  ///
  /// In hu, this message translates to:
  /// **'Mintavétel'**
  String get measurementTypeSample;

  /// No description provided for @instrumentDeleteTitle.
  ///
  /// In hu, this message translates to:
  /// **'Műszer törlése'**
  String get instrumentDeleteTitle;

  /// No description provided for @instrumentDeleteConfirm.
  ///
  /// In hu, this message translates to:
  /// **'\"{name}\" törlése? A hozzá tartozó korábbi mérések megmaradnak, csak a műszer-hivatkozás törlődik róluk.'**
  String instrumentDeleteConfirm(String name);

  /// No description provided for @deleteButton.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get deleteButton;

  /// No description provided for @noInstrumentsYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs felvéve műszer. Adj hozzá egyet a + gombbal.'**
  String get noInstrumentsYet;

  /// No description provided for @noCalibrationData.
  ///
  /// In hu, this message translates to:
  /// **'Nincs kalibrációs adat'**
  String get noCalibrationData;

  /// No description provided for @nextCalibrationOn.
  ///
  /// In hu, this message translates to:
  /// **'Következő kalibráció: {date}'**
  String nextCalibrationOn(String date);

  /// No description provided for @noSerialNumber.
  ///
  /// In hu, this message translates to:
  /// **'sorozatszám nélkül'**
  String get noSerialNumber;

  /// No description provided for @newInstrumentButton.
  ///
  /// In hu, this message translates to:
  /// **'Új műszer'**
  String get newInstrumentButton;

  /// No description provided for @editInstrumentTitle.
  ///
  /// In hu, this message translates to:
  /// **'Műszer szerkesztése'**
  String get editInstrumentTitle;

  /// No description provided for @instrumentNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Műszer neve / típusa'**
  String get instrumentNameLabel;

  /// No description provided for @requiredFieldError.
  ///
  /// In hu, this message translates to:
  /// **'Kötelező'**
  String get requiredFieldError;

  /// No description provided for @serialNumberLabel.
  ///
  /// In hu, this message translates to:
  /// **'Sorozatszám'**
  String get serialNumberLabel;

  /// No description provided for @nextCalibrationLabel.
  ///
  /// In hu, this message translates to:
  /// **'Következő kalibráció dátuma'**
  String get nextCalibrationLabel;

  /// No description provided for @notSetLabel.
  ///
  /// In hu, this message translates to:
  /// **'Nincs megadva'**
  String get notSetLabel;

  /// No description provided for @calibrationFactorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kalibrációs tényező'**
  String get calibrationFactorLabel;

  /// No description provided for @modbusConnectedLabel.
  ///
  /// In hu, this message translates to:
  /// **'WiFi Modbus/TCP-n elérhető'**
  String get modbusConnectedLabel;

  /// No description provided for @modbusHostLabel.
  ///
  /// In hu, this message translates to:
  /// **'IP cím / host'**
  String get modbusHostLabel;

  /// No description provided for @modbusPortLabel.
  ///
  /// In hu, this message translates to:
  /// **'Port (pl. 502)'**
  String get modbusPortLabel;

  /// No description provided for @modbusUnitIdLabel.
  ///
  /// In hu, this message translates to:
  /// **'Modbus Unit ID (slave cím)'**
  String get modbusUnitIdLabel;

  /// No description provided for @modbusRegisterAddressLabel.
  ///
  /// In hu, this message translates to:
  /// **'Regiszter cím (pl. 294)'**
  String get modbusRegisterAddressLabel;

  /// No description provided for @modbusRegisterAddressHelper.
  ///
  /// In hu, this message translates to:
  /// **'A mért érték (float32) kezdő holding regisztere'**
  String get modbusRegisterAddressHelper;

  /// No description provided for @modbusGpsEnabledLabel.
  ///
  /// In hu, this message translates to:
  /// **'GPS pozíció olvasása Modbuson'**
  String get modbusGpsEnabledLabel;

  /// No description provided for @modbusGpsLatAddressLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szélesség regiszter (float32, alap: 426)'**
  String get modbusGpsLatAddressLabel;

  /// No description provided for @modbusGpsLonAddressLabel.
  ///
  /// In hu, this message translates to:
  /// **'Hosszúság regiszter (float32, alap: 428)'**
  String get modbusGpsLonAddressLabel;

  /// No description provided for @pickPositionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Pozíció kiválasztása'**
  String get pickPositionTitle;

  /// No description provided for @confirmPositionButton.
  ///
  /// In hu, this message translates to:
  /// **'Pozíció megerősítése'**
  String get confirmPositionButton;

  /// No description provided for @isotopeCalculatorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Izotóp kalkulátor'**
  String get isotopeCalculatorTitle;

  /// No description provided for @gammaConstantsDisclaimer.
  ///
  /// In hu, this message translates to:
  /// **'A Γ-állandók tájékoztató referenciaértékek. Hatósági jegyzőkönyvhöz ellenőrizd őket hiteles forrásból, mielőtt dokumentálod az eredményt.'**
  String get gammaConstantsDisclaimer;

  /// No description provided for @isotopeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Izotóp'**
  String get isotopeLabel;

  /// No description provided for @modeDoseFromActivity.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitásból\ndózisteljesítmény'**
  String get modeDoseFromActivity;

  /// No description provided for @modeActivityFromDose.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítményből\naktivitás'**
  String get modeActivityFromDose;

  /// No description provided for @distanceFromSourceLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolság a forrástól (m)'**
  String get distanceFromSourceLabel;

  /// No description provided for @activityLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás (MBq)'**
  String get activityLabel;

  /// No description provided for @measuredDoseRateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mért dózisteljesítmény (µSv/h)'**
  String get measuredDoseRateLabel;

  /// No description provided for @calculateButton.
  ///
  /// In hu, this message translates to:
  /// **'Számítás'**
  String get calculateButton;

  /// No description provided for @invalidDistanceError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy érvényes, pozitív távolságot (m).'**
  String get invalidDistanceError;

  /// No description provided for @invalidActivityError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy érvényes aktivitást (MBq).'**
  String get invalidActivityError;

  /// No description provided for @invalidDoseRateError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy érvényes dózisteljesítményt (µSv/h).'**
  String get invalidDoseRateError;

  /// No description provided for @calculationErrorMessage.
  ///
  /// In hu, this message translates to:
  /// **'Számítási hiba: {error}'**
  String calculationErrorMessage(String error);

  /// No description provided for @calculatedDoseRateResult.
  ///
  /// In hu, this message translates to:
  /// **'Számított dózisteljesítmény: {uSvH} µSv/h\n({nSvH} nSv/h)'**
  String calculatedDoseRateResult(String uSvH, String nSvH);

  /// No description provided for @calculatedActivityResult.
  ///
  /// In hu, this message translates to:
  /// **'Számított aktivitás: {mbq} MBq\n({gbq} GBq)'**
  String calculatedActivityResult(String mbq, String gbq);

  /// No description provided for @distanceToolTitle.
  ///
  /// In hu, this message translates to:
  /// **'Távolságmérés'**
  String get distanceToolTitle;

  /// No description provided for @locationServiceDisabledError.
  ///
  /// In hu, this message translates to:
  /// **'A helyszolgáltatás ki van kapcsolva.'**
  String get locationServiceDisabledError;

  /// No description provided for @locationPermissionDeniedError.
  ///
  /// In hu, this message translates to:
  /// **'Helymeghatározási jogosultság megtagadva.'**
  String get locationPermissionDeniedError;

  /// No description provided for @gpsErrorMessage.
  ///
  /// In hu, this message translates to:
  /// **'GPS hiba: {error}'**
  String gpsErrorMessage(String error);

  /// No description provided for @selectTargetFirstError.
  ///
  /// In hu, this message translates to:
  /// **'Előbb válaszd ki a célpontot.'**
  String get selectTargetFirstError;

  /// No description provided for @noGpsPositionError.
  ///
  /// In hu, this message translates to:
  /// **'Nincs GPS pozíció. Frissítsd, vagy válassz kiindulópontot.'**
  String get noGpsPositionError;

  /// No description provided for @selectStartPointError.
  ///
  /// In hu, this message translates to:
  /// **'Válassz kiindulópontot.'**
  String get selectStartPointError;

  /// No description provided for @selectTargetPointError.
  ///
  /// In hu, this message translates to:
  /// **'Válaszd ki a célpontot.'**
  String get selectTargetPointError;

  /// No description provided for @startFromCurrentPositionLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiindulópont: jelenlegi pozícióm'**
  String get startFromCurrentPositionLabel;

  /// No description provided for @noPositionFetchedYet.
  ///
  /// In hu, this message translates to:
  /// **'Nincs lekérve'**
  String get noPositionFetchedYet;

  /// No description provided for @refreshGpsButton.
  ///
  /// In hu, this message translates to:
  /// **'GPS frissítése'**
  String get refreshGpsButton;

  /// No description provided for @startPointLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiindulópont'**
  String get startPointLabel;

  /// No description provided for @targetPointLabel.
  ///
  /// In hu, this message translates to:
  /// **'Célpont'**
  String get targetPointLabel;

  /// No description provided for @liveTrackingLabel.
  ///
  /// In hu, this message translates to:
  /// **'Élő követés'**
  String get liveTrackingLabel;

  /// No description provided for @liveTrackingSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'Folyamatosan frissíti a távolságot és az irányt séta közben.'**
  String get liveTrackingSubtitle;

  /// No description provided for @calculateDistanceButton.
  ///
  /// In hu, this message translates to:
  /// **'Kiszámítás'**
  String get calculateDistanceButton;

  /// No description provided for @liveTrackingRunningHint.
  ///
  /// In hu, this message translates to:
  /// **'Élő követés fut — sétálj a nyíl irányába.'**
  String get liveTrackingRunningHint;

  /// No description provided for @sourceSearchTitle.
  ///
  /// In hu, this message translates to:
  /// **'Forráskereső'**
  String get sourceSearchTitle;

  /// No description provided for @measurementTypeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mérés típusa'**
  String get measurementTypeLabel;

  /// No description provided for @pointsRecordedForType.
  ///
  /// In hu, this message translates to:
  /// **'{count} rögzített pont ehhez a típushoz ezen a felmérésen belül.'**
  String pointsRecordedForType(int count);

  /// No description provided for @lowConfidenceWarning.
  ///
  /// In hu, this message translates to:
  /// **'Kevés pont (< 4) — a becslés bizonytalan, vegyél fel több mérést a keresési terület más-más pontjain.'**
  String get lowConfidenceWarning;

  /// No description provided for @gradientEstimateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Becsült gradiens: {value} {unit}/m'**
  String gradientEstimateLabel(String value, String unit);

  /// No description provided for @directionEstimateHint.
  ///
  /// In hu, this message translates to:
  /// **'Erre nő a mért érték a becslés szerint.'**
  String get directionEstimateHint;

  /// No description provided for @sourceSearchDisclaimer.
  ///
  /// In hu, this message translates to:
  /// **'A javasolt irány egyszerű lineáris gradiens-becslésen alapul a felmérésen belül eddig rögzített pontokból. Zajos terepi adatoknál, kevés pontnál, vagy ha a valódi forrás a mért terület méretéhez képest messze van, pontatlan lehet. Csak tájékoztató jellegű, nem helyettesíti a szakmai megítélést.'**
  String get sourceSearchDisclaimer;

  /// No description provided for @newMeasurementButton.
  ///
  /// In hu, this message translates to:
  /// **'Új mérés felvétele'**
  String get newMeasurementButton;

  /// No description provided for @mapTitle.
  ///
  /// In hu, this message translates to:
  /// **'Térkép'**
  String get mapTitle;

  /// No description provided for @noPointsRecordedYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs rögzített mérési pont.'**
  String get noPointsRecordedYet;

  /// No description provided for @saveScreenshotTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Képernyőkép mentése a jegyzőkönyvhöz'**
  String get saveScreenshotTooltip;

  /// No description provided for @screenshotSavedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Térkép elmentve — a jegyzőkönyv exportálásakor csatolva lesz.'**
  String get screenshotSavedMessage;

  /// No description provided for @screenshotErrorMessage.
  ///
  /// In hu, this message translates to:
  /// **'Képernyőkép hiba: {error}'**
  String screenshotErrorMessage(String error);

  /// No description provided for @valueLabel.
  ///
  /// In hu, this message translates to:
  /// **'Érték: {value} {unit}'**
  String valueLabel(String value, String unit);

  /// No description provided for @distanceFromSourceValue.
  ///
  /// In hu, this message translates to:
  /// **'Táv. forrástól: {value} m'**
  String distanceFromSourceValue(String value);

  /// No description provided for @timestampLabel.
  ///
  /// In hu, this message translates to:
  /// **'Időpont: {value}'**
  String timestampLabel(String value);

  /// No description provided for @sourcePositionLabel.
  ///
  /// In hu, this message translates to:
  /// **'Forrás pozíció'**
  String get sourcePositionLabel;

  /// No description provided for @editButton.
  ///
  /// In hu, this message translates to:
  /// **'Szerkesztés'**
  String get editButton;

  /// No description provided for @closeSurveyTitle.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés lezárása'**
  String get closeSurveyTitle;

  /// No description provided for @closeSurveyConfirm.
  ///
  /// In hu, this message translates to:
  /// **'Lezárás után a jegyzőkönyv a mai dátumot fogja mutatni befejezési időpontként. A pontokat ez nem zárolja, később is szerkesztheted őket.'**
  String get closeSurveyConfirm;

  /// No description provided for @closeSurveyButton.
  ///
  /// In hu, this message translates to:
  /// **'Lezárás'**
  String get closeSurveyButton;

  /// No description provided for @surveyClosedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés lezárva.'**
  String get surveyClosedMessage;

  /// No description provided for @listScreenshotSavedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Lista képernyőkép elmentve — a jegyzőkönyv exportálásakor csatolva lesz.'**
  String get listScreenshotSavedMessage;

  /// No description provided for @exportErrorMessage.
  ///
  /// In hu, this message translates to:
  /// **'Export hiba: {error}'**
  String exportErrorMessage(String error);

  /// No description provided for @importErrorMessage.
  ///
  /// In hu, this message translates to:
  /// **'Import hiba: {error}'**
  String importErrorMessage(String error);

  /// No description provided for @protocolShareSubject.
  ///
  /// In hu, this message translates to:
  /// **'Jegyzőkönyv – {title}'**
  String protocolShareSubject(String title);

  /// No description provided for @dataExportSubject.
  ///
  /// In hu, this message translates to:
  /// **'Mérési pontok (adat) – {title}'**
  String dataExportSubject(String title);

  /// No description provided for @csvExportSubject.
  ///
  /// In hu, this message translates to:
  /// **'Mérési pontok (CSV) – {title}'**
  String csvExportSubject(String title);

  /// No description provided for @importDoneTitle.
  ///
  /// In hu, this message translates to:
  /// **'Importálás kész'**
  String get importDoneTitle;

  /// No description provided for @importedPointsMessage.
  ///
  /// In hu, this message translates to:
  /// **'{points} pont importálva.\n{instruments} új műszer létrehozva.\n{sources} új sugárforrás létrehozva.'**
  String importedPointsMessage(int points, int instruments, int sources);

  /// No description provided for @okButton.
  ///
  /// In hu, this message translates to:
  /// **'Rendben'**
  String get okButton;

  /// No description provided for @toolsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Eszközök'**
  String get toolsTooltip;

  /// No description provided for @autoLogMenuItem.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus mérés'**
  String get autoLogMenuItem;

  /// No description provided for @captureListScreenshotMenuItem.
  ///
  /// In hu, this message translates to:
  /// **'Lista képernyőkép mentése'**
  String get captureListScreenshotMenuItem;

  /// No description provided for @exportProtocolMenuItem.
  ///
  /// In hu, this message translates to:
  /// **'Jegyzőkönyv exportálása'**
  String get exportProtocolMenuItem;

  /// No description provided for @exportJsonMenuItem.
  ///
  /// In hu, this message translates to:
  /// **'Pontok exportálása (adat, JSON)'**
  String get exportJsonMenuItem;

  /// No description provided for @exportCsvMenuItem.
  ///
  /// In hu, this message translates to:
  /// **'Pontok exportálása (táblázat, CSV)'**
  String get exportCsvMenuItem;

  /// No description provided for @importJsonMenuItem.
  ///
  /// In hu, this message translates to:
  /// **'Pontok importálása (JSON)'**
  String get importJsonMenuItem;

  /// No description provided for @newPointButton.
  ///
  /// In hu, this message translates to:
  /// **'Új pont'**
  String get newPointButton;

  /// No description provided for @sampleTakenListLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mintavétel · {date}'**
  String sampleTakenListLabel(String date);

  /// No description provided for @unknownModbusError.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen Modbus hiba.'**
  String get unknownModbusError;

  /// No description provided for @noValidPositionError.
  ///
  /// In hu, this message translates to:
  /// **'Nincs érvényes pozíció megadva.'**
  String get noValidPositionError;

  /// No description provided for @thresholdExceededTitle.
  ///
  /// In hu, this message translates to:
  /// **'Riasztási küszöb túllépve'**
  String get thresholdExceededTitle;

  /// No description provided for @thresholdExceededMessage.
  ///
  /// In hu, this message translates to:
  /// **'A mért érték ({value} {unit}) eléri vagy meghaladja a(z) {type} típushoz beállított küszöböt ({threshold} {unit}).'**
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  );

  /// No description provided for @newPointTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új mérési pont'**
  String get newPointTitle;

  /// No description provided for @editPointTitle.
  ///
  /// In hu, this message translates to:
  /// **'Pont szerkesztése'**
  String get editPointTitle;

  /// No description provided for @locationLabelFieldLabel.
  ///
  /// In hu, this message translates to:
  /// **'Helyszín megnevezése'**
  String get locationLabelFieldLabel;

  /// No description provided for @measuredValueLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mért érték'**
  String get measuredValueLabel;

  /// No description provided for @numberRequiredError.
  ///
  /// In hu, this message translates to:
  /// **'Számot adj meg'**
  String get numberRequiredError;

  /// No description provided for @unitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Egység'**
  String get unitLabel;

  /// No description provided for @instrumentLabel.
  ///
  /// In hu, this message translates to:
  /// **'Műszer'**
  String get instrumentLabel;

  /// No description provided for @addInstrumentTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Új műszer felvétele'**
  String get addInstrumentTooltip;

  /// No description provided for @queryingLabel.
  ///
  /// In hu, this message translates to:
  /// **'Lekérdezés...'**
  String get queryingLabel;

  /// No description provided for @modbusQueryButton.
  ///
  /// In hu, this message translates to:
  /// **'Modbus lekérdezés ({name})'**
  String modbusQueryButton(String name);

  /// No description provided for @sourcePositionSwitchLabel.
  ///
  /// In hu, this message translates to:
  /// **'Ez a forrás pozíció (max. érték)'**
  String get sourcePositionSwitchLabel;

  /// No description provided for @sampleTakenSwitchLabel.
  ///
  /// In hu, this message translates to:
  /// **'Fizikai mintavétel történt itt'**
  String get sampleTakenSwitchLabel;

  /// No description provided for @sampleContainerLabel.
  ///
  /// In hu, this message translates to:
  /// **'Edény azonosító'**
  String get sampleContainerLabel;

  /// No description provided for @sampleAmountLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mennyiség'**
  String get sampleAmountLabel;

  /// No description provided for @sampleMethodLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mintavétel módja'**
  String get sampleMethodLabel;

  /// No description provided for @notesLabel.
  ///
  /// In hu, this message translates to:
  /// **'Megjegyzés'**
  String get notesLabel;

  /// No description provided for @takePhotoLabel.
  ///
  /// In hu, this message translates to:
  /// **'Fotó készítése'**
  String get takePhotoLabel;

  /// No description provided for @retakePhotoLabel.
  ///
  /// In hu, this message translates to:
  /// **'Fotó cseréje'**
  String get retakePhotoLabel;

  /// No description provided for @chooseFromGalleryLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiválasztás a galériából'**
  String get chooseFromGalleryLabel;

  /// No description provided for @positionLabel.
  ///
  /// In hu, this message translates to:
  /// **'Pozíció'**
  String get positionLabel;

  /// No description provided for @latitudeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szélesség (lat)'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Hosszúság (lon)'**
  String get longitudeLabel;

  /// No description provided for @invalidValueError.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen'**
  String get invalidValueError;

  /// No description provided for @liveGpsButton.
  ///
  /// In hu, this message translates to:
  /// **'Élő GPS'**
  String get liveGpsButton;

  /// No description provided for @onMapButton.
  ///
  /// In hu, this message translates to:
  /// **'Térképen'**
  String get onMapButton;

  /// No description provided for @autoLogDisclaimer.
  ///
  /// In hu, this message translates to:
  /// **'A rögzítés csak addig fut, amíg ez a képernyő nyitva van. Ha a telefon kikapcsol vagy másik appra váltasz, a mérés szünetel — visszatéréskor újra kell indítani.'**
  String get autoLogDisclaimer;

  /// No description provided for @noModbusInstrumentMessage.
  ///
  /// In hu, this message translates to:
  /// **'Nincs Modbus/TCP-n elérhető műszer beállítva. Vegyél fel egyet a Műszerek listában (WiFi Modbus/TCP kapcsoló be, IP, Unit ID és regiszter cím kitöltve).'**
  String get noModbusInstrumentMessage;

  /// No description provided for @triggerModeTime.
  ///
  /// In hu, this message translates to:
  /// **'Idő alapú'**
  String get triggerModeTime;

  /// No description provided for @triggerModeDistance.
  ///
  /// In hu, this message translates to:
  /// **'Táv alapú'**
  String get triggerModeDistance;

  /// No description provided for @intervalSecondsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Időköz (másodperc)'**
  String get intervalSecondsLabel;

  /// No description provided for @distanceIntervalLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolságköz (méter)'**
  String get distanceIntervalLabel;

  /// No description provided for @connectingLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolódás...'**
  String get connectingLabel;

  /// No description provided for @stopButton.
  ///
  /// In hu, this message translates to:
  /// **'Leállítás'**
  String get stopButton;

  /// No description provided for @loggingRunningLabel.
  ///
  /// In hu, this message translates to:
  /// **'Rögzítés fut...'**
  String get loggingRunningLabel;

  /// No description provided for @loggingStoppedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Rögzítés leállítva'**
  String get loggingStoppedLabel;

  /// No description provided for @capturedPointsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Rögzített pontok: {count}'**
  String capturedPointsLabel(int count);

  /// No description provided for @lastValueLabel.
  ///
  /// In hu, this message translates to:
  /// **'Utolsó érték: {value} {unit}'**
  String lastValueLabel(String value, String unit);

  /// No description provided for @failedReadingsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Sikertelen olvasások: {count}'**
  String failedReadingsLabel(int count);

  /// No description provided for @lastErrorSuffix.
  ///
  /// In hu, this message translates to:
  /// **' (utolsó hiba: {error})'**
  String lastErrorSuffix(String error);

  /// No description provided for @intervalMinError.
  ///
  /// In hu, this message translates to:
  /// **'Az időköznek legalább 1 másodpercnek kell lennie.'**
  String get intervalMinError;

  /// No description provided for @distanceMinError.
  ///
  /// In hu, this message translates to:
  /// **'A távolságnak legalább 1 méternek kell lennie.'**
  String get distanceMinError;

  /// No description provided for @modbusConnectErrorMessage.
  ///
  /// In hu, this message translates to:
  /// **'Modbus kapcsolódási hiba: {error}'**
  String modbusConnectErrorMessage(String error);

  /// No description provided for @csvHeaderSerialNumber.
  ///
  /// In hu, this message translates to:
  /// **'Sorszám'**
  String get csvHeaderSerialNumber;

  /// No description provided for @csvHeaderLocation.
  ///
  /// In hu, this message translates to:
  /// **'Helyszín'**
  String get csvHeaderLocation;

  /// No description provided for @csvHeaderType.
  ///
  /// In hu, this message translates to:
  /// **'Típus'**
  String get csvHeaderType;

  /// No description provided for @csvHeaderValue.
  ///
  /// In hu, this message translates to:
  /// **'Érték'**
  String get csvHeaderValue;

  /// No description provided for @csvHeaderUnit.
  ///
  /// In hu, this message translates to:
  /// **'Egység'**
  String get csvHeaderUnit;

  /// No description provided for @csvHeaderDistanceFromSource.
  ///
  /// In hu, this message translates to:
  /// **'Táv. forrástól (m)'**
  String get csvHeaderDistanceFromSource;

  /// No description provided for @csvHeaderInstrument.
  ///
  /// In hu, this message translates to:
  /// **'Műszer'**
  String get csvHeaderInstrument;

  /// No description provided for @csvHeaderGpsLatitude.
  ///
  /// In hu, this message translates to:
  /// **'GPS szélesség'**
  String get csvHeaderGpsLatitude;

  /// No description provided for @csvHeaderGpsLongitude.
  ///
  /// In hu, this message translates to:
  /// **'GPS hosszúság'**
  String get csvHeaderGpsLongitude;

  /// No description provided for @csvHeaderGpsAccuracy.
  ///
  /// In hu, this message translates to:
  /// **'GPS pontosság (m)'**
  String get csvHeaderGpsAccuracy;

  /// No description provided for @csvHeaderTimestamp.
  ///
  /// In hu, this message translates to:
  /// **'Időpont'**
  String get csvHeaderTimestamp;

  /// No description provided for @csvHeaderSample.
  ///
  /// In hu, this message translates to:
  /// **'Mintavétel'**
  String get csvHeaderSample;

  /// No description provided for @csvHeaderNotes.
  ///
  /// In hu, this message translates to:
  /// **'Megjegyzés'**
  String get csvHeaderNotes;

  /// No description provided for @csvHeaderEstimatedActivity.
  ///
  /// In hu, this message translates to:
  /// **'Becsült aktivitás (mérésből)'**
  String get csvHeaderEstimatedActivity;

  /// No description provided for @csvHeaderAttachedSources.
  ///
  /// In hu, this message translates to:
  /// **'Hozzárendelt forrás(ok)'**
  String get csvHeaderAttachedSources;

  /// No description provided for @csvHeaderCalculatedDoseRate.
  ///
  /// In hu, this message translates to:
  /// **'Számított dózisteljesítmény (µSv/h)'**
  String get csvHeaderCalculatedDoseRate;

  /// No description provided for @csvHeaderDoseRateDifference.
  ///
  /// In hu, this message translates to:
  /// **'Eltérés (µSv/h)'**
  String get csvHeaderDoseRateDifference;

  /// No description provided for @csvYes.
  ///
  /// In hu, this message translates to:
  /// **'igen'**
  String get csvYes;

  /// No description provided for @csvNo.
  ///
  /// In hu, this message translates to:
  /// **'nem'**
  String get csvNo;

  /// No description provided for @importUnknownTypeWarning.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen mérés-típus kihagyva egy ponton.'**
  String get importUnknownTypeWarning;

  /// No description provided for @importMissingGpsWarning.
  ///
  /// In hu, this message translates to:
  /// **'Hiányzó GPS-koordináta miatt kihagyva egy pont.'**
  String get importMissingGpsWarning;

  /// No description provided for @manageSourcesLabel.
  ///
  /// In hu, this message translates to:
  /// **'Radioaktív forrás(ok) kezelése'**
  String get manageSourcesLabel;

  /// No description provided for @sourcesCountLabel.
  ///
  /// In hu, this message translates to:
  /// **'{count} forrás'**
  String sourcesCountLabel(int count);

  /// No description provided for @radiationSourcesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Források'**
  String get radiationSourcesTitle;

  /// No description provided for @newSourceButton.
  ///
  /// In hu, this message translates to:
  /// **'Forrás hozzáadása'**
  String get newSourceButton;

  /// No description provided for @newSourceTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új forrás'**
  String get newSourceTitle;

  /// No description provided for @editSourceTitle.
  ///
  /// In hu, this message translates to:
  /// **'Forrás szerkesztése'**
  String get editSourceTitle;

  /// No description provided for @noSourcesRecordedYet.
  ///
  /// In hu, this message translates to:
  /// **'Ehhez a ponthoz még nincs forrás hozzárendelve.'**
  String get noSourcesRecordedYet;

  /// No description provided for @sourcesTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Források'**
  String get sourcesTooltip;

  /// No description provided for @pointSourcesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Forrás(ok) a ponton'**
  String get pointSourcesTitle;

  /// No description provided for @attachSourceButton.
  ///
  /// In hu, this message translates to:
  /// **'Forrás hozzárendelése'**
  String get attachSourceButton;

  /// No description provided for @pickSourceTitle.
  ///
  /// In hu, this message translates to:
  /// **'Forrás kiválasztása'**
  String get pickSourceTitle;

  /// No description provided for @noSourcesToAttach.
  ///
  /// In hu, this message translates to:
  /// **'Nincs még felvehető forrás — vedd fel előbb a főoldali Források listában.'**
  String get noSourcesToAttach;

  /// No description provided for @noSourcesYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs felvéve forrás. Adj hozzá egyet a + gombbal.'**
  String get noSourcesYet;

  /// No description provided for @enterDistanceDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Távolság megadása'**
  String get enterDistanceDialogTitle;

  /// No description provided for @detachSourceConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Forrás leválasztása'**
  String get detachSourceConfirmTitle;

  /// No description provided for @detachSourceConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Leválasztod a \"{identifier}\" forrást erről a pontról? A forrás a nyilvántartásban megmarad, csak ez a hozzárendelés törlődik.'**
  String detachSourceConfirmMessage(String identifier);

  /// No description provided for @detachButton.
  ///
  /// In hu, this message translates to:
  /// **'Leválasztás'**
  String get detachButton;

  /// No description provided for @totalCalculatedDoseRateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Források összesített, számított dózisteljesítménye'**
  String get totalCalculatedDoseRateLabel;

  /// No description provided for @sourcesUnknownNuclideSkippedNote.
  ///
  /// In hu, this message translates to:
  /// **'{count} forrás nuklidja ismeretlen — nem szerepel az összegben.'**
  String sourcesUnknownNuclideSkippedNote(int count);

  /// No description provided for @sourceIdentifierLabel.
  ///
  /// In hu, this message translates to:
  /// **'Egyedi azonosító'**
  String get sourceIdentifierLabel;

  /// No description provided for @nuclideLabel.
  ///
  /// In hu, this message translates to:
  /// **'Nuklid'**
  String get nuclideLabel;

  /// No description provided for @customNuclideOption.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb (kézi megadás)'**
  String get customNuclideOption;

  /// No description provided for @customNuclideNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Nuklid neve'**
  String get customNuclideNameLabel;

  /// No description provided for @activityAtManufactureLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás gyártáskor (MBq)'**
  String get activityAtManufactureLabel;

  /// No description provided for @activityErrorPercentLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás hibája (±%)'**
  String get activityErrorPercentLabel;

  /// No description provided for @manufactureDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Gyártás dátuma'**
  String get manufactureDateLabel;

  /// No description provided for @serviceLifeExpiryDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szolgálati idő lejárata'**
  String get serviceLifeExpiryDateLabel;

  /// No description provided for @nextInspectionDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Következő ellenőrzés dátuma'**
  String get nextInspectionDateLabel;

  /// No description provided for @sourceDistanceLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolság a mérési ponttól (m)'**
  String get sourceDistanceLabel;

  /// No description provided for @asOfDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás dátuma (számításhoz)'**
  String get asOfDateLabel;

  /// No description provided for @currentActivityResultLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktuális aktivitás'**
  String get currentActivityResultLabel;

  /// No description provided for @calculatedDoseRateResultLabel.
  ///
  /// In hu, this message translates to:
  /// **'Számított dózisteljesítmény'**
  String get calculatedDoseRateResultLabel;

  /// No description provided for @measuredDoseRateResultLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mért dózisteljesítmény (a ponton)'**
  String get measuredDoseRateResultLabel;

  /// No description provided for @doseRateDifferenceResultLabel.
  ///
  /// In hu, this message translates to:
  /// **'Eltérés (mért − számított)'**
  String get doseRateDifferenceResultLabel;

  /// No description provided for @unknownNuclideDecayWarning.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen nuklid: nincs tárolt felezési idő és gamma-állandó, ezért az aktuális aktivitás és a számított dózisteljesítmény nem határozható meg. A forrás adatai elmenthetők, de az összehasonlítás kimarad.'**
  String get unknownNuclideDecayWarning;

  /// No description provided for @noMeasuredValueForComparisonNote.
  ///
  /// In hu, this message translates to:
  /// **'A ponthoz nincs rögzített mért érték — az összehasonlítás nem végezhető el.'**
  String get noMeasuredValueForComparisonNote;

  /// No description provided for @unrecognizedUnitForComparisonNote.
  ///
  /// In hu, this message translates to:
  /// **'A mérési egység ({unit}) nem alakítható át automatikusan — az összehasonlítás nem végezhető el.'**
  String unrecognizedUnitForComparisonNote(String unit);

  /// No description provided for @sourceExpiredWarning.
  ///
  /// In hu, this message translates to:
  /// **'A forrás szolgálati ideje lejárt.'**
  String get sourceExpiredWarning;

  /// No description provided for @deleteSourceConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Forrás törlése'**
  String get deleteSourceConfirmTitle;

  /// No description provided for @deleteSourceConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd a \"{identifier}\" azonosítójú forrást a nyilvántartásból? Minden ponthoz rendelt hozzárendelése is törlődik vele. A művelet nem vonható vissza.'**
  String deleteSourceConfirmMessage(String identifier);

  /// No description provided for @sourceCalculationDisclaimer.
  ///
  /// In hu, this message translates to:
  /// **'A számított értékek tájékoztató jellegűek, referencia gamma-állandók és felezési idők alapján. Hatósági jegyzőkönyvhöz ellenőrizd hiteles forrásból.'**
  String get sourceCalculationDisclaimer;

  /// No description provided for @estimatedActivityFromMeasurementLabel.
  ///
  /// In hu, this message translates to:
  /// **'Becsült aktivitás (a mért értékből)'**
  String get estimatedActivityFromMeasurementLabel;

  /// No description provided for @personsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Személyek'**
  String get personsTooltip;

  /// No description provided for @personsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személyek'**
  String get personsTitle;

  /// No description provided for @newPersonButton.
  ///
  /// In hu, this message translates to:
  /// **'Személy hozzáadása'**
  String get newPersonButton;

  /// No description provided for @newPersonTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új személy'**
  String get newPersonTitle;

  /// No description provided for @editPersonTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személy szerkesztése'**
  String get editPersonTitle;

  /// No description provided for @noPersonsYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs felvéve személy. Adj hozzá egyet a + gombbal.'**
  String get noPersonsYet;

  /// No description provided for @personNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Név'**
  String get personNameLabel;

  /// No description provided for @medicalExamExpiryDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Orvosi vizsgálat érvényessége'**
  String get medicalExamExpiryDateLabel;

  /// No description provided for @trainingExpiryDateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Oktatás érvényessége'**
  String get trainingExpiryDateLabel;

  /// No description provided for @deletePersonConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személy törlése'**
  String get deletePersonConfirmTitle;

  /// No description provided for @deletePersonConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd \"{name}\" nevű személyt a nyilvántartásból? Minden felméréshez rendelt hozzárendelése is törlődik vele. A művelet nem vonható vissza.'**
  String deletePersonConfirmMessage(String name);

  /// No description provided for @sessionPersonsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Felmérésen résztvevő személyek'**
  String get sessionPersonsTitle;

  /// No description provided for @noPersonsAttachedYet.
  ///
  /// In hu, this message translates to:
  /// **'Ehhez a felméréshez még nincs személy hozzárendelve.'**
  String get noPersonsAttachedYet;

  /// No description provided for @attachPersonButton.
  ///
  /// In hu, this message translates to:
  /// **'Személy hozzárendelése'**
  String get attachPersonButton;

  /// No description provided for @pickPersonTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személy kiválasztása'**
  String get pickPersonTitle;

  /// No description provided for @noPersonsToAttach.
  ///
  /// In hu, this message translates to:
  /// **'Nincs még felvehető személy — vedd fel előbb a főoldali Személyek listában.'**
  String get noPersonsToAttach;

  /// No description provided for @detachPersonConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személy leválasztása'**
  String get detachPersonConfirmTitle;

  /// No description provided for @detachPersonConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Leválasztod \"{name}\" nevű személyt erről a felmérésről? A személy a nyilvántartásban megmarad, csak ez a hozzárendelés törlődik.'**
  String detachPersonConfirmMessage(String name);

  /// No description provided for @expiryNotificationsSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Lejárati értesítések'**
  String get expiryNotificationsSectionTitle;

  /// No description provided for @expiryNotificationsSwitchTitle.
  ///
  /// In hu, this message translates to:
  /// **'Értesítés a lejáratokról'**
  String get expiryNotificationsSwitchTitle;

  /// No description provided for @expiryNotificationsSwitchSubtitle.
  ///
  /// In hu, this message translates to:
  /// **'A források (szolgálati idő, ellenőrzés) és a személyek (orvosi vizsgálat, oktatás) jövőbeli lejárati dátumairól, reggel 8 órakor.'**
  String get expiryNotificationsSwitchSubtitle;

  /// No description provided for @expiryLeadTimeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mennyivel előbb jöjjön az értesítés'**
  String get expiryLeadTimeLabel;

  /// No description provided for @expiryLeadSameDay.
  ///
  /// In hu, this message translates to:
  /// **'Aznap'**
  String get expiryLeadSameDay;

  /// No description provided for @expiryLeadOneDay.
  ///
  /// In hu, this message translates to:
  /// **'1 nappal előtte'**
  String get expiryLeadOneDay;

  /// No description provided for @expiryLeadTwoDays.
  ///
  /// In hu, this message translates to:
  /// **'2 nappal előtte'**
  String get expiryLeadTwoDays;

  /// No description provided for @expiryLeadOneWeek.
  ///
  /// In hu, this message translates to:
  /// **'1 héttel előtte'**
  String get expiryLeadOneWeek;

  /// No description provided for @expiryNotificationsPermissionDenied.
  ///
  /// In hu, this message translates to:
  /// **'Az értesítések le vannak tiltva a telefon beállításaiban, engedélyezd ott a RadRecon értesítéseit.'**
  String get expiryNotificationsPermissionDenied;

  /// No description provided for @expiryNotificationTitleToday.
  ///
  /// In hu, this message translates to:
  /// **'Ma lejár'**
  String get expiryNotificationTitleToday;

  /// No description provided for @expiryNotificationTitleUpcoming.
  ///
  /// In hu, this message translates to:
  /// **'Hamarosan lejár'**
  String get expiryNotificationTitleUpcoming;

  /// No description provided for @expiryNotificationChannelName.
  ///
  /// In hu, this message translates to:
  /// **'Lejárati értesítések'**
  String get expiryNotificationChannelName;

  /// No description provided for @expiryNotificationChannelDescription.
  ///
  /// In hu, this message translates to:
  /// **'Források és személyek közelgő lejárati dátumai'**
  String get expiryNotificationChannelDescription;

  /// No description provided for @importRegistryCsv.
  ///
  /// In hu, this message translates to:
  /// **'CSV importálása'**
  String get importRegistryCsv;

  /// No description provided for @exportRegistryCsv.
  ///
  /// In hu, this message translates to:
  /// **'CSV exportálása'**
  String get exportRegistryCsv;

  /// No description provided for @registryCsvExportSubject.
  ///
  /// In hu, this message translates to:
  /// **'RadRecon nyilvántartás (CSV)'**
  String get registryCsvExportSubject;

  /// No description provided for @duplicatePolicyTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ha már létezik ilyen rekord'**
  String get duplicatePolicyTitle;

  /// No description provided for @duplicateReplace.
  ///
  /// In hu, this message translates to:
  /// **'Meglévő rekord cseréje'**
  String get duplicateReplace;

  /// No description provided for @duplicateSkip.
  ///
  /// In hu, this message translates to:
  /// **'Az egyező rekord kihagyása'**
  String get duplicateSkip;

  /// No description provided for @duplicateKeep.
  ///
  /// In hu, this message translates to:
  /// **'Importálás duplikátumként'**
  String get duplicateKeep;

  /// No description provided for @registryImportSummary.
  ///
  /// In hu, this message translates to:
  /// **'Importálva: {imported}, cserélve: {replaced}, kihagyva: {skipped}'**
  String registryImportSummary(int imported, int replaced, int skipped);

  /// No description provided for @modbusTestConnectionButton.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolat tesztelése'**
  String get modbusTestConnectionButton;

  /// No description provided for @modbusTestingLabel.
  ///
  /// In hu, this message translates to:
  /// **'Tesztelés...'**
  String get modbusTestingLabel;

  /// No description provided for @modbusTestSuccessTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolat sikeres'**
  String get modbusTestSuccessTitle;

  /// No description provided for @modbusTestFailureTitle.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolat meghiúsult'**
  String get modbusTestFailureTitle;

  /// No description provided for @modbusTestValue.
  ///
  /// In hu, this message translates to:
  /// **'Érték: {value}'**
  String modbusTestValue(String value);

  /// No description provided for @modbusTestPosition.
  ///
  /// In hu, this message translates to:
  /// **'Szél: {lat}, Hossz: {lon}'**
  String modbusTestPosition(String lat, String lon);

  /// No description provided for @missingFieldMessage.
  ///
  /// In hu, this message translates to:
  /// **'Kérjük töltse ki: {field}'**
  String missingFieldMessage(String field);

  /// No description provided for @errorTitle.
  ///
  /// In hu, this message translates to:
  /// **'Hiba'**
  String get errorTitle;

  /// No description provided for @modbusReadErrorWithCode.
  ///
  /// In hu, this message translates to:
  /// **'Modbus hiba a kiolvasás során: {code}'**
  String modbusReadErrorWithCode(String code);

  /// No description provided for @instrumentDidNotSendValidValue.
  ///
  /// In hu, this message translates to:
  /// **'A műszer nem küldött érvényes értéket.'**
  String get instrumentDidNotSendValidValue;

  /// No description provided for @gpsPositionReadFailed.
  ///
  /// In hu, this message translates to:
  /// **'A GPS pozíció kiolvasása a műszerből sikertelen.'**
  String get gpsPositionReadFailed;

  /// No description provided for @instrumentIPAddressNotSet.
  ///
  /// In hu, this message translates to:
  /// **'Nincs megadva a műszer IP-címe.'**
  String get instrumentIPAddressNotSet;

  /// No description provided for @modbusUnitIdNotSet.
  ///
  /// In hu, this message translates to:
  /// **'Nincs megadva a Modbus Unit ID.'**
  String get modbusUnitIdNotSet;

  /// No description provided for @registerAddressNotSet.
  ///
  /// In hu, this message translates to:
  /// **'Nincs megadva a regiszter cím.'**
  String get registerAddressNotSet;

  /// No description provided for @failedToConnectToInstrument.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült kapcsolódni a műszerhez.'**
  String get failedToConnectToInstrument;

  /// No description provided for @connectionErrorWithDetails.
  ///
  /// In hu, this message translates to:
  /// **'Kapcsolódási hiba: {error}'**
  String connectionErrorWithDetails(String error);

  /// No description provided for @modbusAccessIncomplete.
  ///
  /// In hu, this message translates to:
  /// **'A műszerhez nincs teljesen kitöltve a Modbus elérhetőség (IP, Unit ID, regiszter cím).'**
  String get modbusAccessIncomplete;

  /// No description provided for @noDisplayableContentForScreenshot.
  ///
  /// In hu, this message translates to:
  /// **'Nincs megjeleníthető tartalom a képernyőképhez.'**
  String get noDisplayableContentForScreenshot;

  /// No description provided for @failedToConvertScreenshotToPng.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült PNG-vé alakítani a képernyőképet.'**
  String get failedToConvertScreenshotToPng;

  /// No description provided for @doseSourceOnline.
  ///
  /// In hu, this message translates to:
  /// **'Online (detektorból)'**
  String get doseSourceOnline;

  /// No description provided for @doseSourceManual.
  ///
  /// In hu, this message translates to:
  /// **'Manuális'**
  String get doseSourceManual;

  /// No description provided for @doseSourcePassive.
  ///
  /// In hu, this message translates to:
  /// **'Passzív dozimetria'**
  String get doseSourcePassive;

  /// No description provided for @annualDoseLabel.
  ///
  /// In hu, this message translates to:
  /// **'{year}. évi dózis'**
  String annualDoseLabel(int year);

  /// No description provided for @doseYearLabel.
  ///
  /// In hu, this message translates to:
  /// **'Év'**
  String get doseYearLabel;

  /// No description provided for @doseBreakdownLabel.
  ///
  /// In hu, this message translates to:
  /// **'online {online} · manuális {manual} · passzív {passive}'**
  String doseBreakdownLabel(String online, String manual, String passive);

  /// No description provided for @personDosesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dózisok – {name}'**
  String personDosesTitle(String name);

  /// No description provided for @personDosesTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Dózisok kezelése'**
  String get personDosesTooltip;

  /// No description provided for @noDosesYet.
  ///
  /// In hu, this message translates to:
  /// **'Ebben az évben még nincs dózis-bejegyzés.'**
  String get noDosesYet;

  /// No description provided for @addPassiveDoseButton.
  ///
  /// In hu, this message translates to:
  /// **'Passzív dozimetria rögzítése'**
  String get addPassiveDoseButton;

  /// No description provided for @newPassiveDoseTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új passzív dozimetria'**
  String get newPassiveDoseTitle;

  /// No description provided for @editDoseTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dózis szerkesztése'**
  String get editDoseTitle;

  /// No description provided for @doseValueLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dózis'**
  String get doseValueLabel;

  /// No description provided for @dosePeriodStartLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiértékelési időszak kezdete'**
  String get dosePeriodStartLabel;

  /// No description provided for @dosePeriodEndLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiértékelési időszak vége'**
  String get dosePeriodEndLabel;

  /// No description provided for @dosePeriodEndBeforeStartError.
  ///
  /// In hu, this message translates to:
  /// **'A vég nem lehet a kezdet előtt.'**
  String get dosePeriodEndBeforeStartError;

  /// No description provided for @doseTotalLabel.
  ///
  /// In hu, this message translates to:
  /// **'Összesen'**
  String get doseTotalLabel;

  /// No description provided for @doseDeleteConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dózis-bejegyzés törlése'**
  String get doseDeleteConfirmTitle;

  /// No description provided for @doseDeleteConfirmMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd ezt a dózis-bejegyzést? A művelet nem vonható vissza.'**
  String get doseDeleteConfirmMessage;

  /// No description provided for @sessionDoseDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'{name} dózisa'**
  String sessionDoseDialogTitle(String name);

  /// No description provided for @onlineDoseLabel.
  ///
  /// In hu, this message translates to:
  /// **'Online dózis'**
  String get onlineDoseLabel;

  /// No description provided for @manualDoseLabel.
  ///
  /// In hu, this message translates to:
  /// **'Manuális dózis'**
  String get manualDoseLabel;

  /// No description provided for @closeSurveyDosesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dózisok ellenőrzése'**
  String get closeSurveyDosesTitle;

  /// No description provided for @closeSurveyDosesHint.
  ///
  /// In hu, this message translates to:
  /// **'Lezárás előtt ellenőrizheted vagy korrigálhatod a résztvevők dózisát.'**
  String get closeSurveyDosesHint;

  /// No description provided for @autoLogDoseSaved.
  ///
  /// In hu, this message translates to:
  /// **'Dózis rögzítve {count} személynek: {dose}'**
  String autoLogDoseSaved(int count, String dose);

  /// No description provided for @autoLogDoseNoPersons.
  ///
  /// In hu, this message translates to:
  /// **'A mért dózis ({dose}) nem lett elmentve, mert a felméréshez nincs személy rendelve.'**
  String autoLogDoseNoPersons(String dose);

  /// No description provided for @autoLogDoseLabel.
  ///
  /// In hu, this message translates to:
  /// **'Integrált dózis: {dose}'**
  String autoLogDoseLabel(String dose);

  /// No description provided for @autoLogDoseGaps.
  ///
  /// In hu, this message translates to:
  /// **'{count} hosszabb adatkiesés a mérésben'**
  String autoLogDoseGaps(int count);

  /// No description provided for @autoLogDoseOnlyDoseRate.
  ///
  /// In hu, this message translates to:
  /// **'A dózis csak dózisteljesítmény típusú mérésből számolható és menthető.'**
  String get autoLogDoseOnlyDoseRate;

  /// No description provided for @importPersonDosesCsv.
  ///
  /// In hu, this message translates to:
  /// **'Dózisok importálása (CSV)'**
  String get importPersonDosesCsv;

  /// No description provided for @exportPersonDosesCsv.
  ///
  /// In hu, this message translates to:
  /// **'Dózisok exportálása (CSV)'**
  String get exportPersonDosesCsv;

  /// No description provided for @dataManagementSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Adatkezelés'**
  String get dataManagementSectionTitle;

  /// No description provided for @saveDatabaseButton.
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis mentése fájlba'**
  String get saveDatabaseButton;

  /// No description provided for @loadDatabaseButton.
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis betöltése fájlból'**
  String get loadDatabaseButton;

  /// No description provided for @clearDatabaseButton.
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis törlése'**
  String get clearDatabaseButton;

  /// No description provided for @companySwitchButton.
  ///
  /// In hu, this message translates to:
  /// **'Cégváltás'**
  String get companySwitchButton;

  /// No description provided for @dataManagementHint.
  ///
  /// In hu, this message translates to:
  /// **'A mentésfájl tartalmazza az összes adatot a fotókkal együtt, így új telefonra költözéshez vagy több cég adatainak külön kezeléséhez is használható.'**
  String get dataManagementHint;

  /// No description provided for @saveDatabaseSubject.
  ///
  /// In hu, this message translates to:
  /// **'RadRecon adatbázis mentés'**
  String get saveDatabaseSubject;

  /// No description provided for @databaseSavedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis elmentve: {path}'**
  String databaseSavedMessage(String path);

  /// No description provided for @loadDatabaseConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis betöltése'**
  String get loadDatabaseConfirmTitle;

  /// No description provided for @loadDatabaseConfirmBody.
  ///
  /// In hu, this message translates to:
  /// **'A betöltés felülírja az eszközön lévő összes jelenlegi adatot. Ha szükség van rájuk, előbb mentsd el őket. Folytatod?'**
  String get loadDatabaseConfirmBody;

  /// No description provided for @loadButton.
  ///
  /// In hu, this message translates to:
  /// **'Betöltés'**
  String get loadButton;

  /// No description provided for @databaseLoadedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Betöltve: {name}'**
  String databaseLoadedMessage(String name);

  /// No description provided for @clearDatabaseConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Adatbázis törlése'**
  String get clearDatabaseConfirmTitle;

  /// No description provided for @clearDatabaseConfirmBody.
  ///
  /// In hu, this message translates to:
  /// **'Az összes felmérés, mérési pont, műszer, forrás, személy és fotó véglegesen törlődik az eszközről. Ez nem vonható vissza — előbb készíts mentést!'**
  String get clearDatabaseConfirmBody;

  /// No description provided for @databaseClearedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Az adatbázis törölve.'**
  String get databaseClearedMessage;

  /// No description provided for @companySwitchTitle.
  ///
  /// In hu, this message translates to:
  /// **'Cégváltás'**
  String get companySwitchTitle;

  /// No description provided for @activeCompanyLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktív cég'**
  String get activeCompanyLabel;

  /// No description provided for @companiesFolderLabel.
  ///
  /// In hu, this message translates to:
  /// **'Cégek mappája'**
  String get companiesFolderLabel;

  /// No description provided for @chooseFolderButton.
  ///
  /// In hu, this message translates to:
  /// **'Mappa kiválasztása'**
  String get chooseFolderButton;

  /// No description provided for @resetFolderButton.
  ///
  /// In hu, this message translates to:
  /// **'Vissza az alapértelmezett mappához'**
  String get resetFolderButton;

  /// No description provided for @noCompaniesYet.
  ///
  /// In hu, this message translates to:
  /// **'Ebben a mappában még nincs mentett cég. Az aktív cég az első váltáskor automatikusan elmentődik, vagy hozz létre újat / adj hozzá mentésfájlt a felső gombokkal.'**
  String get noCompaniesYet;

  /// No description provided for @companyBackupInfo.
  ///
  /// In hu, this message translates to:
  /// **'Mentve: {date}'**
  String companyBackupInfo(String date);

  /// No description provided for @newCompanyButton.
  ///
  /// In hu, this message translates to:
  /// **'Új cég'**
  String get newCompanyButton;

  /// No description provided for @newCompanyDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új cég létrehozása'**
  String get newCompanyDialogTitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Cég neve'**
  String get companyNameLabel;

  /// No description provided for @companyNameExistsMessage.
  ///
  /// In hu, this message translates to:
  /// **'Ilyen nevű cég már létezik.'**
  String get companyNameExistsMessage;

  /// No description provided for @createButton.
  ///
  /// In hu, this message translates to:
  /// **'Létrehozás'**
  String get createButton;

  /// No description provided for @addCompanyFromFileButton.
  ///
  /// In hu, this message translates to:
  /// **'Cég hozzáadása mentésfájlból'**
  String get addCompanyFromFileButton;

  /// No description provided for @companySwitchConfirmTitle.
  ///
  /// In hu, this message translates to:
  /// **'Cégváltás'**
  String get companySwitchConfirmTitle;

  /// No description provided for @companySwitchConfirmBody.
  ///
  /// In hu, this message translates to:
  /// **'Átváltasz erre: {company}? A jelenlegi adatok automatikusan elmentődnek a(z) {active} cég alatt.'**
  String companySwitchConfirmBody(String company, String active);

  /// No description provided for @companySwitchAction.
  ///
  /// In hu, this message translates to:
  /// **'Váltás'**
  String get companySwitchAction;

  /// No description provided for @companySwitchedMessage.
  ///
  /// In hu, this message translates to:
  /// **'Aktív cég: {name}'**
  String companySwitchedMessage(String name);

  /// No description provided for @deleteCompanyBackupTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mentés törlése'**
  String get deleteCompanyBackupTitle;

  /// No description provided for @deleteCompanyBackupBody.
  ///
  /// In hu, this message translates to:
  /// **'Törlöd a(z) {name} cég mentését a mappából? Az éppen betöltött adatot ez nem érinti.'**
  String deleteCompanyBackupBody(String name);

  /// No description provided for @importPersonCsv.
  ///
  /// In hu, this message translates to:
  /// **'Személyek importálása (CSV)'**
  String get importPersonCsv;

  /// No description provided for @exportPersonCsv.
  ///
  /// In hu, this message translates to:
  /// **'Személyek exportálása (CSV)'**
  String get exportPersonCsv;

  /// No description provided for @privateFolderHint.
  ///
  /// In hu, this message translates to:
  /// **'Az app jelenleg a saját, más appból nem elérhető mappáját használja. Válassz egy mappát (pl. Letöltések vagy Google Drive), hogy a mentéseket a fájlkezelőből is elérd.'**
  String get privateFolderHint;

  /// No description provided for @contributorsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Közreműködők'**
  String get contributorsTitle;

  /// No description provided for @contributorsThanks.
  ///
  /// In hu, this message translates to:
  /// **'Köszönet mindenkinek, aki segít a RadRecon tesztelésében, fejlesztésében, fordításában és szakmai átnézésében. A RadRecon nonprofit civil kezdeményezés, önkéntesek munkájából épül.'**
  String get contributorsThanks;

  /// No description provided for @contributorsOrganizationsTitle.
  ///
  /// In hu, this message translates to:
  /// **'Szervezetek és cégek'**
  String get contributorsOrganizationsTitle;

  /// No description provided for @contributorsPeopleTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személyek'**
  String get contributorsPeopleTitle;

  /// No description provided for @contributorsEmpty.
  ///
  /// In hu, this message translates to:
  /// **'A lista még üres. Légy te az első!'**
  String get contributorsEmpty;

  /// No description provided for @contributorsLoadError.
  ///
  /// In hu, this message translates to:
  /// **'A lista nem tölthető be.'**
  String get contributorsLoadError;

  /// No description provided for @contributorsJoinHint.
  ///
  /// In hu, this message translates to:
  /// **'Szeretnél felkerülni a listára? Jelentkezz önkéntesnek, és írd meg, hogyan szeretnél megjelenni:'**
  String get contributorsJoinHint;

  /// No description provided for @contributorsCopyLink.
  ///
  /// In hu, this message translates to:
  /// **'Link másolása'**
  String get contributorsCopyLink;

  /// No description provided for @contributorsLinkCopied.
  ///
  /// In hu, this message translates to:
  /// **'Link másolva.'**
  String get contributorsLinkCopied;

  /// No description provided for @contributorRoleTesting.
  ///
  /// In hu, this message translates to:
  /// **'Tesztelés'**
  String get contributorRoleTesting;

  /// No description provided for @contributorRoleDevelopment.
  ///
  /// In hu, this message translates to:
  /// **'Fejlesztés'**
  String get contributorRoleDevelopment;

  /// No description provided for @contributorRoleReview.
  ///
  /// In hu, this message translates to:
  /// **'Szakmai átnézés'**
  String get contributorRoleReview;

  /// No description provided for @contributorRoleTranslation.
  ///
  /// In hu, this message translates to:
  /// **'Fordítás'**
  String get contributorRoleTranslation;

  /// No description provided for @contributorRoleOther.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb'**
  String get contributorRoleOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
