// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'RadRecon';

  @override
  String get instrumentsTooltip => 'Strumenti';

  @override
  String get searchHint => 'Cerca';

  @override
  String get searchNoResults => 'Nessun risultato corrispondente';

  @override
  String get alertThresholdsTooltip => 'Soglie di allarme';

  @override
  String get noSurveysYet =>
      'Ancora nessun sopralluogo. Avviane uno con il pulsante +.';

  @override
  String get newSurveyButton => 'Nuovo sopralluogo';

  @override
  String get newSurveyDialogTitle => 'Nuovo sopralluogo';

  @override
  String get surveyNameLabel => 'Nome';

  @override
  String get surveyLocationLabel => 'Luogo (facoltativo)';

  @override
  String get editSurveyDetailsTooltip => 'Modifica nome e luogo';

  @override
  String get editSurveyDetailsTitle => 'Modifica i dati del sopralluogo';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get deletePointTooltip => 'Elimina punto di misura';

  @override
  String get deletePointTitle => 'Elimina punto di misura';

  @override
  String get deletePointBody =>
      'Eliminare questo punto di misura? Verranno eliminate anche le assegnazioni delle sorgenti e il registro delle modifiche. L\'operazione non è reversibile.';

  @override
  String get startButton => 'Avvia';

  @override
  String surveyDefaultTitle(String date) {
    return 'Sopralluogo – $date';
  }

  @override
  String get noLocationPlaceholder => '—';

  @override
  String get doseUnitSectionTitle => 'Unità predefinita del rateo di dose';

  @override
  String get doseUnitSectionHint =>
      'Queste unità sono preselezionate per le nuove misure. Durante la registrazione se ne può scegliere un\'altra da un elenco, senza digitare, e il numero inserito viene convertito automaticamente al cambio di unità. Anche la soglia di allarme del rateo di dose viene convertita.';

  @override
  String get unitsSectionTitle => 'Unità';

  @override
  String get activityUnitLabel => 'Unità predefinita dell\'attività';

  @override
  String get distanceUnitLabel => 'Unità predefinita della distanza';

  @override
  String get activityPlainLabel => 'Attività';

  @override
  String get measuredDoseRatePlainLabel => 'Rateo di dose misurato';

  @override
  String get distanceFromSourcePlainLabel => 'Distanza dalla sorgente';

  @override
  String get sourceDistancePlainLabel => 'Distanza dal punto di misura';

  @override
  String get activityAtManufacturePlainLabel => 'Attività alla fabbricazione';

  @override
  String get invalidDistancePlainError =>
      'Inserisci una distanza valida e positiva.';

  @override
  String get invalidActivityPlainError => 'Inserisci un\'attività valida.';

  @override
  String get invalidDoseRatePlainError => 'Inserisci un rateo di dose valido.';

  @override
  String get distanceFromSourceShortLabel => 'Distanza dalla sorgente';

  @override
  String get calculatedActivityResultLabel => 'Attività calcolata';

  @override
  String get distanceIntervalPlainLabel => 'Intervallo di distanza';

  @override
  String get modbusQuantityLabel => 'Cosa restituisce il registro';

  @override
  String get modbusRegisterUnitLabel => 'Unità del registro';

  @override
  String get modbusQuantityHelper =>
      'Durante la registrazione l\'app converte il valore nell\'unità predefinita scelta nelle Impostazioni.';

  @override
  String get autoLogTypeFromInstrument =>
      'La registrazione automatica salva la grandezza configurata per lo strumento.';

  @override
  String get nuclideIdSectionTitle => 'Identificazione del nuclide';

  @override
  String get nuclideStatusNone => 'Non indicato';

  @override
  String get nuclideStatusIdentified => 'Nuclide/i identificato/i';

  @override
  String get nuclideStatusUnknown => 'Sconosciuto';

  @override
  String get nuclideStatusOther => 'Altro (non in elenco)';

  @override
  String get nuclideStatusMixture => 'Presumibilmente più sorgenti (miscela)';

  @override
  String get nuclideKnownListLabel => 'Nuclidi dall\'elenco';

  @override
  String get nuclideCustomLabel => 'Nome di un altro nuclide';

  @override
  String get nuclideAddButton => 'Aggiungi';

  @override
  String get nuclideRequiredError =>
      'Inserisci almeno un nuclide o scegli Sconosciuto.';

  @override
  String get csvHeaderNuclides => 'Identificazione del nuclide';

  @override
  String get nuclideDoneButton => 'Fatto';

  @override
  String get unshieldedActivityLabel => 'Attività (senza schermatura)';

  @override
  String get shieldingSectionTitle => 'Schermatura (facoltativa)';

  @override
  String get shieldingHint =>
      'Se la sorgente è dietro una schermatura, inserisci materiale e spessore: l\'app stimerà anche l\'attività reale della sorgente schermata.';

  @override
  String get shieldingMaterialLabel => 'Materiale della schermatura';

  @override
  String get shieldingNoneOption => 'Nessuna schermatura';

  @override
  String get shieldingThicknessLabel => 'Spessore della schermatura';

  @override
  String get shieldingThicknessError => 'Inserisci uno spessore positivo';

  @override
  String get shieldedActivityLabel =>
      'Attività stimata della sorgente schermata';

  @override
  String get shieldingDisclaimer =>
      'Stima approssimativa: l\'attenuazione è modellata con strati di dimezzamento (ogni strato dimezza il rateo di dose) usando valori indicativi. La radiazione diffusa (build-up), la geometria della sorgente e lo spettro sono semplificati, quindi il risultato tende a sovrastimare l\'attività. Per i protocolli ufficiali, verifica con una fonte autorevole.';

  @override
  String get shieldingMaterialLead => 'Piombo';

  @override
  String get shieldingMaterialSteel => 'Acciaio (ferro)';

  @override
  String get shieldingMaterialConcrete => 'Calcestruzzo';

  @override
  String get shieldingMaterialTungsten => 'Tungsteno';

  @override
  String get shieldingMaterialAluminium => 'Alluminio';

  @override
  String get shieldingMaterialWater => 'Acqua';

  @override
  String get csvUnshieldedNote => 'senza schermatura';

  @override
  String get csvShieldedSourceNote => 'sorgente schermata';

  @override
  String get shieldingAddLayer => 'Aggiungi strato';

  @override
  String get shieldingLayerLabel => 'Strato';

  @override
  String get shieldingRemoveLayer => 'Rimuovi strato';

  @override
  String get doseRateUnshieldedLabel => 'Rateo di dose (senza schermatura)';

  @override
  String get doseRateShieldedLabel => 'Rateo di dose dietro la schermatura';

  @override
  String get calibrationSectionTitle => 'Verifica e taratura';

  @override
  String get calibrationKindVerification => 'Verifica';

  @override
  String get calibrationKindCalibration => 'Taratura';

  @override
  String get calibrationAddButton => 'Aggiungi registrazione';

  @override
  String get calibrationDialogTitle => 'Registrazione di verifica / taratura';

  @override
  String get calibrationKindLabel => 'Tipo';

  @override
  String get calibrationPerformedOnLabel => 'Data di esecuzione';

  @override
  String get calibrationValidUntilLabel => 'Valido fino al';

  @override
  String get calibrationCertificateLabel => 'Numero del certificato';

  @override
  String get calibrationPerformedByLabel =>
      'Eseguita da (laboratorio / autorità)';

  @override
  String get calibrationAttachFile => 'Allega certificato';

  @override
  String get calibrationRemoveFile => 'Rimuovi allegato';

  @override
  String get calibrationOpenFile => 'Apri / condividi certificato';

  @override
  String get calibrationEmptyList => 'Ancora nessuna registrazione.';

  @override
  String get calibrationStatusValid => 'Valido';

  @override
  String get calibrationStatusSoon => 'In scadenza';

  @override
  String get calibrationStatusExpired => 'SCADUTO';

  @override
  String get calibrationStatusUnknown => 'Nessun dato';

  @override
  String get calibrationExpiredWarning =>
      'Attenzione: la verifica/taratura dello strumento selezionato è scaduta. Valido fino al:';

  @override
  String get calibrationSoonWarning =>
      'Attenzione: la verifica/taratura dello strumento selezionato scade a breve. Valido fino al:';

  @override
  String get calibrationUnknownWarning =>
      'Lo strumento selezionato non ha dati di verifica/taratura.';

  @override
  String get calibrationSaveAnywayTitle => 'Verifica/taratura scaduta';

  @override
  String get calibrationSaveAnywayBody =>
      'La misura è stata eseguita con uno strumento la cui verifica/taratura è scaduta; il protocollo lo segnalerà. Salvare comunque?';

  @override
  String get calibrationSaveAnywayConfirm => 'Salva comunque';

  @override
  String get calibrationValidUntilBeforeError =>
      'La validità non può essere precedente alla data di esecuzione';

  @override
  String get csvHeaderInstrumentCalibration =>
      'Verifica/taratura dello strumento';

  @override
  String get personPhoneLabel => 'Numero di telefono';

  @override
  String get personEmailLabel => 'Indirizzo e-mail';

  @override
  String get personAddEmail => 'Aggiungi indirizzo e-mail';

  @override
  String get personRemoveEmail => 'Rimuovi e-mail';

  @override
  String get personEmailInvalidError => 'Indirizzo e-mail non valido';

  @override
  String get personCertificatesTitle => 'Certificati';

  @override
  String get personCertificateAdd => 'Aggiungi certificato';

  @override
  String get personCertificateDialogTitle => 'Certificato';

  @override
  String get personCertificateNameLabel =>
      'Denominazione (es. esame di radioprotezione)';

  @override
  String get personCertificateNumberLabel => 'Numero del certificato';

  @override
  String get personCertificateIssuerLabel => 'Ente emittente';

  @override
  String get personCertificateIssuedLabel => 'Data di emissione';

  @override
  String get personCertificateNameRequired =>
      'Inserisci la denominazione del certificato';

  @override
  String get personCertificateValidBeforeError =>
      'La validità non può essere precedente alla data di emissione';

  @override
  String get personCertificatesEmpty => 'Ancora nessun certificato.';

  @override
  String get sourceCertificateTitle => 'Certificato della sorgente';

  @override
  String get sourceCertificateAttach => 'Allega certificato';

  @override
  String get sourceCertificateEmpty => 'Nessun certificato allegato.';

  @override
  String get companyDocumentsTooltip =>
      'Documenti e autorizzazioni dell\'azienda';

  @override
  String get companyDocumentNew => 'Nuovo documento';

  @override
  String get companyDocumentEdit => 'Modifica documento';

  @override
  String get companyDocumentTitleLabel => 'Nome del documento';

  @override
  String get companyDocumentIdentifierLabel =>
      'Identificativo (n. pratica / autorizzazione)';

  @override
  String get companyDocumentIssuerLabel => 'Ente emittente / autorità';

  @override
  String get companyDocumentIssuedLabel =>
      'Data di emissione / entrata in vigore';

  @override
  String get companyDocumentValidUntilLabel => 'Valido / da rivedere fino al';

  @override
  String get companyDocumentFilesTitle => 'File allegati';

  @override
  String get companyDocumentAttach => 'Allega file';

  @override
  String get companyDocumentsEmpty => 'Ancora nessun documento.';

  @override
  String get companyDocumentDeleteTitle => 'Elimina documento';

  @override
  String get companyDocumentDeleteConfirm => 'Eliminare questo documento?';

  @override
  String get companyDocSuggestionsLabel => 'Documenti comuni';

  @override
  String get companyDocSuggestRadiationPolicy =>
      'Regolamento di radioprotezione del luogo di lavoro';

  @override
  String get companyDocSuggestRadiationDescription =>
      'Descrizione della radioprotezione';

  @override
  String get companyDocSuggestPhysicalProtection =>
      'Piano di protezione fisica';

  @override
  String get companyDocSuggestEmergencyPlan => 'Piano di emergenza';

  @override
  String get companyDocSuggestOfficialLicense =>
      'Autorizzazione amministrativa';

  @override
  String get nuclideEditButton => 'Modifica nuclidi';

  @override
  String get languageSectionTitle => 'Lingua';

  @override
  String get languageSystemOption => 'Lingua del telefono';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get appearanceSectionTitle => 'Aspetto';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get alertThresholdExplanation =>
      'Se una misura registrata raggiunge o supera la soglia impostata qui, l\'app ti avvisa (suono + finestra). Lascia vuoto per non avere allarmi su quel tipo.';

  @override
  String get noThresholdSetHint => 'Nessuna soglia impostata';

  @override
  String get saveButton => 'Salva';

  @override
  String get settingsSavedMessage => 'Impostazioni salvate.';

  @override
  String get measurementTypeDoseRate => 'Rateo di dose';

  @override
  String get measurementTypeSurfaceContamination =>
      'Contaminazione superficiale';

  @override
  String get measurementTypeCps => 'Frequenza di conteggio (cps)';

  @override
  String get measurementTypeNeutronCps =>
      'Frequenza di conteggio neutronico (cps)';

  @override
  String get measurementTypeSample => 'Campionamento';

  @override
  String get instrumentDeleteTitle => 'Elimina strumento';

  @override
  String instrumentDeleteConfirm(String name) {
    return 'Eliminare \"$name\"? Le misure passate collegate vengono mantenute: viene rimosso solo il riferimento allo strumento.';
  }

  @override
  String get deleteButton => 'Elimina';

  @override
  String get noInstrumentsYet =>
      'Ancora nessuno strumento. Aggiungine uno con il pulsante +.';

  @override
  String get noCalibrationData => 'Nessun dato di taratura';

  @override
  String nextCalibrationOn(String date) {
    return 'Prossima taratura: $date';
  }

  @override
  String get noSerialNumber => 'nessun numero di serie';

  @override
  String get newInstrumentButton => 'Nuovo strumento';

  @override
  String get editInstrumentTitle => 'Modifica strumento';

  @override
  String get instrumentNameLabel => 'Nome / tipo dello strumento';

  @override
  String get requiredFieldError => 'Obbligatorio';

  @override
  String get serialNumberLabel => 'Numero di serie';

  @override
  String get nextCalibrationLabel => 'Data della prossima taratura';

  @override
  String get notSetLabel => 'Non impostato';

  @override
  String get calibrationFactorLabel => 'Fattore di taratura';

  @override
  String get modbusConnectedLabel => 'Raggiungibile via WiFi con Modbus/TCP';

  @override
  String get modbusHostLabel => 'Indirizzo IP / host';

  @override
  String get modbusPortLabel => 'Porta (es. 502)';

  @override
  String get modbusUnitIdLabel => 'ID unità Modbus (indirizzo slave)';

  @override
  String get modbusRegisterAddressLabel => 'Indirizzo del registro (es. 294)';

  @override
  String get modbusRegisterAddressHelper =>
      'Registro holding iniziale del valore misurato (float32)';

  @override
  String get modbusGpsEnabledLabel => 'Leggi la posizione GPS via Modbus';

  @override
  String get modbusGpsLatAddressLabel =>
      'Registro della latitudine (float32, predefinito 426)';

  @override
  String get modbusGpsLonAddressLabel =>
      'Registro della longitudine (float32, predefinito 428)';

  @override
  String get pickPositionTitle => 'Scegli una posizione';

  @override
  String get confirmPositionButton => 'Conferma posizione';

  @override
  String get isotopeCalculatorTitle => 'Calcolatore di isotopi';

  @override
  String get gammaConstantsDisclaimer =>
      'Le costanti Γ sono solo indicative. Per un protocollo ufficiale, verificale con una fonte autorevole prima di documentare il risultato.';

  @override
  String get isotopeLabel => 'Isotopo';

  @override
  String get modeDoseFromActivity => 'Attività in\nrateo di dose';

  @override
  String get modeActivityFromDose => 'Rateo di dose in\nattività';

  @override
  String get distanceFromSourceLabel => 'Distanza dalla sorgente (m)';

  @override
  String get activityLabel => 'Attività (MBq)';

  @override
  String get measuredDoseRateLabel => 'Rateo di dose misurato (µSv/h)';

  @override
  String get calculateButton => 'Calcola';

  @override
  String get invalidDistanceError =>
      'Inserisci una distanza (m) valida e positiva.';

  @override
  String get invalidActivityError => 'Inserisci un\'attività (MBq) valida.';

  @override
  String get invalidDoseRateError =>
      'Inserisci un rateo di dose (µSv/h) valido.';

  @override
  String calculationErrorMessage(String error) {
    return 'Errore di calcolo: $error';
  }

  @override
  String calculatedDoseRateResult(String uSvH, String nSvH) {
    return 'Rateo di dose calcolato: $uSvH µSv/h\n($nSvH nSv/h)';
  }

  @override
  String calculatedActivityResult(String mbq, String gbq) {
    return 'Attività calcolata: $mbq MBq\n($gbq GBq)';
  }

  @override
  String get distanceToolTitle => 'Misura della distanza';

  @override
  String get locationServiceDisabledError =>
      'I servizi di localizzazione sono disattivati.';

  @override
  String get locationPermissionDeniedError =>
      'Permesso di localizzazione negato.';

  @override
  String gpsErrorMessage(String error) {
    return 'Errore GPS: $error';
  }

  @override
  String get selectTargetFirstError => 'Scegli prima il punto di destinazione.';

  @override
  String get noGpsPositionError =>
      'Nessuna posizione GPS. Aggiorna o scegli un punto di partenza.';

  @override
  String get selectStartPointError => 'Scegli un punto di partenza.';

  @override
  String get selectTargetPointError => 'Scegli il punto di destinazione.';

  @override
  String get startFromCurrentPositionLabel =>
      'Partenza: la mia posizione attuale';

  @override
  String get noPositionFetchedYet => 'Non ancora acquisita';

  @override
  String get refreshGpsButton => 'Aggiorna GPS';

  @override
  String get startPointLabel => 'Punto di partenza';

  @override
  String get targetPointLabel => 'Punto di destinazione';

  @override
  String get liveTrackingLabel => 'Tracciamento in tempo reale';

  @override
  String get liveTrackingSubtitle =>
      'Aggiorna di continuo distanza e direzione mentre cammini.';

  @override
  String get calculateDistanceButton => 'Calcola';

  @override
  String get liveTrackingRunningHint =>
      'Il tracciamento in tempo reale è attivo: cammina nella direzione della freccia.';

  @override
  String get sourceSearchTitle => 'Ricerca della sorgente';

  @override
  String get measurementTypeLabel => 'Tipo di misura';

  @override
  String pointsRecordedForType(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punti registrati',
      one: '$count punto registrato',
    );
    return '$_temp0 per questo tipo in questo sopralluogo.';
  }

  @override
  String get lowConfidenceWarning =>
      'Pochi punti (< 4): la stima non è affidabile; esegui più misure in punti diversi dell\'area di ricerca.';

  @override
  String gradientEstimateLabel(String value, String unit) {
    return 'Gradiente stimato: $value $unit/m';
  }

  @override
  String get directionEstimateHint =>
      'Si stima che il valore misurato aumenti in questa direzione.';

  @override
  String get sourceSearchDisclaimer =>
      'La direzione suggerita si basa su una semplice stima lineare del gradiente a partire dai punti registrati finora in questo sopralluogo. Può essere imprecisa con dati di campo rumorosi, pochi punti, o quando la sorgente reale è lontana rispetto alle dimensioni dell\'area rilevata. Solo a scopo indicativo: non sostituisce il giudizio professionale.';

  @override
  String get newMeasurementButton => 'Nuova misura';

  @override
  String get mapTitle => 'Mappa';

  @override
  String get noPointsRecordedYet => 'Ancora nessun punto di misura registrato.';

  @override
  String get saveScreenshotTooltip => 'Salva schermata per il protocollo';

  @override
  String get screenshotSavedMessage =>
      'Mappa salvata: sarà allegata all\'esportazione del protocollo.';

  @override
  String screenshotErrorMessage(String error) {
    return 'Errore della schermata: $error';
  }

  @override
  String valueLabel(String value, String unit) {
    return 'Valore: $value $unit';
  }

  @override
  String distanceFromSourceValue(String value) {
    return 'Distanza dalla sorgente: $value m';
  }

  @override
  String timestampLabel(String value) {
    return 'Ora: $value';
  }

  @override
  String get sourcePositionLabel => 'Posizione della sorgente';

  @override
  String get editButton => 'Modifica';

  @override
  String get closeSurveyTitle => 'Chiudi sopralluogo';

  @override
  String get closeSurveyConfirm =>
      'Una volta chiuso, il protocollo mostrerà la data di oggi come ora di fine. I punti non vengono bloccati: potrai ancora modificarli.';

  @override
  String get closeSurveyButton => 'Chiudi';

  @override
  String get surveyClosedMessage => 'Sopralluogo chiuso.';

  @override
  String get listScreenshotSavedMessage =>
      'Schermata dell\'elenco salvata: sarà allegata all\'esportazione del protocollo.';

  @override
  String exportErrorMessage(String error) {
    return 'Errore di esportazione: $error';
  }

  @override
  String importErrorMessage(String error) {
    return 'Errore di importazione: $error';
  }

  @override
  String protocolShareSubject(String title) {
    return 'Protocollo – $title';
  }

  @override
  String dataExportSubject(String title) {
    return 'Punti di misura (dati) – $title';
  }

  @override
  String csvExportSubject(String title) {
    return 'Punti di misura (CSV) – $title';
  }

  @override
  String get importDoneTitle => 'Importazione completata';

  @override
  String importedPointsMessage(int points, int instruments, int sources) {
    return '$points punti importati.\n$instruments nuovi strumenti creati.\n$sources nuove sorgenti radioattive create.';
  }

  @override
  String get okButton => 'OK';

  @override
  String get toolsTooltip => 'Strumenti';

  @override
  String get autoLogMenuItem => 'Registrazione automatica';

  @override
  String get captureListScreenshotMenuItem => 'Salva schermata dell\'elenco';

  @override
  String get protocolFormatTitle => 'Formato del protocollo';

  @override
  String get protocolFormatWord => 'Word (ZIP: .docx + foto)';

  @override
  String get protocolFormatPdf => 'PDF (con foto)';

  @override
  String get sessionDoseLabel => 'Dose di misura';

  @override
  String get dosimeterDoseLabel => 'Dosimetro';

  @override
  String get dosimeterValueLabel => 'Dose valutata';

  @override
  String get includeInAnnualLabel => 'Conta nella dose annuale';

  @override
  String get notCountedInAnnualLabel => 'non conteggiato nella dose annuale';

  @override
  String get calcDoseFromPointsButton => 'Calcola dai punti';

  @override
  String get calcDoseNeedTwoPoints =>
      'Servono almeno 2 punti di rateo di dose.';

  @override
  String calcDoseResultInfo(int count) {
    return 'Calcolato da $count punti (interpolazione lineare)';
  }

  @override
  String get dosimetersButton => 'Dosimetri';

  @override
  String get addDosimeterButton => 'Aggiungi dosimetro';

  @override
  String get dosimeterKindEpdGamma => 'EPD gamma (elettronico)';

  @override
  String get dosimeterKindEpdNeutron => 'EPD neutroni (elettronico)';

  @override
  String get dosimeterKindTlOfficial => 'TL/OSL passivo (ufficiale)';

  @override
  String get dosimeterKindTlWorkplace => 'TL/OSL passivo (posto di lavoro)';

  @override
  String get dosimeterTypeLabel => 'Tipo';

  @override
  String get dosimeterIdentifierLabel => 'Identificativo';

  @override
  String get dosimeterPersonLabel => 'Indossato da';

  @override
  String get dosimeterNobody => 'Non assegnato';

  @override
  String get dosimeterStartLabel => 'Lettura iniziale';

  @override
  String get dosimeterEndLabel => 'Lettura finale';

  @override
  String get dosimeterEndBeforeStartError =>
      'La lettura finale non può essere inferiore a quella iniziale.';

  @override
  String get noDosimetersYet => 'Nessun dosimetro per questa misura.';

  @override
  String get dosimeterEditTitle => 'Dosimetro';

  @override
  String get dosimeterNoReading => 'nessun dato';

  @override
  String get dosimeterDeleteTitle => 'Elimina dosimetro';

  @override
  String get dosimeterDeleteMessage => 'Eliminare questa voce del dosimetro?';

  @override
  String get exportProtocolMenuItem => 'Esporta protocollo';

  @override
  String get exportJsonMenuItem => 'Esporta punti (dati, JSON)';

  @override
  String get exportCsvMenuItem => 'Esporta punti (tabella, CSV)';

  @override
  String get importJsonMenuItem => 'Importa punti (JSON)';

  @override
  String get newPointButton => 'Nuovo punto';

  @override
  String sampleTakenListLabel(String date) {
    return 'Campionamento · $date';
  }

  @override
  String get unknownModbusError => 'Errore Modbus sconosciuto.';

  @override
  String get noValidPositionError => 'Nessuna posizione valida indicata.';

  @override
  String get thresholdExceededTitle => 'Soglia di allarme superata';

  @override
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  ) {
    return 'Il valore misurato ($value $unit) raggiunge o supera la soglia impostata per $type ($threshold $unit).';
  }

  @override
  String get newPointTitle => 'Nuovo punto di misura';

  @override
  String get editPointTitle => 'Modifica punto';

  @override
  String get locationLabelFieldLabel => 'Nome del luogo';

  @override
  String get measuredValueLabel => 'Valore misurato';

  @override
  String get numberRequiredError => 'Inserisci un numero';

  @override
  String get unitLabel => 'Unità';

  @override
  String get instrumentLabel => 'Strumento';

  @override
  String get addInstrumentTooltip => 'Aggiungi un nuovo strumento';

  @override
  String get queryingLabel => 'Interrogazione...';

  @override
  String modbusQueryButton(String name) {
    return 'Interrogazione Modbus ($name)';
  }

  @override
  String get sourcePositionSwitchLabel =>
      'Questa è la posizione della sorgente (valore massimo)';

  @override
  String get sampleTakenSwitchLabel =>
      'Qui è stato prelevato un campione fisico';

  @override
  String get sampleContainerLabel => 'ID del contenitore';

  @override
  String get sampleAmountLabel => 'Quantità';

  @override
  String get sampleUnitLabel => 'Unità';

  @override
  String get sampleUnitOther => 'Altro';

  @override
  String get sampleUnitCustomLabel => 'Nome dell\'unità';

  @override
  String get sampleAmountInvalid => 'Inserisci un numero (es. 2,5 o 2.5)';

  @override
  String get sampleMethodLabel => 'Metodo di campionamento';

  @override
  String get notesLabel => 'Note';

  @override
  String get takePhotoLabel => 'Scatta foto';

  @override
  String get retakePhotoLabel => 'Sostituisci foto';

  @override
  String get chooseFromGalleryLabel => 'Scegli dalla galleria';

  @override
  String get positionLabel => 'Posizione';

  @override
  String get latitudeLabel => 'Latitudine';

  @override
  String get longitudeLabel => 'Longitudine';

  @override
  String get invalidValueError => 'Non valido';

  @override
  String get liveGpsButton => 'GPS in tempo reale';

  @override
  String get onMapButton => 'Sulla mappa';

  @override
  String get autoLogDisclaimer =>
      'La registrazione funziona solo finché questa schermata è aperta. Se il telefono si blocca o cambi app, la misura va in pausa: dovrai riavviarla al ritorno.';

  @override
  String get noModbusInstrumentMessage =>
      'Nessuno strumento raggiungibile via Modbus/TCP è configurato. Aggiungine uno nell\'elenco Strumenti (interruttore WiFi Modbus/TCP attivo, IP, ID unità e indirizzo del registro compilati).';

  @override
  String get triggerModeTime => 'A tempo';

  @override
  String get triggerModeDistance => 'A distanza';

  @override
  String get intervalSecondsLabel => 'Intervallo (secondi)';

  @override
  String get distanceIntervalLabel => 'Intervallo di distanza (metri)';

  @override
  String get connectingLabel => 'Connessione...';

  @override
  String get stopButton => 'Stop';

  @override
  String get loggingRunningLabel => 'Registrazione in corso...';

  @override
  String get loggingStoppedLabel => 'Registrazione interrotta';

  @override
  String capturedPointsLabel(int count) {
    return 'Punti registrati: $count';
  }

  @override
  String lastValueLabel(String value, String unit) {
    return 'Ultimo valore: $value $unit';
  }

  @override
  String failedReadingsLabel(int count) {
    return 'Letture non riuscite: $count';
  }

  @override
  String lastErrorSuffix(String error) {
    return ' (ultimo errore: $error)';
  }

  @override
  String get intervalMinError =>
      'L\'intervallo deve essere di almeno 1 secondo.';

  @override
  String get distanceMinError => 'La distanza deve essere di almeno 1 metro.';

  @override
  String modbusConnectErrorMessage(String error) {
    return 'Errore di connessione Modbus: $error';
  }

  @override
  String get csvHeaderSerialNumber => 'N.';

  @override
  String get csvHeaderLocation => 'Luogo';

  @override
  String get csvHeaderType => 'Tipo';

  @override
  String get csvHeaderValue => 'Valore';

  @override
  String get csvHeaderUnit => 'Unità';

  @override
  String get csvHeaderDistanceFromSource => 'Distanza dalla sorgente';

  @override
  String get csvHeaderInstrument => 'Strumento';

  @override
  String get csvHeaderGpsLatitude => 'Latitudine GPS';

  @override
  String get csvHeaderGpsLongitude => 'Longitudine GPS';

  @override
  String get csvHeaderGpsAccuracy => 'Precisione GPS';

  @override
  String get csvHeaderTimestamp => 'Data e ora';

  @override
  String get csvHeaderSample => 'Campionamento';

  @override
  String get csvHeaderNotes => 'Note';

  @override
  String get csvHeaderEstimatedActivity => 'Attività stimata (dalla misura)';

  @override
  String get csvHeaderAttachedSources => 'Sorgente/i associata/e';

  @override
  String get csvHeaderCalculatedDoseRate => 'Rateo di dose calcolato';

  @override
  String get csvHeaderDoseRateDifference => 'Differenza';

  @override
  String get csvYes => 'sì';

  @override
  String get csvNo => 'no';

  @override
  String get importUnknownTypeWarning =>
      'Tipo di misura sconosciuto ignorato per un punto.';

  @override
  String get importMissingGpsWarning =>
      'Un punto è stato ignorato per mancanza della coordinata GPS.';

  @override
  String get manageSourcesLabel => 'Gestisci sorgente/i radioattiva/e';

  @override
  String sourcesCountLabel(int count) {
    return '$count sorgente/i';
  }

  @override
  String get radiationSourcesTitle => 'Sorgenti';

  @override
  String get newSourceButton => 'Aggiungi sorgente';

  @override
  String get newSourceTitle => 'Nuova sorgente';

  @override
  String get editSourceTitle => 'Modifica sorgente';

  @override
  String get noSourcesRecordedYet =>
      'A questo punto non è ancora associata nessuna sorgente.';

  @override
  String get sourcesTooltip => 'Sorgenti';

  @override
  String get pointSourcesTitle => 'Sorgente/i in questo punto';

  @override
  String get attachSourceButton => 'Associa sorgente';

  @override
  String get pickSourceTitle => 'Scegli sorgente';

  @override
  String get noSourcesToAttach =>
      'Ancora nessuna sorgente disponibile: aggiungine prima una nell\'elenco principale delle Sorgenti.';

  @override
  String get noSourcesYet =>
      'Ancora nessuna sorgente aggiunta. Aggiungine una con il pulsante +.';

  @override
  String get enterDistanceDialogTitle => 'Inserisci la distanza';

  @override
  String get detachSourceConfirmTitle => 'Dissocia sorgente';

  @override
  String detachSourceConfirmMessage(String identifier) {
    return 'Dissociare la sorgente \"$identifier\" da questo punto? La sorgente resta nel registro: viene rimosso solo questo collegamento.';
  }

  @override
  String get detachButton => 'Dissocia';

  @override
  String get totalCalculatedDoseRateLabel =>
      'Rateo di dose totale calcolato (tutte le sorgenti)';

  @override
  String sourcesUnknownNuclideSkippedNote(int count) {
    return '$count sorgente/i hanno un nuclide sconosciuto e sono escluse dal totale.';
  }

  @override
  String get sourceIdentifierLabel => 'Identificativo univoco';

  @override
  String get nuclideLabel => 'Nuclide';

  @override
  String get customNuclideOption => 'Altro (inserimento manuale)';

  @override
  String get customNuclideNameLabel => 'Nome del nuclide';

  @override
  String get activityAtManufactureLabel => 'Attività alla fabbricazione (MBq)';

  @override
  String get activityErrorPercentLabel => 'Errore dell\'attività (±%)';

  @override
  String get manufactureDateLabel => 'Data di fabbricazione';

  @override
  String get serviceLifeExpiryDateLabel => 'Fine della vita utile';

  @override
  String get nextInspectionDateLabel => 'Data della prossima ispezione';

  @override
  String get sourceDistanceLabel => 'Distanza dal punto di misura (m)';

  @override
  String get asOfDateLabel => 'Data di riferimento dell\'attività';

  @override
  String get currentActivityResultLabel => 'Attività attuale';

  @override
  String get calculatedDoseRateResultLabel => 'Rateo di dose calcolato';

  @override
  String get measuredDoseRateResultLabel =>
      'Rateo di dose misurato (nel punto)';

  @override
  String get doseRateDifferenceResultLabel =>
      'Differenza (misurato − calcolato)';

  @override
  String get unknownNuclideDecayWarning =>
      'Nuclide sconosciuto: emivita e costante gamma non sono memorizzate, quindi attività attuale e rateo di dose calcolato non possono essere determinati. I dati della sorgente possono comunque essere salvati, ma il confronto viene saltato.';

  @override
  String get noMeasuredValueForComparisonNote =>
      'Nessun valore misurato registrato per questo punto: il confronto non è possibile.';

  @override
  String unrecognizedUnitForComparisonNote(String unit) {
    return 'L\'unità di misura ($unit) non può essere convertita automaticamente: il confronto non è possibile.';
  }

  @override
  String get sourceExpiredWarning => 'La vita utile della sorgente è scaduta.';

  @override
  String get deleteSourceConfirmTitle => 'Elimina sorgente';

  @override
  String deleteSourceConfirmMessage(String identifier) {
    return 'Eliminare la sorgente \"$identifier\" dal registro? Verrà rimossa anche da tutti i punti a cui è associata. L\'operazione non può essere annullata.';
  }

  @override
  String get sourceCalculationDisclaimer =>
      'I valori calcolati sono solo indicativi e si basano su costanti gamma ed emivite standard. Per le registrazioni ufficiali, verifica con una fonte autorevole.';

  @override
  String get estimatedActivityFromMeasurementLabel =>
      'Attività stimata (dal valore misurato)';

  @override
  String get personsTooltip => 'Persone';

  @override
  String get personsTitle => 'Persone';

  @override
  String get newPersonButton => 'Aggiungi persona';

  @override
  String get newPersonTitle => 'Nuova persona';

  @override
  String get editPersonTitle => 'Modifica persona';

  @override
  String get noPersonsYet =>
      'Ancora nessuna persona aggiunta. Aggiungine una con il pulsante +.';

  @override
  String get personNameLabel => 'Nome';

  @override
  String get medicalExamExpiryDateLabel => 'Scadenza della visita medica';

  @override
  String get trainingExpiryDateLabel => 'Scadenza della formazione';

  @override
  String get deletePersonConfirmTitle => 'Elimina persona';

  @override
  String deletePersonConfirmMessage(String name) {
    return 'Eliminare \"$name\" dal registro? Verrà rimossa anche da tutti i sopralluoghi a cui è assegnata. L\'operazione non può essere annullata.';
  }

  @override
  String get sessionPersonsTitle => 'Personale di questo sopralluogo';

  @override
  String get noPersonsAttachedYet =>
      'Ancora nessuna persona assegnata a questo sopralluogo.';

  @override
  String get attachPersonButton => 'Assegna persona';

  @override
  String get pickPersonTitle => 'Scegli persona';

  @override
  String get noPersonsToAttach =>
      'Ancora nessuna persona disponibile: aggiungine prima una nell\'elenco principale delle Persone.';

  @override
  String get detachPersonConfirmTitle => 'Rimuovi persona';

  @override
  String detachPersonConfirmMessage(String name) {
    return 'Rimuovere \"$name\" da questo sopralluogo? La persona resta nel registro: viene rimossa solo questa assegnazione.';
  }

  @override
  String get expiryNotificationsSectionTitle => 'Notifiche di scadenza';

  @override
  String get expiryNotificationsSwitchTitle => 'Notifica le scadenze';

  @override
  String get expiryNotificationsSwitchSubtitle =>
      'Per le prossime scadenze di sorgenti (vita utile, ispezione) e persone (visita medica, formazione), inviate alle 8:00 del mattino.';

  @override
  String get expiryLeadTimeLabel => 'Con quanto anticipo notificare';

  @override
  String get expiryLeadSameDay => 'Nello stesso giorno';

  @override
  String get expiryLeadOneDay => '1 giorno prima';

  @override
  String get expiryLeadTwoDays => '2 giorni prima';

  @override
  String get expiryLeadOneWeek => '1 settimana prima';

  @override
  String get expiryLeadTwoWeeks => '2 settimane prima';

  @override
  String expiryLeadMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi prima',
      one: '1 mese prima',
    );
    return '$_temp0';
  }

  @override
  String get expiryNotificationsPermissionDenied =>
      'Le notifiche sono bloccate nelle impostazioni del telefono. Consenti lì le notifiche di RadRecon.';

  @override
  String get expiryNotificationTitleToday => 'Scade oggi';

  @override
  String get expiryNotificationTitleUpcoming => 'In scadenza';

  @override
  String get expiryNotificationChannelName => 'Notifiche di scadenza';

  @override
  String get expiryNotificationChannelDescription =>
      'Prossime scadenze di sorgenti e persone';

  @override
  String get importRegistryCsv => 'Importa CSV';

  @override
  String get exportRegistryCsv => 'Esporta CSV';

  @override
  String get registryCsvExportSubject => 'Dati del registro RadRecon (CSV)';

  @override
  String get duplicatePolicyTitle => 'Quando esiste un record corrispondente';

  @override
  String get duplicateReplace => 'Sostituisci il record esistente';

  @override
  String get duplicateSkip => 'Salta il record corrispondente';

  @override
  String get duplicateKeep => 'Importa come duplicato';

  @override
  String registryImportSummary(int imported, int replaced, int skipped) {
    return 'Importati: $imported, sostituiti: $replaced, saltati: $skipped';
  }

  @override
  String get modbusTestConnectionButton => 'Prova connessione';

  @override
  String get modbusTestingLabel => 'Prova in corso...';

  @override
  String get modbusTestSuccessTitle => 'Connessione riuscita';

  @override
  String get modbusTestFailureTitle => 'Connessione non riuscita';

  @override
  String modbusTestValue(String value) {
    return 'Valore: $value';
  }

  @override
  String modbusTestPosition(String lat, String lon) {
    return 'Lat: $lat, Lon: $lon';
  }

  @override
  String missingFieldMessage(String field) {
    return 'Compila: $field';
  }

  @override
  String get errorTitle => 'Errore';

  @override
  String modbusReadErrorWithCode(String code) {
    return 'Errore Modbus durante la lettura: $code';
  }

  @override
  String get instrumentDidNotSendValidValue =>
      'Lo strumento non ha inviato un valore valido.';

  @override
  String get gpsPositionReadFailed =>
      'Impossibile leggere la posizione GPS dallo strumento.';

  @override
  String get instrumentIPAddressNotSet =>
      'Indirizzo IP dello strumento non impostato.';

  @override
  String get modbusUnitIdNotSet => 'ID unità Modbus non impostato.';

  @override
  String get registerAddressNotSet => 'Indirizzo del registro non impostato.';

  @override
  String get failedToConnectToInstrument =>
      'Impossibile connettersi allo strumento.';

  @override
  String connectionErrorWithDetails(String error) {
    return 'Errore di connessione: $error';
  }

  @override
  String get modbusAccessIncomplete =>
      'I dati di accesso Modbus dello strumento sono incompleti (IP, ID unità, indirizzo del registro).';

  @override
  String get noDisplayableContentForScreenshot =>
      'Nessun contenuto visualizzabile per la schermata.';

  @override
  String get failedToConvertScreenshotToPng =>
      'Impossibile convertire la schermata in PNG.';

  @override
  String get doseSourceOnline => 'Online (dal rivelatore)';

  @override
  String get doseSourceManual => 'Manuale';

  @override
  String get doseSourcePassive => 'Dosimetria passiva';

  @override
  String annualDoseLabel(int year) {
    return 'Dose nel $year';
  }

  @override
  String get doseYearLabel => 'Anno';

  @override
  String doseBreakdownLabel(String online, String manual, String passive) {
    return 'online $online · manuale $manual · passiva $passive';
  }

  @override
  String personDosesTitle(String name) {
    return 'Dosi – $name';
  }

  @override
  String get personDosesTooltip => 'Gestisci le dosi';

  @override
  String get noDosesYet => 'Ancora nessuna dose registrata per quest\'anno.';

  @override
  String get addPassiveDoseButton => 'Aggiungi dosimetria passiva';

  @override
  String get newPassiveDoseTitle => 'Nuova dosimetria passiva';

  @override
  String get editDoseTitle => 'Modifica dose';

  @override
  String get doseValueLabel => 'Dose';

  @override
  String get dosePeriodStartLabel => 'Inizio del periodo di valutazione';

  @override
  String get dosePeriodEndLabel => 'Fine del periodo di valutazione';

  @override
  String get dosePeriodEndBeforeStartError =>
      'La fine non può essere precedente all\'inizio.';

  @override
  String get doseTotalLabel => 'Totale';

  @override
  String get doseDeleteConfirmTitle => 'Elimina registrazione di dose';

  @override
  String get doseDeleteConfirmMessage =>
      'Eliminare questa registrazione di dose? L\'operazione non può essere annullata.';

  @override
  String sessionDoseDialogTitle(String name) {
    return 'Dose di $name';
  }

  @override
  String get onlineDoseLabel => 'Dose online';

  @override
  String get manualDoseLabel => 'Dose manuale';

  @override
  String get closeSurveyDosesTitle => 'Verifica le dosi';

  @override
  String get closeSurveyDosesHint =>
      'Prima di chiudere, verifica o correggi la dose di ogni partecipante.';

  @override
  String autoLogDoseSaved(int count, String dose) {
    return 'Dose salvata per $count persona/e: $dose';
  }

  @override
  String autoLogDoseNoPersons(String dose) {
    return 'La dose misurata ($dose) non è stata salvata perché a questo sopralluogo non è assegnata nessuna persona.';
  }

  @override
  String autoLogDoseLabel(String dose) {
    return 'Dose integrata: $dose';
  }

  @override
  String autoLogDoseGaps(int count) {
    return '$count lacuna/e di dati più lunga/e durante la misura';
  }

  @override
  String get autoLogDoseOnlyDoseRate =>
      'La dose può essere calcolata e salvata solo da misure di rateo di dose.';

  @override
  String get importPersonDosesCsv => 'Importa dosi (CSV)';

  @override
  String get exportPersonDosesCsv => 'Esporta dosi (CSV)';

  @override
  String get dataManagementSectionTitle => 'Gestione dei dati';

  @override
  String get saveDatabaseButton => 'Salva il database in un file';

  @override
  String get loadDatabaseButton => 'Carica il database da un file';

  @override
  String get clearDatabaseButton => 'Cancella il database';

  @override
  String get companySwitchButton => 'Cambia azienda';

  @override
  String get dataManagementHint =>
      'Il file di backup contiene tutti i dati, foto comprese, quindi può servire per passare a un nuovo telefono o per tenere separati i dati di più aziende.';

  @override
  String get saveDatabaseSubject => 'Backup del database di RadRecon';

  @override
  String databaseSavedMessage(String path) {
    return 'Database salvato: $path';
  }

  @override
  String get loadDatabaseConfirmTitle => 'Carica database';

  @override
  String get loadDatabaseConfirmBody =>
      'Il caricamento sovrascrive tutti i dati attualmente presenti su questo dispositivo. Salvali prima se ti servono ancora. Continuare?';

  @override
  String get loadButton => 'Carica';

  @override
  String databaseLoadedMessage(String name) {
    return 'Caricato: $name';
  }

  @override
  String get clearDatabaseConfirmTitle => 'Cancella database';

  @override
  String get clearDatabaseConfirmBody =>
      'Tutti i sopralluoghi, i punti di misura, gli strumenti, le sorgenti, le persone e le foto verranno eliminati definitivamente da questo dispositivo. L\'operazione non può essere annullata: fai prima un backup!';

  @override
  String get databaseClearedMessage => 'Database cancellato.';

  @override
  String get companySwitchTitle => 'Cambia azienda';

  @override
  String get activeCompanyLabel => 'Azienda attiva';

  @override
  String get companiesFolderLabel => 'Cartella delle aziende';

  @override
  String get chooseFolderButton => 'Scegli cartella';

  @override
  String get resetFolderButton => 'Torna alla cartella predefinita';

  @override
  String get noCompaniesYet =>
      'Ancora nessuna azienda salvata in questa cartella. L\'azienda attiva viene salvata automaticamente al primo cambio, oppure creane una nuova / aggiungi un file di backup con i pulsanti qui sopra.';

  @override
  String companyBackupInfo(String date) {
    return 'Salvato: $date';
  }

  @override
  String get newCompanyButton => 'Nuova azienda';

  @override
  String get newCompanyDialogTitle => 'Crea nuova azienda';

  @override
  String get companyNameLabel => 'Nome dell\'azienda';

  @override
  String get companyNameExistsMessage =>
      'Esiste già un\'azienda con questo nome.';

  @override
  String get createButton => 'Crea';

  @override
  String get addCompanyFromFileButton => 'Aggiungi azienda da file di backup';

  @override
  String get companySwitchConfirmTitle => 'Cambia azienda';

  @override
  String companySwitchConfirmBody(String company, String active) {
    return 'Passare a $company? I dati attuali vengono salvati automaticamente come $active.';
  }

  @override
  String get companySwitchAction => 'Cambia';

  @override
  String companySwitchedMessage(String name) {
    return 'Azienda attiva: $name';
  }

  @override
  String get deleteCompanyBackupTitle => 'Elimina backup';

  @override
  String deleteCompanyBackupBody(String name) {
    return 'Eliminare dalla cartella il backup di $name? I dati attualmente caricati non sono interessati.';
  }

  @override
  String get importPersonCsv => 'Importa persone (CSV)';

  @override
  String get exportPersonCsv => 'Esporta persone (CSV)';

  @override
  String get privateFolderHint =>
      'L\'app sta usando la propria cartella privata, a cui le altre app non possono accedere. Scegli una cartella (es. Download o Google Drive) per raggiungere i backup dal gestore file.';

  @override
  String get contributorsTitle => 'Collaboratori';

  @override
  String get contributorsThanks =>
      'Grazie a tutti coloro che aiutano a testare, sviluppare, tradurre e rivedere RadRecon. RadRecon è un\'iniziativa civica senza scopo di lucro realizzata da volontari.';

  @override
  String get contributorsOrganizationsTitle => 'Organizzazioni e aziende';

  @override
  String get contributorsPeopleTitle => 'Persone';

  @override
  String get contributorsEmpty => 'L\'elenco è ancora vuoto. Sii il primo!';

  @override
  String get contributorsLoadError => 'Impossibile caricare l\'elenco.';

  @override
  String get contributorsJoinHint =>
      'Vuoi comparire nell\'elenco? Iscriviti come volontario e dicci come vuoi apparire:';

  @override
  String get contributorsCopyLink => 'Copia link';

  @override
  String get contributorsLinkCopied => 'Link copiato.';

  @override
  String get contributorRoleTesting => 'Test';

  @override
  String get contributorRoleDevelopment => 'Sviluppo';

  @override
  String get contributorRoleReview => 'Revisione esperta';

  @override
  String get contributorRoleTranslation => 'Traduzione';

  @override
  String get contributorRoleOther => 'Altro';

  @override
  String get regulatoryProfileLabel => 'Profilo normativo';

  @override
  String get regulatoryProfileInternational => 'Internazionale (IAEA)';

  @override
  String get regulatoryProfileHungary => 'Ungheria (OAH)';

  @override
  String get classificationTitle => 'Classificazione (D, R, esenzione)';

  @override
  String get classificationDisclaimer =>
      'Calcolo indicativo da tabelle dei nuclidi e dall\'attività attuale (corretta per il decadimento). La classificazione ufficiale è stabilita dalla legge vigente e dall\'autorità. La classe di laboratorio secondo MSZ 62-7 è un valore indicativo ricavato dall\'attività.';

  @override
  String get classificationUnsealedWork =>
      'Lavoro regolare con sorgenti non sigillate';

  @override
  String get classificationOutsideWorkplace =>
      'Uso al di fuori del luogo di lavoro con radiazioni';

  @override
  String get classificationTotal => 'Totale (sorgenti selezionate)';

  @override
  String get classificationPhysCat => 'Categoria di protezione fisica';

  @override
  String get classificationProtCat => 'Categoria di radioprotezione';

  @override
  String get classificationUnknownCount =>
      'Sorgenti senza R (nuclide sconosciuto)';

  @override
  String get classificationActivity => 'Attività';

  @override
  String get classificationNotDecayCorrected =>
      'non corretta per il decadimento';

  @override
  String get classificationDInfinite => 'D = ∞ (non contribuisce a R)';

  @override
  String get classificationDUnknown =>
      'Nessun valore D per questo nuclide, R non può essere calcolato';

  @override
  String get classificationExemptUnknown =>
      'Nessun valore di esenzione per questo nuclide';

  @override
  String get classificationExemptActivity => 'Attività esente';

  @override
  String get classificationSpecificConc =>
      'Concentrazione di esenzione specifica';

  @override
  String get classificationGeneralConc => 'generale';

  @override
  String get classificationBelowExempt =>
      'L\'attività è pari o inferiore all\'attività esente';

  @override
  String get classificationAboveExempt =>
      'L\'attività supera l\'attività esente';

  @override
  String get classificationProtLevel => 'Livello di protezione fisica';

  @override
  String get classificationAdrConsignmentLimit => 'limite del collo esente';

  @override
  String get classificationAdrBelow => 'l\'attività è inferiore (non Classe 7)';

  @override
  String get classificationAdrAbove =>
      'l\'attività è superiore (conta anche la concentrazione)';

  @override
  String get classificationLabIndustrial => 'Laboratorio industriale';

  @override
  String get classificationLabMedical => 'Laboratorio medico';

  @override
  String get classificationLabAboveIII => '> III';

  @override
  String get classificationLabOps => 'Tipi di operazione consentiti';

  @override
  String get classificationLabUnknown =>
      'MSZ 62-7: nessun valore AM per questo nuclide';

  @override
  String get autoLogChartTitle => 'Valore misurato nel tempo';

  @override
  String get gpsAverageButton => 'GPS mediato';

  @override
  String get gpsAverageTitle => 'Media della posizione';

  @override
  String get gpsAverageHint =>
      'Resta fermo nello stesso punto durante la misura. Un tempo di media più lungo dà un risultato più affidabile; a cielo aperto funziona meglio. I campioni sono pesati in base alla precisione e le posizioni anomale vengono scartate.';

  @override
  String get gpsAverageStart => 'Avvia';

  @override
  String get gpsAverageUse => 'Usa';

  @override
  String get gpsAverageSamples => 'Campioni';

  @override
  String get gpsAverageCurrent => 'Precisione attuale';

  @override
  String get gpsAverageResult => 'Precisione stimata della media';

  @override
  String get modbusAverageButton => 'Misura mediata';

  @override
  String get modbusAverageRunning => 'Media in corso';

  @override
  String get modbusAverageDone => 'Fatto';

  @override
  String get modbusAverageTooFew =>
      'Servono almeno 2 campioni validi per calcolare l\'errore; è stato inserito solo il valore.';

  @override
  String get measurementErrorLabel => 'Errore (±)';

  @override
  String get measurementErrorHelper =>
      'In una misura mediata è l\'errore standard della media (1σ); per i valori inseriti manualmente può essere inserito anche a mano. È incluso nel protocollo.';

  @override
  String get measurementAveragedLabel => 'Misura mediata';

  @override
  String get csvHeaderValueError => 'Errore (±)';

  @override
  String get csvHeaderAveraging => 'Media (campioni; s)';

  @override
  String get helpManualTitle => 'Guida (manuale utente)';

  @override
  String get helpManualOpenError => 'Impossibile aprire il manuale.';

  @override
  String get appVersionLabel => 'Versione';

  @override
  String get appUpdateTitle => 'Nuova versione disponibile';

  @override
  String appUpdateAvailableMessage(String version) {
    return 'La versione $version è disponibile. Aggiorna l\'app per le ultime migliorie.';
  }

  @override
  String appUpdateRequiredMessage(String version) {
    return 'Questa versione non è più supportata. Aggiorna alla versione $version per continuare.';
  }

  @override
  String get appUpdateLater => 'Più tardi';

  @override
  String get appUpdateNow => 'Aggiorna';

  @override
  String get rrRoleSurveyor => 'Operatore';

  @override
  String get rrRoleVictim => 'Persona coinvolta / vittima';

  @override
  String get rrTriageNone => 'Non classificato';

  @override
  String get rrTriageRed => 'Rosso – cure immediate';

  @override
  String get rrTriageYellow => 'Giallo – cure differite';

  @override
  String get rrTriageGreen => 'Verde – lesione lieve';

  @override
  String get rrTriageBlack => 'Nero – deceduto / nessuna cura';

  @override
  String get rrConditionInjury => 'Lesione';

  @override
  String get rrConditionIllness => 'Malattia';

  @override
  String get rrAffectedPrefix => 'Coinvolto';

  @override
  String get rrEditStatusTooltip => 'Ruolo, triage, lesioni';

  @override
  String get rrRoleLabel => 'Ruolo';

  @override
  String get rrTriageCategoryLabel => 'Categoria di triage';

  @override
  String get rrInjuriesAndIllnesses => 'Lesioni e malattie';

  @override
  String get rrDescriptionHint => 'Descrizione';

  @override
  String get rrAddItem => 'Aggiungi voce';

  @override
  String get rrDeleteTooltip => 'Elimina';

  @override
  String get rrMeteoSection => 'Meteorologia (facoltativo)';

  @override
  String get rrMetTemp => 'Temperatura dell\'aria (°C)';

  @override
  String get rrMetHumidity => 'Umidità relativa (%)';

  @override
  String get rrMetPressure => 'Pressione atmosferica (hPa)';

  @override
  String get rrMetWind => 'Velocità del vento (m/s)';

  @override
  String get rrMetWindDir => 'Direzione del vento (°)';

  @override
  String get rrMetGust => 'Raffica di vento (m/s)';

  @override
  String get rrMetPrecipIntensity => 'Intensità delle precipitazioni (mm/h)';

  @override
  String get rrMetSolar => 'Radiazione solare (W/m²)';

  @override
  String get rrMetCloud => 'Copertura nuvolosa (ottavi, 0–8)';

  @override
  String get rrMetVisibility => 'Visibilità (m)';

  @override
  String get rrMetSoil => 'Umidità del suolo (%)';

  @override
  String get rrMetAerosol => 'Concentrazione di aerosol (µg/m³)';

  @override
  String get rrPrecipState => 'Stato delle precipitazioni';

  @override
  String get rrPrecipNone => 'Nessuna precipitazione';

  @override
  String get rrPrecipDrizzle => 'Pioggerella';

  @override
  String get rrPrecipRain => 'Pioggia';

  @override
  String get rrPrecipSnow => 'Neve';

  @override
  String get rrPrecipSleet => 'Nevischio';

  @override
  String get rrPrecipHail => 'Grandine';

  @override
  String get rrMetOther => 'Altra osservazione';

  @override
  String get rrGasSection => 'Misura dei gas';

  @override
  String get rrAddGas => 'Aggiungi gas';

  @override
  String get rrGasSpecies => 'Composto';

  @override
  String get rrGasOther => 'Altro';

  @override
  String get rrGasOtherName => 'Nome del composto';

  @override
  String get rrFormulaLabel => 'Formula';

  @override
  String get rrGasConcentration => 'Concentrazione';

  @override
  String get rrGasUnit => 'Unità';

  @override
  String get rrInvalidValue => 'Valore non valido';

  @override
  String get rrGasAmmonia => 'Ammoniaca';

  @override
  String get rrGasBenzene => 'Benzene';

  @override
  String get rrGasPhosphine => 'Fosfina';

  @override
  String get rrGasPhosgene => 'Fosgene';

  @override
  String get rrGasHydrogen => 'Idrogeno';

  @override
  String get rrGasHydrogenCyanide => 'Acido cianidrico';

  @override
  String get rrGasVoc => 'Composti organici volatili';

  @override
  String get rrGasSulfurDioxide => 'Biossido di zolfo';

  @override
  String get rrGasSulfurHexafluoride => 'Esafluoruro di zolfo';

  @override
  String get rrGasHydrogenSulfide => 'Solfuro di idrogeno';

  @override
  String get rrGasChlorine => 'Cloro';

  @override
  String get rrGasMethane => 'Metano';

  @override
  String get rrGasMethanol => 'Metanolo';

  @override
  String get rrGasMethylSalicylate => 'Salicilato di metile';

  @override
  String get rrGasNitricOxide => 'Monossido di azoto';

  @override
  String get rrGasNitrogenDioxide => 'Biossido di azoto';

  @override
  String get rrGasNitrogenOxides => 'Ossidi di azoto';

  @override
  String get rrGasOxygen => 'Ossigeno';

  @override
  String get rrGasOzone => 'Ozono';

  @override
  String get rrGasPropane => 'Propano';

  @override
  String get rrGasCarbonDioxide => 'Anidride carbonica';

  @override
  String get rrGasCarbonMonoxide => 'Monossido di carbonio';

  @override
  String get rrGasToluene => 'Toluene';

  @override
  String get rrGasTributylPhosphate => 'Tributilfosfato';

  @override
  String get measurementTypeMeteorology => 'Meteorologia';

  @override
  String get measurementTypeGasMeasurement => 'Misura dei gas';

  @override
  String get mapAreaButtonTooltip => 'Segna un\'area';

  @override
  String get mapAreaListTooltip => 'Aree segnate';

  @override
  String get mapAreaNewTitle => 'Nuova area';

  @override
  String get mapAreaNameLabel => 'Nome (es. Area rilevata)';

  @override
  String get mapAreaNameRequired => 'Inserisci il nome dell\'area.';

  @override
  String get mapAreaShapeLabel => 'Forma';

  @override
  String get mapAreaPolygon => 'Poligono';

  @override
  String get mapAreaCircle => 'Cerchio';

  @override
  String get mapAreaColorLabel => 'Colore';

  @override
  String get mapAreaStartDrawing => 'Disegna';

  @override
  String get mapAreaHintPolygon => 'Tocca gli angoli, poi premi Fatto.';

  @override
  String get mapAreaHintCircle =>
      'Tocca il centro, poi un punto del bordo per impostare il raggio.';

  @override
  String get mapAreaMinPointsError => 'Servono almeno 3 angoli.';

  @override
  String get mapAreaCircleIncomplete => 'Segna sia il centro sia il raggio.';

  @override
  String get mapAreaUndo => 'Annulla';

  @override
  String get mapAreaDone => 'Fatto';

  @override
  String get mapAreaNoAreas => 'Nessuna area segnata.';

  @override
  String get mapAreaDeleteConfirm => 'Eliminare l\'area selezionata?';

  @override
  String get mapAreaDeleteTooltip => 'Elimina area';

  @override
  String get unitConverterTitle => 'Convertitore di unità';

  @override
  String get unitConverterCategoryLabel => 'Grandezza';

  @override
  String get unitConverterValueLabel => 'Valore';

  @override
  String get unitConverterFromLabel => 'Unità di partenza';

  @override
  String get unitConverterMolarMassLabel => 'Massa molare (g/mol)';

  @override
  String get unitConverterMolarMassHint =>
      'Per convertire tra concentrazione in massa e in volume serve la massa molare, es. CO: 28,01. Calcolo a 25 °C, 1 atm.';

  @override
  String get unitConverterNeedsMolarMass =>
      'Inserisci la massa molare per convertire tra unità di massa e di volume.';

  @override
  String get unitConverterEnterValue => 'Inserisci un valore.';

  @override
  String get unitConverterTapHint =>
      'Tocca una riga: il valore viene convertito in quell\'unità, che diventa l\'unità di partenza.';

  @override
  String get unitConverterGasNote =>
      'L\'unità %LIE della concentrazione di gas non si può convertire, perché dipende dal limite del gas.';

  @override
  String get unitCatDose => 'Dose';

  @override
  String get unitCatDoseRate => 'Rateo di dose';

  @override
  String get unitCatActivity => 'Attività';

  @override
  String get unitCatActivityConcentration => 'Concentrazione di attività';

  @override
  String get unitCatSurfaceContamination => 'Contaminazione superficiale';

  @override
  String get unitCatCountRate => 'Tasso di conteggio';

  @override
  String get unitCatLength => 'Lunghezza';

  @override
  String get unitCatArea => 'Area';

  @override
  String get unitCatVolume => 'Volume';

  @override
  String get unitCatMass => 'Massa';

  @override
  String get unitCatTemperature => 'Temperatura';

  @override
  String get unitCatPressure => 'Pressione';

  @override
  String get unitCatSpeed => 'Velocità';

  @override
  String get unitCatTime => 'Tempo';

  @override
  String get unitCatIrradiance => 'Irradianza';

  @override
  String get unitCatRainRate => 'Intensità della precipitazione';

  @override
  String get unitCatMassConcentration => 'Concentrazione in massa (aerosol)';

  @override
  String get unitCatGasConcentration => 'Concentrazione di gas';

  @override
  String get unitConverterGasPick => 'Scegli il gas (compila la massa molare)';

  @override
  String get decayCalcTitle => 'Calcolatore di decadimento';

  @override
  String get decayCalcIsotope => 'Isotopo';

  @override
  String get decayCalcCustom => 'Altro (emivita personalizzata)';

  @override
  String get decayCalcHalfLife => 'Emivita';

  @override
  String get decayCalcInitialActivity => 'Attività iniziale';

  @override
  String get decayCalcElapsed => 'Tempo trascorso';

  @override
  String get decayCalcTargetActivity => 'Attività obiettivo';

  @override
  String get decayCalcModeForward => 'Attività dopo il tempo t';

  @override
  String get decayCalcModeBackward => 'Tempo fino all\'attività obiettivo';

  @override
  String get decayCalcDistance => 'Distanza (m, facoltativo)';

  @override
  String get decayCalcResultActivity => 'Attività';

  @override
  String get decayCalcResultRemaining => 'Frazione rimanente';

  @override
  String get decayCalcResultHalfLives => 'Numero di emivite';

  @override
  String get decayCalcResultDoseRate => 'Rateo di dose alla distanza';

  @override
  String get decayCalcResultTime => 'Tempo necessario';

  @override
  String get decayCalcErrorTarget =>
      'L\'attività obiettivo deve essere positiva e inferiore a quella iniziale.';

  @override
  String get decayCalcNeedsInput => 'Inserisci i numeri.';

  @override
  String get decayCalcNoHalfLife => 'Inserisci l\'emivita.';

  @override
  String get decayCalcNote =>
      'Decadimento esponenziale puro; non include i figli né altre radiazioni.';

  @override
  String get doseLimitTitle => 'Limite di dose annuale';

  @override
  String get doseLimitCategoryOccupational => 'Professionale';

  @override
  String get doseLimitCategoryPublic => 'Pubblico';

  @override
  String get doseLimitSourceOah => 'Decreto OAH 2/2022 (IV. 29.)';

  @override
  String get doseLimitSourceIaea => 'IAEA GSR Part 3';

  @override
  String get doseLimitUsedLabel => 'utilizzato';

  @override
  String get doseLimitStatusOk => 'entro il limite';

  @override
  String get doseLimitStatusWarning => 'livello di avviso raggiunto';

  @override
  String get doseLimitStatusExceeded => 'limite superato';

  @override
  String get doseLimitNote =>
      'Verifica su un anno; la media su cinque anni dello IAEA non è applicata.';

  @override
  String get displayUnitsHint =>
      'La visualizzazione e il protocollo usano queste unità. Esportazioni (CSV, JSON) e backup mantengono sempre l\'unità salvata.';

  @override
  String get displayDoseUnitLabel => 'Unità della dose personale';

  @override
  String get displayDoseAutoOption => 'Automatico (µSv, mSv sopra 1 mSv)';

  @override
  String get displaySurfaceUnitLabel =>
      'Unità della contaminazione superficiale';

  @override
  String get displayTemperatureUnitLabel => 'Unità di temperatura';

  @override
  String get displayPressureUnitLabel => 'Unità di pressione';

  @override
  String get displayWindUnitLabel => 'Unità della velocità del vento';
}
