import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_it.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
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

  /// No description provided for @deletePointTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Mérési pont törlése'**
  String get deletePointTooltip;

  /// No description provided for @deletePointTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mérési pont törlése'**
  String get deletePointTitle;

  /// No description provided for @deletePointBody.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd ezt a mérési pontot? A hozzá tartozó forrás-hozzárendelések és a módosítási napló is törlődik. Ez nem visszavonható.'**
  String get deletePointBody;

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

  /// No description provided for @doseUnitSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítmény alapegysége'**
  String get doseUnitSectionTitle;

  /// No description provided for @doseUnitSectionHint.
  ///
  /// In hu, this message translates to:
  /// **'Új mérésnél ezek az egységek vannak előre kiválasztva. Rögzítéskor legördülő listából lehet másikat választani, beírni nem kell, és egységváltáskor a beírt szám automatikusan átváltódik. A dózisteljesítmény riasztási küszöbe is átváltódik.'**
  String get doseUnitSectionHint;

  /// No description provided for @unitsSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mértékegységek'**
  String get unitsSectionTitle;

  /// No description provided for @activityUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás alapegysége'**
  String get activityUnitLabel;

  /// No description provided for @distanceUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolság alapegysége'**
  String get distanceUnitLabel;

  /// No description provided for @activityPlainLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás'**
  String get activityPlainLabel;

  /// No description provided for @measuredDoseRatePlainLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mért dózisteljesítmény'**
  String get measuredDoseRatePlainLabel;

  /// No description provided for @distanceFromSourcePlainLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolság a forrástól'**
  String get distanceFromSourcePlainLabel;

  /// No description provided for @sourceDistancePlainLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolság a mérési ponttól'**
  String get sourceDistancePlainLabel;

  /// No description provided for @activityAtManufacturePlainLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás gyártáskor'**
  String get activityAtManufacturePlainLabel;

  /// No description provided for @invalidDistancePlainError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy érvényes, pozitív távolságot.'**
  String get invalidDistancePlainError;

  /// No description provided for @invalidActivityPlainError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy érvényes aktivitást.'**
  String get invalidActivityPlainError;

  /// No description provided for @invalidDoseRatePlainError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg egy érvényes dózisteljesítményt.'**
  String get invalidDoseRatePlainError;

  /// No description provided for @distanceFromSourceShortLabel.
  ///
  /// In hu, this message translates to:
  /// **'Táv. forrástól'**
  String get distanceFromSourceShortLabel;

  /// No description provided for @calculatedActivityResultLabel.
  ///
  /// In hu, this message translates to:
  /// **'Számított aktivitás'**
  String get calculatedActivityResultLabel;

  /// No description provided for @distanceIntervalPlainLabel.
  ///
  /// In hu, this message translates to:
  /// **'Távolságköz'**
  String get distanceIntervalPlainLabel;

  /// No description provided for @modbusQuantityLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mit ad vissza a regiszter'**
  String get modbusQuantityLabel;

  /// No description provided for @modbusRegisterUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'A regiszter mértékegysége'**
  String get modbusRegisterUnitLabel;

  /// No description provided for @modbusQuantityHelper.
  ///
  /// In hu, this message translates to:
  /// **'Rögzítéskor az app a kiolvasott értéket a Beállításokban választott alapegységre váltja.'**
  String get modbusQuantityHelper;

  /// No description provided for @autoLogTypeFromInstrument.
  ///
  /// In hu, this message translates to:
  /// **'Az automata naplózás a műszerhez beállított mennyiséget rögzíti.'**
  String get autoLogTypeFromInstrument;

  /// No description provided for @nuclideIdSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Nuklid-azonosítás'**
  String get nuclideIdSectionTitle;

  /// No description provided for @nuclideStatusNone.
  ///
  /// In hu, this message translates to:
  /// **'Nincs megadva'**
  String get nuclideStatusNone;

  /// No description provided for @nuclideStatusIdentified.
  ///
  /// In hu, this message translates to:
  /// **'Azonosított nuklid(ok)'**
  String get nuclideStatusIdentified;

  /// No description provided for @nuclideStatusUnknown.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen'**
  String get nuclideStatusUnknown;

  /// No description provided for @nuclideStatusOther.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb (nem szerepel a listában)'**
  String get nuclideStatusOther;

  /// No description provided for @nuclideStatusMixture.
  ///
  /// In hu, this message translates to:
  /// **'Feltételezhetően több forrás (keverék)'**
  String get nuclideStatusMixture;

  /// No description provided for @nuclideKnownListLabel.
  ///
  /// In hu, this message translates to:
  /// **'Nuklidok a listából'**
  String get nuclideKnownListLabel;

  /// No description provided for @nuclideCustomLabel.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb nuklid neve'**
  String get nuclideCustomLabel;

  /// No description provided for @nuclideAddButton.
  ///
  /// In hu, this message translates to:
  /// **'Hozzáadás'**
  String get nuclideAddButton;

  /// No description provided for @nuclideRequiredError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg legalább egy nuklidot, vagy válaszd az Ismeretlen lehetőséget.'**
  String get nuclideRequiredError;

  /// No description provided for @csvHeaderNuclides.
  ///
  /// In hu, this message translates to:
  /// **'Nuklid-azonosítás'**
  String get csvHeaderNuclides;

  /// No description provided for @nuclideDoneButton.
  ///
  /// In hu, this message translates to:
  /// **'Kész'**
  String get nuclideDoneButton;

  /// No description provided for @unshieldedActivityLabel.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás (árnyékolás nélkül)'**
  String get unshieldedActivityLabel;

  /// No description provided for @shieldingSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Árnyékolás (opcionális)'**
  String get shieldingSectionTitle;

  /// No description provided for @shieldingHint.
  ///
  /// In hu, this message translates to:
  /// **'Ha a forrás árnyékolás mögött van, add meg az anyagát és a vastagságát — a program az árnyékolt forrás tényleges aktivitását is megbecsüli.'**
  String get shieldingHint;

  /// No description provided for @shieldingMaterialLabel.
  ///
  /// In hu, this message translates to:
  /// **'Árnyékoló anyag'**
  String get shieldingMaterialLabel;

  /// No description provided for @shieldingNoneOption.
  ///
  /// In hu, this message translates to:
  /// **'Nincs árnyékolás'**
  String get shieldingNoneOption;

  /// No description provided for @shieldingThicknessLabel.
  ///
  /// In hu, this message translates to:
  /// **'Árnyékolás vastagsága'**
  String get shieldingThicknessLabel;

  /// No description provided for @shieldingThicknessError.
  ///
  /// In hu, this message translates to:
  /// **'Adj meg pozitív vastagságot'**
  String get shieldingThicknessError;

  /// No description provided for @shieldedActivityLabel.
  ///
  /// In hu, this message translates to:
  /// **'Árnyékolt forrás becsült aktivitása'**
  String get shieldedActivityLabel;

  /// No description provided for @shieldingDisclaimer.
  ///
  /// In hu, this message translates to:
  /// **'Közelítő becslés: a gyengítést félértékréteg-modell írja le (a vastagság minden HVL-nyi egységén felezi a dózisteljesítményt), tájékoztató HVL-értékekkel. A szórt sugárzás (buildup), a forrás geometriája és a sugárzási spektrum egyszerűsítve szerepel, ezért az eredmény inkább felülbecsli az aktivitást. Hatósági jegyzőkönyvhöz ellenőrizd hiteles forrásból.'**
  String get shieldingDisclaimer;

  /// No description provided for @shieldingMaterialLead.
  ///
  /// In hu, this message translates to:
  /// **'Ólom'**
  String get shieldingMaterialLead;

  /// No description provided for @shieldingMaterialSteel.
  ///
  /// In hu, this message translates to:
  /// **'Acél (vas)'**
  String get shieldingMaterialSteel;

  /// No description provided for @shieldingMaterialConcrete.
  ///
  /// In hu, this message translates to:
  /// **'Beton'**
  String get shieldingMaterialConcrete;

  /// No description provided for @shieldingMaterialTungsten.
  ///
  /// In hu, this message translates to:
  /// **'Wolfram'**
  String get shieldingMaterialTungsten;

  /// No description provided for @shieldingMaterialAluminium.
  ///
  /// In hu, this message translates to:
  /// **'Alumínium'**
  String get shieldingMaterialAluminium;

  /// No description provided for @shieldingMaterialWater.
  ///
  /// In hu, this message translates to:
  /// **'Víz'**
  String get shieldingMaterialWater;

  /// No description provided for @csvUnshieldedNote.
  ///
  /// In hu, this message translates to:
  /// **'árnyékolás nélkül'**
  String get csvUnshieldedNote;

  /// No description provided for @csvShieldedSourceNote.
  ///
  /// In hu, this message translates to:
  /// **'árnyékolt forrás'**
  String get csvShieldedSourceNote;

  /// No description provided for @shieldingAddLayer.
  ///
  /// In hu, this message translates to:
  /// **'Réteg hozzáadása'**
  String get shieldingAddLayer;

  /// No description provided for @shieldingLayerLabel.
  ///
  /// In hu, this message translates to:
  /// **'Réteg'**
  String get shieldingLayerLabel;

  /// No description provided for @shieldingRemoveLayer.
  ///
  /// In hu, this message translates to:
  /// **'Réteg törlése'**
  String get shieldingRemoveLayer;

  /// No description provided for @doseRateUnshieldedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítmény (árnyékolás nélkül)'**
  String get doseRateUnshieldedLabel;

  /// No description provided for @doseRateShieldedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítmény az árnyékolás mögött'**
  String get doseRateShieldedLabel;

  /// No description provided for @calibrationSectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Hitelesítés és kalibrálás'**
  String get calibrationSectionTitle;

  /// No description provided for @calibrationKindVerification.
  ///
  /// In hu, this message translates to:
  /// **'Hitelesítés'**
  String get calibrationKindVerification;

  /// No description provided for @calibrationKindCalibration.
  ///
  /// In hu, this message translates to:
  /// **'Kalibrálás'**
  String get calibrationKindCalibration;

  /// No description provided for @calibrationAddButton.
  ///
  /// In hu, this message translates to:
  /// **'Bejegyzés hozzáadása'**
  String get calibrationAddButton;

  /// No description provided for @calibrationDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Hitelesítés / kalibrálás bejegyzés'**
  String get calibrationDialogTitle;

  /// No description provided for @calibrationKindLabel.
  ///
  /// In hu, this message translates to:
  /// **'Típus'**
  String get calibrationKindLabel;

  /// No description provided for @calibrationPerformedOnLabel.
  ///
  /// In hu, this message translates to:
  /// **'Elvégzés dátuma'**
  String get calibrationPerformedOnLabel;

  /// No description provided for @calibrationValidUntilLabel.
  ///
  /// In hu, this message translates to:
  /// **'Érvényes eddig'**
  String get calibrationValidUntilLabel;

  /// No description provided for @calibrationCertificateLabel.
  ///
  /// In hu, this message translates to:
  /// **'Bizonylat száma'**
  String get calibrationCertificateLabel;

  /// No description provided for @calibrationPerformedByLabel.
  ///
  /// In hu, this message translates to:
  /// **'Végezte (labor / hatóság)'**
  String get calibrationPerformedByLabel;

  /// No description provided for @calibrationAttachFile.
  ///
  /// In hu, this message translates to:
  /// **'Bizonylat csatolása'**
  String get calibrationAttachFile;

  /// No description provided for @calibrationRemoveFile.
  ///
  /// In hu, this message translates to:
  /// **'Csatolmány törlése'**
  String get calibrationRemoveFile;

  /// No description provided for @calibrationOpenFile.
  ///
  /// In hu, this message translates to:
  /// **'Bizonylat megnyitása / megosztása'**
  String get calibrationOpenFile;

  /// No description provided for @calibrationEmptyList.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs bejegyzés.'**
  String get calibrationEmptyList;

  /// No description provided for @calibrationStatusValid.
  ///
  /// In hu, this message translates to:
  /// **'Érvényes'**
  String get calibrationStatusValid;

  /// No description provided for @calibrationStatusSoon.
  ///
  /// In hu, this message translates to:
  /// **'Hamarosan lejár'**
  String get calibrationStatusSoon;

  /// No description provided for @calibrationStatusExpired.
  ///
  /// In hu, this message translates to:
  /// **'LEJÁRT'**
  String get calibrationStatusExpired;

  /// No description provided for @calibrationStatusUnknown.
  ///
  /// In hu, this message translates to:
  /// **'Nincs adat'**
  String get calibrationStatusUnknown;

  /// No description provided for @calibrationExpiredWarning.
  ///
  /// In hu, this message translates to:
  /// **'Figyelem: a kiválasztott műszer hitelesítése/kalibrálása lejárt. Érvényes eddig:'**
  String get calibrationExpiredWarning;

  /// No description provided for @calibrationSoonWarning.
  ///
  /// In hu, this message translates to:
  /// **'Figyelem: a kiválasztott műszer hitelesítése/kalibrálása hamarosan lejár. Érvényes eddig:'**
  String get calibrationSoonWarning;

  /// No description provided for @calibrationUnknownWarning.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott műszernél nincs hitelesítési/kalibrálási adat.'**
  String get calibrationUnknownWarning;

  /// No description provided for @calibrationSaveAnywayTitle.
  ///
  /// In hu, this message translates to:
  /// **'Lejárt hitelesítés/kalibrálás'**
  String get calibrationSaveAnywayTitle;

  /// No description provided for @calibrationSaveAnywayBody.
  ///
  /// In hu, this message translates to:
  /// **'A mérés lejárt hitelesítésű/kalibrálású műszerrel készült, a jegyzőkönyvben ez jelölve lesz. Mented?'**
  String get calibrationSaveAnywayBody;

  /// No description provided for @calibrationSaveAnywayConfirm.
  ///
  /// In hu, this message translates to:
  /// **'Mentés mégis'**
  String get calibrationSaveAnywayConfirm;

  /// No description provided for @calibrationValidUntilBeforeError.
  ///
  /// In hu, this message translates to:
  /// **'Az érvényesség nem lehet az elvégzés előtt'**
  String get calibrationValidUntilBeforeError;

  /// No description provided for @csvHeaderInstrumentCalibration.
  ///
  /// In hu, this message translates to:
  /// **'Műszer hitelesítése/kalibrálása'**
  String get csvHeaderInstrumentCalibration;

  /// No description provided for @personPhoneLabel.
  ///
  /// In hu, this message translates to:
  /// **'Telefonszám'**
  String get personPhoneLabel;

  /// No description provided for @personEmailLabel.
  ///
  /// In hu, this message translates to:
  /// **'E-mail cím'**
  String get personEmailLabel;

  /// No description provided for @personAddEmail.
  ///
  /// In hu, this message translates to:
  /// **'E-mail cím hozzáadása'**
  String get personAddEmail;

  /// No description provided for @personRemoveEmail.
  ///
  /// In hu, this message translates to:
  /// **'E-mail törlése'**
  String get personRemoveEmail;

  /// No description provided for @personEmailInvalidError.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen e-mail cím'**
  String get personEmailInvalidError;

  /// No description provided for @personCertificatesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Bizonyítványok'**
  String get personCertificatesTitle;

  /// No description provided for @personCertificateAdd.
  ///
  /// In hu, this message translates to:
  /// **'Bizonyítvány hozzáadása'**
  String get personCertificateAdd;

  /// No description provided for @personCertificateDialogTitle.
  ///
  /// In hu, this message translates to:
  /// **'Bizonyítvány'**
  String get personCertificateDialogTitle;

  /// No description provided for @personCertificateNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Megnevezés (pl. sugárvédelmi vizsga)'**
  String get personCertificateNameLabel;

  /// No description provided for @personCertificateNumberLabel.
  ///
  /// In hu, this message translates to:
  /// **'Bizonyítvány száma'**
  String get personCertificateNumberLabel;

  /// No description provided for @personCertificateIssuerLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiállító'**
  String get personCertificateIssuerLabel;

  /// No description provided for @personCertificateIssuedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiállítás dátuma'**
  String get personCertificateIssuedLabel;

  /// No description provided for @personCertificateNameRequired.
  ///
  /// In hu, this message translates to:
  /// **'Add meg a bizonyítvány megnevezését'**
  String get personCertificateNameRequired;

  /// No description provided for @personCertificateValidBeforeError.
  ///
  /// In hu, this message translates to:
  /// **'Az érvényesség nem lehet a kiállítás előtt'**
  String get personCertificateValidBeforeError;

  /// No description provided for @personCertificatesEmpty.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs bizonyítvány.'**
  String get personCertificatesEmpty;

  /// No description provided for @sourceCertificateTitle.
  ///
  /// In hu, this message translates to:
  /// **'Műbizonylat'**
  String get sourceCertificateTitle;

  /// No description provided for @sourceCertificateAttach.
  ///
  /// In hu, this message translates to:
  /// **'Műbizonylat csatolása'**
  String get sourceCertificateAttach;

  /// No description provided for @sourceCertificateEmpty.
  ///
  /// In hu, this message translates to:
  /// **'Nincs csatolt műbizonylat.'**
  String get sourceCertificateEmpty;

  /// No description provided for @companyDocumentsTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Cég dokumentumai és engedélyei'**
  String get companyDocumentsTooltip;

  /// No description provided for @companyDocumentNew.
  ///
  /// In hu, this message translates to:
  /// **'Új dokumentum'**
  String get companyDocumentNew;

  /// No description provided for @companyDocumentEdit.
  ///
  /// In hu, this message translates to:
  /// **'Dokumentum szerkesztése'**
  String get companyDocumentEdit;

  /// No description provided for @companyDocumentTitleLabel.
  ///
  /// In hu, this message translates to:
  /// **'Dokumentum megnevezése'**
  String get companyDocumentTitleLabel;

  /// No description provided for @companyDocumentIdentifierLabel.
  ///
  /// In hu, this message translates to:
  /// **'Azonosító (iktatószám, engedélyszám)'**
  String get companyDocumentIdentifierLabel;

  /// No description provided for @companyDocumentIssuerLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiadó / hatóság'**
  String get companyDocumentIssuerLabel;

  /// No description provided for @companyDocumentIssuedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiadás vagy hatályba lépés dátuma'**
  String get companyDocumentIssuedLabel;

  /// No description provided for @companyDocumentValidUntilLabel.
  ///
  /// In hu, this message translates to:
  /// **'Érvényes / felülvizsgálandó eddig'**
  String get companyDocumentValidUntilLabel;

  /// No description provided for @companyDocumentFilesTitle.
  ///
  /// In hu, this message translates to:
  /// **'Csatolt fájlok'**
  String get companyDocumentFilesTitle;

  /// No description provided for @companyDocumentAttach.
  ///
  /// In hu, this message translates to:
  /// **'Fájl csatolása'**
  String get companyDocumentAttach;

  /// No description provided for @companyDocumentsEmpty.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs dokumentum.'**
  String get companyDocumentsEmpty;

  /// No description provided for @companyDocumentDeleteTitle.
  ///
  /// In hu, this message translates to:
  /// **'Dokumentum törlése'**
  String get companyDocumentDeleteTitle;

  /// No description provided for @companyDocumentDeleteConfirm.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd ezt a dokumentumot?'**
  String get companyDocumentDeleteConfirm;

  /// No description provided for @companyDocSuggestionsLabel.
  ///
  /// In hu, this message translates to:
  /// **'Gyakori dokumentumok'**
  String get companyDocSuggestionsLabel;

  /// No description provided for @companyDocSuggestRadiationPolicy.
  ///
  /// In hu, this message translates to:
  /// **'Munkahelyi Sugárvédelmi Szabályzat'**
  String get companyDocSuggestRadiationPolicy;

  /// No description provided for @companyDocSuggestRadiationDescription.
  ///
  /// In hu, this message translates to:
  /// **'Sugárvédelmi Leírás'**
  String get companyDocSuggestRadiationDescription;

  /// No description provided for @companyDocSuggestPhysicalProtection.
  ///
  /// In hu, this message translates to:
  /// **'Fizikai Védelmi Terv'**
  String get companyDocSuggestPhysicalProtection;

  /// No description provided for @companyDocSuggestEmergencyPlan.
  ///
  /// In hu, this message translates to:
  /// **'Balesetelhárítási Intézkedési Terv'**
  String get companyDocSuggestEmergencyPlan;

  /// No description provided for @companyDocSuggestOfficialLicense.
  ///
  /// In hu, this message translates to:
  /// **'Hatósági engedély'**
  String get companyDocSuggestOfficialLicense;

  /// No description provided for @nuclideEditButton.
  ///
  /// In hu, this message translates to:
  /// **'Nuklidok módosítása'**
  String get nuclideEditButton;

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

  /// No description provided for @protocolFormatTitle.
  ///
  /// In hu, this message translates to:
  /// **'Jegyzőkönyv formátuma'**
  String get protocolFormatTitle;

  /// No description provided for @protocolFormatWord.
  ///
  /// In hu, this message translates to:
  /// **'Word (ZIP: .docx + fotók)'**
  String get protocolFormatWord;

  /// No description provided for @protocolFormatPdf.
  ///
  /// In hu, this message translates to:
  /// **'PDF (fotókkal)'**
  String get protocolFormatPdf;

  /// No description provided for @sessionDoseLabel.
  ///
  /// In hu, this message translates to:
  /// **'Felmérési dózis'**
  String get sessionDoseLabel;

  /// No description provided for @dosimeterDoseLabel.
  ///
  /// In hu, this message translates to:
  /// **'Doziméter'**
  String get dosimeterDoseLabel;

  /// No description provided for @dosimeterValueLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiértékelt dózis'**
  String get dosimeterValueLabel;

  /// No description provided for @includeInAnnualLabel.
  ///
  /// In hu, this message translates to:
  /// **'Beszámít az éves dózisba'**
  String get includeInAnnualLabel;

  /// No description provided for @notCountedInAnnualLabel.
  ///
  /// In hu, this message translates to:
  /// **'nem számít az éves dózisba'**
  String get notCountedInAnnualLabel;

  /// No description provided for @calcDoseFromPointsButton.
  ///
  /// In hu, this message translates to:
  /// **'Számítás a pontokból'**
  String get calcDoseFromPointsButton;

  /// No description provided for @calcDoseNeedTwoPoints.
  ///
  /// In hu, this message translates to:
  /// **'Legalább 2 dózisteljesítmény-pont kell a számításhoz.'**
  String get calcDoseNeedTwoPoints;

  /// No description provided for @calcDoseResultInfo.
  ///
  /// In hu, this message translates to:
  /// **'{count} pontból számítva (lineáris interpoláció)'**
  String calcDoseResultInfo(int count);

  /// No description provided for @dosimetersButton.
  ///
  /// In hu, this message translates to:
  /// **'Doziméterek'**
  String get dosimetersButton;

  /// No description provided for @addDosimeterButton.
  ///
  /// In hu, this message translates to:
  /// **'Doziméter hozzáadása'**
  String get addDosimeterButton;

  /// No description provided for @dosimeterKindEpdGamma.
  ///
  /// In hu, this message translates to:
  /// **'EPD gamma (elektronikus)'**
  String get dosimeterKindEpdGamma;

  /// No description provided for @dosimeterKindEpdNeutron.
  ///
  /// In hu, this message translates to:
  /// **'EPD neutron (elektronikus)'**
  String get dosimeterKindEpdNeutron;

  /// No description provided for @dosimeterKindTlOfficial.
  ///
  /// In hu, this message translates to:
  /// **'TL/OSL passzív (hivatalos)'**
  String get dosimeterKindTlOfficial;

  /// No description provided for @dosimeterKindTlWorkplace.
  ///
  /// In hu, this message translates to:
  /// **'TL/OSL passzív (munkahelyi)'**
  String get dosimeterKindTlWorkplace;

  /// No description provided for @dosimeterTypeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Típus'**
  String get dosimeterTypeLabel;

  /// No description provided for @dosimeterIdentifierLabel.
  ///
  /// In hu, this message translates to:
  /// **'Azonosító'**
  String get dosimeterIdentifierLabel;

  /// No description provided for @dosimeterPersonLabel.
  ///
  /// In hu, this message translates to:
  /// **'Viselője'**
  String get dosimeterPersonLabel;

  /// No description provided for @dosimeterNobody.
  ///
  /// In hu, this message translates to:
  /// **'Nincs hozzárendelve'**
  String get dosimeterNobody;

  /// No description provided for @dosimeterStartLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kezdő állás'**
  String get dosimeterStartLabel;

  /// No description provided for @dosimeterEndLabel.
  ///
  /// In hu, this message translates to:
  /// **'Záró állás'**
  String get dosimeterEndLabel;

  /// No description provided for @dosimeterEndBeforeStartError.
  ///
  /// In hu, this message translates to:
  /// **'A záró állás nem lehet kisebb a kezdőnél.'**
  String get dosimeterEndBeforeStartError;

  /// No description provided for @noDosimetersYet.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs doziméter ennél a felmérésnél.'**
  String get noDosimetersYet;

  /// No description provided for @dosimeterEditTitle.
  ///
  /// In hu, this message translates to:
  /// **'Doziméter'**
  String get dosimeterEditTitle;

  /// No description provided for @dosimeterNoReading.
  ///
  /// In hu, this message translates to:
  /// **'nincs adat'**
  String get dosimeterNoReading;

  /// No description provided for @dosimeterDeleteTitle.
  ///
  /// In hu, this message translates to:
  /// **'Doziméter törlése'**
  String get dosimeterDeleteTitle;

  /// No description provided for @dosimeterDeleteMessage.
  ///
  /// In hu, this message translates to:
  /// **'Biztosan törlöd ezt a doziméter-bejegyzést?'**
  String get dosimeterDeleteMessage;

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

  /// No description provided for @sampleUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Egység'**
  String get sampleUnitLabel;

  /// No description provided for @sampleUnitOther.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb'**
  String get sampleUnitOther;

  /// No description provided for @sampleUnitCustomLabel.
  ///
  /// In hu, this message translates to:
  /// **'Egység megnevezése'**
  String get sampleUnitCustomLabel;

  /// No description provided for @sampleAmountInvalid.
  ///
  /// In hu, this message translates to:
  /// **'Számot adj meg (pl. 2,5 vagy 2.5)'**
  String get sampleAmountInvalid;

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
  /// **'Táv. forrástól'**
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
  /// **'GPS pontosság'**
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
  /// **'Számított dózisteljesítmény'**
  String get csvHeaderCalculatedDoseRate;

  /// No description provided for @csvHeaderDoseRateDifference.
  ///
  /// In hu, this message translates to:
  /// **'Eltérés'**
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

  /// No description provided for @expiryLeadTwoWeeks.
  ///
  /// In hu, this message translates to:
  /// **'2 héttel előtte'**
  String get expiryLeadTwoWeeks;

  /// No description provided for @expiryLeadMonths.
  ///
  /// In hu, this message translates to:
  /// **'{count} hónappal előtte'**
  String expiryLeadMonths(int count);

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

  /// No description provided for @regulatoryProfileLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szabályozási profil'**
  String get regulatoryProfileLabel;

  /// No description provided for @regulatoryProfileInternational.
  ///
  /// In hu, this message translates to:
  /// **'Nemzetközi (IAEA)'**
  String get regulatoryProfileInternational;

  /// No description provided for @regulatoryProfileHungary.
  ///
  /// In hu, this message translates to:
  /// **'Magyarország (OAH)'**
  String get regulatoryProfileHungary;

  /// No description provided for @classificationTitle.
  ///
  /// In hu, this message translates to:
  /// **'Besorolás (D, R, mentesség)'**
  String get classificationTitle;

  /// No description provided for @classificationDisclaimer.
  ///
  /// In hu, this message translates to:
  /// **'Tájékoztató számítás a nuklidtáblák és az aktuális (bomlással korrigált) aktivitás alapján. A hatósági besorolás a hatályos jogszabály és a hatóság döntése szerint érvényes. Az MSZ 62-7 szerinti laborosztály az aktivitásból számolt tájékoztató érték.'**
  String get classificationDisclaimer;

  /// No description provided for @classificationUnsealedWork.
  ///
  /// In hu, this message translates to:
  /// **'Nyitott sugárforrással végzett rendszeres munka'**
  String get classificationUnsealedWork;

  /// No description provided for @classificationOutsideWorkplace.
  ///
  /// In hu, this message translates to:
  /// **'Alkalmazás sugárveszélyes munkahelyen kívül'**
  String get classificationOutsideWorkplace;

  /// No description provided for @classificationTotal.
  ///
  /// In hu, this message translates to:
  /// **'Összesített (kijelölt források)'**
  String get classificationTotal;

  /// No description provided for @classificationPhysCat.
  ///
  /// In hu, this message translates to:
  /// **'Fizikai védelmi kategória'**
  String get classificationPhysCat;

  /// No description provided for @classificationProtCat.
  ///
  /// In hu, this message translates to:
  /// **'Sugárvédelmi kategória'**
  String get classificationProtCat;

  /// No description provided for @classificationUnknownCount.
  ///
  /// In hu, this message translates to:
  /// **'R nélküli források (ismeretlen nuklid)'**
  String get classificationUnknownCount;

  /// No description provided for @classificationActivity.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás'**
  String get classificationActivity;

  /// No description provided for @classificationNotDecayCorrected.
  ///
  /// In hu, this message translates to:
  /// **'bomlás nélkül'**
  String get classificationNotDecayCorrected;

  /// No description provided for @classificationDInfinite.
  ///
  /// In hu, this message translates to:
  /// **'D = ∞ (nem járul hozzá az R-hez)'**
  String get classificationDInfinite;

  /// No description provided for @classificationDUnknown.
  ///
  /// In hu, this message translates to:
  /// **'Ehhez a nuklidhoz nincs D érték, R nem számolható'**
  String get classificationDUnknown;

  /// No description provided for @classificationExemptUnknown.
  ///
  /// In hu, this message translates to:
  /// **'Nincs mentességi érték ehhez a nuklidhoz'**
  String get classificationExemptUnknown;

  /// No description provided for @classificationExemptActivity.
  ///
  /// In hu, this message translates to:
  /// **'Mentességi aktivitás'**
  String get classificationExemptActivity;

  /// No description provided for @classificationSpecificConc.
  ///
  /// In hu, this message translates to:
  /// **'Specifikus mentességi koncentráció'**
  String get classificationSpecificConc;

  /// No description provided for @classificationGeneralConc.
  ///
  /// In hu, this message translates to:
  /// **'általános'**
  String get classificationGeneralConc;

  /// No description provided for @classificationBelowExempt.
  ///
  /// In hu, this message translates to:
  /// **'Az aktivitás a mentességi aktivitás alatt van'**
  String get classificationBelowExempt;

  /// No description provided for @classificationAboveExempt.
  ///
  /// In hu, this message translates to:
  /// **'Az aktivitás a mentességi aktivitás felett van'**
  String get classificationAboveExempt;

  /// No description provided for @classificationProtLevel.
  ///
  /// In hu, this message translates to:
  /// **'Fizikai védelmi szint'**
  String get classificationProtLevel;

  /// No description provided for @classificationAdrConsignmentLimit.
  ///
  /// In hu, this message translates to:
  /// **'mentes küldemény határa'**
  String get classificationAdrConsignmentLimit;

  /// No description provided for @classificationAdrBelow.
  ///
  /// In hu, this message translates to:
  /// **'az aktivitás alatta van (nem 7. osztály)'**
  String get classificationAdrBelow;

  /// No description provided for @classificationAdrAbove.
  ///
  /// In hu, this message translates to:
  /// **'az aktivitás felette van (a koncentráció is számít)'**
  String get classificationAdrAbove;

  /// No description provided for @classificationLabIndustrial.
  ///
  /// In hu, this message translates to:
  /// **'Ipari labor'**
  String get classificationLabIndustrial;

  /// No description provided for @classificationLabMedical.
  ///
  /// In hu, this message translates to:
  /// **'Orvosi labor'**
  String get classificationLabMedical;

  /// No description provided for @classificationLabAboveIII.
  ///
  /// In hu, this message translates to:
  /// **'> III.'**
  String get classificationLabAboveIII;

  /// No description provided for @classificationLabOps.
  ///
  /// In hu, this message translates to:
  /// **'Végezhető művelettípusok'**
  String get classificationLabOps;

  /// No description provided for @classificationLabUnknown.
  ///
  /// In hu, this message translates to:
  /// **'MSZ 62-7: nincs AM érték ehhez a nuklidhoz'**
  String get classificationLabUnknown;

  /// No description provided for @autoLogChartTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mért érték az idő függvényében'**
  String get autoLogChartTitle;

  /// No description provided for @gpsAverageButton.
  ///
  /// In hu, this message translates to:
  /// **'Átlagolt GPS'**
  String get gpsAverageButton;

  /// No description provided for @gpsAverageTitle.
  ///
  /// In hu, this message translates to:
  /// **'Pozíció átlagolása'**
  String get gpsAverageTitle;

  /// No description provided for @gpsAverageHint.
  ///
  /// In hu, this message translates to:
  /// **'Állj meg egy helyen, és ne mozdulj a mérés alatt. Minél hosszabb az átlagolás, annál megbízhatóbb az eredmény; nyílt ég alatt a legjobb. A telefon a pontosság szerint súlyozza a mintákat, és elhagyja a kiugró pozíciókat.'**
  String get gpsAverageHint;

  /// No description provided for @gpsAverageStart.
  ///
  /// In hu, this message translates to:
  /// **'Indítás'**
  String get gpsAverageStart;

  /// No description provided for @gpsAverageUse.
  ///
  /// In hu, this message translates to:
  /// **'Használ'**
  String get gpsAverageUse;

  /// No description provided for @gpsAverageSamples.
  ///
  /// In hu, this message translates to:
  /// **'Minták'**
  String get gpsAverageSamples;

  /// No description provided for @gpsAverageCurrent.
  ///
  /// In hu, this message translates to:
  /// **'Aktuális pontosság'**
  String get gpsAverageCurrent;

  /// No description provided for @gpsAverageResult.
  ///
  /// In hu, this message translates to:
  /// **'Becsült pontosság az átlagból'**
  String get gpsAverageResult;

  /// No description provided for @modbusAverageButton.
  ///
  /// In hu, this message translates to:
  /// **'Átlagoló mérés'**
  String get modbusAverageButton;

  /// No description provided for @modbusAverageRunning.
  ///
  /// In hu, this message translates to:
  /// **'Átlagolás'**
  String get modbusAverageRunning;

  /// No description provided for @modbusAverageDone.
  ///
  /// In hu, this message translates to:
  /// **'Kész'**
  String get modbusAverageDone;

  /// No description provided for @modbusAverageTooFew.
  ///
  /// In hu, this message translates to:
  /// **'A hiba számításához legalább 2 érvényes minta kell, csak az érték került be.'**
  String get modbusAverageTooFew;

  /// No description provided for @measurementErrorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Hiba (±)'**
  String get measurementErrorLabel;

  /// No description provided for @measurementErrorHelper.
  ///
  /// In hu, this message translates to:
  /// **'Átlagolt mérésnél az átlag standard hibája (1σ), kézzel feltöltött értéknél kézzel is megadható. A jegyzőkönyvre kerül.'**
  String get measurementErrorHelper;

  /// No description provided for @measurementAveragedLabel.
  ///
  /// In hu, this message translates to:
  /// **'Átlagolt mérés'**
  String get measurementAveragedLabel;

  /// No description provided for @csvHeaderValueError.
  ///
  /// In hu, this message translates to:
  /// **'Hiba (±)'**
  String get csvHeaderValueError;

  /// No description provided for @csvHeaderAveraging.
  ///
  /// In hu, this message translates to:
  /// **'Átlagolás (minta; mp)'**
  String get csvHeaderAveraging;

  /// No description provided for @helpManualTitle.
  ///
  /// In hu, this message translates to:
  /// **'Súgó (használati útmutató)'**
  String get helpManualTitle;

  /// No description provided for @helpManualOpenError.
  ///
  /// In hu, this message translates to:
  /// **'Az útmutató nem nyitható meg.'**
  String get helpManualOpenError;

  /// No description provided for @appVersionLabel.
  ///
  /// In hu, this message translates to:
  /// **'Verzió'**
  String get appVersionLabel;

  /// No description provided for @appUpdateTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új verzió érhető el'**
  String get appUpdateTitle;

  /// No description provided for @appUpdateAvailableMessage.
  ///
  /// In hu, this message translates to:
  /// **'A {version} verzió elérhető. Frissítsd az alkalmazást a legújabb javításokért és funkciókért.'**
  String appUpdateAvailableMessage(String version);

  /// No description provided for @appUpdateRequiredMessage.
  ///
  /// In hu, this message translates to:
  /// **'Az alkalmazás ezen verziója már nem támogatott. Frissítsd a {version} verzióra a folytatáshoz.'**
  String appUpdateRequiredMessage(String version);

  /// No description provided for @appUpdateLater.
  ///
  /// In hu, this message translates to:
  /// **'Később'**
  String get appUpdateLater;

  /// No description provided for @appUpdateNow.
  ///
  /// In hu, this message translates to:
  /// **'Frissítés'**
  String get appUpdateNow;

  /// No description provided for @rrRoleSurveyor.
  ///
  /// In hu, this message translates to:
  /// **'Felmérő'**
  String get rrRoleSurveyor;

  /// No description provided for @rrRoleVictim.
  ///
  /// In hu, this message translates to:
  /// **'Érintett / áldozat'**
  String get rrRoleVictim;

  /// No description provided for @rrTriageNone.
  ///
  /// In hu, this message translates to:
  /// **'Nincs besorolva'**
  String get rrTriageNone;

  /// No description provided for @rrTriageRed.
  ///
  /// In hu, this message translates to:
  /// **'Piros – azonnali ellátás'**
  String get rrTriageRed;

  /// No description provided for @rrTriageYellow.
  ///
  /// In hu, this message translates to:
  /// **'Sárga – halasztható ellátás'**
  String get rrTriageYellow;

  /// No description provided for @rrTriageGreen.
  ///
  /// In hu, this message translates to:
  /// **'Zöld – könnyű sérülés'**
  String get rrTriageGreen;

  /// No description provided for @rrTriageBlack.
  ///
  /// In hu, this message translates to:
  /// **'Fekete – elhunyt / nincs ellátás'**
  String get rrTriageBlack;

  /// No description provided for @rrConditionInjury.
  ///
  /// In hu, this message translates to:
  /// **'Sérülés'**
  String get rrConditionInjury;

  /// No description provided for @rrConditionIllness.
  ///
  /// In hu, this message translates to:
  /// **'Betegség'**
  String get rrConditionIllness;

  /// No description provided for @rrAffectedPrefix.
  ///
  /// In hu, this message translates to:
  /// **'Érintett'**
  String get rrAffectedPrefix;

  /// No description provided for @rrEditStatusTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Szerep, triázs, sérülések'**
  String get rrEditStatusTooltip;

  /// No description provided for @rrRoleLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szerep'**
  String get rrRoleLabel;

  /// No description provided for @rrTriageCategoryLabel.
  ///
  /// In hu, this message translates to:
  /// **'Triázs-besorolás'**
  String get rrTriageCategoryLabel;

  /// No description provided for @rrInjuriesAndIllnesses.
  ///
  /// In hu, this message translates to:
  /// **'Sérülések és betegségek'**
  String get rrInjuriesAndIllnesses;

  /// No description provided for @rrDescriptionHint.
  ///
  /// In hu, this message translates to:
  /// **'Leírás'**
  String get rrDescriptionHint;

  /// No description provided for @rrAddItem.
  ///
  /// In hu, this message translates to:
  /// **'Tétel hozzáadása'**
  String get rrAddItem;

  /// No description provided for @rrDeleteTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Törlés'**
  String get rrDeleteTooltip;

  /// No description provided for @rrMeteoSection.
  ///
  /// In hu, this message translates to:
  /// **'Meteorológia (opcionális)'**
  String get rrMeteoSection;

  /// No description provided for @rrMetTemp.
  ///
  /// In hu, this message translates to:
  /// **'Levegő-hőmérséklet (°C)'**
  String get rrMetTemp;

  /// No description provided for @rrMetHumidity.
  ///
  /// In hu, this message translates to:
  /// **'Relatív páratartalom (%)'**
  String get rrMetHumidity;

  /// No description provided for @rrMetPressure.
  ///
  /// In hu, this message translates to:
  /// **'Légnyomás (hPa)'**
  String get rrMetPressure;

  /// No description provided for @rrMetWind.
  ///
  /// In hu, this message translates to:
  /// **'Szélsebesség (m/s)'**
  String get rrMetWind;

  /// No description provided for @rrMetWindDir.
  ///
  /// In hu, this message translates to:
  /// **'Szélirány (°)'**
  String get rrMetWindDir;

  /// No description provided for @rrMetGust.
  ///
  /// In hu, this message translates to:
  /// **'Széllökés (m/s)'**
  String get rrMetGust;

  /// No description provided for @rrMetPrecipIntensity.
  ///
  /// In hu, this message translates to:
  /// **'Csapadékintenzitás (mm/h)'**
  String get rrMetPrecipIntensity;

  /// No description provided for @rrMetSolar.
  ///
  /// In hu, this message translates to:
  /// **'Napsugárzás (W/m²)'**
  String get rrMetSolar;

  /// No description provided for @rrMetCloud.
  ///
  /// In hu, this message translates to:
  /// **'Felhőzet (okta, 0–8)'**
  String get rrMetCloud;

  /// No description provided for @rrMetVisibility.
  ///
  /// In hu, this message translates to:
  /// **'Látástávolság (m)'**
  String get rrMetVisibility;

  /// No description provided for @rrMetSoil.
  ///
  /// In hu, this message translates to:
  /// **'Talajnedvesség (%)'**
  String get rrMetSoil;

  /// No description provided for @rrMetAerosol.
  ///
  /// In hu, this message translates to:
  /// **'Aeroszolkoncentráció (µg/m³)'**
  String get rrMetAerosol;

  /// No description provided for @rrPrecipState.
  ///
  /// In hu, this message translates to:
  /// **'Csapadékállapot'**
  String get rrPrecipState;

  /// No description provided for @rrPrecipNone.
  ///
  /// In hu, this message translates to:
  /// **'Nincs csapadék'**
  String get rrPrecipNone;

  /// No description provided for @rrPrecipDrizzle.
  ///
  /// In hu, this message translates to:
  /// **'Szitálás'**
  String get rrPrecipDrizzle;

  /// No description provided for @rrPrecipRain.
  ///
  /// In hu, this message translates to:
  /// **'Eső'**
  String get rrPrecipRain;

  /// No description provided for @rrPrecipSnow.
  ///
  /// In hu, this message translates to:
  /// **'Hó'**
  String get rrPrecipSnow;

  /// No description provided for @rrPrecipSleet.
  ///
  /// In hu, this message translates to:
  /// **'Ónos eső'**
  String get rrPrecipSleet;

  /// No description provided for @rrPrecipHail.
  ///
  /// In hu, this message translates to:
  /// **'Jégeső'**
  String get rrPrecipHail;

  /// No description provided for @rrMetOther.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb megfigyelés'**
  String get rrMetOther;

  /// No description provided for @rrGasSection.
  ///
  /// In hu, this message translates to:
  /// **'Gázmérés'**
  String get rrGasSection;

  /// No description provided for @rrAddGas.
  ///
  /// In hu, this message translates to:
  /// **'Gáz hozzáadása'**
  String get rrAddGas;

  /// No description provided for @rrGasSpecies.
  ///
  /// In hu, this message translates to:
  /// **'Vegyület'**
  String get rrGasSpecies;

  /// No description provided for @rrGasOther.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb'**
  String get rrGasOther;

  /// No description provided for @rrGasOtherName.
  ///
  /// In hu, this message translates to:
  /// **'Vegyület neve'**
  String get rrGasOtherName;

  /// No description provided for @rrFormulaLabel.
  ///
  /// In hu, this message translates to:
  /// **'Képlet'**
  String get rrFormulaLabel;

  /// No description provided for @rrGasConcentration.
  ///
  /// In hu, this message translates to:
  /// **'Koncentráció'**
  String get rrGasConcentration;

  /// No description provided for @rrGasUnit.
  ///
  /// In hu, this message translates to:
  /// **'Egység'**
  String get rrGasUnit;

  /// No description provided for @rrInvalidValue.
  ///
  /// In hu, this message translates to:
  /// **'Hibás érték'**
  String get rrInvalidValue;

  /// No description provided for @rrGasAmmonia.
  ///
  /// In hu, this message translates to:
  /// **'Ammónia'**
  String get rrGasAmmonia;

  /// No description provided for @rrGasBenzene.
  ///
  /// In hu, this message translates to:
  /// **'Benzol'**
  String get rrGasBenzene;

  /// No description provided for @rrGasPhosphine.
  ///
  /// In hu, this message translates to:
  /// **'Foszfin'**
  String get rrGasPhosphine;

  /// No description provided for @rrGasPhosgene.
  ///
  /// In hu, this message translates to:
  /// **'Foszgén'**
  String get rrGasPhosgene;

  /// No description provided for @rrGasHydrogen.
  ///
  /// In hu, this message translates to:
  /// **'Hidrogén'**
  String get rrGasHydrogen;

  /// No description provided for @rrGasHydrogenCyanide.
  ///
  /// In hu, this message translates to:
  /// **'Hidrogén-cianid'**
  String get rrGasHydrogenCyanide;

  /// No description provided for @rrGasVoc.
  ///
  /// In hu, this message translates to:
  /// **'Illékony szerves vegyületek'**
  String get rrGasVoc;

  /// No description provided for @rrGasSulfurDioxide.
  ///
  /// In hu, this message translates to:
  /// **'Kén-dioxid'**
  String get rrGasSulfurDioxide;

  /// No description provided for @rrGasSulfurHexafluoride.
  ///
  /// In hu, this message translates to:
  /// **'Kén-hexafluorid'**
  String get rrGasSulfurHexafluoride;

  /// No description provided for @rrGasHydrogenSulfide.
  ///
  /// In hu, this message translates to:
  /// **'Kén-hidrogén'**
  String get rrGasHydrogenSulfide;

  /// No description provided for @rrGasChlorine.
  ///
  /// In hu, this message translates to:
  /// **'Klór'**
  String get rrGasChlorine;

  /// No description provided for @rrGasMethane.
  ///
  /// In hu, this message translates to:
  /// **'Metán'**
  String get rrGasMethane;

  /// No description provided for @rrGasMethanol.
  ///
  /// In hu, this message translates to:
  /// **'Metanol'**
  String get rrGasMethanol;

  /// No description provided for @rrGasMethylSalicylate.
  ///
  /// In hu, this message translates to:
  /// **'Metil-szalicilát'**
  String get rrGasMethylSalicylate;

  /// No description provided for @rrGasNitricOxide.
  ///
  /// In hu, this message translates to:
  /// **'Nitrogén-monoxid'**
  String get rrGasNitricOxide;

  /// No description provided for @rrGasNitrogenDioxide.
  ///
  /// In hu, this message translates to:
  /// **'Nitrogén-dioxid'**
  String get rrGasNitrogenDioxide;

  /// No description provided for @rrGasNitrogenOxides.
  ///
  /// In hu, this message translates to:
  /// **'Nitrogén-oxidok'**
  String get rrGasNitrogenOxides;

  /// No description provided for @rrGasOxygen.
  ///
  /// In hu, this message translates to:
  /// **'Oxigén'**
  String get rrGasOxygen;

  /// No description provided for @rrGasOzone.
  ///
  /// In hu, this message translates to:
  /// **'Ózon'**
  String get rrGasOzone;

  /// No description provided for @rrGasPropane.
  ///
  /// In hu, this message translates to:
  /// **'Propán'**
  String get rrGasPropane;

  /// No description provided for @rrGasCarbonDioxide.
  ///
  /// In hu, this message translates to:
  /// **'Szén-dioxid'**
  String get rrGasCarbonDioxide;

  /// No description provided for @rrGasCarbonMonoxide.
  ///
  /// In hu, this message translates to:
  /// **'Szén-monoxid'**
  String get rrGasCarbonMonoxide;

  /// No description provided for @rrGasToluene.
  ///
  /// In hu, this message translates to:
  /// **'Toluol'**
  String get rrGasToluene;

  /// No description provided for @rrGasTributylPhosphate.
  ///
  /// In hu, this message translates to:
  /// **'Tributil-foszfát'**
  String get rrGasTributylPhosphate;

  /// No description provided for @measurementTypeMeteorology.
  ///
  /// In hu, this message translates to:
  /// **'Meteorológia'**
  String get measurementTypeMeteorology;

  /// No description provided for @measurementTypeGasMeasurement.
  ///
  /// In hu, this message translates to:
  /// **'Gázmérés'**
  String get measurementTypeGasMeasurement;

  /// No description provided for @mapAreaButtonTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Terület jelölése'**
  String get mapAreaButtonTooltip;

  /// No description provided for @mapAreaListTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Jelölt területek'**
  String get mapAreaListTooltip;

  /// No description provided for @mapAreaNewTitle.
  ///
  /// In hu, this message translates to:
  /// **'Új terület'**
  String get mapAreaNewTitle;

  /// No description provided for @mapAreaNameLabel.
  ///
  /// In hu, this message translates to:
  /// **'Név (pl. Felmért terület)'**
  String get mapAreaNameLabel;

  /// No description provided for @mapAreaNameRequired.
  ///
  /// In hu, this message translates to:
  /// **'Adja meg a terület nevét.'**
  String get mapAreaNameRequired;

  /// No description provided for @mapAreaShapeLabel.
  ///
  /// In hu, this message translates to:
  /// **'Alakzat'**
  String get mapAreaShapeLabel;

  /// No description provided for @mapAreaPolygon.
  ///
  /// In hu, this message translates to:
  /// **'Poligon'**
  String get mapAreaPolygon;

  /// No description provided for @mapAreaCircle.
  ///
  /// In hu, this message translates to:
  /// **'Kör'**
  String get mapAreaCircle;

  /// No description provided for @mapAreaColorLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szín'**
  String get mapAreaColorLabel;

  /// No description provided for @mapAreaStartDrawing.
  ///
  /// In hu, this message translates to:
  /// **'Rajzolás'**
  String get mapAreaStartDrawing;

  /// No description provided for @mapAreaHintPolygon.
  ///
  /// In hu, this message translates to:
  /// **'Koppintással jelölje a sarokpontokat, majd nyomja meg a Kész gombot.'**
  String get mapAreaHintPolygon;

  /// No description provided for @mapAreaHintCircle.
  ///
  /// In hu, this message translates to:
  /// **'Koppintással jelölje a középpontot, majd egy pontot a sugár megadásához.'**
  String get mapAreaHintCircle;

  /// No description provided for @mapAreaMinPointsError.
  ///
  /// In hu, this message translates to:
  /// **'Legalább 3 sarokpont kell.'**
  String get mapAreaMinPointsError;

  /// No description provided for @mapAreaCircleIncomplete.
  ///
  /// In hu, this message translates to:
  /// **'Jelölje meg a középpontot és a sugarat is.'**
  String get mapAreaCircleIncomplete;

  /// No description provided for @mapAreaUndo.
  ///
  /// In hu, this message translates to:
  /// **'Visszavonás'**
  String get mapAreaUndo;

  /// No description provided for @mapAreaDone.
  ///
  /// In hu, this message translates to:
  /// **'Kész'**
  String get mapAreaDone;

  /// No description provided for @mapAreaNoAreas.
  ///
  /// In hu, this message translates to:
  /// **'Nincs jelölt terület.'**
  String get mapAreaNoAreas;

  /// No description provided for @mapAreaDeleteConfirm.
  ///
  /// In hu, this message translates to:
  /// **'Törli a kijelölt területet?'**
  String get mapAreaDeleteConfirm;

  /// No description provided for @mapAreaDeleteTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Terület törlése'**
  String get mapAreaDeleteTooltip;

  /// No description provided for @unitConverterTitle.
  ///
  /// In hu, this message translates to:
  /// **'Mértékegység-váltó'**
  String get unitConverterTitle;

  /// No description provided for @unitConverterCategoryLabel.
  ///
  /// In hu, this message translates to:
  /// **'Mennyiség'**
  String get unitConverterCategoryLabel;

  /// No description provided for @unitConverterValueLabel.
  ///
  /// In hu, this message translates to:
  /// **'Érték'**
  String get unitConverterValueLabel;

  /// No description provided for @unitConverterFromLabel.
  ///
  /// In hu, this message translates to:
  /// **'Kiindulási egység'**
  String get unitConverterFromLabel;

  /// No description provided for @unitConverterMolarMassLabel.
  ///
  /// In hu, this message translates to:
  /// **'Moláris tömeg (g/mol)'**
  String get unitConverterMolarMassLabel;

  /// No description provided for @unitConverterMolarMassHint.
  ///
  /// In hu, this message translates to:
  /// **'Tömeg- és térfogat-koncentráció között a gáz moláris tömege kell, pl. CO: 28,01. Számítás 25 °C-on, 1 atm nyomáson.'**
  String get unitConverterMolarMassHint;

  /// No description provided for @unitConverterNeedsMolarMass.
  ///
  /// In hu, this message translates to:
  /// **'Adja meg a moláris tömeget a tömeg- és térfogat-egységek közötti számításhoz.'**
  String get unitConverterNeedsMolarMass;

  /// No description provided for @unitConverterEnterValue.
  ///
  /// In hu, this message translates to:
  /// **'Adjon meg egy értéket.'**
  String get unitConverterEnterValue;

  /// No description provided for @unitConverterTapHint.
  ///
  /// In hu, this message translates to:
  /// **'Koppintson egy sorra: az érték átíródik arra az egységre, és az lesz a kiindulási egység.'**
  String get unitConverterTapHint;

  /// No description provided for @unitConverterGasNote.
  ///
  /// In hu, this message translates to:
  /// **'A gázkoncentráció %LEL egysége nem váltható át, mert a gáz határértékétől függ.'**
  String get unitConverterGasNote;

  /// No description provided for @unitCatDose.
  ///
  /// In hu, this message translates to:
  /// **'Dózis'**
  String get unitCatDose;

  /// No description provided for @unitCatDoseRate.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítmény'**
  String get unitCatDoseRate;

  /// No description provided for @unitCatActivity.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás'**
  String get unitCatActivity;

  /// No description provided for @unitCatActivityConcentration.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitáskoncentráció'**
  String get unitCatActivityConcentration;

  /// No description provided for @unitCatSurfaceContamination.
  ///
  /// In hu, this message translates to:
  /// **'Felületi szennyezettség'**
  String get unitCatSurfaceContamination;

  /// No description provided for @unitCatCountRate.
  ///
  /// In hu, this message translates to:
  /// **'Beütésszám'**
  String get unitCatCountRate;

  /// No description provided for @unitCatLength.
  ///
  /// In hu, this message translates to:
  /// **'Hosszúság'**
  String get unitCatLength;

  /// No description provided for @unitCatArea.
  ///
  /// In hu, this message translates to:
  /// **'Terület'**
  String get unitCatArea;

  /// No description provided for @unitCatVolume.
  ///
  /// In hu, this message translates to:
  /// **'Térfogat'**
  String get unitCatVolume;

  /// No description provided for @unitCatMass.
  ///
  /// In hu, this message translates to:
  /// **'Tömeg'**
  String get unitCatMass;

  /// No description provided for @unitCatTemperature.
  ///
  /// In hu, this message translates to:
  /// **'Hőmérséklet'**
  String get unitCatTemperature;

  /// No description provided for @unitCatPressure.
  ///
  /// In hu, this message translates to:
  /// **'Nyomás'**
  String get unitCatPressure;

  /// No description provided for @unitCatSpeed.
  ///
  /// In hu, this message translates to:
  /// **'Sebesség'**
  String get unitCatSpeed;

  /// No description provided for @unitCatTime.
  ///
  /// In hu, this message translates to:
  /// **'Idő'**
  String get unitCatTime;

  /// No description provided for @unitCatIrradiance.
  ///
  /// In hu, this message translates to:
  /// **'Sugárzási teljesítmény'**
  String get unitCatIrradiance;

  /// No description provided for @unitCatRainRate.
  ///
  /// In hu, this message translates to:
  /// **'Csapadék-intenzitás'**
  String get unitCatRainRate;

  /// No description provided for @unitCatMassConcentration.
  ///
  /// In hu, this message translates to:
  /// **'Tömegkoncentráció (aeroszol)'**
  String get unitCatMassConcentration;

  /// No description provided for @unitCatGasConcentration.
  ///
  /// In hu, this message translates to:
  /// **'Gázkoncentráció'**
  String get unitCatGasConcentration;

  /// No description provided for @unitConverterGasPick.
  ///
  /// In hu, this message translates to:
  /// **'Gáz kiválasztása (kitölti a moláris tömeget)'**
  String get unitConverterGasPick;

  /// No description provided for @decayCalcTitle.
  ///
  /// In hu, this message translates to:
  /// **'Bomlás-számító'**
  String get decayCalcTitle;

  /// No description provided for @decayCalcIsotope.
  ///
  /// In hu, this message translates to:
  /// **'Izotóp'**
  String get decayCalcIsotope;

  /// No description provided for @decayCalcCustom.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb (kézi felezési idő)'**
  String get decayCalcCustom;

  /// No description provided for @decayCalcHalfLife.
  ///
  /// In hu, this message translates to:
  /// **'Felezési idő'**
  String get decayCalcHalfLife;

  /// No description provided for @decayCalcInitialActivity.
  ///
  /// In hu, this message translates to:
  /// **'Kezdeti aktivitás'**
  String get decayCalcInitialActivity;

  /// No description provided for @decayCalcElapsed.
  ///
  /// In hu, this message translates to:
  /// **'Eltelt idő'**
  String get decayCalcElapsed;

  /// No description provided for @decayCalcTargetActivity.
  ///
  /// In hu, this message translates to:
  /// **'Célaktivitás'**
  String get decayCalcTargetActivity;

  /// No description provided for @decayCalcModeForward.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás t idő után'**
  String get decayCalcModeForward;

  /// No description provided for @decayCalcModeBackward.
  ///
  /// In hu, this message translates to:
  /// **'Idő a célaktivitásig'**
  String get decayCalcModeBackward;

  /// No description provided for @decayCalcDistance.
  ///
  /// In hu, this message translates to:
  /// **'Távolság (m, opcionális)'**
  String get decayCalcDistance;

  /// No description provided for @decayCalcResultActivity.
  ///
  /// In hu, this message translates to:
  /// **'Aktivitás'**
  String get decayCalcResultActivity;

  /// No description provided for @decayCalcResultRemaining.
  ///
  /// In hu, this message translates to:
  /// **'Megmaradt hányad'**
  String get decayCalcResultRemaining;

  /// No description provided for @decayCalcResultHalfLives.
  ///
  /// In hu, this message translates to:
  /// **'Felezési idők száma'**
  String get decayCalcResultHalfLives;

  /// No description provided for @decayCalcResultDoseRate.
  ///
  /// In hu, this message translates to:
  /// **'Dózisteljesítmény a távolságban'**
  String get decayCalcResultDoseRate;

  /// No description provided for @decayCalcResultTime.
  ///
  /// In hu, this message translates to:
  /// **'Szükséges idő'**
  String get decayCalcResultTime;

  /// No description provided for @decayCalcErrorTarget.
  ///
  /// In hu, this message translates to:
  /// **'A célaktivitásnak pozitívnak és kisebbnek kell lennie a kezdeti aktivitásnál.'**
  String get decayCalcErrorTarget;

  /// No description provided for @decayCalcNeedsInput.
  ///
  /// In hu, this message translates to:
  /// **'Adja meg a számokat.'**
  String get decayCalcNeedsInput;

  /// No description provided for @decayCalcNoHalfLife.
  ///
  /// In hu, this message translates to:
  /// **'Adja meg a felezési időt.'**
  String get decayCalcNoHalfLife;

  /// No description provided for @decayCalcNote.
  ///
  /// In hu, this message translates to:
  /// **'Tiszta exponenciális bomlás; a leánynuklidokat és a többi sugárzást nem veszi figyelembe.'**
  String get decayCalcNote;

  /// No description provided for @doseLimitTitle.
  ///
  /// In hu, this message translates to:
  /// **'Éves dózis-keret'**
  String get doseLimitTitle;

  /// No description provided for @doseLimitCategoryOccupational.
  ///
  /// In hu, this message translates to:
  /// **'Foglalkozásszerű'**
  String get doseLimitCategoryOccupational;

  /// No description provided for @doseLimitCategoryPublic.
  ///
  /// In hu, this message translates to:
  /// **'Lakosság'**
  String get doseLimitCategoryPublic;

  /// No description provided for @doseLimitSourceOah.
  ///
  /// In hu, this message translates to:
  /// **'OAH 2/2022 (IV. 29.) rendelet'**
  String get doseLimitSourceOah;

  /// No description provided for @doseLimitSourceIaea.
  ///
  /// In hu, this message translates to:
  /// **'IAEA GSR Part 3'**
  String get doseLimitSourceIaea;

  /// No description provided for @doseLimitUsedLabel.
  ///
  /// In hu, this message translates to:
  /// **'kihasználtság'**
  String get doseLimitUsedLabel;

  /// No description provided for @doseLimitStatusOk.
  ///
  /// In hu, this message translates to:
  /// **'keret rendben'**
  String get doseLimitStatusOk;

  /// No description provided for @doseLimitStatusWarning.
  ///
  /// In hu, this message translates to:
  /// **'figyelmeztetési szint elérve'**
  String get doseLimitStatusWarning;

  /// No description provided for @doseLimitStatusExceeded.
  ///
  /// In hu, this message translates to:
  /// **'keret túllépve'**
  String get doseLimitStatusExceeded;

  /// No description provided for @doseLimitNote.
  ///
  /// In hu, this message translates to:
  /// **'Egyéves összeg vizsgálata; az IAEA 5 éves átlagolása nincs figyelembe véve.'**
  String get doseLimitNote;

  /// No description provided for @displayUnitsHint.
  ///
  /// In hu, this message translates to:
  /// **'A megjelenítés és a jegyzőkönyv ezt használja. Az adatexport (CSV, JSON) és a mentés mindig az eredeti, tárolt egységben marad.'**
  String get displayUnitsHint;

  /// No description provided for @displayDoseUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Személyes dózis egysége'**
  String get displayDoseUnitLabel;

  /// No description provided for @displayDoseAutoOption.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus (µSv, 1 mSv felett mSv)'**
  String get displayDoseAutoOption;

  /// No description provided for @displaySurfaceUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Felületi szennyezettség egysége'**
  String get displaySurfaceUnitLabel;

  /// No description provided for @displayTemperatureUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Hőmérséklet egysége'**
  String get displayTemperatureUnitLabel;

  /// No description provided for @displayPressureUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Nyomás egysége'**
  String get displayPressureUnitLabel;

  /// No description provided for @displayWindUnitLabel.
  ///
  /// In hu, this message translates to:
  /// **'Szélsebesség egysége'**
  String get displayWindUnitLabel;

  /// No description provided for @protoTitle.
  ///
  /// In hu, this message translates to:
  /// **'Terepi sugárzásmérési jegyzőkönyv'**
  String get protoTitle;

  /// No description provided for @protoCompany.
  ///
  /// In hu, this message translates to:
  /// **'Cég'**
  String get protoCompany;

  /// No description provided for @protoSurveyName.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés megnevezése'**
  String get protoSurveyName;

  /// No description provided for @protoLocation.
  ///
  /// In hu, this message translates to:
  /// **'Helyszín'**
  String get protoLocation;

  /// No description provided for @protoStarted.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés kezdete'**
  String get protoStarted;

  /// No description provided for @protoClosed.
  ///
  /// In hu, this message translates to:
  /// **'Felmérés lezárása'**
  String get protoClosed;

  /// No description provided for @protoNotes.
  ///
  /// In hu, this message translates to:
  /// **'Megjegyzés'**
  String get protoNotes;

  /// No description provided for @protoOngoing.
  ///
  /// In hu, this message translates to:
  /// **'folyamatban'**
  String get protoOngoing;

  /// No description provided for @protoDate.
  ///
  /// In hu, this message translates to:
  /// **'Dátum'**
  String get protoDate;

  /// No description provided for @protoSignature.
  ///
  /// In hu, this message translates to:
  /// **'Aláírás'**
  String get protoSignature;

  /// No description provided for @protoSurveyedBy.
  ///
  /// In hu, this message translates to:
  /// **'Felmérést végezte'**
  String get protoSurveyedBy;

  /// No description provided for @protoColon.
  ///
  /// In hu, this message translates to:
  /// **': '**
  String get protoColon;

  /// No description provided for @protoDecimalSep.
  ///
  /// In hu, this message translates to:
  /// **','**
  String get protoDecimalSep;

  /// No description provided for @protoDateTimeFormat.
  ///
  /// In hu, this message translates to:
  /// **'yyyy.MM.dd HH:mm'**
  String get protoDateTimeFormat;

  /// No description provided for @protoDateFormat.
  ///
  /// In hu, this message translates to:
  /// **'yyyy.MM.dd'**
  String get protoDateFormat;

  /// No description provided for @protoPointsHeading.
  ///
  /// In hu, this message translates to:
  /// **'Mérési pontok'**
  String get protoPointsHeading;

  /// No description provided for @protoSourceHeading.
  ///
  /// In hu, this message translates to:
  /// **'Sugárforrás-elemzés'**
  String get protoSourceHeading;

  /// No description provided for @protoNoSourcePoints.
  ///
  /// In hu, this message translates to:
  /// **'Nincs forrással vagy aktivitás-becsléssel rendelkező mérési pont.'**
  String get protoNoSourcePoints;

  /// No description provided for @protoSourceNote.
  ///
  /// In hu, this message translates to:
  /// **'Csak a forrással vagy aktivitás-becsléssel rendelkező mérési pontok szerepelnek. A számított értékek tájékoztató jellegűek.'**
  String get protoSourceNote;

  /// No description provided for @protoDosimeterHeading.
  ///
  /// In hu, this message translates to:
  /// **'Doziméterek'**
  String get protoDosimeterHeading;

  /// No description provided for @protoVictimsHeading.
  ///
  /// In hu, this message translates to:
  /// **'Érintettek (áldozatok)'**
  String get protoVictimsHeading;

  /// No description provided for @protoAreasHeading.
  ///
  /// In hu, this message translates to:
  /// **'Jelölt területek'**
  String get protoAreasHeading;

  /// No description provided for @protoMeteoHeading.
  ///
  /// In hu, this message translates to:
  /// **'Meteorológia'**
  String get protoMeteoHeading;

  /// No description provided for @protoGasHeading.
  ///
  /// In hu, this message translates to:
  /// **'Gázmérés'**
  String get protoGasHeading;

  /// No description provided for @protoPhotosHeading.
  ///
  /// In hu, this message translates to:
  /// **'Fényképek'**
  String get protoPhotosHeading;

  /// No description provided for @protoScreenshotsHeading.
  ///
  /// In hu, this message translates to:
  /// **'Képernyőképek'**
  String get protoScreenshotsHeading;

  /// No description provided for @protoPhotoUnreadable.
  ///
  /// In hu, this message translates to:
  /// **'(a fénykép nem olvasható)'**
  String get protoPhotoUnreadable;

  /// No description provided for @protoNoDosimeter.
  ///
  /// In hu, this message translates to:
  /// **'Nincs felvett doziméter'**
  String get protoNoDosimeter;

  /// No description provided for @protoYes.
  ///
  /// In hu, this message translates to:
  /// **'igen'**
  String get protoYes;

  /// No description provided for @protoNo.
  ///
  /// In hu, this message translates to:
  /// **'nem'**
  String get protoNo;

  /// No description provided for @protoColType.
  ///
  /// In hu, this message translates to:
  /// **'Típus'**
  String get protoColType;

  /// No description provided for @protoColValue.
  ///
  /// In hu, this message translates to:
  /// **'Érték'**
  String get protoColValue;

  /// No description provided for @protoColUnit.
  ///
  /// In hu, this message translates to:
  /// **'Egység'**
  String get protoColUnit;

  /// No description provided for @protoColDistance.
  ///
  /// In hu, this message translates to:
  /// **'Táv. forrástól ({unit})'**
  String protoColDistance(String unit);

  /// No description provided for @protoColInstrument.
  ///
  /// In hu, this message translates to:
  /// **'Műszer'**
  String get protoColInstrument;

  /// No description provided for @protoColGps.
  ///
  /// In hu, this message translates to:
  /// **'GPS koordináta'**
  String get protoColGps;

  /// No description provided for @protoColGpsAccuracy.
  ///
  /// In hu, this message translates to:
  /// **'GPS pontosság ({unit})'**
  String protoColGpsAccuracy(String unit);

  /// No description provided for @protoColTime.
  ///
  /// In hu, this message translates to:
  /// **'Időpont'**
  String get protoColTime;

  /// No description provided for @protoColPhoto.
  ///
  /// In hu, this message translates to:
  /// **'Fénykép fájl'**
  String get protoColPhoto;

  /// No description provided for @protoColEstActivity.
  ///
  /// In hu, this message translates to:
  /// **'Becsült aktivitás (mérésből)'**
  String get protoColEstActivity;

  /// No description provided for @protoColAttached.
  ///
  /// In hu, this message translates to:
  /// **'Hozzárendelt forrás(ok)'**
  String get protoColAttached;

  /// No description provided for @protoColCalcTotal.
  ///
  /// In hu, this message translates to:
  /// **'Számított dózisteljesítmény'**
  String get protoColCalcTotal;

  /// No description provided for @protoColMeasured.
  ///
  /// In hu, this message translates to:
  /// **'Mért dózisteljesítmény'**
  String get protoColMeasured;

  /// No description provided for @protoColDiff.
  ///
  /// In hu, this message translates to:
  /// **'Eltérés'**
  String get protoColDiff;

  /// No description provided for @protoColIdentifier.
  ///
  /// In hu, this message translates to:
  /// **'Azonosító'**
  String get protoColIdentifier;

  /// No description provided for @protoColWearer.
  ///
  /// In hu, this message translates to:
  /// **'Viselő'**
  String get protoColWearer;

  /// No description provided for @protoColReading.
  ///
  /// In hu, this message translates to:
  /// **'Állás (kezdő → záró)'**
  String get protoColReading;

  /// No description provided for @protoColDose.
  ///
  /// In hu, this message translates to:
  /// **'Dózis'**
  String get protoColDose;

  /// No description provided for @protoColCounted.
  ///
  /// In hu, this message translates to:
  /// **'Beszámít'**
  String get protoColCounted;

  /// No description provided for @protoColFormula.
  ///
  /// In hu, this message translates to:
  /// **'Képlet'**
  String get protoColFormula;

  /// No description provided for @protoColName.
  ///
  /// In hu, this message translates to:
  /// **'Név'**
  String get protoColName;

  /// No description provided for @protoColTriage.
  ///
  /// In hu, this message translates to:
  /// **'Triázs'**
  String get protoColTriage;

  /// No description provided for @protoColInjuries.
  ///
  /// In hu, this message translates to:
  /// **'Sérülések'**
  String get protoColInjuries;

  /// No description provided for @protoColIllnesses.
  ///
  /// In hu, this message translates to:
  /// **'Betegségek'**
  String get protoColIllnesses;

  /// No description provided for @protoColAreaName.
  ///
  /// In hu, this message translates to:
  /// **'Terület megnevezése'**
  String get protoColAreaName;

  /// No description provided for @protoColShape.
  ///
  /// In hu, this message translates to:
  /// **'Alakzat'**
  String get protoColShape;

  /// No description provided for @protoColGeometry.
  ///
  /// In hu, this message translates to:
  /// **'Geometria'**
  String get protoColGeometry;

  /// No description provided for @protoColAreaSize.
  ///
  /// In hu, this message translates to:
  /// **'Felület (m²)'**
  String get protoColAreaSize;

  /// No description provided for @protoColTemp.
  ///
  /// In hu, this message translates to:
  /// **'Hőm. ({unit})'**
  String protoColTemp(String unit);

  /// No description provided for @protoColHumidity.
  ///
  /// In hu, this message translates to:
  /// **'Pára (%)'**
  String get protoColHumidity;

  /// No description provided for @protoColPressure.
  ///
  /// In hu, this message translates to:
  /// **'Nyomás ({unit})'**
  String protoColPressure(String unit);

  /// No description provided for @protoColWind.
  ///
  /// In hu, this message translates to:
  /// **'Szél ({unit})'**
  String protoColWind(String unit);

  /// No description provided for @protoColWindDir.
  ///
  /// In hu, this message translates to:
  /// **'Szélirány (°)'**
  String get protoColWindDir;

  /// No description provided for @protoColGust.
  ///
  /// In hu, this message translates to:
  /// **'Széllökés ({unit})'**
  String protoColGust(String unit);

  /// No description provided for @protoColPrecip.
  ///
  /// In hu, this message translates to:
  /// **'Csapadék'**
  String get protoColPrecip;

  /// No description provided for @protoColPrecipIntensity.
  ///
  /// In hu, this message translates to:
  /// **'Csapadék int. (mm/h)'**
  String get protoColPrecipIntensity;

  /// No description provided for @protoColSolar.
  ///
  /// In hu, this message translates to:
  /// **'Napsugárzás (W/m²)'**
  String get protoColSolar;

  /// No description provided for @protoColCloud.
  ///
  /// In hu, this message translates to:
  /// **'Felhőzet (okta)'**
  String get protoColCloud;

  /// No description provided for @protoColVisibility.
  ///
  /// In hu, this message translates to:
  /// **'Látástáv. (m)'**
  String get protoColVisibility;

  /// No description provided for @protoColSoil.
  ///
  /// In hu, this message translates to:
  /// **'Talajnedv. (%)'**
  String get protoColSoil;

  /// No description provided for @protoColAerosol.
  ///
  /// In hu, this message translates to:
  /// **'Aeroszol (µg/m³)'**
  String get protoColAerosol;

  /// No description provided for @protoColOther.
  ///
  /// In hu, this message translates to:
  /// **'Egyéb'**
  String get protoColOther;

  /// No description provided for @protoShapePolygon.
  ///
  /// In hu, this message translates to:
  /// **'Poligon'**
  String get protoShapePolygon;

  /// No description provided for @protoShapeCircle.
  ///
  /// In hu, this message translates to:
  /// **'Kör'**
  String get protoShapeCircle;

  /// No description provided for @protoCornerPoints.
  ///
  /// In hu, this message translates to:
  /// **'{count} sarokpont'**
  String protoCornerPoints(String count);

  /// No description provided for @protoCenterRadius.
  ///
  /// In hu, this message translates to:
  /// **'középpont: {lat}, {lon}; sugár: {radius} m'**
  String protoCenterRadius(String lat, String lon, String radius);

  /// No description provided for @protoPersonDose.
  ///
  /// In hu, this message translates to:
  /// **'{name} (dózis: {total})'**
  String protoPersonDose(String name, String total);

  /// No description provided for @protoPersonDoseBreakdown.
  ///
  /// In hu, this message translates to:
  /// **'{name} (dózis: {total} – {breakdown})'**
  String protoPersonDoseBreakdown(String name, String total, String breakdown);

  /// No description provided for @protoDoseSession.
  ///
  /// In hu, this message translates to:
  /// **'felmérési {dose}'**
  String protoDoseSession(String dose);

  /// No description provided for @protoDoseDosimeter.
  ///
  /// In hu, this message translates to:
  /// **'doziméter {dose}'**
  String protoDoseDosimeter(String dose);

  /// No description provided for @protoInstrumentWithSerial.
  ///
  /// In hu, this message translates to:
  /// **'{name} (s/n: {serial})'**
  String protoInstrumentWithSerial(String name, String serial);

  /// No description provided for @protoCalibValidUntil.
  ///
  /// In hu, this message translates to:
  /// **'érvényes: {date}-ig'**
  String protoCalibValidUntil(String date);

  /// No description provided for @protoCalibCertificate.
  ///
  /// In hu, this message translates to:
  /// **'bizonylat: {number}'**
  String protoCalibCertificate(String number);

  /// No description provided for @protoCalibExpiredAtMeasure.
  ///
  /// In hu, this message translates to:
  /// **' – LEJÁRT a mérés időpontjában'**
  String get protoCalibExpiredAtMeasure;

  /// No description provided for @protoCalibFallback.
  ///
  /// In hu, this message translates to:
  /// **'Kalibráció érvényes: {date}-ig'**
  String protoCalibFallback(String date);

  /// No description provided for @protoUnshielded.
  ///
  /// In hu, this message translates to:
  /// **'árnyékolás nélkül'**
  String get protoUnshielded;

  /// No description provided for @protoShieldedActivity.
  ///
  /// In hu, this message translates to:
  /// **'árnyékolt: {activity}'**
  String protoShieldedActivity(String activity);

  /// No description provided for @protoInputData.
  ///
  /// In hu, this message translates to:
  /// **'Bemenő adatok: mért {measured}, távolság {distance}'**
  String protoInputData(String measured, String distance);

  /// No description provided for @protoShieldingInline.
  ///
  /// In hu, this message translates to:
  /// **'árnyékolás'**
  String get protoShieldingInline;

  /// No description provided for @protoTransmission.
  ///
  /// In hu, this message translates to:
  /// **'áteresztés T = {value}'**
  String protoTransmission(String value);

  /// No description provided for @protoNuclideIdPrefix.
  ///
  /// In hu, this message translates to:
  /// **'Nuklid-azonosítás: {text}'**
  String protoNuclideIdPrefix(String text);

  /// No description provided for @protoShotMap.
  ///
  /// In hu, this message translates to:
  /// **'Térkép'**
  String get protoShotMap;

  /// No description provided for @protoShotList.
  ///
  /// In hu, this message translates to:
  /// **'Pontok listája'**
  String get protoShotList;

  /// No description provided for @protoPhotoCaption.
  ///
  /// In hu, this message translates to:
  /// **'{index}. pont · {type} · {location} · {time}'**
  String protoPhotoCaption(
    String index,
    String type,
    String location,
    String time,
  );

  /// No description provided for @mapMeasureTooltip.
  ///
  /// In hu, this message translates to:
  /// **'Távolságmérés'**
  String get mapMeasureTooltip;

  /// No description provided for @mapMeasureHint.
  ///
  /// In hu, this message translates to:
  /// **'Koppints két pontra a vonalhoz. A vonal címkéjére koppintva kijelölheted, színezheted vagy törölheted.'**
  String get mapMeasureHint;

  /// No description provided for @mapMeasureClear.
  ///
  /// In hu, this message translates to:
  /// **'Összes törlése'**
  String get mapMeasureClear;

  /// No description provided for @mapMeasureDeleteSelected.
  ///
  /// In hu, this message translates to:
  /// **'Kijelölt törlése'**
  String get mapMeasureDeleteSelected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hu',
    'it',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hu':
      return AppLocalizationsHu();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
