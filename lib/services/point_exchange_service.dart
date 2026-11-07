import '../models/bio_agent.dart';
import '../models/radiation_kind.dart';
import '../models/dose_quantity.dart';
import '../models/spectrum.dart';
import 'spectrum_service.dart';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/gas_reading.dart';
import '../models/meteorology.dart';
import '../models/instrument.dart';
import '../models/calibration_labels.dart';
import '../models/instrument_calibration.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/nuclide_id.dart';
import '../models/point_source_link.dart';
import '../models/shielding.dart';
import '../models/activity_origin.dart';
import '../models/radiation_source.dart';
import '../models/source_nuclide.dart';
import '../models/survey_source_placement.dart';
import 'exchange_format.dart';
import 'activity_estimate.dart';
import 'dose_unit_controller.dart';
import 'dose_unit_converter.dart';
import 'unit_format.dart';

/// A CSV export nyelvfüggő fejlécei és a igen/nem szövegek — a szolgáltatás
/// rétegnek nincs `BuildContext`-je, ezért ezt a hívó (egy widget) állítja
/// össze az `AppLocalizations`-ból.
class CsvHeaders {
  final String radiation;
  final String quantity;
  final String basis;
  final String spectrum;
  final String serialNumber;
  final String location;
  final String type;
  final String value;
  final String unit;
  final String distanceFromSource;
  final String instrument;
  final String gpsLatitude;
  final String gpsLongitude;
  final String gpsAccuracy;
  final String timestamp;
  final String sample;
  final String notes;
  final String estimatedActivity;
  final String attachedSources;
  final String calculatedDoseRate;
  final String doseRateDifference;
  final String nuclides;
  final String instrumentCalibration;
  final String valueError;
  final String averaging;
  final String Function(CalibrationKind) calibrationKindLabel;
  final String validUntilLabel;
  final String certificateLabel;
  final String expiredNote;
  final String Function(NuclideIdStatus) nuclideStatusLabel;
  final String Function(ShieldingMaterial) shieldingMaterialLabel;
  final String unshieldedNote;
  final String shieldedSourceNote;
  final String yes;
  final String no;

  const CsvHeaders({
    this.radiation = '',
    this.quantity = '',
    this.basis = '',
    this.spectrum = '',
    required this.serialNumber,
    required this.location,
    required this.type,
    required this.value,
    required this.unit,
    required this.distanceFromSource,
    required this.instrument,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAccuracy,
    required this.timestamp,
    required this.sample,
    required this.notes,
    required this.estimatedActivity,
    required this.attachedSources,
    required this.calculatedDoseRate,
    required this.doseRateDifference,
    required this.nuclides,
    required this.instrumentCalibration,
    required this.valueError,
    required this.averaging,
    required this.calibrationKindLabel,
    required this.validUntilLabel,
    required this.certificateLabel,
    required this.expiredNote,
    required this.nuclideStatusLabel,
    required this.shieldingMaterialLabel,
    required this.unshieldedNote,
    required this.shieldedSourceNote,
    required this.yes,
    required this.no,
  });
}

/// Egy JSON-importálás eredménye.
class ImportResult {
  final int pointsImported;
  final int instrumentsCreated;
  final int sourcesCreated;
  final List<String> warnings;

  const ImportResult({
    required this.pointsImported,
    required this.instrumentsCreated,
    required this.sourcesCreated,
    required this.warnings,
  });
}

/// Mérési pontok exportálása/importálása — más RadRecon-felhasználónak
/// való átadáshoz, vagy táblázatkezelőben (Excel) való megtekintéshez.
///
/// A pontcsere-export zip-csomag (`.zip`): a `points.json` írja le a pontokat
/// (típus, érték, egység, GPS-pontosság stb.), a `photos/` a fotókat, a
/// `spectra/` az N42 spektrumfájlokat tartalmazza. A JSON csak ezek nevére
/// hivatkozik, képet vagy fájlt nem tartalmaz. A régi, base64-es `.json`
/// export továbbra is importálható.
/// A CSV egyszerű táblázatos nézet Excelhez, azt az app nem tudja visszaolvasni.
class PointExchangeService {
  static const _formatId = ExchangeFormat.jsonCurrentId;
  static const _formatVersion = ExchangeFormat.jsonCurrentVersion;
  static const _zipDataEntryName = 'points.json';
  static const _zipPhotosDirName = 'photos';
  static const _zipPhotosPrefix = '$_zipPhotosDirName/';
  static const _zipImportDirName = 'pontcsere_import';
  static const _zipExportDirName = 'pontcsere_export';
  static const _zipSpectraDirName = 'spectra';
  static const _zipSpectraPrefix = '$_zipSpectraDirName/';

  /// Kicsomagolt fotó bemásolása az app-mappába, a visszaállításnál használt
  /// `rad_recon_photos` mappába.
  static Future<String> _importPhotoFile(File source) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'rad_recon_photos'));
    await dir.create(recursive: true);
    final target = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source.path)}',
    );
    await source.copy(target);
    return target;
  }

  Future<File> exportJson(int surveySessionId) async {
    final db = DatabaseHelper.instance;
    final session = await db.getSurveySession(surveySessionId);
    if (session == null) {
      throw StateError('Nem található felmérés: $surveySessionId');
    }
    final points = await db.getMeasurementPoints(surveySessionId);
    final instruments = await db.getInstruments();
    final instrumentById = {for (final i in instruments) i.id: i};

    final usedInstrumentIds =
        points.map((pt) => pt.instrumentId).whereType<int>().toSet();
    final usedInstruments =
        instruments.where((i) => usedInstrumentIds.contains(i.id)).toList();

    // A ponthoz rendelt sugárforrások — globális nyilvántartásból, a
    // műszerekhez hasonlóan csak az ebben a felmérésben tényleg használt
    // forrásokat exportáljuk, azonosító (identifier) alapján párosíthatóan.
    final attachedByPointId = <int, List<AttachedSource>>{};
    for (final pt in points) {
      if (pt.id == null) continue;
      attachedByPointId[pt.id!] = await db.getAttachedSources(pt.id!);
    }
    final usedSourcesById = <int, RadiationSource>{};
    for (final attached in attachedByPointId.values) {
      for (final a in attached) {
        if (a.source.id != null) usedSourcesById[a.source.id!] = a.source;
      }
    }

    // A felmérés elhelyezéseinél szereplő források is exportálandók, akkor is,
    // ha egyik ponthoz sincsenek kötve.
    final placements = await db.getSurveyPlacements(surveySessionId);
    final registry = {
      for (final s in await db.getRadiationSources())
        if (s.id != null) s.id!: s,
    };
    final exportSourceIds = <int>{
      ...usedSourcesById.keys,
      for (final pl in placements) pl.radiationSourceId,
    };
    final exportSources = exportSourceIds
        .map((id) => registry[id])
        .whereType<RadiationSource>()
        .toList()
      ..sort((a, b) => a.identifier.compareTo(b.identifier));

    final calibrationsByInstrumentId = <int, List<InstrumentCalibration>>{};
    for (final i in usedInstruments) {
      if (i.id != null) {
        calibrationsByInstrumentId[i.id!] = await db.getCalibrations(i.id!);
      }
    }

    // Fotók és N42 spektrumfájlok a zipbe kerülnek; a JSON csak a nevükre hivatkozik.
    final zipFiles = <String, File>{};
    final photoEntryById = <int?, String>{};
    final spectrumEntryById = <int?, String>{};
    for (final pt in points) {
      final photo = pt.photoPath;
      if (photo != null && await File(photo).exists()) {
        final name = '$_zipPhotosPrefix${pt.id}_${p.basename(photo)}';
        zipFiles[name] = File(photo);
        photoEntryById[pt.id] = name;
      }
      final spectrum = pt.spectrumPath;
      if (spectrum != null && await File(spectrum).exists()) {
        final name = '$_zipSpectraPrefix${pt.id}_${p.basename(spectrum)}';
        zipFiles[name] = File(spectrum);
        spectrumEntryById[pt.id] = name;
      }
    }

    final data = {
      'format': _formatId,
      'version': _formatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'survey': {
        'title': session.title,
        'location': session.location,
        'notes': session.notes,
        'started_at': session.startedAt.toIso8601String(),
        'closed_at': session.closedAt?.toIso8601String(),
      },
      'instruments': usedInstruments
          .map((i) => {
                'name': i.name,
                'serial_number': i.serialNumber,
                'calibration_date': i.calibrationDate?.toIso8601String(),
                'calibration_factor': i.calibrationFactor,
                'is_modbus_connected': i.isModbusConnected,
                'modbus_host': i.modbusHost,
                'modbus_port': i.modbusPort,
                'modbus_unit_id': i.modbusUnitId,
                'modbus_register_address': i.modbusRegisterAddress,
                'is_modbus_gps_enabled': i.isModbusGpsEnabled,
                'modbus_gps_lat_address': i.modbusGpsLatAddress,
                'modbus_gps_lon_address': i.modbusGpsLonAddress,
                'modbus_measurement_type': i.modbusMeasurementType.dbValue,
                'modbus_unit': i.modbusUnit,
                'calibrations': [
                  for (final c in calibrationsByInstrumentId[i.id] ?? const [])
                    c.toJson()
                ],
              })
          .toList(),
      'sources': [
        for (final s in exportSources) await _sourceJsonV2(db, s),
      ],
      'placements': [
        for (final pl in placements)
          if (registry[pl.radiationSourceId] != null)
            {
              'source_identifier': registry[pl.radiationSourceId]!.identifier,
              'included': pl.included,
              'calc_date_override': pl.calcDateOverride?.toIso8601String(),
              'plan_x': pl.planX,
              'plan_y': pl.planY,
              'map_lat': pl.mapLat,
              'map_lon': pl.mapLon,
            },
      ],
      'points': points
          .map((pt) => {
                'location_label': pt.locationLabel,
                'group_key': pt.groupKey,
                'latitude': pt.latitude,
                'longitude': pt.longitude,
                'gps_accuracy_meters': pt.gpsAccuracyMeters,
                'measurement_type': pt.type.dbValue,
                'value': pt.value,
                'value_error': pt.valueError,
                'averaging_samples': pt.averagingSamples,
                'averaging_seconds': pt.averagingSeconds,
                'unit': pt.unit,
                'distance_from_source_meters': pt.distanceFromSourceMeters,
                'activity_calc_nuclide': pt.activityCalcNuclide,
                'instrument_name': instrumentById[pt.instrumentId]?.name,
                'nuclide_status': pt.nuclideStatus.dbValue,
                'nuclides': pt.nuclides,
                'shielding_layers': [
                  for (final l in pt.shieldingLayers) l.toJson()
                ],
                'attached_sources': (attachedByPointId[pt.id] ?? const [])
                    .map((a) => {
                          'source_identifier': a.source.identifier,
                          'distance_meters': a.link.distanceMeters,
                        })
                    .toList(),
                'is_source_position': pt.isSourcePosition,
                'is_sample': pt.isSample,
                'sample_container_id': pt.sampleContainerId,
                'sample_amount': pt.sampleAmount,
                'sample_method': pt.sampleMethod,
                'sample_unit': pt.sampleUnit,
                'meteo_json': pt.meteoJson,
                'gas_json': pt.gasJson,
                'bio_json': pt.bioJson,
                'notes': pt.notes,
                'basis_amount': pt.basisAmount,
                'basis_unit': pt.basisUnit,
                'spectrum_kind': pt.spectrumKind,
                'spectrum_file_name': pt.spectrumFileName,
                'spectrum_channels': pt.spectrumChannels,
                'spectrum_live_seconds': pt.spectrumLiveSeconds,
                'spectrum_total_counts': pt.spectrumTotalCounts,
                'spectrum_activity_json': pt.spectrumActivityJson,
                'radiation_kind': pt.radiationKind,
                'dose_quantity': pt.doseQuantity,
                'dose_depth_mm': pt.doseDepthMm,
                'spectrum_file': spectrumEntryById[pt.id],
                'photo_file': photoEntryById[pt.id],
                'timestamp': pt.timestamp.toIso8601String(),
              })
          .toList(),
    };

    // A pontadat (points.json) és a fotók egy zipbe kerülnek. A zip a
    // dokumentum-mappába készül, a megosztás ebből a fájlból történik.
    final docs = await getApplicationDocumentsDirectory();
    final tmp = await getTemporaryDirectory();
    final work = Directory(p.join(tmp.path, _zipExportDirName));
    if (await work.exists()) await work.delete(recursive: true);
    await work.create(recursive: true);
    try {
      final dataFile = File(p.join(work.path, _zipDataEntryName));
      await dataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
      final zipFile = File(
        p.join(docs.path, '${_safeFileName(session.title)}_pontok.zip'),
      );
      if (await zipFile.exists()) await zipFile.delete();
      final encoder = ZipFileEncoder()..create(zipFile.path);
      try {
        await encoder.addFile(dataFile, _zipDataEntryName);
        for (final e in zipFiles.entries) {
          await encoder.addFile(e.value, e.key);
        }
      } finally {
        await encoder.close();
      }
      return zipFile;
    } finally {
      await work.delete(recursive: true);
    }
  }

  /// `typeLabel`: a mérési típus nyelvfüggő megjelenítési neve — a
  /// szolgáltatás rétegnek nincs `BuildContext`-je, ezért ezt a hívó (egy
  /// widget) adja át, `(t) => t.label(context)` formában.
  Future<File> exportCsv(
    int surveySessionId, {
    required String Function(MeasurementType) typeLabel,
    required CsvHeaders csvHeaders,
  }) async {
    final db = DatabaseHelper.instance;
    final session = await db.getSurveySession(surveySessionId);
    if (session == null) {
      throw StateError('Nem található felmérés: $surveySessionId');
    }
    // A dózisteljesítmény-pontok az aktuális alapegységben kerülnek a CSV-be.
    final points = (await db.getMeasurementPoints(surveySessionId))
        .map(withCurrentDoseUnit)
        .toList();
    final instruments = await db.getInstruments();
    final instrumentById = {for (final i in instruments) i.id: i};
    final doseUnit = DoseUnitController.current;
    final distanceUnit = DistanceUnitController.current;

    const sep = ';'; // magyar Excel alapértelmezett listaelválasztója
    final buffer = StringBuffer();
    buffer.writeln([
      csvHeaders.serialNumber, csvHeaders.location, csvHeaders.type,
      csvHeaders.value, csvHeaders.unit,
      '${csvHeaders.distanceFromSource} (${distanceUnit.symbol})',
      csvHeaders.instrument, csvHeaders.gpsLatitude, csvHeaders.gpsLongitude,
      '${csvHeaders.gpsAccuracy} (${distanceUnit.symbol})', csvHeaders.timestamp, csvHeaders.sample,
      csvHeaders.notes, csvHeaders.estimatedActivity,
      csvHeaders.attachedSources,
      '${csvHeaders.calculatedDoseRate} (${doseUnit.symbol})',
      '${csvHeaders.doseRateDifference} (${doseUnit.symbol})',
      csvHeaders.nuclides,
      csvHeaders.instrumentCalibration,
      '${csvHeaders.valueError} (${csvHeaders.unit})',
      csvHeaders.averaging,
      csvHeaders.basis,
      csvHeaders.spectrum,
      csvHeaders.radiation,
      csvHeaders.quantity,
    ].join(sep));

    final calibrationsByInstrument = <int, List<InstrumentCalibration>>{};
    for (final i in instruments) {
      if (i.id != null) {
        calibrationsByInstrument[i.id!] = await db.getCalibrations(i.id!);
      }
    }

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final instrument = instrumentById[pt.instrumentId];
      final List<AttachedSource> attached =
          pt.id == null ? const [] : await db.getAttachedSources(pt.id!);
      final estimatedActivity = _estimatedActivityText(pt, csvHeaders);
      final measuredUSvH =
          pt.value == null ? null : toMicroSievertPerHour(pt.value!, pt.unit);
      final (calculatedTotalUSvH, _) =
          _totalCalculatedDoseRateUSvH(attached, pt.timestamp);
      final hasCalculatedTotal = attached.isNotEmpty;
      buffer.writeln([
        '${i + 1}',
        _csvField(pt.locationLabel ?? ''),
        typeLabel(pt.type),
        pt.value == null
            ? ''
            : double.parse(pt.value!.toStringAsPrecision(6)).toString(),
        pt.unit,
        pt.distanceFromSourceMeters == null
            ? ''
            : double.parse(
                distanceUnit
                    .fromMeters(pt.distanceFromSourceMeters!)
                    .toStringAsFixed(3),
              ).toString(),
        _csvField(instrument?.name ?? ''),
        pt.latitude.toStringAsFixed(6),
        pt.longitude.toStringAsFixed(6),
        pt.gpsAccuracyMeters == null
            ? ''
            : distanceUnit.fromMeters(pt.gpsAccuracyMeters!).toStringAsFixed(1),
        pt.timestamp.toIso8601String(),
        pt.isSample ? csvHeaders.yes : csvHeaders.no,
        _csvField(pt.notes ?? ''),
        _csvField(estimatedActivity ?? ''),
        _csvField(attached.isEmpty
            ? ''
            : attached
                .map((a) =>
                    '${a.source.identifier} (${a.source.nuclideName}, '
                    '${formatDistanceMeters(a.link.distanceMeters)})')
                .join('; ')),
        hasCalculatedTotal
            ? _formatValue(doseUnit.fromMicroSvPerHour(calculatedTotalUSvH))
            : '',
        (measuredUSvH != null && hasCalculatedTotal)
            ? _formatValue(
                doseUnit.fromMicroSvPerHour(measuredUSvH - calculatedTotalUSvH))
            : '',
        _csvField(nuclideSummaryText(
          status: pt.nuclideStatus,
          nuclides: pt.nuclides,
          statusLabel: csvHeaders.nuclideStatusLabel,
        )),
        _csvField(_calibrationText(
          instrument,
          instrument?.id == null
              ? const []
              : (calibrationsByInstrument[instrument!.id!] ?? const []),
          pt.timestamp,
          csvHeaders,
        )),
        pt.valueError == null
            ? ''
            : double.parse(pt.valueError!.toStringAsPrecision(3)).toString(),
        pt.averagingSamples == null
            ? ''
            : '${pt.averagingSamples}; ${pt.averagingSeconds ?? ''}',
        _csvField(_basisCsv(pt)),
        _csvField(_spectrumCsv(pt)),
        _csvField(_radiationCsv(pt)),
        _csvField(_quantityCsv(pt)),
      ].join(sep));
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dir.path, '${_safeFileName(session.title)}_pontok.csv'),
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// A műszer hitelesítése/kalibrálása a mérés időpontjában érvényes
  /// bejegyzések alapján; lejárt esetén jelölve.
  String _calibrationText(
    Instrument? instrument,
    List<InstrumentCalibration> records,
    DateTime at,
    CsvHeaders h,
  ) {
    if (instrument == null) return '';
    bool expiredAt(DateTime? until) =>
        until != null &&
        at.isAfter(DateTime(until.year, until.month, until.day, 23, 59, 59));

    final parts = <String>[];
    for (final kind in CalibrationKind.values) {
      final r = latestOfKind(records, kind, at: at);
      if (r == null) continue;
      final b = StringBuffer(
          '${h.calibrationKindLabel(kind)} ${calibrationDateText(r.performedOn)}');
      if (r.validUntil != null) {
        b.write(', ${h.validUntilLabel}: ${calibrationDateText(r.validUntil!)}');
      }
      if (r.certificateNumber != null) {
        b.write(', ${h.certificateLabel}: ${r.certificateNumber}');
      }
      if (r.performedBy != null) b.write(' (${r.performedBy})');
      if (expiredAt(r.validUntil)) b.write(' - ${h.expiredNote}');
      parts.add(b.toString());
    }
    if (parts.isEmpty && instrument.nextCalibrationDate != null) {
      final d = instrument.nextCalibrationDate!;
      parts.add('${h.validUntilLabel}: ${calibrationDateText(d)}'
          '${expiredAt(d) ? ' - ${h.expiredNote}' : ''}');
    }
    return parts.join('; ');
  }

  String _radiationCsv(MeasurementPoint pt) {
    if (pt.type != MeasurementType.doseRate && pt.type != MeasurementType.countRate) {
      return '';
    }
    return pt.radiationKind ?? RadiationKind.gamma.dbValue;
  }

  String _quantityCsv(MeasurementPoint pt) {
    if (pt.type != MeasurementType.doseRate) return '';
    final q = DoseQuantity.fromDbValue(pt.doseQuantity);
    final depth = pt.doseDepthMm == null ? '' : ' d=${pt.doseDepthMm} mm';
    return '${q.symbol}$depth';
  }

  String _basisCsv(MeasurementPoint pt) {
    if (pt.basisUnit == null) return '';
    final amount = pt.basisAmount == null ? '' : '${pt.basisAmount} ';
    return '$amount${pt.basisUnit}';
  }

  String _spectrumCsv(MeasurementPoint pt) {
    if (pt.spectrumChannels == null) return '';
    final live = pt.spectrumLiveSeconds == null ? '' : '; ${pt.spectrumLiveSeconds} s';
    final acts = NuclideActivity.listFromJson(pt.spectrumActivityJson);
    final actText = acts.isEmpty
        ? ''
        : '; ${acts.map((a) => '${a.nuclide} ${formatActivityNumberMBq(a.mbq)} ${ActivityUnitController.current.symbol}').join(', ')}';
    return '${pt.spectrumKind ?? ''}; ${pt.spectrumChannels} csatorna$live; ${pt.spectrumTotalCounts ?? ''}$actText';
  }

  String _csvField(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatValue(double v) {
    if (v.abs() >= 1000 || (v != 0 && v.abs() < 0.01)) {
      return v.toStringAsExponential(3);
    }
    return v.toStringAsFixed(3);
  }

  /// A "forrás távolság" mező melletti nuklidválasztóból és a mért
  /// értékből visszaszámolt aktivitás-becslés szöveges alakja.
  String? _estimatedActivityText(
    MeasurementPoint point, CsvHeaders headers) {
    final nuclideName = point.estimationNuclide;
    final distance = point.distanceFromSourceMeters;
    final measuredValue = point.value;
    if (nuclideName == null || distance == null || distance <= 0 ||
        measuredValue == null) {
      return null;
    }
    final measuredUSvH = toMicroSievertPerHour(measuredValue, point.unit);
    if (measuredUSvH == null) return null;
    final estimate = estimateActivity(
      nuclide: nuclideName,
      doseRateUSvH: measuredUSvH,
      distanceM: distance,
      layers: point.shieldingLayers,
    );
    if (estimate == null) return null;
    final text = '$nuclideName: ${formatActivityMBq(estimate.unshieldedMBq)} '
        '(${headers.unshieldedNote})';
    if (estimate.shieldedMBq == null) return text;
    final layers = point.shieldingLayers
        .map((l) => '${headers.shieldingMaterialLabel(l.material)} '
            '${formatDistanceMeters(l.thicknessCm / 100)}')
        .join(' + ');
    return '$text; ${headers.shieldedSourceNote} ($layers): '
        '${formatActivityMBq(estimate.shieldedMBq!)}';
  }

  /// A ponthoz rendelt források összesített, számított dózisteljesítménye
  /// (µSv/h) a mérés időpontjára visszaszámolva.
  (double, int) _totalCalculatedDoseRateUSvH(
    List<AttachedSource> attached,
    DateTime asOf,
  ) {
    double total = 0;
    int unknownCount = 0;
    for (final a in attached) {
      final isotope = a.source.knownIsotope;
      final decayed = a.source.decayedActivityMBqAt(asOf);
      if (isotope == null || decayed == null) {
        unknownCount++;
        continue;
      }
      total += isotope.doseRateAt(
        activityMBq: decayed,
        distanceM: a.link.distanceMeters,
      );
    }
    return (total, unknownCount);
  }

  String _safeFileName(String input) =>
      input.replaceAll(RegExp(r'[^\w\-]'), '_');

  /// Beolvassa a JSON exportot, és a benne lévő pontokat/műszereket
  /// hozzáadja a megadott felméréshez. A hiányzó nevű műszereket létrehozza,
  /// a meglévőket a nevük alapján párosítja.
  /// Egy forrás JSON-ja (v2): nyilvántartási adatok és a nuklid-sorok.
  Future<Map<String, Object?>> _sourceJsonV2(
    DatabaseHelper db,
    RadiationSource s,
  ) async {
    final nuclides = await db.getSourceNuclides(s.id!);
    return {
      'identifier': s.identifier,
      'activity_error_percent': s.activityErrorPercent,
      'manufacture_date': s.manufactureDate?.toIso8601String(),
      'origin': s.origin,
      'service_life_expiry_date': s.serviceLifeExpiryDate?.toIso8601String(),
      'next_inspection_date': s.nextInspectionDate?.toIso8601String(),
      'notes': s.notes,
      'nuclides': [
        for (final n in nuclides)
          {
            'nuclide': n.nuclide,
            'activity_mbq': n.activityMBq,
            'reference_date': n.referenceDate.toIso8601String(),
            'origin': n.origin.name,
          },
      ],
    };
  }

  /// Egy bejövő forrás-bejegyzés. v1: a bejegyzés egy nuklidot tartalmaz.
  /// v2: a `nuclides` lista. Gyártási dátum nélkül is importálható (talált forrás).
  ({RadiationSource? source, List<SourceNuclide> nuclides, String? warning})
      _parseIncomingSource(Map<String, dynamic> entry, int formatVersion) {
    final identifier = entry['identifier'] as String;
    final now = DateTime.now();
    final manufactureRaw = entry['manufacture_date'] as String?;
    final List<SourceNuclide> nuclides;
    if (formatVersion >= 2) {
      nuclides = [
        for (final raw
            in (entry['nuclides'] as List? ?? const []).cast<Map<String, dynamic>>())
          SourceNuclide(
            radiationSourceId: 0,
            nuclide: raw['nuclide'] as String,
            activityMBq: (raw['activity_mbq'] as num?)?.toDouble(),
            referenceDate: DateTime.parse(raw['reference_date'] as String),
            origin: ActivityOrigin.values.byName(raw['origin'] as String),
            createdAt: now,
          ),
      ];
    } else {
      final name = entry['nuclide_name'] as String?;
      nuclides = [
        if (name != null && manufactureRaw != null)
          SourceNuclide(
            radiationSourceId: 0,
            nuclide: name,
            activityMBq:
                (entry['activity_at_manufacture_mbq'] as num?)?.toDouble(),
            referenceDate: DateTime.parse(manufactureRaw),
            origin: ActivityOrigin.manual,
            createdAt: now,
          ),
      ];
    }
    final primary = nuclides.isEmpty ? null : nuclides.first;
    return (
      source: RadiationSource(
        identifier: identifier,
        nuclideName: primary?.nuclide ?? '',
        activityAtManufactureMBq: primary?.activityMBq,
        activityErrorPercent:
            (entry['activity_error_percent'] as num?)?.toDouble(),
        manufactureDate:
            manufactureRaw == null ? null : DateTime.parse(manufactureRaw),
        serviceLifeExpiryDate: entry['service_life_expiry_date'] == null
            ? null
            : DateTime.parse(entry['service_life_expiry_date'] as String),
        nextInspectionDate: entry['next_inspection_date'] == null
            ? null
            : DateTime.parse(entry['next_inspection_date'] as String),
        notes: entry['notes'] as String?,
        origin: (entry['origin'] as String?) ?? 'own',
        createdAt: now,
        updatedAt: now,
      ),
      nuclides: nuclides,
      warning: null,
    );
  }

  /// `.zip`: kicsomagolás ideiglenes mappába, a fotók onnan kerülnek át.
  /// `.json`: régi, fotó nélküli export.
  Future<ImportResult> importJson(
    String filePath,
    int targetSurveySessionId, {
    String unknownTypeWarning = 'Ismeretlen mérés-típus kihagyva egy ponton.',
    String missingGpsWarning =
        'Hiányzó GPS-koordináta miatt kihagyva egy pont.',
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw StateError('A fájl nem található: $filePath');
    }
    if (p.extension(filePath).toLowerCase() != '.zip') {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _importData(
        data,
        targetSurveySessionId,
        archiveDir: null,
        unknownTypeWarning: unknownTypeWarning,
        missingGpsWarning: missingGpsWarning,
      );
    }

    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, _zipImportDirName));
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    try {
      extractArchiveToDisk(
        ZipDecoder().decodeBuffer(InputFileStream(filePath)),
        dir.path,
      );
      final dataFile = File(p.join(dir.path, _zipDataEntryName));
      if (!await dataFile.exists()) {
        throw StateError('A zip nem tartalmaz pontadatot (points.json).');
      }
      final data =
          jsonDecode(await dataFile.readAsString()) as Map<String, dynamic>;
      return await _importData(
        data,
        targetSurveySessionId,
        archiveDir: dir.path,
        unknownTypeWarning: unknownTypeWarning,
        missingGpsWarning: missingGpsWarning,
      );
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }

  Future<ImportResult> _importData(
    Map<String, dynamic> data,
    int targetSurveySessionId, {
    required String? archiveDir,
    required String unknownTypeWarning,
    required String missingGpsWarning,
  }) async {

    final formatVersion = ExchangeFormat.jsonVersion(data['format'] as String?);
    if (formatVersion == null) {
      throw StateError('Ismeretlen fájlformátum — ez nem RadRecon export.');
    }
    if (formatVersion > ExchangeFormat.jsonCurrentVersion) {
      throw StateError(
        'Ez az export újabb RadRecon verzióval készült. Frissítsd az appot.',
      );
    }

    final db = DatabaseHelper.instance;
    final warnings = <String>[];

    final existingInstruments = await db.getInstruments();
    final instrumentIdByName = {
      for (final i in existingInstruments) i.name: i.id,
    };

    var instrumentsCreated = 0;
    final incomingInstruments =
        (data['instruments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final entry in incomingInstruments) {
      final name = entry['name'] as String?;
      if (name == null || instrumentIdByName.containsKey(name)) continue;
      final incomingCalibrations = (entry['calibrations'] as List? ?? const [])
          .map(InstrumentCalibration.fromJson)
          .whereType<InstrumentCalibration>()
          .toList();
      final instrument = Instrument(
        name: name,
        serialNumber: entry['serial_number'] as String?,
        calibrationDate: incomingCalibrations.isNotEmpty
            ? latestPerformedOn(incomingCalibrations)
            : (entry['calibration_date'] == null
                ? null
                : DateTime.parse(entry['calibration_date'] as String)),
        nextCalibrationDate: effectiveValidUntil(incomingCalibrations),
        calibrationFactor: (entry['calibration_factor'] as num?)?.toDouble(),
        isModbusConnected: entry['is_modbus_connected'] as bool? ?? false,
        modbusHost: entry['modbus_host'] as String?,
        modbusPort: entry['modbus_port'] as int?,
        modbusUnitId: entry['modbus_unit_id'] as int?,
        modbusRegisterAddress: entry['modbus_register_address'] as int?,
        isModbusGpsEnabled: entry['is_modbus_gps_enabled'] as bool? ?? false,
        modbusGpsLatAddress: entry['modbus_gps_lat_address'] as int? ?? 426,
        modbusGpsLonAddress: entry['modbus_gps_lon_address'] as int? ?? 428,
        modbusMeasurementType: Instrument.fromMap({
          'name': name,
          'modbus_measurement_type': entry['modbus_measurement_type'],
        }).modbusMeasurementType,
        modbusUnit: entry['modbus_unit'] as String? ?? 'nSv/h',
      );
      final newId = await db.insertInstrument(instrument);
      if (incomingCalibrations.isNotEmpty) {
        await db.replaceCalibrations(newId, incomingCalibrations);
      }
      instrumentIdByName[name] = newId;
      instrumentsCreated++;
    }

    // A ponthoz rendelt sugárforrások — a globális nyilvántartásba
    // azonosító (identifier) alapján párosítjuk, a hiányzókat létrehozzuk.
    final existingSources = await db.getRadiationSources();
    final sourceIdByIdentifier = {
      for (final s in existingSources) s.identifier: s.id,
    };

    var sourcesCreated = 0;
    final incomingSources =
        (data['sources'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final entry in incomingSources) {
      final identifier = entry['identifier'] as String?;
      if (identifier == null || sourceIdByIdentifier.containsKey(identifier)) {
        continue;
      }
      final parsed = _parseIncomingSource(entry, formatVersion);
      final source = parsed.source;
      if (source == null) {
        warnings.add(parsed.warning ?? 'Forrás kihagyva: $identifier');
        continue;
      }
      final newSourceId =
          await db.insertRadiationSourceWithNuclides(source, parsed.nuclides);
      sourceIdByIdentifier[identifier] = newSourceId;
      sourcesCreated++;
    }

    // Felmérés-elhelyezések (v2): bekerül-e a forrás az összegbe, és hol.
    final incomingPlacements =
        (data['placements'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (incomingPlacements.isNotEmpty) {
      final placedSourceIds = {
        for (final pl in await db.getSurveyPlacements(targetSurveySessionId))
          pl.radiationSourceId,
      };
      for (final entry in incomingPlacements) {
        final sourceId =
            sourceIdByIdentifier[entry['source_identifier'] as String?];
        if (sourceId == null || placedSourceIds.contains(sourceId)) continue;
        await db.insertSurveyPlacement(SurveySourcePlacement(
          surveySessionId: targetSurveySessionId,
          radiationSourceId: sourceId,
          included: entry['included'] as bool? ?? true,
          calcDateOverride: entry['calc_date_override'] == null
              ? null
              : DateTime.parse(entry['calc_date_override'] as String),
          planX: (entry['plan_x'] as num?)?.toDouble(),
          planY: (entry['plan_y'] as num?)?.toDouble(),
          mapLat: (entry['map_lat'] as num?)?.toDouble(),
          mapLon: (entry['map_lon'] as num?)?.toDouble(),
          createdAt: DateTime.now(),
        ));
        placedSourceIds.add(sourceId);
      }
    }

    final incomingPoints =
        (data['points'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    var pointsImported = 0;
    for (final entry in incomingPoints) {
      MeasurementType type;
      try {
        type =
            MeasurementTypeX.fromDbValue(entry['measurement_type'] as String);
      } catch (_) {
        warnings.add(unknownTypeWarning);
        continue;
      }

      if (entry['latitude'] == null || entry['longitude'] == null) {
        warnings.add(missingGpsWarning);
        continue;
      }

      final instrumentName = entry['instrument_name'] as String?;
      final instrumentId =
          instrumentName == null ? null : instrumentIdByName[instrumentName];

      // Spektrumfájl: a zip "spectra/" mappájából, régi JSON-nál base64-ben.
      String? spectrumPath;
      final spectrumRel = entry['spectrum_file'] as String?;
      final spectrumB64 = entry['spectrum_file_base64'] as String?;
      final spectrumName = p.basename(
        entry['spectrum_file_name'] as String? ?? 'spectrum.n42',
      );
      if (spectrumRel != null && archiveDir != null) {
        final src = File(
          p.join(archiveDir, _zipSpectraDirName, p.basename(spectrumRel)),
        );
        if (await src.exists()) {
          spectrumPath = await SpectrumService.importFile(
            bytes: await src.readAsBytes(),
            fileName: spectrumName,
          );
        }
      } else if (spectrumB64 != null && spectrumB64.isNotEmpty) {
        spectrumPath = await SpectrumService.importFile(
          bytes: base64Decode(spectrumB64),
          fileName: spectrumName,
        );
      }

      // Fotó: a zip "photos/" mappájából. JSON-importnál nincs archiveDir, így nincs fotó.
      String? photoPath;
      final photoRel = entry['photo_file'] as String?;
      if (photoRel != null && archiveDir != null) {
        final src = File(
          p.join(archiveDir, _zipPhotosDirName, p.basename(photoRel)),
        );
        if (await src.exists()) photoPath = await _importPhotoFile(src);
      }

      final now = DateTime.now();
      final point = MeasurementPoint(
        surveySessionId: targetSurveySessionId,
        locationLabel: entry['location_label'] as String?,
        groupKey: entry['group_key'] as String?,
        latitude: (entry['latitude'] as num).toDouble(),
        longitude: (entry['longitude'] as num).toDouble(),
        gpsAccuracyMeters: (entry['gps_accuracy_meters'] as num?)?.toDouble(),
        type: type,
        value: (entry['value'] as num?)?.toDouble(),
        valueError: (entry['value_error'] as num?)?.toDouble(),
        averagingSamples: (entry['averaging_samples'] as num?)?.toInt(),
        averagingSeconds: (entry['averaging_seconds'] as num?)?.toInt(),
        unit: entry['unit'] as String? ?? type.defaultUnit,
        distanceFromSourceMeters:
            (entry['distance_from_source_meters'] as num?)?.toDouble(),
        activityCalcNuclide: entry['activity_calc_nuclide'] as String?,
        instrumentId: instrumentId,
        nuclideStatus: NuclideIdStatus.fromDb(entry['nuclide_status']),
        nuclides: (entry['nuclides'] as List?)?.whereType<String>().toList() ??
            const [],
        shieldingLayers: ShieldingLayer.listFromJson(entry['shielding_layers']),
        isSourcePosition: entry['is_source_position'] as bool? ?? false,
        isSample: entry['is_sample'] as bool? ?? false,
        sampleContainerId: entry['sample_container_id'] as String?,
        sampleAmount: (entry['sample_amount'] as num?)?.toDouble(),
        sampleMethod: entry['sample_method'] as String?,
        sampleUnit: entry['sample_unit'] as String?,
        meteorology: Meteorology.fromJsonString(entry['meteo_json'] as String?),
        gases: GasReading.listFromJsonString(entry['gas_json'] as String?),
        bioAgents: BioAgentReading.listFromJsonString(entry['bio_json'] as String?),
        basisAmount: (entry['basis_amount'] as num?)?.toDouble(),
        basisUnit: entry['basis_unit'] as String?,
        spectrumKind: entry['spectrum_kind'] as String?,
        spectrumFileName: entry['spectrum_file_name'] as String?,
        spectrumPath: spectrumPath,
        photoPath: photoPath,
        spectrumChannels: (entry['spectrum_channels'] as num?)?.toInt(),
        spectrumLiveSeconds: (entry['spectrum_live_seconds'] as num?)?.toDouble(),
        spectrumTotalCounts: (entry['spectrum_total_counts'] as num?)?.toInt(),
        spectrumActivityJson: entry['spectrum_activity_json'] as String?,
        radiationKind: entry['radiation_kind'] as String? ??
            MeasurementTypeX.legacyRadiationKind(entry['measurement_type'] as String)
                ?.dbValue,
        doseQuantity: entry['dose_quantity'] as String?,
        doseDepthMm: (entry['dose_depth_mm'] as num?)?.toDouble(),
        notes: entry['notes'] as String?,
        timestamp: entry['timestamp'] == null
            ? now
            : DateTime.parse(entry['timestamp'] as String),
        createdAt: now,
        updatedAt: now,
      );
      final newPointId = await db.insertMeasurementPoint(point);
      pointsImported++;

      final incomingAttached = (entry['attached_sources'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      for (final linkEntry in incomingAttached) {
        final sourceIdentifier = linkEntry['source_identifier'] as String?;
        final distance = (linkEntry['distance_meters'] as num?)?.toDouble();
        final sourceId = sourceIdentifier == null
            ? null
            : sourceIdByIdentifier[sourceIdentifier];
        if (sourceId == null || distance == null) continue;
        await db.insertPointSource(
          measurementPointId: newPointId,
          radiationSourceId: sourceId,
          distanceMeters: distance,
        );
      }
    }

    return ImportResult(
      pointsImported: pointsImported,
      instrumentsCreated: instrumentsCreated,
      sourcesCreated: sourcesCreated,
      warnings: warnings,
    );
  }
}