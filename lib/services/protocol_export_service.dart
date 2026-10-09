import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/instrument.dart';
import '../models/person_dose.dart';
import '../models/isotope.dart';
import '../models/measurement_point.dart';
import '../models/point_source_link.dart';
import '../models/survey_session.dart';
import 'dose_unit_converter.dart';
import 'screenshot_service.dart';

/// A felmérés lezárásakor generálja a Word jegyzőkönyvet a
/// `assets/templates/jegyzokonyv_template.docx` sablon alapján.
///
/// A generálás NEM külső csomagra (pl. `docx_template`) épül, hanem
/// közvetlenül a .docx belső `word/document.xml`-jét szerkeszti: mivel a
/// sablont mi magunk generáltuk, pontosan tudjuk, hogy minden `${...}`
/// placeholder egyetlen, töretlen `<w:t>` elemben van (nem darabolta fel
/// utólagos Word-szerkesztés), ezért egyszerű szöveges csere is megbízható.
/// A táblázat adatsorát (a `${points.*}` placeholdereket tartalmazó
/// `<w:tr>`-t) pontonként megsokszorozzuk.
///
/// V1 döntés: a fényképek NEM ágyazódnak be közvetlenül a táblázat celláiba
/// (egyenlőtlen fotószámmal ez törékeny lenne). Helyette a táblázat a
/// fénykép fájlnevére hivatkozik, a végeredmény pedig egy .zip, ami a
/// jegyzőkönyv .docx mellett egy "fotok/" mappában tartalmazza az összes
/// ténylegesen csatolt képet.
class ProtocolExportService {
  static const _templateAssetPath = 'assets/templates/jegyzokonyv_template.docx';

  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');
  final _dateOnlyFormat = DateFormat('yyyy.MM.dd');

  /// Legenerálja a jegyzőkönyvet, és visszaadja a létrejött .zip fájl elérési
  /// útját (docx + a hozzá tartozó fotók).
  Future<File> exportSurvey(int surveySessionId) async {
    final db = DatabaseHelper.instance;
    final session = await db.getSurveySession(surveySessionId);
    if (session == null) {
      throw StateError('Nem található felmérés: $surveySessionId');
    }
    final points = await db.getMeasurementPoints(surveySessionId);
    final instruments = await db.getInstruments();
    final instrumentById = {for (final i in instruments) i.id: i};

    final attachedByPointId = <int, List<AttachedSource>>{};
    for (final point in points) {
      if (point.id == null) continue;
      attachedByPointId[point.id!] = await db.getAttachedSources(point.id!);
    }

    final attachedPersons = await db.getAttachedPersons(surveySessionId);
    // Résztvevők a felmérésen kapott dózisukkal (online + manuális).
    final sessionDoses = await db.getSessionDoses(surveySessionId);
    final personsText = attachedPersons.map((a) {
      final d = sessionDoses[a.person.id] ?? const <DoseSource, double>{};
      final online = d[DoseSource.online] ?? 0;
      final manual = d[DoseSource.manual] ?? 0;
      if (online + manual <= 0) return a.person.name;
      final parts = [
        if (online > 0) 'online ${formatDoseText(online)}',
        if (manual > 0) 'manuális ${formatDoseText(manual)}',
      ];
      return '${a.person.name} (dózis: ${formatDoseText(online + manual)}'
          '${parts.length > 1 ? ' – ${parts.join(', ')}' : ''})';
    }).join('; ');
    final docxBytes = await _generateDocx(
      session,
      points,
      instrumentById,
      attachedByPointId,
      personsText,
    );

    final outputDir = await _prepareOutputDir(session);
    final docxFile = File(p.join(outputDir.path, 'jegyzokonyv.docx'));
    await docxFile.writeAsBytes(docxBytes);

    final photosDir = Directory(p.join(outputDir.path, 'fotok'));
    await photosDir.create(recursive: true);
    for (final point in points) {
      final path = point.photoPath;
      if (path == null) continue;
      final source = File(path);
      if (!await source.exists()) continue;
      final destName = _photoFileName(point);
      await source.copy(p.join(photosDir.path, destName));
    }

    final screenshots = await ScreenshotService.listScreenshots(surveySessionId);
    if (screenshots.isNotEmpty) {
      final screenshotsDir = Directory(p.join(outputDir.path, 'kepernyokepek'));
      await screenshotsDir.create(recursive: true);
      for (final shot in screenshots) {
        await shot.copy(p.join(screenshotsDir.path, p.basename(shot.path)));
      }
    }

    final zipFile = File(p.join(
      (await getApplicationDocumentsDirectory()).path,
      '${_safeFileName(session.title)}_jegyzokonyv.zip',
    ));
    if (await zipFile.exists()) await zipFile.delete();
    await ZipFileEncoder().zipDirectoryAsync(outputDir, filename: zipFile.path);

    return zipFile;
  }

  Future<Directory> _prepareOutputDir(SurveySession session) async {
    final tempRoot = await getTemporaryDirectory();
    final dir = Directory(
      p.join(tempRoot.path, 'rad_recon_export_${session.id}'),
    );
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    return dir;
  }

  String _photoFileName(MeasurementPoint point) {
    final ext = p.extension(point.photoPath!);
    final label = (point.locationLabel ?? 'pont_${point.id}')
        .replaceAll(RegExp(r'[^\w\-]'), '_');
    return '${point.id}_$label$ext';
  }

  String _safeFileName(String input) =>
      input.replaceAll(RegExp(r'[^\w\-]'), '_');

  String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _formatValue(double v) {
    if (v.abs() >= 1000 || (v != 0 && v.abs() < 0.01)) {
      return v.toStringAsExponential(3);
    }
    return v.toStringAsFixed(3);
  }

  /// A "forrás távolság" mező melletti nuklidválasztóból és a mért
  /// értékből visszaszámolt aktivitás-becslés szöveges alakja — ugyanaz a
  /// számítás, mint az Edit point képernyő gyors kalkulátora. Null, ha
  /// nincs elég adat hozzá.
  String? _estimatedActivityText(MeasurementPoint point) {
    final nuclideName = point.activityCalcNuclide;
    final distance = point.distanceFromSourceMeters;
    final measuredValue = point.value;
    if (nuclideName == null || distance == null || distance <= 0 ||
        measuredValue == null) {
      return null;
    }
    final isotope = Isotope.findByName(nuclideName);
    if (isotope == null) return null;
    final measuredUSvH = toMicroSievertPerHour(measuredValue, point.unit);
    if (measuredUSvH == null) return null;
    final activityMBq = isotope.activityFrom(
      doseRateUSvH: measuredUSvH,
      distanceM: distance,
    );
    return '$nuclideName: ${_formatValue(activityMBq)} MBq';
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

  Future<List<int>> _generateDocx(
    SurveySession session,
    List<MeasurementPoint> points,
    Map<int?, Instrument> instrumentById,
    Map<int, List<AttachedSource>> attachedByPointId,
    String personsText,
  ) async {
    final templateData = await rootBundle.load(_templateAssetPath);
    final templateArchive =
        ZipDecoder().decodeBytes(templateData.buffer.asUint8List());

    final documentFile = templateArchive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw StateError(
        'A sablonban nem található word/document.xml — sérült sablonfájl.',
      ),
    );
    var xml = utf8.decode(documentFile.content as List<int>);

    // A ${points.*} placeholdereket tartalmazó <w:tr> a repeatelendő sablonsor.
    const rowMarker = r'${points.';
    final markerIndex = xml.indexOf(rowMarker);
    if (markerIndex == -1) {
      throw StateError('A sablonban nem található a mérési pontok táblázat-sora.');
    }
    final rowStart = xml.lastIndexOf('<w:tr>', markerIndex);
    final rowEndTagIndex = xml.indexOf('</w:tr>', markerIndex);
    if (rowStart == -1 || rowEndTagIndex == -1) {
      throw StateError('A táblázat sablonsorának határai nem azonosíthatók.');
    }
    final rowEnd = rowEndTagIndex + '</w:tr>'.length;
    final rowTemplate = xml.substring(rowStart, rowEnd);

    final generatedRows = StringBuffer();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final instrument = instrumentById[point.instrumentId];
      final values = <String, String>{
        'idx': '${i + 1}',
        'location': point.locationLabel ?? '—',
        'type': point.type.name,
        'value': point.value == null ? '—' : point.value!.toStringAsFixed(2),
        'unit': point.unit,
        'distance': point.distanceFromSourceMeters == null
            ? '—'
            : point.distanceFromSourceMeters!.toStringAsFixed(1),
        'instrument': instrument?.name ?? '—',
        'gps':
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
        'accuracy': point.gpsAccuracyMeters == null
            ? '—'
            : point.gpsAccuracyMeters!.toStringAsFixed(1),
        'timestamp': _dateFormat.format(point.timestamp),
        'photo': point.photoPath == null ? '—' : _photoFileName(point),
        'notes': point.notes ?? '—',
      };

      var row = rowTemplate;
      for (final entry in values.entries) {
        row = row.replaceAll(
          '\${points.${entry.key}}',
          _xmlEscape(entry.value),
        );
      }
      generatedRows.write(row);
    }

    xml = xml.replaceRange(rowStart, rowEnd, generatedRows.toString());

    // A ${sources.*} placeholdereket tartalmazó <w:tr> a "Sugárforrás-elemzés"
    // táblázat repeatelendő sablonsora — csak azok a pontok kerülnek bele,
    // amelyekhez van hozzárendelt forrás, vagy van aktivitás-becslés.
    const sourceRowMarker = r'${sources.';
    final sourceMarkerIndex = xml.indexOf(sourceRowMarker);
    if (sourceMarkerIndex == -1) {
      throw StateError(
        'A sablonban nem található a sugárforrás-elemzés táblázat-sora.',
      );
    }
    final sourceRowStart = xml.lastIndexOf('<w:tr>', sourceMarkerIndex);
    final sourceRowEndTagIndex = xml.indexOf('</w:tr>', sourceMarkerIndex);
    if (sourceRowStart == -1 || sourceRowEndTagIndex == -1) {
      throw StateError(
        'A sugárforrás-elemzés táblázat sablonsorának határai nem azonosíthatók.',
      );
    }
    final sourceRowEnd = sourceRowEndTagIndex + '</w:tr>'.length;
    final sourceRowTemplate = xml.substring(sourceRowStart, sourceRowEnd);

    final generatedSourceRows = StringBuffer();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final attached = attachedByPointId[point.id] ?? const [];
      final estimatedActivity = _estimatedActivityText(point);
      if (attached.isEmpty && estimatedActivity == null) continue;

      final measuredUSvH = point.value == null
          ? null
          : toMicroSievertPerHour(point.value!, point.unit);
      final (calculatedTotalUSvH, _) =
          _totalCalculatedDoseRateUSvH(attached, point.timestamp);
      final hasCalculatedTotal = attached.isNotEmpty;

      final values = <String, String>{
        'idx': '${i + 1}',
        'location': point.locationLabel ?? '—',
        'estimated_activity': estimatedActivity ?? '—',
        'attached': attached.isEmpty
            ? '—'
            : attached
                .map((a) =>
                    '${a.source.identifier} (${a.source.nuclideName}, '
                    '${double.parse(a.link.distanceMeters.toStringAsFixed(2))} m)')
                .join('; '),
        'calculated_total': hasCalculatedTotal
            ? '${_formatValue(calculatedTotalUSvH)} µSv/h'
            : '—',
        'measured': measuredUSvH != null
            ? '${_formatValue(measuredUSvH)} µSv/h'
            : (point.value == null
                ? '—'
                : '${point.value!.toStringAsFixed(2)} ${point.unit}'),
        'diff': (measuredUSvH != null && hasCalculatedTotal)
            ? '${_formatValue(measuredUSvH - calculatedTotalUSvH)} µSv/h'
            : '—',
      };

      var row = sourceRowTemplate;
      for (final entry in values.entries) {
        row = row.replaceAll(
          '\${sources.${entry.key}}',
          _xmlEscape(entry.value),
        );
      }
      generatedSourceRows.write(row);
    }

    xml = xml.replaceRange(
      sourceRowStart,
      sourceRowEnd,
      generatedSourceRows.toString(),
    );

    final scalars = <String, String>{
      'survey_title': session.title,
      'survey_location': session.location ?? '—',
      'survey_started': _dateFormat.format(session.startedAt),
      'survey_closed': session.closedAt == null
          ? 'folyamatban'
          : _dateFormat.format(session.closedAt!),
      'survey_notes': session.notes ?? '—',
      'surveyor_name': personsText.isEmpty ? '—' : personsText,
      'export_date': _dateOnlyFormat.format(DateTime.now()),
    };
    for (final entry in scalars.entries) {
      xml = xml.replaceAll('\${${entry.key}}', _xmlEscape(entry.value));
    }

    final newDocumentBytes = utf8.encode(xml);
    final outputArchive = Archive();
    for (final file in templateArchive.files) {
      if (!file.isFile) continue;
      if (file.name == 'word/document.xml') {
        outputArchive.addFile(ArchiveFile(
          'word/document.xml',
          newDocumentBytes.length,
          newDocumentBytes,
        ));
      } else {
        final content = file.content as List<int>;
        outputArchive.addFile(ArchiveFile(file.name, content.length, content));
      }
    }

    final encoded = ZipEncoder().encode(outputArchive);
   if (encoded == null) {
      throw StateError('A jegyzőkönyv ZIP-fájlja nem hozható létre.');
    }
    return encoded;
  }
}