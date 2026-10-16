import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/instrument.dart';
import '../models/calibration_labels.dart';
import '../models/instrument_calibration.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/nuclide_id.dart';
import '../models/point_source_link.dart';
import '../models/shielding.dart';
import '../models/radiation_source.dart';
import 'activity_estimate.dart';
import 'dose_unit_controller.dart';
import 'dose_unit_converter.dart';
import 'unit_format.dart';

/// A CSV export nyelvfüggő fejlécei és a igen/nem szövegek — a szolgáltatás
/// rétegnek nincs `BuildContext`-je, ezért ezt a hívó (egy widget) állítja
/// össze az `AppLocalizations`-ból.
class CsvHeaders {
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
/// A JSON formátum a teljes nyers adatot megőrzi (típus, érték, egység,
/// GPS-pontosság stb.) és egy másik RadRecon-telepítésbe visszatölthető.
/// A fényképek NEM részei ennek az exportnak — azokat a jegyzőkönyv-export
/// (.zip, "fotok/" mappával) viszi át. A CSV egyszerű táblázatos nézet
/// Excelhez, azt az app nem tudja visszaolvasni.
class PointExchangeService {
  static const _formatId = 'rad_recon_export';
  static const _formatVersion = 1;

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

    final calibrationsByInstrumentId = <int, List<InstrumentCalibration>>{};
    for (final i in usedInstruments) {
      if (i.id != null) {
        calibrationsByInstrumentId[i.id!] = await db.getCalibrations(i.id!);
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
      'sources': usedSourcesById.values
          .map((s) => {
                'identifier': s.identifier,
                'nuclide_name': s.nuclideName,
                'activity_at_manufacture_mbq': s.activityAtManufactureMBq,
                'activity_error_percent': s.activityErrorPercent,
                'manufacture_date': s.manufactureDate.toIso8601String(),
                'service_life_expiry_date':
                    s.serviceLifeExpiryDate?.toIso8601String(),
                'notes': s.notes,
              })
          .toList(),
      'points': points
          .map((pt) => {
                'location_label': pt.locationLabel,
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
                'notes': pt.notes,
                'timestamp': pt.timestamp.toIso8601String(),
              })
          .toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dir.path, '${_safeFileName(session.title)}_pontok.json'),
    );
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
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
    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (data['format'] != _formatId) {
      throw StateError('Ismeretlen fájlformátum — ez nem RadRecon export.');
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
      final nuclideName = entry['nuclide_name'] as String?;
      final manufactureDateRaw = entry['manufacture_date'] as String?;
      if (identifier == null ||
          sourceIdByIdentifier.containsKey(identifier) ||
          nuclideName == null ||
          manufactureDateRaw == null) {
        continue;
      }
      final now = DateTime.now();
      final source = RadiationSource(
        identifier: identifier,
        nuclideName: nuclideName,
        activityAtManufactureMBq:
            (entry['activity_at_manufacture_mbq'] as num?)?.toDouble() ?? 0,
        activityErrorPercent:
            (entry['activity_error_percent'] as num?)?.toDouble(),
        manufactureDate: DateTime.parse(manufactureDateRaw),
        serviceLifeExpiryDate: entry['service_life_expiry_date'] == null
            ? null
            : DateTime.parse(entry['service_life_expiry_date'] as String),
        notes: entry['notes'] as String?,
        createdAt: now,
        updatedAt: now,
      );
      final newSourceId = await db.insertRadiationSource(source);
      sourceIdByIdentifier[identifier] = newSourceId;
      sourcesCreated++;
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

      final now = DateTime.now();
      final point = MeasurementPoint(
        surveySessionId: targetSurveySessionId,
        locationLabel: entry['location_label'] as String?,
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