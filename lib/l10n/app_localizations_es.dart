// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'RadRecon';

  @override
  String get instrumentsTooltip => 'Instrumentos';

  @override
  String get searchHint => 'Buscar';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String get alertThresholdsTooltip => 'Umbrales de alerta';

  @override
  String get noSurveysYet =>
      'Aún no hay inspecciones. Empieza una con el botón +.';

  @override
  String get newSurveyButton => 'Nueva inspección';

  @override
  String get newSurveyDialogTitle => 'Nueva inspección';

  @override
  String get surveyNameLabel => 'Nombre';

  @override
  String get surveyLocationLabel => 'Ubicación (opcional)';

  @override
  String get editSurveyDetailsTooltip => 'Editar nombre y ubicación';

  @override
  String get editSurveyDetailsTitle => 'Editar datos de la inspección';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deletePointTooltip => 'Eliminar punto de medición';

  @override
  String get deletePointTitle => 'Eliminar punto de medición';

  @override
  String get deletePointBody =>
      '¿Eliminar este punto de medición? También se eliminarán sus asignaciones de fuentes y el registro de cambios. No se puede deshacer.';

  @override
  String get startButton => 'Iniciar';

  @override
  String surveyDefaultTitle(String date) {
    return 'Inspección – $date';
  }

  @override
  String get noLocationPlaceholder => '—';

  @override
  String get doseUnitSectionTitle => 'Unidad predeterminada de tasa de dosis';

  @override
  String get doseUnitSectionHint =>
      'Estas unidades vienen preseleccionadas para las nuevas mediciones. Al registrar se puede elegir otra de una lista, sin escribir, y el número introducido se convierte automáticamente al cambiar de unidad. El umbral de alerta de la tasa de dosis también se convierte.';

  @override
  String get unitsSectionTitle => 'Unidades';

  @override
  String get activityUnitLabel => 'Unidad predeterminada de actividad';

  @override
  String get distanceUnitLabel => 'Unidad predeterminada de distancia';

  @override
  String get activityPlainLabel => 'Actividad';

  @override
  String get measuredDoseRatePlainLabel => 'Tasa de dosis medida';

  @override
  String get distanceFromSourcePlainLabel => 'Distancia a la fuente';

  @override
  String get sourceDistancePlainLabel => 'Distancia al punto de medida';

  @override
  String get activityAtManufacturePlainLabel => 'Actividad en la fabricación';

  @override
  String get invalidDistancePlainError =>
      'Introduce una distancia válida y positiva.';

  @override
  String get invalidActivityPlainError => 'Introduce una actividad válida.';

  @override
  String get invalidDoseRatePlainError => 'Introduce una tasa de dosis válida.';

  @override
  String get distanceFromSourceShortLabel => 'Distancia a la fuente';

  @override
  String get calculatedActivityResultLabel => 'Actividad calculada';

  @override
  String get distanceIntervalPlainLabel => 'Intervalo de distancia';

  @override
  String get modbusQuantityLabel => 'Qué devuelve el registro';

  @override
  String get modbusRegisterUnitLabel => 'Unidad del registro';

  @override
  String get modbusQuantityHelper =>
      'Al registrar, la app convierte el valor a la unidad predeterminada elegida en Ajustes.';

  @override
  String get autoLogTypeFromInstrument =>
      'El registro automático guarda la magnitud configurada para el instrumento.';

  @override
  String get nuclideIdSectionTitle => 'Identificación del nucleído';

  @override
  String get nuclideStatusNone => 'No indicado';

  @override
  String get nuclideStatusIdentified => 'Nucleído(s) identificado(s)';

  @override
  String get nuclideStatusUnknown => 'Desconocido';

  @override
  String get nuclideStatusOther => 'Otro (no está en la lista)';

  @override
  String get nuclideStatusMixture => 'Presumiblemente varias fuentes (mezcla)';

  @override
  String get nuclideKnownListLabel => 'Nucleídos de la lista';

  @override
  String get nuclideCustomLabel => 'Nombre de otro nucleído';

  @override
  String get nuclideAddButton => 'Añadir';

  @override
  String get nuclideRequiredError =>
      'Introduce al menos un nucleído o elige Desconocido.';

  @override
  String get csvHeaderNuclides => 'Identificación del nucleído';

  @override
  String get nuclideDoneButton => 'Listo';

  @override
  String get unshieldedActivityLabel => 'Actividad (sin blindaje)';

  @override
  String get shieldingSectionTitle => 'Blindaje (opcional)';

  @override
  String get shieldingHint =>
      'Si la fuente está tras un blindaje, introduce su material y espesor: la app estimará también la actividad real de la fuente blindada.';

  @override
  String get shieldingMaterialLabel => 'Material del blindaje';

  @override
  String get shieldingNoneOption => 'Sin blindaje';

  @override
  String get shieldingThicknessLabel => 'Espesor del blindaje';

  @override
  String get shieldingThicknessError => 'Introduce un espesor positivo';

  @override
  String get shieldedActivityLabel =>
      'Actividad estimada de la fuente blindada';

  @override
  String get shieldingDisclaimer =>
      'Estimación aproximada: la atenuación se modela con capas de semirreducción (cada capa reduce la tasa de dosis a la mitad) con valores orientativos. La radiación dispersa (acumulación), la geometría de la fuente y el espectro están simplificados, por lo que el resultado tiende a sobrestimar la actividad. Para protocolos oficiales, contrasta con una fuente autorizada.';

  @override
  String get shieldingMaterialLead => 'Plomo';

  @override
  String get shieldingMaterialSteel => 'Acero (hierro)';

  @override
  String get shieldingMaterialConcrete => 'Hormigón';

  @override
  String get shieldingMaterialTungsten => 'Wolframio';

  @override
  String get shieldingMaterialAluminium => 'Aluminio';

  @override
  String get shieldingMaterialWater => 'Agua';

  @override
  String get csvUnshieldedNote => 'sin blindaje';

  @override
  String get csvShieldedSourceNote => 'fuente blindada';

  @override
  String get shieldingAddLayer => 'Añadir capa';

  @override
  String get shieldingLayerLabel => 'Capa';

  @override
  String get shieldingRemoveLayer => 'Quitar capa';

  @override
  String get doseRateUnshieldedLabel => 'Tasa de dosis (sin blindaje)';

  @override
  String get doseRateShieldedLabel => 'Tasa de dosis tras el blindaje';

  @override
  String get calibrationSectionTitle => 'Verificación y calibración';

  @override
  String get calibrationKindVerification => 'Verificación';

  @override
  String get calibrationKindCalibration => 'Calibración';

  @override
  String get calibrationAddButton => 'Añadir registro';

  @override
  String get calibrationDialogTitle => 'Registro de verificación / calibración';

  @override
  String get calibrationKindLabel => 'Tipo';

  @override
  String get calibrationPerformedOnLabel => 'Fecha de realización';

  @override
  String get calibrationValidUntilLabel => 'Válido hasta';

  @override
  String get calibrationCertificateLabel => 'Número de certificado';

  @override
  String get calibrationPerformedByLabel =>
      'Realizado por (laboratorio / autoridad)';

  @override
  String get calibrationAttachFile => 'Adjuntar certificado';

  @override
  String get calibrationRemoveFile => 'Quitar adjunto';

  @override
  String get calibrationOpenFile => 'Abrir / compartir certificado';

  @override
  String get calibrationEmptyList => 'Aún no hay registros.';

  @override
  String get calibrationStatusValid => 'Válido';

  @override
  String get calibrationStatusSoon => 'Vence pronto';

  @override
  String get calibrationStatusExpired => 'VENCIDO';

  @override
  String get calibrationStatusUnknown => 'Sin datos';

  @override
  String get calibrationExpiredWarning =>
      'Atención: la verificación/calibración del instrumento seleccionado ha vencido. Válido hasta:';

  @override
  String get calibrationSoonWarning =>
      'Atención: la verificación/calibración del instrumento seleccionado vence pronto. Válido hasta:';

  @override
  String get calibrationUnknownWarning =>
      'El instrumento seleccionado no tiene datos de verificación/calibración.';

  @override
  String get calibrationSaveAnywayTitle => 'Verificación/calibración vencida';

  @override
  String get calibrationSaveAnywayBody =>
      'La medición se hizo con un instrumento cuya verificación/calibración ha vencido; el protocolo lo señalará. ¿Guardar de todos modos?';

  @override
  String get calibrationSaveAnywayConfirm => 'Guardar de todos modos';

  @override
  String get calibrationValidUntilBeforeError =>
      'La validez no puede ser anterior a la fecha de realización';

  @override
  String get csvHeaderInstrumentCalibration =>
      'Verificación/calibración del instrumento';

  @override
  String get personPhoneLabel => 'Número de teléfono';

  @override
  String get personEmailLabel => 'Correo electrónico';

  @override
  String get personAddEmail => 'Añadir correo electrónico';

  @override
  String get personRemoveEmail => 'Quitar correo';

  @override
  String get personEmailInvalidError => 'Correo electrónico no válido';

  @override
  String get personCertificatesTitle => 'Certificados';

  @override
  String get personCertificateAdd => 'Añadir certificado';

  @override
  String get personCertificateDialogTitle => 'Certificado';

  @override
  String get personCertificateNameLabel =>
      'Nombre (p. ej. examen de protección radiológica)';

  @override
  String get personCertificateNumberLabel => 'Número de certificado';

  @override
  String get personCertificateIssuerLabel => 'Emisor';

  @override
  String get personCertificateIssuedLabel => 'Fecha de emisión';

  @override
  String get personCertificateNameRequired =>
      'Introduce el nombre del certificado';

  @override
  String get personCertificateValidBeforeError =>
      'La validez no puede ser anterior a la fecha de emisión';

  @override
  String get personCertificatesEmpty => 'Aún no hay certificados.';

  @override
  String get sourceCertificateTitle => 'Certificado de la fuente';

  @override
  String get sourceCertificateAttach => 'Adjuntar certificado';

  @override
  String get sourceCertificateEmpty => 'No hay certificado adjunto.';

  @override
  String get companyDocumentsTooltip => 'Documentos y permisos de la empresa';

  @override
  String get companyDocumentNew => 'Nuevo documento';

  @override
  String get companyDocumentEdit => 'Editar documento';

  @override
  String get companyDocumentTitleLabel => 'Nombre del documento';

  @override
  String get companyDocumentIdentifierLabel =>
      'Identificador (n.º de expediente / permiso)';

  @override
  String get companyDocumentIssuerLabel => 'Emisor / autoridad';

  @override
  String get companyDocumentIssuedLabel =>
      'Fecha de emisión / entrada en vigor';

  @override
  String get companyDocumentValidUntilLabel =>
      'Válido / revisión pendiente hasta';

  @override
  String get companyDocumentFilesTitle => 'Archivos adjuntos';

  @override
  String get companyDocumentAttach => 'Adjuntar archivo';

  @override
  String get companyDocumentsEmpty => 'Aún no hay documentos.';

  @override
  String get companyDocumentDeleteTitle => 'Eliminar documento';

  @override
  String get companyDocumentDeleteConfirm => '¿Eliminar este documento?';

  @override
  String get companyDocSuggestionsLabel => 'Documentos habituales';

  @override
  String get companyDocSuggestRadiationPolicy =>
      'Reglamento de protección radiológica del lugar de trabajo';

  @override
  String get companyDocSuggestRadiationDescription =>
      'Descripción de la protección radiológica';

  @override
  String get companyDocSuggestPhysicalProtection => 'Plan de protección física';

  @override
  String get companyDocSuggestEmergencyPlan =>
      'Plan de respuesta a emergencias';

  @override
  String get companyDocSuggestOfficialLicense => 'Licencia administrativa';

  @override
  String get nuclideEditButton => 'Editar nucleídos';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageSystemOption => 'Idioma del teléfono';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appearanceSectionTitle => 'Apariencia';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get alertThresholdExplanation =>
      'Si una medición registrada alcanza o supera el umbral fijado aquí, la app te avisará (sonido + ventana emergente). Déjalo vacío para no tener alerta en ese tipo.';

  @override
  String get noThresholdSetHint => 'Sin umbral fijado';

  @override
  String get saveButton => 'Guardar';

  @override
  String get settingsSavedMessage => 'Ajustes guardados.';

  @override
  String get measurementTypeDoseRate => 'Tasa de dosis';

  @override
  String get measurementTypeSurfaceContamination => 'Contaminación superficial';

  @override
  String get measurementTypeCps => 'Tasa de recuento (cps)';

  @override
  String get measurementTypeNeutronCps => 'Tasa de recuento de neutrones (cps)';

  @override
  String get measurementTypeSample => 'Toma de muestras';

  @override
  String get instrumentDeleteTitle => 'Eliminar instrumento';

  @override
  String instrumentDeleteConfirm(String name) {
    return '¿Eliminar «$name»? Las mediciones anteriores vinculadas se conservan; solo se elimina la referencia al instrumento.';
  }

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get noInstrumentsYet =>
      'Aún no hay instrumentos. Añade uno con el botón +.';

  @override
  String get noCalibrationData => 'Sin datos de calibración';

  @override
  String nextCalibrationOn(String date) {
    return 'Próxima calibración: $date';
  }

  @override
  String get noSerialNumber => 'sin número de serie';

  @override
  String get newInstrumentButton => 'Nuevo instrumento';

  @override
  String get editInstrumentTitle => 'Editar instrumento';

  @override
  String get instrumentNameLabel => 'Nombre / tipo del instrumento';

  @override
  String get requiredFieldError => 'Obligatorio';

  @override
  String get serialNumberLabel => 'Número de serie';

  @override
  String get nextCalibrationLabel => 'Fecha de la próxima calibración';

  @override
  String get notSetLabel => 'Sin definir';

  @override
  String get calibrationFactorLabel => 'Factor de calibración';

  @override
  String get modbusConnectedLabel => 'Accesible por WiFi mediante Modbus/TCP';

  @override
  String get modbusHostLabel => 'Dirección IP / host';

  @override
  String get modbusPortLabel => 'Puerto (p. ej. 502)';

  @override
  String get modbusUnitIdLabel => 'ID de unidad Modbus (dirección esclavo)';

  @override
  String get modbusRegisterAddressLabel =>
      'Dirección del registro (p. ej. 294)';

  @override
  String get modbusRegisterAddressHelper =>
      'Registro de retención inicial del valor medido (float32)';

  @override
  String get modbusGpsEnabledLabel => 'Leer la posición GPS por Modbus';

  @override
  String get modbusGpsLatAddressLabel =>
      'Registro de latitud (float32, predeterminado 426)';

  @override
  String get modbusGpsLonAddressLabel =>
      'Registro de longitud (float32, predeterminado 428)';

  @override
  String get pickPositionTitle => 'Elegir una posición';

  @override
  String get confirmPositionButton => 'Confirmar posición';

  @override
  String get isotopeCalculatorTitle => 'Calculadora de isótopos';

  @override
  String get gammaConstantsDisclaimer =>
      'Las constantes Γ son solo orientativas. Para un protocolo oficial, verifícalas con una fuente autorizada antes de documentar el resultado.';

  @override
  String get isotopeLabel => 'Isótopo';

  @override
  String get modeDoseFromActivity => 'Actividad a\ntasa de dosis';

  @override
  String get modeActivityFromDose => 'Tasa de dosis a\nactividad';

  @override
  String get distanceFromSourceLabel => 'Distancia a la fuente (m)';

  @override
  String get activityLabel => 'Actividad (MBq)';

  @override
  String get measuredDoseRateLabel => 'Tasa de dosis medida (µSv/h)';

  @override
  String get calculateButton => 'Calcular';

  @override
  String get invalidDistanceError =>
      'Introduce una distancia (m) válida y positiva.';

  @override
  String get invalidActivityError => 'Introduce una actividad (MBq) válida.';

  @override
  String get invalidDoseRateError =>
      'Introduce una tasa de dosis (µSv/h) válida.';

  @override
  String calculationErrorMessage(String error) {
    return 'Error de cálculo: $error';
  }

  @override
  String calculatedDoseRateResult(String uSvH, String nSvH) {
    return 'Tasa de dosis calculada: $uSvH µSv/h\n($nSvH nSv/h)';
  }

  @override
  String calculatedActivityResult(String mbq, String gbq) {
    return 'Actividad calculada: $mbq MBq\n($gbq GBq)';
  }

  @override
  String get distanceToolTitle => 'Medición de distancia';

  @override
  String get locationServiceDisabledError =>
      'Los servicios de ubicación están desactivados.';

  @override
  String get locationPermissionDeniedError => 'Permiso de ubicación denegado.';

  @override
  String gpsErrorMessage(String error) {
    return 'Error de GPS: $error';
  }

  @override
  String get selectTargetFirstError => 'Elige primero el punto de destino.';

  @override
  String get noGpsPositionError =>
      'Sin posición GPS. Actualiza o elige un punto de partida.';

  @override
  String get selectStartPointError => 'Elige un punto de partida.';

  @override
  String get selectTargetPointError => 'Elige el punto de destino.';

  @override
  String get startFromCurrentPositionLabel => 'Partir de: mi posición actual';

  @override
  String get noPositionFetchedYet => 'Aún no obtenida';

  @override
  String get refreshGpsButton => 'Actualizar GPS';

  @override
  String get startPointLabel => 'Punto de partida';

  @override
  String get targetPointLabel => 'Punto de destino';

  @override
  String get liveTrackingLabel => 'Seguimiento en vivo';

  @override
  String get liveTrackingSubtitle =>
      'Actualiza continuamente la distancia y el rumbo mientras caminas.';

  @override
  String get calculateDistanceButton => 'Calcular';

  @override
  String get liveTrackingRunningHint =>
      'El seguimiento en vivo está activo: camina en la dirección de la flecha.';

  @override
  String get sourceSearchTitle => 'Búsqueda de la fuente';

  @override
  String get measurementTypeLabel => 'Tipo de medición';

  @override
  String pointsRecordedForType(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos registrados',
      one: '$count punto registrado',
    );
    return '$_temp0 de este tipo en esta inspección.';
  }

  @override
  String get lowConfidenceWarning =>
      'Pocos puntos (< 4): la estimación no es fiable; toma más mediciones en distintos lugares del área de búsqueda.';

  @override
  String gradientEstimateLabel(String value, String unit) {
    return 'Gradiente estimado: $value $unit/m';
  }

  @override
  String get directionEstimateHint =>
      'Se estima que el valor medido aumenta en esta dirección.';

  @override
  String get sourceSearchDisclaimer =>
      'La dirección sugerida se basa en una estimación lineal sencilla del gradiente a partir de los puntos registrados hasta ahora en esta inspección. Puede ser inexacta con datos de campo ruidosos, pocos puntos o cuando la fuente real está lejos en relación con el tamaño del área inspeccionada. Solo orientativa: no sustituye el criterio profesional.';

  @override
  String get newMeasurementButton => 'Nueva medición';

  @override
  String get mapTitle => 'Mapa';

  @override
  String get noPointsRecordedYet => 'Aún no hay puntos de medida registrados.';

  @override
  String get saveScreenshotTooltip => 'Guardar captura para el protocolo';

  @override
  String get screenshotSavedMessage =>
      'Mapa guardado: se adjuntará al exportar el protocolo.';

  @override
  String screenshotErrorMessage(String error) {
    return 'Error de captura: $error';
  }

  @override
  String valueLabel(String value, String unit) {
    return 'Valor: $value $unit';
  }

  @override
  String distanceFromSourceValue(String value) {
    return 'Distancia a la fuente: $value m';
  }

  @override
  String timestampLabel(String value) {
    return 'Hora: $value';
  }

  @override
  String get sourcePositionLabel => 'Posición de la fuente';

  @override
  String get editButton => 'Editar';

  @override
  String get closeSurveyTitle => 'Cerrar inspección';

  @override
  String get closeSurveyConfirm =>
      'Al cerrarla, el protocolo mostrará la fecha de hoy como hora de finalización. Los puntos no se bloquean: aún puedes editarlos después.';

  @override
  String get closeSurveyButton => 'Cerrar';

  @override
  String get surveyClosedMessage => 'Inspección cerrada.';

  @override
  String get listScreenshotSavedMessage =>
      'Captura de la lista guardada: se adjuntará al exportar el protocolo.';

  @override
  String exportErrorMessage(String error) {
    return 'Error de exportación: $error';
  }

  @override
  String importErrorMessage(String error) {
    return 'Error de importación: $error';
  }

  @override
  String protocolShareSubject(String title) {
    return 'Protocolo – $title';
  }

  @override
  String dataExportSubject(String title) {
    return 'Puntos de medida (datos) – $title';
  }

  @override
  String csvExportSubject(String title) {
    return 'Puntos de medida (CSV) – $title';
  }

  @override
  String get importDoneTitle => 'Importación completada';

  @override
  String importedPointsMessage(int points, int instruments, int sources) {
    return '$points puntos importados.\n$instruments instrumentos nuevos creados.\n$sources fuentes radiactivas nuevas creadas.';
  }

  @override
  String get okButton => 'Aceptar';

  @override
  String get toolsTooltip => 'Herramientas';

  @override
  String get autoLogMenuItem => 'Registro automático';

  @override
  String get captureListScreenshotMenuItem => 'Guardar captura de la lista';

  @override
  String get protocolFormatTitle => 'Formato del protocolo';

  @override
  String get protocolFormatWord => 'Word (ZIP: .docx + fotos)';

  @override
  String get protocolFormatPdf => 'PDF (con fotos)';

  @override
  String get sessionDoseLabel => 'Dosis de la medición';

  @override
  String get dosimeterDoseLabel => 'Dosímetro';

  @override
  String get dosimeterValueLabel => 'Dosis evaluada';

  @override
  String get includeInAnnualLabel => 'Cuenta para la dosis anual';

  @override
  String get notCountedInAnnualLabel => 'no cuenta en la dosis anual';

  @override
  String get calcDoseFromPointsButton => 'Calcular desde los puntos';

  @override
  String get calcDoseNeedTwoPoints =>
      'Se necesitan al menos 2 puntos de tasa de dosis.';

  @override
  String calcDoseResultInfo(int count) {
    return 'Calculado a partir de $count puntos (interpolación lineal)';
  }

  @override
  String get dosimetersButton => 'Dosímetros';

  @override
  String get addDosimeterButton => 'Añadir dosímetro';

  @override
  String get dosimeterKindEpdGamma => 'EPD gamma (electrónico)';

  @override
  String get dosimeterKindEpdNeutron => 'EPD neutrones (electrónico)';

  @override
  String get dosimeterKindTlOfficial => 'TL/OSL pasivo (oficial)';

  @override
  String get dosimeterKindTlWorkplace => 'TL/OSL pasivo (puesto de trabajo)';

  @override
  String get dosimeterTypeLabel => 'Tipo';

  @override
  String get dosimeterIdentifierLabel => 'Identificador';

  @override
  String get dosimeterPersonLabel => 'Portado por';

  @override
  String get dosimeterNobody => 'Sin asignar';

  @override
  String get dosimeterStartLabel => 'Lectura inicial';

  @override
  String get dosimeterEndLabel => 'Lectura final';

  @override
  String get dosimeterEndBeforeStartError =>
      'La lectura final no puede ser menor que la inicial.';

  @override
  String get noDosimetersYet => 'Todavía no hay dosímetros en esta medición.';

  @override
  String get dosimeterEditTitle => 'Dosímetro';

  @override
  String get dosimeterNoReading => 'sin datos';

  @override
  String get dosimeterDeleteTitle => 'Eliminar dosímetro';

  @override
  String get dosimeterDeleteMessage => '¿Eliminar esta entrada de dosímetro?';

  @override
  String get exportProtocolMenuItem => 'Exportar protocolo';

  @override
  String get exportJsonMenuItem => 'Exportar puntos (datos, JSON)';

  @override
  String get exportCsvMenuItem => 'Exportar puntos (tabla, CSV)';

  @override
  String get importJsonMenuItem => 'Importar puntos (JSON)';

  @override
  String get newPointButton => 'Nuevo punto';

  @override
  String sampleTakenListLabel(String date) {
    return 'Toma de muestras · $date';
  }

  @override
  String get unknownModbusError => 'Error Modbus desconocido.';

  @override
  String get noValidPositionError => 'No se indicó una posición válida.';

  @override
  String get thresholdExceededTitle => 'Umbral de alerta superado';

  @override
  String thresholdExceededMessage(
    String value,
    String unit,
    String type,
    String threshold,
  ) {
    return 'El valor medido ($value $unit) alcanza o supera el umbral fijado para $type ($threshold $unit).';
  }

  @override
  String get newPointTitle => 'Nuevo punto de medida';

  @override
  String get editPointTitle => 'Editar punto';

  @override
  String get locationLabelFieldLabel => 'Nombre del lugar';

  @override
  String get measuredValueLabel => 'Valor medido';

  @override
  String get numberRequiredError => 'Introduce un número';

  @override
  String get unitLabel => 'Unidad';

  @override
  String get instrumentLabel => 'Instrumento';

  @override
  String get addInstrumentTooltip => 'Añadir un instrumento nuevo';

  @override
  String get queryingLabel => 'Consultando...';

  @override
  String modbusQueryButton(String name) {
    return 'Consulta Modbus ($name)';
  }

  @override
  String get sourcePositionSwitchLabel =>
      'Esta es la posición de la fuente (valor máximo)';

  @override
  String get sampleTakenSwitchLabel => 'Aquí se tomó una muestra física';

  @override
  String get sampleContainerLabel => 'ID del recipiente';

  @override
  String get sampleAmountLabel => 'Cantidad';

  @override
  String get sampleUnitLabel => 'Unidad';

  @override
  String get sampleUnitOther => 'Otra';

  @override
  String get sampleUnitCustomLabel => 'Nombre de la unidad';

  @override
  String get sampleAmountInvalid => 'Introduce un número (p. ej. 2,5 o 2.5)';

  @override
  String get sampleMethodLabel => 'Método de muestreo';

  @override
  String get notesLabel => 'Notas';

  @override
  String get takePhotoLabel => 'Hacer foto';

  @override
  String get retakePhotoLabel => 'Sustituir foto';

  @override
  String get chooseFromGalleryLabel => 'Elegir de la galería';

  @override
  String get positionLabel => 'Posición';

  @override
  String get latitudeLabel => 'Latitud';

  @override
  String get longitudeLabel => 'Longitud';

  @override
  String get invalidValueError => 'No válido';

  @override
  String get liveGpsButton => 'GPS en vivo';

  @override
  String get onMapButton => 'En el mapa';

  @override
  String get autoLogDisclaimer =>
      'El registro solo funciona mientras esta pantalla está abierta. Si el teléfono se bloquea o cambias de app, la medición se pausa y tendrás que reiniciarla al volver.';

  @override
  String get noModbusInstrumentMessage =>
      'No hay ningún instrumento accesible por Modbus/TCP configurado. Añade uno en la lista de Instrumentos (con el interruptor WiFi Modbus/TCP activado y la IP, el ID de unidad y la dirección del registro rellenados).';

  @override
  String get triggerModeTime => 'Por tiempo';

  @override
  String get triggerModeDistance => 'Por distancia';

  @override
  String get intervalSecondsLabel => 'Intervalo (segundos)';

  @override
  String get distanceIntervalLabel => 'Intervalo de distancia (metros)';

  @override
  String get connectingLabel => 'Conectando...';

  @override
  String get stopButton => 'Detener';

  @override
  String get loggingRunningLabel => 'Registro en curso...';

  @override
  String get loggingStoppedLabel => 'Registro detenido';

  @override
  String capturedPointsLabel(int count) {
    return 'Puntos registrados: $count';
  }

  @override
  String lastValueLabel(String value, String unit) {
    return 'Último valor: $value $unit';
  }

  @override
  String failedReadingsLabel(int count) {
    return 'Lecturas fallidas: $count';
  }

  @override
  String lastErrorSuffix(String error) {
    return ' (último error: $error)';
  }

  @override
  String get intervalMinError => 'El intervalo debe ser de al menos 1 segundo.';

  @override
  String get distanceMinError => 'La distancia debe ser de al menos 1 metro.';

  @override
  String modbusConnectErrorMessage(String error) {
    return 'Error de conexión Modbus: $error';
  }

  @override
  String get csvHeaderSerialNumber => 'N.º';

  @override
  String get csvHeaderLocation => 'Lugar';

  @override
  String get csvHeaderType => 'Tipo';

  @override
  String get csvHeaderValue => 'Valor';

  @override
  String get csvHeaderUnit => 'Unidad';

  @override
  String get csvHeaderDistanceFromSource => 'Distancia a la fuente';

  @override
  String get csvHeaderInstrument => 'Instrumento';

  @override
  String get csvHeaderGpsLatitude => 'Latitud GPS';

  @override
  String get csvHeaderGpsLongitude => 'Longitud GPS';

  @override
  String get csvHeaderGpsAccuracy => 'Precisión GPS';

  @override
  String get csvHeaderTimestamp => 'Marca de tiempo';

  @override
  String get csvHeaderSample => 'Toma de muestras';

  @override
  String get csvHeaderNotes => 'Notas';

  @override
  String get csvHeaderEstimatedActivity =>
      'Actividad estimada (a partir de la medición)';

  @override
  String get csvHeaderAttachedSources => 'Fuente(s) asociada(s)';

  @override
  String get csvHeaderCalculatedDoseRate => 'Tasa de dosis calculada';

  @override
  String get csvHeaderDoseRateDifference => 'Diferencia';

  @override
  String get csvYes => 'sí';

  @override
  String get csvNo => 'no';

  @override
  String get importUnknownTypeWarning =>
      'Se omitió un tipo de medición desconocido en un punto.';

  @override
  String get importMissingGpsWarning =>
      'Se omitió un punto por falta de coordenada GPS.';

  @override
  String get manageSourcesLabel => 'Gestionar fuente(s) radiactiva(s)';

  @override
  String sourcesCountLabel(int count) {
    return '$count fuente(s)';
  }

  @override
  String get radiationSourcesTitle => 'Fuentes';

  @override
  String get newSourceButton => 'Añadir fuente';

  @override
  String get newSourceTitle => 'Nueva fuente';

  @override
  String get editSourceTitle => 'Editar fuente';

  @override
  String get noSourcesRecordedYet =>
      'Este punto aún no tiene fuentes asociadas.';

  @override
  String get sourcesTooltip => 'Fuentes';

  @override
  String get pointSourcesTitle => 'Fuente(s) en este punto';

  @override
  String get attachSourceButton => 'Asociar fuente';

  @override
  String get pickSourceTitle => 'Elegir fuente';

  @override
  String get noSourcesToAttach =>
      'Aún no hay fuentes disponibles: añade primero una en la lista principal de Fuentes.';

  @override
  String get noSourcesYet =>
      'Aún no se han añadido fuentes. Añade una con el botón +.';

  @override
  String get enterDistanceDialogTitle => 'Introducir distancia';

  @override
  String get detachSourceConfirmTitle => 'Desasociar fuente';

  @override
  String detachSourceConfirmMessage(String identifier) {
    return '¿Desasociar la fuente «$identifier» de este punto? La fuente permanece en el registro; solo se elimina este vínculo.';
  }

  @override
  String get detachButton => 'Desasociar';

  @override
  String get totalCalculatedDoseRateLabel =>
      'Tasa de dosis total calculada (todas las fuentes)';

  @override
  String sourcesUnknownNuclideSkippedNote(int count) {
    return '$count fuente(s) tienen un nucleído desconocido y se excluyen del total.';
  }

  @override
  String get sourceIdentifierLabel => 'Identificador único';

  @override
  String get nuclideLabel => 'Nucleído';

  @override
  String get customNuclideOption => 'Otro (entrada manual)';

  @override
  String get customNuclideNameLabel => 'Nombre del nucleído';

  @override
  String get activityAtManufactureLabel => 'Actividad en la fabricación (MBq)';

  @override
  String get activityErrorPercentLabel => 'Error de la actividad (±%)';

  @override
  String get manufactureDateLabel => 'Fecha de fabricación';

  @override
  String get serviceLifeExpiryDateLabel => 'Fin de la vida útil';

  @override
  String get nextInspectionDateLabel => 'Fecha de la próxima inspección';

  @override
  String get sourceDistanceLabel => 'Distancia al punto de medida (m)';

  @override
  String get asOfDateLabel => 'Fecha de referencia de la actividad';

  @override
  String get currentActivityResultLabel => 'Actividad actual';

  @override
  String get calculatedDoseRateResultLabel => 'Tasa de dosis calculada';

  @override
  String get measuredDoseRateResultLabel =>
      'Tasa de dosis medida (en el punto)';

  @override
  String get doseRateDifferenceResultLabel => 'Diferencia (medida − calculada)';

  @override
  String get unknownNuclideDecayWarning =>
      'Nucleído desconocido: no hay periodo de semidesintegración ni constante gamma guardados, por lo que no se pueden determinar la actividad actual ni la tasa de dosis calculada. Los datos de la fuente se pueden guardar igualmente, pero se omite la comparación.';

  @override
  String get noMeasuredValueForComparisonNote =>
      'No hay valor medido registrado para este punto: no es posible comparar.';

  @override
  String unrecognizedUnitForComparisonNote(String unit) {
    return 'La unidad de medida ($unit) no se puede convertir automáticamente: no es posible comparar.';
  }

  @override
  String get sourceExpiredWarning => 'La vida útil de la fuente ha vencido.';

  @override
  String get deleteSourceConfirmTitle => 'Eliminar fuente';

  @override
  String deleteSourceConfirmMessage(String identifier) {
    return '¿Eliminar la fuente «$identifier» del registro? También se quitará de todos los puntos a los que está asociada. No se puede deshacer.';
  }

  @override
  String get sourceCalculationDisclaimer =>
      'Los valores calculados son solo orientativos y se basan en constantes gamma y periodos de semidesintegración estándar. Para registros oficiales, contrasta con una fuente autorizada.';

  @override
  String get estimatedActivityFromMeasurementLabel =>
      'Actividad estimada (a partir del valor medido)';

  @override
  String get personsTooltip => 'Personas';

  @override
  String get personsTitle => 'Personas';

  @override
  String get newPersonButton => 'Añadir persona';

  @override
  String get newPersonTitle => 'Nueva persona';

  @override
  String get editPersonTitle => 'Editar persona';

  @override
  String get noPersonsYet =>
      'Aún no se han añadido personas. Añade una con el botón +.';

  @override
  String get personNameLabel => 'Nombre';

  @override
  String get medicalExamExpiryDateLabel => 'Vencimiento del examen médico';

  @override
  String get trainingExpiryDateLabel => 'Vencimiento de la formación';

  @override
  String get deletePersonConfirmTitle => 'Eliminar persona';

  @override
  String deletePersonConfirmMessage(String name) {
    return '¿Eliminar a «$name» del registro? También se quitará de todas las inspecciones a las que está asignada. No se puede deshacer.';
  }

  @override
  String get sessionPersonsTitle => 'Personal de esta inspección';

  @override
  String get noPersonsAttachedYet =>
      'Aún no hay personas asignadas a esta inspección.';

  @override
  String get attachPersonButton => 'Asignar persona';

  @override
  String get pickPersonTitle => 'Elegir persona';

  @override
  String get noPersonsToAttach =>
      'Aún no hay personas disponibles para añadir: crea primero una en la lista principal de Personas.';

  @override
  String get detachPersonConfirmTitle => 'Quitar persona';

  @override
  String detachPersonConfirmMessage(String name) {
    return '¿Quitar a «$name» de esta inspección? La persona permanece en el registro; solo se elimina esta asignación.';
  }

  @override
  String get expiryNotificationsSectionTitle => 'Notificaciones de vencimiento';

  @override
  String get expiryNotificationsSwitchTitle =>
      'Notificar fechas de vencimiento';

  @override
  String get expiryNotificationsSwitchSubtitle =>
      'Para los próximos vencimientos de fuentes (vida útil, inspección) y personas (examen médico, formación), enviadas a las 8:00 de la mañana.';

  @override
  String get expiryLeadTimeLabel => 'Con cuánta antelación notificar';

  @override
  String get expiryLeadSameDay => 'El mismo día';

  @override
  String get expiryLeadOneDay => '1 día antes';

  @override
  String get expiryLeadTwoDays => '2 días antes';

  @override
  String get expiryLeadOneWeek => '1 semana antes';

  @override
  String get expiryLeadTwoWeeks => '2 semanas antes';

  @override
  String expiryLeadMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses antes',
      one: '1 mes antes',
    );
    return '$_temp0';
  }

  @override
  String get expiryNotificationsPermissionDenied =>
      'Las notificaciones están bloqueadas en los ajustes del teléfono. Permite allí las notificaciones de RadRecon.';

  @override
  String get expiryNotificationTitleToday => 'Vence hoy';

  @override
  String get expiryNotificationTitleUpcoming => 'Vence pronto';

  @override
  String get expiryNotificationChannelName => 'Notificaciones de vencimiento';

  @override
  String get expiryNotificationChannelDescription =>
      'Próximos vencimientos de fuentes y personas';

  @override
  String get importRegistryCsv => 'Importar CSV';

  @override
  String get exportRegistryCsv => 'Exportar CSV';

  @override
  String get registryCsvExportSubject => 'Datos del registro de RadRecon (CSV)';

  @override
  String get duplicatePolicyTitle => 'Cuando existe un registro coincidente';

  @override
  String get duplicateReplace => 'Sustituir el registro existente';

  @override
  String get duplicateSkip => 'Omitir el registro coincidente';

  @override
  String get duplicateKeep => 'Importar como duplicado';

  @override
  String registryImportSummary(int imported, int replaced, int skipped) {
    return 'Importados: $imported, sustituidos: $replaced, omitidos: $skipped';
  }

  @override
  String get modbusTestConnectionButton => 'Probar conexión';

  @override
  String get modbusTestingLabel => 'Probando...';

  @override
  String get modbusTestSuccessTitle => 'Conexión correcta';

  @override
  String get modbusTestFailureTitle => 'Conexión fallida';

  @override
  String modbusTestValue(String value) {
    return 'Valor: $value';
  }

  @override
  String modbusTestPosition(String lat, String lon) {
    return 'Lat: $lat, Lon: $lon';
  }

  @override
  String missingFieldMessage(String field) {
    return 'Rellena: $field';
  }

  @override
  String get errorTitle => 'Error';

  @override
  String modbusReadErrorWithCode(String code) {
    return 'Error Modbus durante la lectura: $code';
  }

  @override
  String get instrumentDidNotSendValidValue =>
      'El instrumento no envió un valor válido.';

  @override
  String get gpsPositionReadFailed =>
      'No se pudo leer la posición GPS del instrumento.';

  @override
  String get instrumentIPAddressNotSet =>
      'No se ha definido la dirección IP del instrumento.';

  @override
  String get modbusUnitIdNotSet => 'No se ha definido el ID de unidad Modbus.';

  @override
  String get registerAddressNotSet =>
      'No se ha definido la dirección del registro.';

  @override
  String get failedToConnectToInstrument =>
      'No se pudo conectar con el instrumento.';

  @override
  String connectionErrorWithDetails(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get modbusAccessIncomplete =>
      'Los datos de acceso Modbus del instrumento están incompletos (IP, ID de unidad, dirección del registro).';

  @override
  String get noDisplayableContentForScreenshot =>
      'No hay contenido visible para la captura.';

  @override
  String get failedToConvertScreenshotToPng =>
      'No se pudo convertir la captura a PNG.';

  @override
  String get doseSourceOnline => 'En línea (desde el detector)';

  @override
  String get doseSourceManual => 'Manual';

  @override
  String get doseSourcePassive => 'Dosimetría pasiva';

  @override
  String annualDoseLabel(int year) {
    return 'Dosis en $year';
  }

  @override
  String get doseYearLabel => 'Año';

  @override
  String doseBreakdownLabel(String online, String manual, String passive) {
    return 'en línea $online · manual $manual · pasiva $passive';
  }

  @override
  String personDosesTitle(String name) {
    return 'Dosis – $name';
  }

  @override
  String get personDosesTooltip => 'Gestionar dosis';

  @override
  String get noDosesYet => 'Aún no hay registros de dosis de este año.';

  @override
  String get addPassiveDoseButton => 'Añadir dosimetría pasiva';

  @override
  String get newPassiveDoseTitle => 'Nueva dosimetría pasiva';

  @override
  String get editDoseTitle => 'Editar dosis';

  @override
  String get doseValueLabel => 'Dosis';

  @override
  String get dosePeriodStartLabel => 'Inicio del periodo de evaluación';

  @override
  String get dosePeriodEndLabel => 'Fin del periodo de evaluación';

  @override
  String get dosePeriodEndBeforeStartError =>
      'El fin no puede ser anterior al inicio.';

  @override
  String get doseTotalLabel => 'Total';

  @override
  String get doseDeleteConfirmTitle => 'Eliminar registro de dosis';

  @override
  String get doseDeleteConfirmMessage =>
      '¿Eliminar este registro de dosis? No se puede deshacer.';

  @override
  String sessionDoseDialogTitle(String name) {
    return 'Dosis de $name';
  }

  @override
  String get onlineDoseLabel => 'Dosis en línea';

  @override
  String get manualDoseLabel => 'Dosis manual';

  @override
  String get closeSurveyDosesTitle => 'Revisar dosis';

  @override
  String get closeSurveyDosesHint =>
      'Antes de cerrar, revisa o corrige la dosis de cada participante.';

  @override
  String autoLogDoseSaved(int count, String dose) {
    return 'Dosis guardada para $count persona(s): $dose';
  }

  @override
  String autoLogDoseNoPersons(String dose) {
    return 'La dosis medida ($dose) no se guardó porque no hay ninguna persona asignada a esta inspección.';
  }

  @override
  String autoLogDoseLabel(String dose) {
    return 'Dosis integrada: $dose';
  }

  @override
  String autoLogDoseGaps(int count) {
    return '$count laguna(s) de datos más larga(s) durante la medición';
  }

  @override
  String get autoLogDoseOnlyDoseRate =>
      'La dosis solo se puede calcular y guardar a partir de mediciones de tasa de dosis.';

  @override
  String get importPersonDosesCsv => 'Importar dosis (CSV)';

  @override
  String get exportPersonDosesCsv => 'Exportar dosis (CSV)';

  @override
  String get dataManagementSectionTitle => 'Gestión de datos';

  @override
  String get saveDatabaseButton => 'Guardar la base de datos en un archivo';

  @override
  String get loadDatabaseButton => 'Cargar la base de datos desde un archivo';

  @override
  String get clearDatabaseButton => 'Borrar la base de datos';

  @override
  String get companySwitchButton => 'Cambiar de empresa';

  @override
  String get dataManagementHint =>
      'El archivo de copia contiene todos los datos, incluidas las fotos, por lo que sirve para pasar a un teléfono nuevo o para mantener separados los datos de varias empresas.';

  @override
  String get saveDatabaseSubject =>
      'Copia de seguridad de la base de datos de RadRecon';

  @override
  String databaseSavedMessage(String path) {
    return 'Base de datos guardada: $path';
  }

  @override
  String get loadDatabaseConfirmTitle => 'Cargar base de datos';

  @override
  String get loadDatabaseConfirmBody =>
      'Al cargar se sobrescriben todos los datos que hay ahora en este dispositivo. Guárdalos antes si aún los necesitas. ¿Continuar?';

  @override
  String get loadButton => 'Cargar';

  @override
  String databaseLoadedMessage(String name) {
    return 'Cargado: $name';
  }

  @override
  String get clearDatabaseConfirmTitle => 'Borrar base de datos';

  @override
  String get clearDatabaseConfirmBody =>
      'Se eliminarán de forma permanente de este dispositivo todas las inspecciones, puntos de medida, instrumentos, fuentes, personas y fotos. No se puede deshacer: ¡haz antes una copia de seguridad!';

  @override
  String get databaseClearedMessage => 'Base de datos borrada.';

  @override
  String get companySwitchTitle => 'Cambiar de empresa';

  @override
  String get activeCompanyLabel => 'Empresa activa';

  @override
  String get companiesFolderLabel => 'Carpeta de empresas';

  @override
  String get chooseFolderButton => 'Elegir carpeta';

  @override
  String get resetFolderButton => 'Volver a la carpeta predeterminada';

  @override
  String get noCompaniesYet =>
      'Aún no hay empresas guardadas en esta carpeta. La empresa activa se guarda automáticamente en el primer cambio, o crea una nueva / añade un archivo de copia con los botones de arriba.';

  @override
  String companyBackupInfo(String date) {
    return 'Guardado: $date';
  }

  @override
  String get newCompanyButton => 'Nueva empresa';

  @override
  String get newCompanyDialogTitle => 'Crear nueva empresa';

  @override
  String get companyNameLabel => 'Nombre de la empresa';

  @override
  String get companyNameExistsMessage =>
      'Ya existe una empresa con este nombre.';

  @override
  String get createButton => 'Crear';

  @override
  String get addCompanyFromFileButton =>
      'Añadir empresa desde un archivo de copia';

  @override
  String get companySwitchConfirmTitle => 'Cambiar de empresa';

  @override
  String companySwitchConfirmBody(String company, String active) {
    return '¿Cambiar a $company? Los datos actuales se guardan automáticamente como $active.';
  }

  @override
  String get companySwitchAction => 'Cambiar';

  @override
  String companySwitchedMessage(String name) {
    return 'Empresa activa: $name';
  }

  @override
  String get deleteCompanyBackupTitle => 'Eliminar copia de seguridad';

  @override
  String deleteCompanyBackupBody(String name) {
    return '¿Eliminar de la carpeta la copia de seguridad de $name? Los datos cargados actualmente no se ven afectados.';
  }

  @override
  String get importPersonCsv => 'Importar personas (CSV)';

  @override
  String get exportPersonCsv => 'Exportar personas (CSV)';

  @override
  String get privateFolderHint =>
      'La app usa ahora su propia carpeta privada, a la que otras apps no pueden acceder. Elige una carpeta (p. ej. Descargas o Google Drive) para acceder a las copias desde el gestor de archivos.';

  @override
  String get contributorsTitle => 'Colaboradores';

  @override
  String get contributorsThanks =>
      'Gracias a todos los que ayudan a probar, desarrollar, traducir y revisar RadRecon. RadRecon es una iniciativa cívica sin ánimo de lucro creada por voluntarios.';

  @override
  String get contributorsOrganizationsTitle => 'Organizaciones y empresas';

  @override
  String get contributorsPeopleTitle => 'Personas';

  @override
  String get contributorsEmpty => 'La lista aún está vacía. ¡Sé el primero!';

  @override
  String get contributorsLoadError => 'No se pudo cargar la lista.';

  @override
  String get contributorsJoinHint =>
      '¿Quieres aparecer en la lista? Inscríbete como voluntario y dinos cómo quieres figurar:';

  @override
  String get contributorsCopyLink => 'Copiar enlace';

  @override
  String get contributorsLinkCopied => 'Enlace copiado.';

  @override
  String get contributorRoleTesting => 'Pruebas';

  @override
  String get contributorRoleDevelopment => 'Desarrollo';

  @override
  String get contributorRoleReview => 'Revisión experta';

  @override
  String get contributorRoleTranslation => 'Traducción';

  @override
  String get contributorRoleOther => 'Otro';

  @override
  String get regulatoryProfileLabel => 'Perfil normativo';

  @override
  String get regulatoryProfileInternational => 'Internacional (OIEA)';

  @override
  String get regulatoryProfileHungary => 'Hungría (OAH)';

  @override
  String get classificationTitle => 'Clasificación (D, R, exención)';

  @override
  String get classificationDisclaimer =>
      'Cálculo orientativo a partir de tablas de nucleídos y de la actividad actual (corregida por desintegración). La clasificación oficial la determinan la ley aplicable y la autoridad. La clase de laboratorio según MSZ 62-7 es un valor orientativo derivado de la actividad.';

  @override
  String get classificationUnsealedWork =>
      'Trabajo regular con fuentes no encapsuladas';

  @override
  String get classificationOutsideWorkplace =>
      'Uso fuera del lugar de trabajo con radiaciones';

  @override
  String get classificationTotal => 'Total (fuentes seleccionadas)';

  @override
  String get classificationPhysCat => 'Categoría de protección física';

  @override
  String get classificationProtCat => 'Categoría de protección radiológica';

  @override
  String get classificationUnknownCount =>
      'Fuentes sin R (nucleído desconocido)';

  @override
  String get classificationActivity => 'Actividad';

  @override
  String get classificationNotDecayCorrected =>
      'sin corrección por desintegración';

  @override
  String get classificationDInfinite => 'D = ∞ (no contribuye a R)';

  @override
  String get classificationDUnknown =>
      'No hay valor D para este nucleído, no se puede calcular R';

  @override
  String get classificationExemptUnknown =>
      'No hay valores de exención para este nucleído';

  @override
  String get classificationExemptActivity => 'Actividad exenta';

  @override
  String get classificationSpecificConc =>
      'Concentración de exención específica';

  @override
  String get classificationGeneralConc => 'general';

  @override
  String get classificationBelowExempt =>
      'La actividad es igual o inferior a la actividad exenta';

  @override
  String get classificationAboveExempt =>
      'La actividad supera la actividad exenta';

  @override
  String get classificationProtLevel => 'Nivel de protección física';

  @override
  String get classificationAdrConsignmentLimit => 'límite de bulto exento';

  @override
  String get classificationAdrBelow =>
      'la actividad es inferior (no es Clase 7)';

  @override
  String get classificationAdrAbove =>
      'la actividad es superior (también importa la concentración)';

  @override
  String get classificationLabIndustrial => 'Laboratorio industrial';

  @override
  String get classificationLabMedical => 'Laboratorio médico';

  @override
  String get classificationLabAboveIII => '> III';

  @override
  String get classificationLabOps => 'Tipos de operación permitidos';

  @override
  String get classificationLabUnknown =>
      'MSZ 62-7: no hay valor AM para este nucleído';

  @override
  String get autoLogChartTitle => 'Valor medido a lo largo del tiempo';

  @override
  String get gpsAverageButton => 'GPS promediado';

  @override
  String get gpsAverageTitle => 'Promediado de posición';

  @override
  String get gpsAverageHint =>
      'Quédate quieto en un mismo lugar durante la medición. Un tiempo de promediado mayor da un resultado más fiable; a cielo abierto es mejor. Las muestras se ponderan por su precisión y se descartan las posiciones atípicas.';

  @override
  String get gpsAverageStart => 'Iniciar';

  @override
  String get gpsAverageUse => 'Usar';

  @override
  String get gpsAverageSamples => 'Muestras';

  @override
  String get gpsAverageCurrent => 'Precisión actual';

  @override
  String get gpsAverageResult => 'Precisión estimada del promedio';

  @override
  String get modbusAverageButton => 'Medición promediada';

  @override
  String get modbusAverageRunning => 'Promediando';

  @override
  String get modbusAverageDone => 'Listo';

  @override
  String get modbusAverageTooFew =>
      'Se necesitan al menos 2 muestras válidas para calcular el error; solo se introdujo el valor.';

  @override
  String get measurementErrorLabel => 'Error (±)';

  @override
  String get measurementErrorHelper =>
      'En una medición promediada es el error estándar de la media (1σ); también puede introducirse a mano en valores introducidos manualmente. Se incluye en el protocolo.';

  @override
  String get measurementAveragedLabel => 'Medición promediada';

  @override
  String get csvHeaderValueError => 'Error (±)';

  @override
  String get csvHeaderAveraging => 'Promediado (muestras; s)';

  @override
  String get helpManualTitle => 'Ayuda (manual de usuario)';

  @override
  String get helpManualOpenError => 'No se pudo abrir el manual.';

  @override
  String get appVersionLabel => 'Versión';

  @override
  String get appUpdateTitle => 'Nueva versión disponible';

  @override
  String appUpdateAvailableMessage(String version) {
    return 'La versión $version está disponible. Actualiza la aplicación para obtener las últimas mejoras.';
  }

  @override
  String appUpdateRequiredMessage(String version) {
    return 'Esta versión ya no es compatible. Actualiza a la versión $version para continuar.';
  }

  @override
  String get appUpdateLater => 'Más tarde';

  @override
  String get appUpdateNow => 'Actualizar';

  @override
  String get rrRoleSurveyor => 'Encuestador';

  @override
  String get rrRoleVictim => 'Afectado / víctima';

  @override
  String get rrTriageNone => 'Sin clasificar';

  @override
  String get rrTriageRed => 'Rojo – atención inmediata';

  @override
  String get rrTriageYellow => 'Amarillo – atención diferida';

  @override
  String get rrTriageGreen => 'Verde – lesión leve';

  @override
  String get rrTriageBlack => 'Negro – fallecido / sin atención';

  @override
  String get rrConditionInjury => 'Lesión';

  @override
  String get rrConditionIllness => 'Enfermedad';

  @override
  String get rrAffectedPrefix => 'Afectado';

  @override
  String get rrEditStatusTooltip => 'Función, triaje, lesiones';

  @override
  String get rrRoleLabel => 'Función';

  @override
  String get rrTriageCategoryLabel => 'Categoría de triaje';

  @override
  String get rrInjuriesAndIllnesses => 'Lesiones y enfermedades';

  @override
  String get rrDescriptionHint => 'Descripción';

  @override
  String get rrAddItem => 'Añadir elemento';

  @override
  String get rrDeleteTooltip => 'Eliminar';

  @override
  String get rrMeteoSection => 'Meteorología (opcional)';

  @override
  String get rrMetTemp => 'Temperatura del aire (°C)';

  @override
  String get rrMetHumidity => 'Humedad relativa (%)';

  @override
  String get rrMetPressure => 'Presión atmosférica (hPa)';

  @override
  String get rrMetWind => 'Velocidad del viento (m/s)';

  @override
  String get rrMetWindDir => 'Dirección del viento (°)';

  @override
  String get rrMetGust => 'Racha de viento (m/s)';

  @override
  String get rrMetPrecipIntensity => 'Intensidad de precipitación (mm/h)';

  @override
  String get rrMetSolar => 'Radiación solar (W/m²)';

  @override
  String get rrMetCloud => 'Nubosidad (octavos, 0–8)';

  @override
  String get rrMetVisibility => 'Visibilidad (m)';

  @override
  String get rrMetSoil => 'Humedad del suelo (%)';

  @override
  String get rrMetAerosol => 'Concentración de aerosoles (µg/m³)';

  @override
  String get rrPrecipState => 'Estado de precipitación';

  @override
  String get rrPrecipNone => 'Sin precipitación';

  @override
  String get rrPrecipDrizzle => 'Llovizna';

  @override
  String get rrPrecipRain => 'Lluvia';

  @override
  String get rrPrecipSnow => 'Nieve';

  @override
  String get rrPrecipSleet => 'Aguanieve';

  @override
  String get rrPrecipHail => 'Granizo';

  @override
  String get rrMetOther => 'Otra observación';

  @override
  String get rrGasSection => 'Medición de gases';

  @override
  String get rrAddGas => 'Añadir gas';

  @override
  String get rrGasSpecies => 'Compuesto';

  @override
  String get rrGasOther => 'Otro';

  @override
  String get rrGasOtherName => 'Nombre del compuesto';

  @override
  String get rrFormulaLabel => 'Fórmula';

  @override
  String get rrGasConcentration => 'Concentración';

  @override
  String get rrGasUnit => 'Unidad';

  @override
  String get rrInvalidValue => 'Valor no válido';

  @override
  String get rrGasAmmonia => 'Amoníaco';

  @override
  String get rrGasBenzene => 'Benceno';

  @override
  String get rrGasPhosphine => 'Fosfina';

  @override
  String get rrGasPhosgene => 'Fosgeno';

  @override
  String get rrGasHydrogen => 'Hidrógeno';

  @override
  String get rrGasHydrogenCyanide => 'Cianuro de hidrógeno';

  @override
  String get rrGasVoc => 'Compuestos orgánicos volátiles';

  @override
  String get rrGasSulfurDioxide => 'Dióxido de azufre';

  @override
  String get rrGasSulfurHexafluoride => 'Hexafluoruro de azufre';

  @override
  String get rrGasHydrogenSulfide => 'Sulfuro de hidrógeno';

  @override
  String get rrGasChlorine => 'Cloro';

  @override
  String get rrGasMethane => 'Metano';

  @override
  String get rrGasMethanol => 'Metanol';

  @override
  String get rrGasMethylSalicylate => 'Salicilato de metilo';

  @override
  String get rrGasNitricOxide => 'Monóxido de nitrógeno';

  @override
  String get rrGasNitrogenDioxide => 'Dióxido de nitrógeno';

  @override
  String get rrGasNitrogenOxides => 'Óxidos de nitrógeno';

  @override
  String get rrGasOxygen => 'Oxígeno';

  @override
  String get rrGasOzone => 'Ozono';

  @override
  String get rrGasPropane => 'Propano';

  @override
  String get rrGasCarbonDioxide => 'Dióxido de carbono';

  @override
  String get rrGasCarbonMonoxide => 'Monóxido de carbono';

  @override
  String get rrGasToluene => 'Tolueno';

  @override
  String get rrGasTributylPhosphate => 'Fosfato de tributilo';

  @override
  String get measurementTypeMeteorology => 'Meteorología';

  @override
  String get measurementTypeGasMeasurement => 'Medición de gases';

  @override
  String get mapAreaButtonTooltip => 'Marcar área';

  @override
  String get mapAreaListTooltip => 'Áreas marcadas';

  @override
  String get mapAreaNewTitle => 'Nueva área';

  @override
  String get mapAreaNameLabel => 'Nombre (p. ej. Área medida)';

  @override
  String get mapAreaNameRequired => 'Introduzca el nombre del área.';

  @override
  String get mapAreaShapeLabel => 'Forma';

  @override
  String get mapAreaPolygon => 'Polígono';

  @override
  String get mapAreaCircle => 'Círculo';

  @override
  String get mapAreaColorLabel => 'Color';

  @override
  String get mapAreaStartDrawing => 'Dibujar';

  @override
  String get mapAreaHintPolygon => 'Toque las esquinas y luego pulse Listo.';

  @override
  String get mapAreaHintCircle =>
      'Toque el centro y luego un punto del borde para fijar el radio.';

  @override
  String get mapAreaMinPointsError => 'Se necesitan al menos 3 esquinas.';

  @override
  String get mapAreaCircleIncomplete => 'Marque el centro y el radio.';

  @override
  String get mapAreaUndo => 'Deshacer';

  @override
  String get mapAreaDone => 'Listo';

  @override
  String get mapAreaNoAreas => 'No hay áreas marcadas.';

  @override
  String get mapAreaDeleteConfirm => '¿Eliminar el área seleccionada?';

  @override
  String get mapAreaDeleteTooltip => 'Eliminar área';

  @override
  String get unitConverterTitle => 'Conversor de unidades';

  @override
  String get unitConverterCategoryLabel => 'Magnitud';

  @override
  String get unitConverterValueLabel => 'Valor';

  @override
  String get unitConverterFromLabel => 'Unidad de origen';

  @override
  String get unitConverterMolarMassLabel => 'Masa molar (g/mol)';

  @override
  String get unitConverterMolarMassHint =>
      'Para convertir entre concentración másica y volumétrica se necesita la masa molar, p. ej. CO: 28,01. Cálculo a 25 °C, 1 atm.';

  @override
  String get unitConverterNeedsMolarMass =>
      'Introduzca la masa molar para convertir entre unidades de masa y de volumen.';

  @override
  String get unitConverterEnterValue => 'Introduzca un valor.';

  @override
  String get unitConverterTapHint =>
      'Toque una fila: el valor se convierte a esa unidad y pasa a ser la unidad de origen.';

  @override
  String get unitConverterGasNote =>
      'La unidad %LIE de la concentración de gas no se puede convertir, porque depende del límite del gas.';

  @override
  String get unitCatDose => 'Dosis';

  @override
  String get unitCatDoseRate => 'Tasa de dosis';

  @override
  String get unitCatActivity => 'Actividad';

  @override
  String get unitCatActivityConcentration => 'Concentración de actividad';

  @override
  String get unitCatSurfaceContamination => 'Contaminación superficial';

  @override
  String get unitCatCountRate => 'Tasa de conteo';

  @override
  String get unitCatLength => 'Longitud';

  @override
  String get unitCatArea => 'Superficie';

  @override
  String get unitCatVolume => 'Volumen';

  @override
  String get unitCatMass => 'Masa';

  @override
  String get unitCatTemperature => 'Temperatura';

  @override
  String get unitCatPressure => 'Presión';

  @override
  String get unitCatSpeed => 'Velocidad';

  @override
  String get unitCatTime => 'Tiempo';

  @override
  String get unitCatIrradiance => 'Irradiancia';

  @override
  String get unitCatRainRate => 'Intensidad de precipitación';

  @override
  String get unitCatMassConcentration => 'Concentración másica (aerosol)';

  @override
  String get unitCatGasConcentration => 'Concentración de gas';

  @override
  String get unitConverterGasPick => 'Seleccionar gas (rellena la masa molar)';

  @override
  String get decayCalcTitle => 'Calculadora de desintegración';

  @override
  String get decayCalcIsotope => 'Isótopo';

  @override
  String get decayCalcCustom => 'Otro (vida media propia)';

  @override
  String get decayCalcHalfLife => 'Vida media';

  @override
  String get decayCalcInitialActivity => 'Actividad inicial';

  @override
  String get decayCalcElapsed => 'Tiempo transcurrido';

  @override
  String get decayCalcTargetActivity => 'Actividad objetivo';

  @override
  String get decayCalcModeForward => 'Actividad tras el tiempo t';

  @override
  String get decayCalcModeBackward => 'Tiempo hasta la actividad objetivo';

  @override
  String get decayCalcDistance => 'Distancia (m, opcional)';

  @override
  String get decayCalcResultActivity => 'Actividad';

  @override
  String get decayCalcResultRemaining => 'Fracción restante';

  @override
  String get decayCalcResultHalfLives => 'Número de vidas medias';

  @override
  String get decayCalcResultDoseRate => 'Tasa de dosis a la distancia';

  @override
  String get decayCalcResultTime => 'Tiempo necesario';

  @override
  String get decayCalcErrorTarget =>
      'La actividad objetivo debe ser positiva y menor que la inicial.';

  @override
  String get decayCalcNeedsInput => 'Introduzca los números.';

  @override
  String get decayCalcNoHalfLife => 'Introduzca la vida media.';

  @override
  String get decayCalcNote =>
      'Desintegración exponencial pura; no incluye hijos ni otra radiación.';

  @override
  String get doseLimitTitle => 'Límite de dosis anual';

  @override
  String get doseLimitCategoryOccupational => 'Ocupacional';

  @override
  String get doseLimitCategoryPublic => 'Público';

  @override
  String get doseLimitSourceOah => 'Decreto OAH 2/2022 (IV. 29.)';

  @override
  String get doseLimitSourceIaea => 'IAEA GSR Part 3';

  @override
  String get doseLimitUsedLabel => 'utilizado';

  @override
  String get doseLimitStatusOk => 'dentro del límite';

  @override
  String get doseLimitStatusWarning => 'nivel de aviso alcanzado';

  @override
  String get doseLimitStatusExceeded => 'límite superado';

  @override
  String get doseLimitNote =>
      'Comprobación de un año; no se aplica el promedio de cinco años de la AIEA.';

  @override
  String get displayUnitsHint =>
      'La visualización y el protocolo usan estas unidades. Las exportaciones (CSV, JSON) y las copias de seguridad conservan siempre la unidad almacenada.';

  @override
  String get displayDoseUnitLabel => 'Unidad de dosis personal';

  @override
  String get displayDoseAutoOption =>
      'Automático (µSv, mSv por encima de 1 mSv)';

  @override
  String get displaySurfaceUnitLabel => 'Unidad de contaminación superficial';

  @override
  String get displayTemperatureUnitLabel => 'Unidad de temperatura';

  @override
  String get displayPressureUnitLabel => 'Unidad de presión';

  @override
  String get displayWindUnitLabel => 'Unidad de velocidad del viento';

  @override
  String get protoTitle => 'Acta de medición radiológica de campo';

  @override
  String get protoCompany => 'Empresa';

  @override
  String get protoSurveyName => 'Nombre del levantamiento';

  @override
  String get protoLocation => 'Lugar';

  @override
  String get protoStarted => 'Inicio del levantamiento';

  @override
  String get protoClosed => 'Cierre del levantamiento';

  @override
  String get protoNotes => 'Observaciones';

  @override
  String get protoOngoing => 'en curso';

  @override
  String get protoDate => 'Fecha';

  @override
  String get protoSignature => 'Firma';

  @override
  String get protoSurveyedBy => 'Levantamiento realizado por';

  @override
  String get protoColon => ': ';

  @override
  String get protoDecimalSep => ',';

  @override
  String get protoDateTimeFormat => 'dd/MM/yyyy HH:mm';

  @override
  String get protoDateFormat => 'dd/MM/yyyy';

  @override
  String get protoPointsHeading => 'Puntos de medición';

  @override
  String get protoSourceHeading => 'Análisis de la fuente';

  @override
  String get protoNoSourcePoints =>
      'Ningún punto de medición con fuente asignada o estimación de actividad.';

  @override
  String get protoSourceNote =>
      'Solo se incluyen los puntos de medición con fuente asignada o estimación de actividad. Los valores calculados son solo orientativos.';

  @override
  String get protoDosimeterHeading => 'Dosímetros';

  @override
  String get protoVictimsHeading => 'Personas afectadas (víctimas)';

  @override
  String get protoAreasHeading => 'Zonas marcadas';

  @override
  String get protoMeteoHeading => 'Meteorología';

  @override
  String get protoGasHeading => 'Medición de gases';

  @override
  String get protoPhotosHeading => 'Fotografías';

  @override
  String get protoScreenshotsHeading => 'Capturas de pantalla';

  @override
  String get protoPhotoUnreadable => '(la foto no se puede leer)';

  @override
  String get protoNoDosimeter => 'Ningún dosimetro registrado';

  @override
  String get protoYes => 'sí';

  @override
  String get protoNo => 'no';

  @override
  String get protoColType => 'Tipo';

  @override
  String get protoColValue => 'Valor';

  @override
  String get protoColUnit => 'Unidad';

  @override
  String protoColDistance(String unit) {
    return 'Distancia a la fuente ($unit)';
  }

  @override
  String get protoColInstrument => 'Instrumento';

  @override
  String get protoColGps => 'Coordenadas GPS';

  @override
  String protoColGpsAccuracy(String unit) {
    return 'Precisión GPS ($unit)';
  }

  @override
  String get protoColTime => 'Fecha y hora';

  @override
  String get protoColPhoto => 'Archivo de foto';

  @override
  String get protoColEstActivity =>
      'Actividad estimada (a partir de la medición)';

  @override
  String get protoColAttached => 'Fuente(s) asignada(s)';

  @override
  String get protoColCalcTotal => 'Tasa de dosis calculada';

  @override
  String get protoColMeasured => 'Tasa de dosis medida';

  @override
  String get protoColDiff => 'Desviación';

  @override
  String get protoColIdentifier => 'Identificador';

  @override
  String get protoColWearer => 'Portador';

  @override
  String get protoColReading => 'Lectura (inicio → fin)';

  @override
  String get protoColDose => 'Dosis';

  @override
  String get protoColCounted => 'Computado';

  @override
  String get protoColFormula => 'Fórmula';

  @override
  String get protoColName => 'Nombre';

  @override
  String get protoColTriage => 'Triaje';

  @override
  String get protoColInjuries => 'Lesiones';

  @override
  String get protoColIllnesses => 'Enfermedades';

  @override
  String get protoColAreaName => 'Nombre de la zona';

  @override
  String get protoColShape => 'Forma';

  @override
  String get protoColGeometry => 'Geometría';

  @override
  String get protoColAreaSize => 'Superficie (m²)';

  @override
  String protoColTemp(String unit) {
    return 'Temp. ($unit)';
  }

  @override
  String get protoColHumidity => 'Humedad (%)';

  @override
  String protoColPressure(String unit) {
    return 'Presión ($unit)';
  }

  @override
  String protoColWind(String unit) {
    return 'Viento ($unit)';
  }

  @override
  String get protoColWindDir => 'Dirección del viento (°)';

  @override
  String protoColGust(String unit) {
    return 'Racha ($unit)';
  }

  @override
  String get protoColPrecip => 'Precipitación';

  @override
  String get protoColPrecipIntensity => 'Intensidad de precip. (mm/h)';

  @override
  String get protoColSolar => 'Radiación solar (W/m²)';

  @override
  String get protoColCloud => 'Nubosidad (octavos)';

  @override
  String get protoColVisibility => 'Visibilidad (m)';

  @override
  String get protoColSoil => 'Humedad del suelo (%)';

  @override
  String get protoColAerosol => 'Aerosol (µg/m³)';

  @override
  String get protoColOther => 'Otros';

  @override
  String get protoShapePolygon => 'Polígono';

  @override
  String get protoShapeCircle => 'Círculo';

  @override
  String protoCornerPoints(String count) {
    return '$count vértices';
  }

  @override
  String protoCenterRadius(String lat, String lon, String radius) {
    return 'centro: $lat, $lon; radio: $radius m';
  }

  @override
  String protoPersonDose(String name, String total) {
    return '$name (dosis: $total)';
  }

  @override
  String protoPersonDoseBreakdown(String name, String total, String breakdown) {
    return '$name (dosis: $total – $breakdown)';
  }

  @override
  String protoDoseSession(String dose) {
    return 'medición $dose';
  }

  @override
  String protoDoseDosimeter(String dose) {
    return 'dosímetro $dose';
  }

  @override
  String protoInstrumentWithSerial(String name, String serial) {
    return '$name (nº de serie: $serial)';
  }

  @override
  String protoCalibValidUntil(String date) {
    return 'válido hasta $date';
  }

  @override
  String protoCalibCertificate(String number) {
    return 'certificado: $number';
  }

  @override
  String get protoCalibExpiredAtMeasure =>
      ' – CADUCADO en el momento de la medición';

  @override
  String protoCalibFallback(String date) {
    return 'Calibración válida hasta $date';
  }

  @override
  String get protoUnshielded => 'sin blindaje';

  @override
  String protoShieldedActivity(String activity) {
    return 'blindada: $activity';
  }

  @override
  String protoInputData(String measured, String distance) {
    return 'Datos de entrada: medido $measured, distancia $distance';
  }

  @override
  String get protoShieldingInline => 'blindaje';

  @override
  String protoTransmission(String value) {
    return 'transmisión T = $value';
  }

  @override
  String protoNuclideIdPrefix(String text) {
    return 'Identificación del nucleido: $text';
  }

  @override
  String get protoShotMap => 'Mapa';

  @override
  String get protoShotList => 'Lista de puntos';

  @override
  String protoPhotoCaption(
    String index,
    String type,
    String location,
    String time,
  ) {
    return 'Punto $index · $type · $location · $time';
  }

  @override
  String get mapMeasureTooltip => 'Medición de distancia';

  @override
  String get mapMeasureHint =>
      'Toca dos puntos para trazar una línea. Toca la etiqueta de una línea para seleccionarla, cambiar su color o borrarla.';

  @override
  String get mapMeasureClear => 'Borrar todo';

  @override
  String get mapMeasureDeleteSelected => 'Borrar selección';
}
