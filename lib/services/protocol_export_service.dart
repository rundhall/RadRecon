import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/measurement_type.dart';
import '../models/calibration_labels.dart';
import '../models/instrument.dart';
import '../models/instrument_calibration.dart';
import '../models/isotope.dart';
import '../models/person_dose.dart';
import '../models/person_condition.dart';
import '../models/session_dosimeter.dart';
import '../models/session_person_link.dart';
import '../models/map_area.dart';
import '../models/measurement_point.dart';
import '../models/nuclide_id.dart';
import '../models/point_source_link.dart';
import '../models/shielding.dart';
import 'value_averager.dart';
import '../models/survey_session.dart';
import 'activity_estimate.dart';
import 'dose_unit_controller.dart';
import 'dose_unit_converter.dart';
import 'unit_format.dart';
import 'display_units.dart';
import 'database_transfer_service.dart';
import 'screenshot_service.dart';
import 'protocol_pdf_builder.dart';

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
    final inputs = await _loadInputs(surveySessionId);
    final session = inputs.session;
    final points = inputs.points;
    final instrumentById = inputs.instrumentById;
    final calibrationsByInstrument = inputs.calibrationsByInstrument;
    final attachedByPointId = inputs.attachedByPointId;
    final personsText = inputs.personsText;
    final docxBytes = await _generateDocx(
      session,
      points,
      instrumentById,
      calibrationsByInstrument,
      attachedByPointId,
      personsText,
      inputs.dosimeters,
      _victimValueRows(inputs.victims, inputs.conditionsByLink),
      _areaRows(inputs.mapAreas),
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

  Future<_ProtocolInputs> _loadInputs(int surveySessionId) async {
    final db = DatabaseHelper.instance;
    final session = await db.getSurveySession(surveySessionId);
    if (session == null) {
      throw StateError('Nem található felmérés: $surveySessionId');
    }
    // A dózisteljesítmény-pontok az aktuális alapegységben kerülnek a jegyzőkönyvbe.
    final points = (await db.getMeasurementPoints(surveySessionId))
        .map(withCurrentDoseUnit)
        .toList();
    final instruments = await db.getInstruments();
    final instrumentById = {for (final i in instruments) i.id: i};
    final calibrationsByInstrument = <int, List<InstrumentCalibration>>{};
    for (final i in instruments) {
      if (i.id != null) {
        calibrationsByInstrument[i.id!] = await db.getCalibrations(i.id!);
      }
    }

    final attachedByPointId = <int, List<AttachedSource>>{};
    for (final point in points) {
      if (point.id == null) continue;
      attachedByPointId[point.id!] = await db.getAttachedSources(point.id!);
    }

    final attachedPersons = await db.getAttachedPersons(surveySessionId);
    // A felmérést végzők és az érintettek (áldozatok) külön kezelendők.
    final surveyors = attachedPersons
        .where((a) => a.link.role == SessionPersonRole.surveyor)
        .toList();
    final victims = attachedPersons
        .where((a) => a.link.role == SessionPersonRole.victim)
        .toList();
    final conditionsByLink = await db.getPersonConditions(surveySessionId);
    final mapAreas = await db.getMapAreas(surveySessionId);
    // Résztvevők a felmérésen kapott dózisukkal (csak a beszámítottak).
    final snapshot = await db.getSessionDoseSnapshot(surveySessionId);
    final personsText = surveyors.map((a) {
      final totals = snapshot.totalsFor(a.person.id!);
      if (totals.total <= 0) return a.person.name;
      final parts = [
        if (totals.session > 0) 'felmérési ${formatDoseText(totals.session)}',
        if (totals.dosimeter > 0)
          'doziméter ${formatDoseText(totals.dosimeter)}',
      ];
      return '${a.person.name} (dózis: ${formatDoseText(totals.total)}'
          '${parts.length > 1 ? ' – ${parts.join(', ')}' : ''})';
    }).join('; ');
    return _ProtocolInputs(
      session: session,
      points: points,
      instrumentById: instrumentById,
      calibrationsByInstrument: calibrationsByInstrument,
      attachedByPointId: attachedByPointId,
      personsText: personsText,
      dosimeters: snapshot.dosimeters,
      victims: victims,
      conditionsByLink: conditionsByLink,
      mapAreas: mapAreas,
    );
  }

  /// Az érintettek (áldozatok) táblázatának fejléce és kulcsai — a Word-
  /// sablonban és a PDF-ben ugyanez a sorrend.
  static const _victimHeaders = ['#', 'Név', 'Triázs', 'Sérülések', 'Betegségek'];
  static const _victimKeys = ['idx', 'name', 'triage', 'injuries', 'illnesses'];

  /// Meteorológia (pontonként) és gázmérés (vegyületenként) táblázatai.
  List<String> get _meteoHeaders => [
    '#',
    'Hőm. (${DisplayUnits.temperature.value})',
    'Pára (%)',
    'Nyomás (${DisplayUnits.pressure.value})',
    'Szél (${DisplayUnits.wind.value})',
    'Szélirány (°)',
    'Széllökés (${DisplayUnits.wind.value})',
    'Csapadék', 'Csapadék int. (mm/h)', 'Napsugárzás (W/m²)',
    'Felhőzet (okta)', 'Látástáv. (m)', 'Talajnedv. (%)', 'Aeroszol (µg/m³)',
    'Egyéb',
  ];
  static const _meteoColumnWidths = [
    400, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
    1000, 1000, 1998,
  ];
  static const _gasHeaders = ['#', 'Vegyület', 'Képlet', 'Koncentráció', 'Egység'];
  static const _gasColumnWidths = [500, 4500, 3000, 3000, 4398];
  static const _victimColumnWidths = [500, 3000, 2600, 4400, 4898];

  List<Map<String, String>> _victimValueRows(
    List<AttachedPerson> victims,
    Map<int, List<PersonCondition>> conditionsByLink,
  ) {
    return [
      for (var i = 0; i < victims.length; i++)
        _victimValues(
          i,
          victims[i],
          conditionsByLink[victims[i].link.id] ?? const [],
        ),
    ];
  }

  Map<String, String> _victimValues(
    int index,
    AttachedPerson victim,
    List<PersonCondition> conditions,
  ) {
    String listOf(ConditionKind kind) {
      final items = [
        for (final c in conditions)
          if (c.kind == kind) c.description,
      ];
      return items.isEmpty ? '—' : items.join('; ');
    }

    return {
      'idx': '${index + 1}',
      'name': victim.person.name,
      'triage': victim.link.triage?.label ?? 'nincs besorolva',
      'injuries': listOf(ConditionKind.injury),
      'illnesses': listOf(ConditionKind.illness),
    };
  }

  /// Szám a magyar jegyzőkönyvhöz (tizedesvessző, legfeljebb két tizedes).
  String _protoNum(double d) {
    final s = d == d.roundToDouble()
        ? d.toStringAsFixed(0)
        : double.parse(d.toStringAsFixed(2)).toString();
    return s.replaceAll('.', ',');
  }

  /// A meteorológiai megfigyeléssel rendelkező mérési pontok sorai.
  static const _areaHeaders = [
    '#', 'Terület megnevezése', 'Alakzat', 'Geometria', 'Felület (m²)',
  ];
  static const _areaColumnWidths = [500, 4000, 2400, 5498, 3000];

  /// A jelölt területek sorai: név, alakzat, geometria és felület (m²).
  List<List<String>> _areaRows(List<MapArea> areas) {
    final rows = <List<String>>[];
    for (var i = 0; i < areas.length; i++) {
      final a = areas[i];
      final String kind;
      final String geometry;
      final double area;
      if (a.shape == MapAreaShape.polygon) {
        kind = 'Poligon';
        geometry = '${a.polygon.length} sarokpont';
        area = _polygonAreaM2(a.polygon);
      } else {
        final c = a.center;
        final r = a.radiusMeters ?? 0;
        kind = 'Kör';
        geometry = c == null
            ? '—'
            : 'középpont: ${c[0].toStringAsFixed(5)}, ${c[1].toStringAsFixed(5)}; '
                'sugár: ${_protoNum(r)} m';
        area = math.pi * r * r;
      }
      rows.add(['${i + 1}', a.name, kind, geometry, _protoNum(area)]);
    }
    return rows;
  }

  /// Poligon felülete m²-ben: a csúcsokat helyi síkvetítésbe (equirectangular)
  /// visszük, majd a cipőfűző-képlettel számoljuk.
  static double _polygonAreaM2(List<List<double>> pts) {
    if (pts.length < 3) return 0;
    const earthR = 6371000.0;
    final lat0 = pts.map((v) => v[0]).reduce((a, b) => a + b) / pts.length;
    final cosLat0 = math.cos(lat0 * math.pi / 180);
    final xs = [for (final v in pts) earthR * v[1] * math.pi / 180 * cosLat0];
    final ys = [for (final v in pts) earthR * v[0] * math.pi / 180];
    var sum = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      sum += xs[i] * ys[j] - xs[j] * ys[i];
    }
    return sum.abs() / 2;
  }

  List<List<String>> _meteoRows(List<MeasurementPoint> points) {
    String v(double? d) => d == null ? '—' : _protoNum(d);
    final rows = <List<String>>[];
    for (var i = 0; i < points.length; i++) {
      final m = points[i].meteorology;
      if (m == null) continue;
      rows.add([
        '${i + 1}',
        v(DisplayUnits.tempFromC(m.airTemperatureC)),
        v(m.relativeHumidityPct),
        v(DisplayUnits.pressureFromHpa(m.pressureHpa)),
        v(DisplayUnits.windFromMs(m.windSpeedMs)),
        v(m.windDirectionDeg),
        v(DisplayUnits.windFromMs(m.gustMs)),
        m.precipitation?.label ?? '—',
        v(m.precipitationMmH),
        v(m.solarWm2),
        v(m.cloudOkta),
        v(m.visibilityM),
        v(m.soilMoisturePct),
        v(m.aerosolUgM3),
        m.other ?? '—',
      ]);
    }
    return rows;
  }

  /// A gázmérések sorai: pontonként, vegyületenként egy sor.
  List<List<String>> _gasRows(List<MeasurementPoint> points) {
    final rows = <List<String>>[];
    for (var i = 0; i < points.length; i++) {
      for (final g in points[i].gases) {
        rows.add([
          '${i + 1}',
          g.name,
          g.formula.isEmpty ? '—' : g.formula,
          _protoNum(g.concentration),
          g.unit.symbol,
        ]);
      }
    }
    return rows;
  }

  String _headingXmlFor(String text) =>
      '<w:p><w:pPr><w:pStyle w:val="Heading2"/>'
      '<w:spacing w:after="120" w:before="200"/></w:pPr>'
      '<w:r><w:t xml:space="preserve">${_xmlEscape(text)}</w:t></w:r></w:p>';

  String _victimHeadingXml() =>
      '<w:p><w:pPr><w:pStyle w:val="Heading2"/>'
      '<w:spacing w:after="120" w:before="200"/></w:pPr>'
      '<w:r><w:t xml:space="preserve">Érintettek (áldozatok)</w:t></w:r></w:p>';

  /// Word-táblázat a jegyzőkönyv stílusában (sötét fejléc, keretes cellák).
  String _tableXml(
    List<String> headers,
    List<List<String>> rows,
    List<int> widths, {
    int fontSize = 18,
  }) {
    final sz = '<w:sz w:val="$fontSize"/><w:szCs w:val="$fontSize"/>';
    final out = StringBuffer(
      '<w:tbl><w:tblPr><w:tblW w:type="dxa" w:w="15398"/><w:tblBorders>'
      '<w:top w:val="single" w:color="auto" w:sz="4"/>'
      '<w:left w:val="single" w:color="auto" w:sz="4"/>'
      '<w:bottom w:val="single" w:color="auto" w:sz="4"/>'
      '<w:right w:val="single" w:color="auto" w:sz="4"/>'
      '<w:insideH w:val="single" w:color="auto" w:sz="4"/>'
      '<w:insideV w:val="single" w:color="auto" w:sz="4"/>'
      '</w:tblBorders></w:tblPr><w:tblGrid>',
    );
    for (final w in widths) {
      out.write('<w:gridCol w:w="$w"/>');
    }
    out.write('</w:tblGrid><w:tr><w:trPr><w:tblHeader/></w:trPr>');
    for (var i = 0; i < headers.length; i++) {
      out.write(
        '<w:tc><w:tcPr><w:tcW w:type="dxa" w:w="${widths[i]}"/>'
        '<w:shd w:fill="2F2F2F" w:val="clear"/></w:tcPr>'
        '<w:p><w:r><w:rPr><w:b/><w:bCs/><w:color w:val="FFFFFF"/>$sz</w:rPr>'
        '<w:t xml:space="preserve">${_xmlEscape(headers[i])}</w:t>'
        '</w:r></w:p></w:tc>',
      );
    }
    out.write('</w:tr>');
    for (final row in rows) {
      out.write('<w:tr>');
      for (var i = 0; i < widths.length; i++) {
        final value = i < row.length ? row[i] : '—';
        out.write(
          '<w:tc><w:tcPr><w:tcW w:type="dxa" w:w="${widths[i]}"/></w:tcPr>'
          '<w:p><w:r><w:rPr>$sz</w:rPr>'
          '<w:t xml:space="preserve">${_xmlEscape(value)}</w:t>'
          '</w:r></w:p></w:tc>',
        );
      }
      out.write('</w:tr>');
    }
    out.write('</w:tbl>');
    return out.toString();
  }

  String _victimTableXml(List<Map<String, String>> rows) => _tableXml(
        _victimHeaders,
        [
          for (final r in rows) [for (final k in _victimKeys) r[k] ?? '—'],
        ],
        _victimColumnWidths,
      );

  /// A doziméter-táblázat oszlopainak kulcsai (a sablon `${dosimeters.*}` helyőrzői).
  static const _dosimeterKeys = [
    'idx', 'kind', 'identifier', 'person', 'reading', 'dose', 'counted',
  ];

  static const _dosimeterKindHu = {
    DosimeterKind.epdGamma: 'EPD gamma (elektronikus)',
    DosimeterKind.epdNeutron: 'EPD neutron (elektronikus)',
    DosimeterKind.tlOfficial: 'TL/OSL passzív (hivatalos)',
    DosimeterKind.tlWorkplace: 'TL/OSL passzív (munkahelyi)',
  };

  /// A doziméterek táblázatának sorai. Doziméter nélkül egyetlen, "nincs
  /// felvéve" jelzésű sor kerül a táblázatba.
  List<Map<String, String>> _dosimeterValueRows(
    List<SessionDosimeter> dosimeters,
  ) {
    if (dosimeters.isEmpty) {
      return [
        {
          'idx': '—',
          'kind': 'Nincs felvett doziméter',
          'identifier': '—',
          'person': '—',
          'reading': '—',
          'dose': '—',
          'counted': '—',
        },
      ];
    }
    return [
      for (var i = 0; i < dosimeters.length; i++)
        _dosimeterValues(i, dosimeters[i]),
    ];
  }

  Map<String, String> _dosimeterValues(int index, SessionDosimeter d) {
    String reading() {
      if (!d.kind.electronic) return '—';
      final start = d.startUsv == null ? '—' : formatDoseText(d.startUsv!);
      final end = d.endUsv == null ? '—' : formatDoseText(d.endUsv!);
      return '$start → $end';
    }

    final dose = d.resolvedDoseUsv;
    return {
      'idx': '${index + 1}',
      'kind': _dosimeterKindHu[d.kind] ?? d.kind.dbValue,
      'identifier': d.identifier,
      'person': d.personName ?? '—',
      'reading': reading(),
      'dose': dose == null ? '—' : formatDoseText(dose),
      'counted': d.includeAnnual ? 'igen' : 'nem',
    };
  }

  /// A mérési pont sorának cellaszövegei (kulcs = a sablon placeholder neve).
  /// A Word- és a PDF-jegyzőkönyv ugyanezt használja.
  Map<String, String> _pointRowValues(
    int index,
    MeasurementPoint point,
    Map<int?, Instrument> instrumentById,
    Map<int, List<InstrumentCalibration>> calibrationsByInstrument,
  ) {
    final instrument = instrumentById[point.instrumentId];
    return {
      'idx': '${index + 1}',
      'location': point.locationLabel ?? '—',
      'type': measurementTypeHu[point.type] ?? point.type.name,
      'value': displayValueOf(point).value == null
          ? '—'
          : formatValueWithError(displayValueOf(point).value!, displayValueOf(point).error) +
              (point.averagingSamples == null
                  ? ''
                  : ' (n=${point.averagingSamples}'
                      '${point.averagingSeconds == null ? '' : ', ${point.averagingSeconds} s'})'),
      'unit': displayValueOf(point).unit,
      'distance': point.distanceFromSourceMeters == null
          ? '—'
          : double.parse(DistanceUnitController.current
                  .fromMeters(point.distanceFromSourceMeters!)
                  .toStringAsFixed(2))
              .toString(),
      'instrument': _instrumentText(
        instrument,
        instrument?.id == null
            ? const []
            : (calibrationsByInstrument[instrument!.id!] ?? const []),
        point.timestamp,
      ),
      'gps':
          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
      'accuracy': point.gpsAccuracyMeters == null
          ? '—'
          : DistanceUnitController.current
              .fromMeters(point.gpsAccuracyMeters!)
              .toStringAsFixed(1),
      'timestamp': _dateFormat.format(point.timestamp),
      'photo': point.photoPath == null ? '—' : _photoFileName(point),
      'notes': _notesWithNuclides(point),
    };
  }

  /// A sugárforrás-elemzés egy sora, vagy null, ha a pontnak nincs hozzárendelt
  /// forrása és nincs aktivitás-becslése (ilyenkor a sor kimarad).
  Map<String, String>? _sourceRowValues(
    int index,
    MeasurementPoint point,
    List<AttachedSource> attached,
  ) {
    final estimatedActivity = _estimatedActivityText(point);
    if (attached.isEmpty && estimatedActivity == null) return null;

    final measuredUSvH = point.value == null
        ? null
        : toMicroSievertPerHour(point.value!, point.unit);
    final (calculatedTotalUSvH, _) =
        _totalCalculatedDoseRateUSvH(attached, point.timestamp);
    final hasCalculatedTotal = attached.isNotEmpty;

    return {
      'idx': '${index + 1}',
      'location': point.locationLabel ?? '—',
      'estimated_activity': estimatedActivity ?? '—',
      'attached': attached.isEmpty
          ? '—'
          : attached
              .map((a) =>
                  '${a.source.identifier} (${a.source.nuclideName}, '
                  '${formatDistanceMeters(a.link.distanceMeters)})')
              .join('; '),
      'calculated_total': hasCalculatedTotal
          ? formatDoseRateUSvH(calculatedTotalUSvH)
          : '—',
      'measured': measuredUSvH != null
          ? formatDoseRateUSvH(measuredUSvH)
          : (point.value == null
              ? '—'
              : '${point.value!.toStringAsFixed(2)} ${point.unit}'),
      'diff': (measuredUSvH != null && hasCalculatedTotal)
          ? formatDoseRateUSvH(measuredUSvH - calculatedTotalUSvH)
          : '—',
    };
  }

  /// A jegyzőkönyv PDF-változata: ugyanazok az adatok (fejléc, mérési pontok,
  /// sugárforrás-elemzés, aláírás-sor), a fényképek a mérési pontra utaló
  /// feliratokkal. Visszaadja a létrehozott .pdf fájlt.
  Future<File> exportSurveyPdf(int surveySessionId) async {
    final inputs = await _loadInputs(surveySessionId);
    final session = inputs.session;
    final points = inputs.points;
    final companyName =
        await DatabaseTransferService.instance.getActiveCompanyName();
    final company = companyName.trim().isEmpty ? '—' : companyName;
    final unitSymbol = DistanceUnitController.current.symbol;

    const pointKeys = [
      'idx', 'location', 'type', 'value', 'unit', 'distance', 'instrument',
      'gps', 'accuracy', 'timestamp', 'notes',
    ];
    const sourceKeys = [
      'idx', 'location', 'estimated_activity', 'attached',
      'calculated_total', 'measured', 'diff',
    ];

    final pointRows = <List<String>>[];
    final sourceRows = <List<String>>[];
    final photos = <ProtocolPhoto>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final values = _pointRowValues(
        i,
        point,
        inputs.instrumentById,
        inputs.calibrationsByInstrument,
      );
      pointRows.add([for (final k in pointKeys) values[k] ?? '—']);

      final attached =
          inputs.attachedByPointId[point.id] ?? const <AttachedSource>[];
      final sourceValues = _sourceRowValues(i, point, attached);
      if (sourceValues != null) {
        sourceRows.add([for (final k in sourceKeys) sourceValues[k] ?? '—']);
      }

      final photoPath = point.photoPath;
      if (photoPath != null) {
        final typeLabel = measurementTypeHu[point.type] ?? point.type.name;
        photos.add(ProtocolPhoto(
          caption: '${i + 1}. pont · $typeLabel · '
              '${point.locationLabel ?? '—'} · '
              '${_dateFormat.format(point.timestamp)}',
          path: photoPath,
        ));
      }
    }

    final data = ProtocolPdfData(
      headerFields: [
        ('Cég', company),
        ('Felmérés megnevezése', session.title),
        ('Helyszín', session.location ?? '—'),
        ('Felmérés kezdete', _dateFormat.format(session.startedAt)),
        (
          'Felmérés lezárása',
          session.closedAt == null
              ? 'folyamatban'
              : _dateFormat.format(session.closedAt!)
        ),
        ('Megjegyzés', session.notes ?? '—'),
      ],
      pointHeaders: [
        '#', 'Helyszín', 'Típus', 'Érték', 'Egység',
        'Táv. forrástól ($unitSymbol)', 'Műszer', 'GPS koordináta',
        'GPS pontosság ($unitSymbol)', 'Időpont', 'Megjegyzés',
      ],
      pointRows: pointRows,
      sourceHeaders: [
        '#', 'Helyszín', 'Becsült aktivitás (mérésből)',
        'Hozzárendelt forrás(ok)', 'Számított dózisteljesítmény',
        'Mért dózisteljesítmény', 'Eltérés',
      ],
      sourceRows: sourceRows,
      dosimeterHeaders: const [
        '#', 'Típus', 'Azonosító', 'Viselő', 'Állás (kezdő → záró)', 'Dózis',
        'Beszámít',
      ],
      dosimeterRows: [
        for (final v in _dosimeterValueRows(inputs.dosimeters))
          [for (final k in _dosimeterKeys) v[k] ?? '—'],
      ],
      meteoHeaders: _meteoHeaders,
      meteoRows: _meteoRows(points),
      gasHeaders: _gasHeaders,
      gasRows: _gasRows(points),
      areaHeaders: _areaHeaders,
      areaRows: _areaRows(inputs.mapAreas),
      victimHeaders: _victimHeaders,
      victimRows: [
        for (final v in _victimValueRows(inputs.victims, inputs.conditionsByLink))
          [for (final k in _victimKeys) v[k] ?? '—'],
      ],
      sourceNote: 'Csak a forrással vagy aktivitás-becsléssel rendelkező mérési '
          'pontok szerepelnek. A számított értékek tájékoztató jellegűek.',
      signatureFields: [
        (
          'Felmérést végezte',
          inputs.personsText.isEmpty ? '—' : inputs.personsText
        ),
        ('Cég', company),
        ('Dátum', _dateOnlyFormat.format(DateTime.now())),
        ('Aláírás', '_______________________'),
      ],
      photos: photos,
    );

    final bytes = await ProtocolPdfBuilder.build(data);
    final docsDir = await getApplicationDocumentsDirectory();
    final pdfFile = File(p.join(
      docsDir.path,
      '${_safeFileName(session.title)}_jegyzokonyv.pdf',
    ));
    await pdfFile.writeAsBytes(bytes);
    return pdfFile;
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

  /// A jegyzőkönyv (magyar sablon) mérés-típus címkéi. Az enum-név (pl. doseRate)
  /// nem kerülhet a dokumentumba.
  static const measurementTypeHu = {
    MeasurementType.doseRate: 'Dózisteljesítmény',
    MeasurementType.surfaceContamination: 'Felületi szennyezettség',
    MeasurementType.cps: 'Beütésszám (cps)',
    MeasurementType.neutronCps: 'Neutron beütésszám (cps)',
    MeasurementType.sample: 'Mintavétel',
    MeasurementType.meteorology: 'Meteorológia',
    MeasurementType.gasMeasurement: 'Gázmérés',
  };

  static const _nuclideStatusHu = {
    NuclideIdStatus.notSpecified: '',
    NuclideIdStatus.identified: 'Azonosított nuklid(ok)',
    NuclideIdStatus.unknown: 'Ismeretlen nuklid',
    NuclideIdStatus.other: 'Egyéb nuklid (nincs a listában)',
    NuclideIdStatus.mixture: 'Feltételezhetően több forrás (keverék)',
  };

  /// A jegyzőkönyv sablonja fix oszlopokat tartalmaz, ezért a nuklid-azonosítás
  /// a Megjegyzés oszlop elejére kerül ("Nuklid-azonosítás: ...").
  String _notesWithNuclides(MeasurementPoint point) {
    final nuclideText = nuclideSummaryText(
      status: point.nuclideStatus,
      nuclides: point.nuclides,
      statusLabel: (s) => _nuclideStatusHu[s] ?? '',
    );
    final notes = point.notes;
    if (nuclideText.isEmpty) return notes ?? '—';
    return notes == null
        ? 'Nuklid-azonosítás: $nuclideText'
        : 'Nuklid-azonosítás: $nuclideText. $notes';
  }

  String _safeFileName(String input) =>
      input.replaceAll(RegExp(r'[^\w\-]'), '_');

  String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// A "forrás távolság" mező melletti nuklidválasztóból és a mért
  /// értékből visszaszámolt aktivitás-becslés szöveges alakja — ugyanaz a
  /// számítás, mint az Edit point képernyő gyors kalkulátora. Null, ha
  /// nincs elég adat hozzá.
  String? _estimatedActivityText(MeasurementPoint point) {
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
    final isotope = Isotope.findByName(nuclideName);
    final buf = StringBuffer(
        '$nuclideName: ${formatActivityMBq(estimate.unshieldedMBq)} (árnyékolás nélkül)');
    if (estimate.shieldedMBq != null) {
      buf.write('; árnyékolt: ${formatActivityMBq(estimate.shieldedMBq!)}');
    }
    // Bemenő adatok, hogy a becslés ellenőrizhető legyen.
    buf.write('. Bemenő adatok: mért ${formatDoseRateUSvH(measuredUSvH)}, '
        'távolság ${formatDistanceMeters(distance)}');
    if (isotope != null) {
      buf.write(', Γ = ${_plainNumber(isotope.gammaConstant)} µSv·m²/(MBq·h)');
    }
    if (point.shieldingLayers.isNotEmpty) {
      final layers = point.shieldingLayers
          .map((l) => '${_shieldingMaterialHu(l.material)} '
              '${_plainNumber(l.thicknessCm)} cm')
          .join(' + ');
      buf.write(', árnyékolás: $layers');
      final t = layersTransmission(nuclideName, point.shieldingLayers);
      if (t != null) buf.write(' (áteresztés T = ${_plainNumber(t)})');
    }
    buf.write('.');
    return buf.toString();
  }

  static String _plainNumber(double v) =>
      double.parse(v.toStringAsPrecision(4)).toString();

  /// A műszer neve + a hitelesítés/kalibrálás adatai a mérés időpontjában
  /// érvényes bejegyzések alapján (lejárt esetén jelölve).
  String _instrumentText(
    Instrument? instrument,
    List<InstrumentCalibration> records,
    DateTime at,
  ) {
    if (instrument == null) return '—';
    final parts = <String>[
      instrument.serialNumber == null
          ? instrument.name
          : '${instrument.name} (s/n: ${instrument.serialNumber})',
    ];
    bool expiredAt(DateTime? until) =>
        until != null &&
        at.isAfter(DateTime(until.year, until.month, until.day, 23, 59, 59));

    var anyRecord = false;
    for (final kind in CalibrationKind.values) {
      final r = latestOfKind(records, kind, at: at);
      if (r == null) continue;
      anyRecord = true;
      final label =
          kind == CalibrationKind.verification ? 'Hitelesítés' : 'Kalibrálás';
      final b = StringBuffer(
          '$label: ${calibrationDateText(r.performedOn)}');
      if (r.validUntil != null) {
        b.write(', érvényes: ${calibrationDateText(r.validUntil!)}-ig');
      }
      if (r.certificateNumber != null) {
        b.write(', bizonylat: ${r.certificateNumber}');
      }
      if (r.performedBy != null) b.write(' (${r.performedBy})');
      if (expiredAt(r.validUntil)) b.write(' – LEJÁRT a mérés időpontjában');
      parts.add(b.toString());
    }
    if (!anyRecord && instrument.nextCalibrationDate != null) {
      final d = instrument.nextCalibrationDate!;
      parts.add('Kalibráció érvényes: ${calibrationDateText(d)}-ig'
          '${expiredAt(d) ? ' – LEJÁRT a mérés időpontjában' : ''}');
    }
    return parts.join('; ');
  }

  String _shieldingMaterialHu(ShieldingMaterial m) {
    switch (m) {
      case ShieldingMaterial.lead:
        return 'ólom';
      case ShieldingMaterial.steel:
        return 'acél';
      case ShieldingMaterial.concrete:
        return 'beton';
      case ShieldingMaterial.tungsten:
        return 'wolfram';
      case ShieldingMaterial.aluminium:
        return 'alumínium';
      case ShieldingMaterial.water:
        return 'víz';
    }
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
    Map<int, List<InstrumentCalibration>> calibrationsByInstrument,
    Map<int, List<AttachedSource>> attachedByPointId,
    String personsText,
    List<SessionDosimeter> dosimeters,
    List<Map<String, String>> victimRows,
    List<List<String>> areaRows,
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
      final values = _pointRowValues(i, point, instrumentById, calibrationsByInstrument);

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

    // A sablon fejléce fix "(m)"-et ír; a kiválasztott távolság-egységre cseréljük.
    xml = xml.replaceAll(
      'Táv. forrástól (m)',
      'Táv. forrástól (${DistanceUnitController.current.symbol})',
    );
    xml = xml.replaceAll(
      'GPS pontosság (m)',
      'GPS pontosság (${DistanceUnitController.current.symbol})',
    );

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
      final values = _sourceRowValues(i, point, attached);
      if (values == null) continue;

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

    // A ${dosimeters.*} placeholdereket tartalmazó <w:tr> a doziméter-táblázat sora.
    const dosimeterRowMarker = r'${dosimeters.';
    final dosimeterMarkerIndex = xml.indexOf(dosimeterRowMarker);
    if (dosimeterMarkerIndex == -1) {
      throw StateError('A sablonban nem található a doziméter-táblázat sora.');
    }
    final dosimeterRowStart = xml.lastIndexOf('<w:tr>', dosimeterMarkerIndex);
    final dosimeterRowEndTagIndex = xml.indexOf('</w:tr>', dosimeterMarkerIndex);
    if (dosimeterRowStart == -1 || dosimeterRowEndTagIndex == -1) {
      throw StateError(
        'A doziméter-táblázat sablonsorának határai nem azonosíthatók.',
      );
    }
    final dosimeterRowEnd = dosimeterRowEndTagIndex + '</w:tr>'.length;
    final dosimeterRowTemplate =
        xml.substring(dosimeterRowStart, dosimeterRowEnd);

    final generatedDosimeterRows = StringBuffer();
    for (final values in _dosimeterValueRows(dosimeters)) {
      var row = dosimeterRowTemplate;
      for (final entry in values.entries) {
        row = row.replaceAll(
          '\${dosimeters.${entry.key}}',
          _xmlEscape(entry.value),
        );
      }
      generatedDosimeterRows.write(row);
    }
    xml = xml.replaceRange(
      dosimeterRowStart,
      dosimeterRowEnd,
      generatedDosimeterRows.toString(),
    );

    // Érintettek (áldozatok) táblázata a doziméterek után — csak ha van érintett.
    if (victimRows.isNotEmpty) {
      final dosimeterTableEnd = xml.indexOf('</w:tbl>', dosimeterRowStart);
      if (dosimeterTableEnd == -1) {
        throw StateError('A doziméter-táblázat vége nem azonosítható.');
      }
      final insertAt = dosimeterTableEnd + '</w:tbl>'.length;
      xml = xml.replaceRange(
        insertAt,
        insertAt,
        _victimHeadingXml() + _victimTableXml(victimRows),
      );
    }

    // Területek, meteorológia és gázmérés az aláírás-sor elé, az érintettek után.
    final meteo = _meteoRows(points);
    final gas = _gasRows(points);
    final signIdx = xml.indexOf('Felmérést végezte: ');
    if (signIdx == -1) {
      throw StateError('A sablonban nem található az aláírás-sor.');
    }
    final signStart = xml.lastIndexOf('<w:p>', signIdx);
    final extraBlock = StringBuffer();
    if (areaRows.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor('Jelölt területek'))
        ..write(_tableXml(_areaHeaders, areaRows, _areaColumnWidths));
    }
    if (meteo.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor('Meteorológia'))
        ..write(_tableXml(_meteoHeaders, meteo, _meteoColumnWidths, fontSize: 14));
    }
    if (gas.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor('Gázmérés'))
        ..write(_tableXml(_gasHeaders, gas, _gasColumnWidths));
    }
    if (extraBlock.isNotEmpty) {
      xml = xml.replaceRange(signStart, signStart, extraBlock.toString());
    }

    final companyName =
        await DatabaseTransferService.instance.getActiveCompanyName();
    final scalars = <String, String>{
      'company_name': companyName.trim().isEmpty ? '—' : companyName,
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

/// A jegyzőkönyv exportálásának formátuma (a menüben választható).
enum ProtocolFormat { word, pdf }

/// Egy felmérés jegyzőkönyvi adatai (a Word- és a PDF-export közös bemenete).
class _ProtocolInputs {
  const _ProtocolInputs({
    required this.session,
    required this.points,
    required this.instrumentById,
    required this.calibrationsByInstrument,
    required this.attachedByPointId,
    required this.personsText,
    required this.dosimeters,
    required this.victims,
    required this.conditionsByLink,
    required this.mapAreas,
  });

  final SurveySession session;
  final List<MeasurementPoint> points;
  final Map<int?, Instrument> instrumentById;
  final Map<int, List<InstrumentCalibration>> calibrationsByInstrument;
  final Map<int, List<AttachedSource>> attachedByPointId;
  final String personsText;
  final List<SessionDosimeter> dosimeters;
  final List<AttachedPerson> victims;
  final Map<int, List<PersonCondition>> conditionsByLink;
  final List<MapArea> mapAreas;
}
