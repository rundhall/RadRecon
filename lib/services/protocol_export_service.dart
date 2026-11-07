import 'phantom_figure_service.dart';
import '../models/decimal_separator.dart';
import '../models/victim_details.dart';
import '../models/sample_analysis.dart';
import '../models/dose_quantity.dart';
import '../models/radiation_kind.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import 'survey_source_total.dart';
import '../models/plan_calibration.dart';
import 'plan_georeference.dart';
import 'plan_figure_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
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
import '../models/measurement_type.dart';
import '../models/nuclide_id.dart';
import '../models/point_source_link.dart';
import '../models/shielding.dart';
import '../models/shielding_labels.dart';
import 'value_averager.dart';
import '../models/protocol_field.dart';
import '../models/survey_purpose.dart';
import '../models/survey_session.dart';
import 'activity_estimate.dart';
import 'dose_unit_controller.dart';
import 'dose_unit_converter.dart';
import 'unit_format.dart';
import 'display_units.dart';
import 'spectrum_service.dart';
import '../models/spectrum.dart';
import 'database_transfer_service.dart';
import 'screenshot_service.dart';
import 'protocol_pdf_builder.dart';
import 'waste_assessment.dart';
import 'source_classification.dart';
import 'decommissioning_assessment.dart';

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
/// A jegyzőkönyv képbeállításai (a formátum-választó ablakban állíthatók).
class ProtocolExportOptions {
  const ProtocolExportOptions({
    this.includeImages = true,
    this.shrinkImages = true,
    this.autoRotate = true,
  });

  /// Fotók és képernyőképek a jegyzőkönyvben. Spektrumábrák és tervrajz mindig benne vannak.
  final bool includeImages;

  /// Kicsinyítés legfeljebb [_docxImageMaxWidth] pixel szélességre.
  final bool shrinkImages;

  /// EXIF-alapú automatikus forgatás (a telefonfotók állása miatt).
  final bool autoRotate;
}

const _docxImageMaxWidth = 1600;

/// A kép előkészítése (háttér-izolátban fut, ezért top-level): EXIF-forgatás
/// rögzítése, ha kérik, és szélesség-korlátozás, ha van. Fotónál JPEG-et,
/// képernyőképnél PNG-t ad vissza.
Uint8List? _processImage((Uint8List, bool, bool, int?) args) {
  final (bytes, asJpeg, rotate, maxWidth) = args;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = rotate ? img.bakeOrientation(decoded) : decoded;
  if (maxWidth != null && image.width > maxWidth) {
    image = img.copyResize(image, width: maxWidth);
  }
  return asJpeg
      ? img.encodeJpg(image, quality: 85)
      : Uint8List.fromList(img.encodePng(image));
}

class ProtocolExportService {
  static const _templateAssetPath = 'assets/templates/jegyzokonyv_template.docx';

  /// Az aktuális nyelv szövegei és dátumformátumai; az exportok elején
  /// (`_begin`) állítjuk be.
  late AppLocalizations _l;
  late DateFormat _dateFormat;
  late DateFormat _dateOnlyFormat;

  ProtocolExportOptions _options = const ProtocolExportOptions();

  /// Csoportjelölés (ugyanazon hely több mérése): pont-id -> 1/2 mérés felirat.
  Map<int, String> _groupSuffixById = {};

  /// Csoportonként (azonos group_key, legalább 2 pont) sorszámozza a pontokat
  /// az időrend szerint.
  void _prepareGroupLabels(List<MeasurementPoint> points) {
    _groupSuffixById = {};
    final byKey = <String, List<MeasurementPoint>>{};
    for (final pt in points) {
      final key = pt.groupKey;
      if (key == null) continue;
      byKey.putIfAbsent(key, () => []).add(pt);
    }
    for (final members in byKey.values) {
      if (members.length < 2) continue;
      members.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (var i = 0; i < members.length; i++) {
        final id = members[i].id;
        if (id != null) {
          _groupSuffixById[id] =
              _l.pointGroupLabel('${i + 1}', '${members.length}');
        }
      }
    }
  }

  /// A pont helyének szövege; csoportnál a sorszámmal együtt.
  String _pointLocation(MeasurementPoint point) {
    final base = point.locationLabel ?? '—';
    final suffix = point.id == null ? null : _groupSuffixById[point.id];
    return suffix == null ? base : '$base · $suffix';
  }

  void _begin(AppLocalizations loc, ProtocolExportOptions options) {
    _options = options;
    _l = loc;
    _dateFormat = DateFormat(loc.protoDateTimeFormat);
    _dateOnlyFormat = DateFormat(loc.protoDateFormat);
  }

  /// A kép bájtjai a beállítások szerint: kicsinyítve és/vagy forgatva.
  /// Ha egyik sincs bekapcsolva, az eredeti bájtok maradnak. Hibánál null.
  Future<Uint8List?> _preparedImageBytes(File file, {required bool asJpeg}) async {
    try {
      final raw = await file.readAsBytes();
      if (!_options.shrinkImages && !_options.autoRotate) return raw;
      return await compute(_processImage, (
        raw,
        asJpeg,
        _options.autoRotate,
        _options.shrinkImages ? _docxImageMaxWidth : null,
      ));
    } catch (_) {
      return null;
    }
  }

  /// Legenerálja a Word-jegyzőkönyvet, és visszaadja a .docx fájl elérési útját.
  /// A fotók, a spektrumábrák és a képernyőképek a dokumentumba kerülnek,
  /// külön mappa vagy zip nem készül.
  Future<File> exportSurvey(
    int surveySessionId,
    AppLocalizations loc, {
    ProtocolExportOptions options = const ProtocolExportOptions(),
  }) async {
    _begin(loc, options);
    final inputs = await _loadInputs(surveySessionId);
    final session = inputs.session;
    final points = inputs.points;
    final instrumentById = inputs.instrumentById;
    final calibrationsByInstrument = inputs.calibrationsByInstrument;
    final attachedByPointId = inputs.attachedByPointId;
    final personsText = inputs.personsText;
    final phantomFigures = await _phantomFiguresFor(inputs.victims);
    final screenshots = await ScreenshotService.listScreenshots(surveySessionId);
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
      inputs.protocolFieldPairs,
      _bioRows(points),
      _sampleRows(points, inputs.sampleAnalysesByPointId),
      _handoverRows(inputs.victims),
      _identityRows(inputs.surveyors, inputs.victims),
      phantomFigures,
      screenshots,
    );

    final tmpDir = await getTemporaryDirectory();
    await _removeOldProtocolFiles(tmpDir.path, '.docx');
    final docxFile = File(p.join(
      tmpDir.path,
      '${_safeFileName(session.title)}.docx',
    ));
    await docxFile.writeAsBytes(docxBytes);
    return docxFile;
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
    _prepareGroupLabels(points);
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

    final sampleAnalysesByPointId = <int, List<SampleAnalysis>>{};
    for (final point in points) {
      if (point.id == null) continue;
      final analyses = await db.getSampleAnalyses(point.id!);
      if (analyses.isNotEmpty) sampleAnalysesByPointId[point.id!] = analyses;
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
    final protocolFields = await db.getProtocolFields(surveySessionId);
    // Résztvevők a felmérésen kapott dózisukkal (csak a beszámítottak).
    final snapshot = await db.getSessionDoseSnapshot(surveySessionId);
    final personsText = surveyors.map((a) {
      final totals = snapshot.totalsFor(a.person.id!);
      if (totals.total <= 0) return a.person.name;
      final total = _dec(formatDoseText(totals.total));
      final parts = [
        if (totals.session > 0)
          _l.protoDoseSession(_dec(formatDoseText(totals.session))),
        if (totals.dosimeter > 0)
          _l.protoDoseDosimeter(_dec(formatDoseText(totals.dosimeter))),
      ];
      if (parts.length < 2) return _l.protoPersonDose(a.person.name, total);
      return _l.protoPersonDoseBreakdown(
          a.person.name, total, parts.join(', '));
    }).join('; ');
    return _ProtocolInputs(
      session: session,
      points: points,
      instrumentById: instrumentById,
      calibrationsByInstrument: calibrationsByInstrument,
      attachedByPointId: attachedByPointId,
      sampleAnalysesByPointId: sampleAnalysesByPointId,
      surveyors: surveyors,
      personsText: personsText,
      dosimeters: snapshot.dosimeters,
      victims: victims,
      conditionsByLink: conditionsByLink,
      mapAreas: mapAreas,
      protocolFieldPairs:
          _protocolFieldPairs(session.purpose, protocolFields, points),
    );
  }

  /// A kiegészítő jegyzőkönyv-mezők (címke, érték) párjai. Hulladék-célnál a
  /// beépített mezők, a légkerma-határérték-ellenőrzés, a nuklidok és az
  /// S-érték tájékoztató besorolással; minden célnál az egyedi mezők.
  List<(String, String)> _protocolFieldPairs(
    SurveyPurpose? purpose,
    List<ProtocolField> fields,
    List<MeasurementPoint> points,
  ) {
    final builtinByKey = {
      for (final field in fields)
        if (!field.isCustom) field.key: field,
    };
    final pairs = <(String, String)>[];
    if (purpose == SurveyPurpose.decommissioning) {
      for (final key in decommissioningProtocolFieldKeys) {
        pairs.add((
          protocolBuiltinLabel(key, _l),
          _protocolFieldValue(key, builtinByKey[key]?.value),
        ));
      }
      pairs.add((_l.decomLimitLabel, _decomLimitText(checkH10Limit(points))));
      pairs.add((
        _l.decomSurfaceLabel,
        _surfaceText(summarizeSurfaceContamination(points)),
      ));
    }
    if (purpose == SurveyPurpose.waste) {
      for (final key in wasteProtocolFieldKeys) {
        pairs.add((
          protocolBuiltinLabel(key, _l),
          _protocolFieldValue(key, builtinByKey[key]?.value),
        ));
      }
      pairs.add((_l.wasteLimitLabel, _limitText(checkAirKermaLimit(points))));
      final isotopes = WasteIsotope.listFromJson(
        builtinByKey[ProtocolFieldKeys.isotopes]?.value,
      );
      if (isotopes.isEmpty) {
        pairs.add((_l.wasteIsotopesLabel, _l.wasteNoIsotopes));
      } else {
        final assessment = assessWasteS(
          massKg:
              parseDecimalInput(builtinByKey[ProtocolFieldKeys.massKg]?.value),
          isotopes: isotopes,
        );
        for (final result in assessment.results) {
          pairs.add((
            '${_l.wasteIsotopeRowLabel}: '
                '${normalizeNuclideName(result.isotope.nuclide)}',
            _isotopeText(result),
          ));
        }
        final total = assessment.total;
        pairs.add((
          _l.wasteSLabel,
          total == null ? _l.wasteSNotComputable : _sigNum(total),
        ));
        pairs.add((_l.wasteCategoryLabel, _categoryText(assessment)));
      }
    }
    for (final field in fields.where((f) => f.isCustom)) {
      final label = (field.customLabel ?? '').trim();
      final value = (field.value ?? '').trim();
      if (label.isNotEmpty && value.isNotEmpty) pairs.add((label, value));
    }
    return pairs;
  }

  String _protocolFieldValue(String key, String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? '—' : protocolFieldValueText(key, value, _l);
  }

  String _limitText(AirKermaLimitCheck check) {
    final max = check.maxMicroGyPerH;
    final verdict = switch (check.status) {
      KermaLimitStatus.noKermaMeasurement => _l.wasteLimitNoKerma,
      KermaLimitStatus.noValidPoint => _l.wasteLimitNoValidPoint,
      KermaLimitStatus.withinLimit =>
        '${_l.wasteLimitMaxPrefix} ${_sigNum(max! / 1000)} mGy/h — ${_l.wasteLimitOk}',
      KermaLimitStatus.exceeded =>
        '${_l.wasteLimitMaxPrefix} ${_sigNum(max! / 1000)} mGy/h — ${_l.wasteLimitExceeded}',
    };
    return check.otherDosePoints > 0
        ? '$verdict (${_l.wasteLimitOtherNote})'
        : verdict;
  }

  String _decomLimitText(H10LimitCheck check) {
    final max = check.maxMicroSvPerH;
    final verdict = switch (check.status) {
      DecomLimitStatus.noH10Measurement => _l.decomLimitNoH10,
      DecomLimitStatus.noValidPoint => _l.decomLimitNoValidPoint,
      DecomLimitStatus.withinLimit =>
        '${_l.wasteLimitMaxPrefix} ${_sigNum(max!)} µSv/h — ${_l.wasteLimitOk}',
      DecomLimitStatus.exceeded =>
        '${_l.wasteLimitMaxPrefix} ${_sigNum(max!)} µSv/h — ${_l.wasteLimitExceeded}',
    };
    return check.otherDosePoints > 0
        ? '$verdict (${_l.decomLimitOtherNote})'
        : verdict;
  }

  String _surfaceText(SurfaceSummary summary) {
    final max = summary.maxBqPerCm2;
    if (max == null) return _l.decomSurfaceNone;
    return '${_l.decomSurfaceMaxPrefix} ${_sigNum(max)} Bq/cm² — '
        '${_l.decomSurfaceReview}';
  }

  String _isotopeText(WasteIsotopeResult result) {
    final activity = result.isotope.activityBq;
    final ak = result.akBqPerKg;
    final smeak = result.smeakBqPerKg;
    final ameak = result.ameakBqPerKg;
    final si = result.si;
    String fmt(double? v) => v == null ? '—' : _sigNum(v);
    return [
      result.isotope.halfLifeOver30y
          ? _l.wasteHalfLifeGt30
          : _l.wasteHalfLifeLe30,
      'A = ${fmt(activity)} Bq',
      'AK = ${fmt(ak)} Bq/kg',
      'SMEAK = ${fmt(smeak)} Bq/kg',
      if (result.isotope.halfLifeOver30y) 'ÁMEAK = ${fmt(ameak)} Bq/kg',
      'S_i = ${fmt(si)}',
    ].join('; ');
  }

  String _categoryText(WasteSAssessment assessment) {
    final category = assessment.category;
    if (category == null) return _l.wasteSNotComputable;
    final code = switch (category) {
      WasteCategory.vllw => 'VLLW',
      WasteCategory.llw => 'LLW',
      WasteCategory.ilw => 'ILW',
    };
    final lifetime = assessment.isShortLived == true
        ? _l.wasteShortLived
        : _l.wasteLongLived;
    return '$code ($lifetime)';
  }

  /// A jegyzőkönyvben használt tizedesjel: a Beállítások szerinti választás,
  /// "auto" esetén az alkalmazás nyelve szerinti (magyar: vessző, angol: pont).
  String get _sep => switch (DecimalSeparatorController.current) {
        DecimalSeparatorMode.comma => ',',
        DecimalSeparatorMode.dot => '.',
        DecimalSeparatorMode.auto => _l.protoDecimalSep,
      };

  /// Numerikus szöveg tizedesjelének átírása a jegyzőkönyv tizedesjelére.
  /// Csak mért vagy számított értékekre hívható: dátumra, azonosítóra és
  /// a GPS-koordinátákra nem.
  String _dec(String text) => text.replaceAllMapped(
        RegExp(r'(\d)[.,](\d)'),
        (m) => '${m[1]}$_sep${m[2]}',
      );

  /// Három értékes jegyre kerekített szám (a kis S-értékek is látszanak).
  String _sigNum(double value) {
    final abs = value.abs();
    final String text;
    if (abs == 0) {
      text = '0';
    } else if (abs < 0.0001 || abs >= 1e6) {
      text = value.toStringAsExponential(2);
    } else {
      final exponent = int.parse(
        abs.toStringAsExponential().split('e').last.replaceFirst('+', ''),
      );
      text = value.toStringAsFixed(math.max(0, math.min(10, 2 - exponent)));
    }
    return _dec(text);
  }

  /// Az érintettek (áldozatok) táblázatának fejléce és kulcsai — a Word-
  /// sablonban és a PDF-ben ugyanez a sorrend.
  List<String> get _victimHeaders => [
        '#',
        _l.protoColName,
        _l.protoColTriage,
        _l.protoColInjuries,
        _l.protoColIllnesses,
      ];
  static const _victimKeys = ['idx', 'name', 'triage', 'injuries', 'illnesses'];

  /// Meteorológia (pontonként) és gázmérés (vegyületenként) táblázatai.
  List<String> get _meteoHeaders => [
    '#',
    _l.protoColTemp(DisplayUnits.temperature.value),
    _l.protoColHumidity,
    _l.protoColPressure(DisplayUnits.pressure.value),
    _l.protoColWind(DisplayUnits.wind.value),
    _l.protoColWindDir,
    _l.protoColGust(DisplayUnits.wind.value),
    _l.protoColPrecip, _l.protoColPrecipIntensity, _l.protoColSolar,
    _l.protoColCloud, _l.protoColVisibility, _l.protoColSoil, _l.protoColAerosol,
    _l.protoColOther,
  ];
  List<String> get _gasHeaders => [
        '#',
        _l.rrGasSpecies,
        _l.protoColFormula,
        _l.rrGasConcentration,
        _l.protoColUnit,
      ];
  static const _gasColumnWidths = [500, 4300, 2800, 3300, 3058];
  static const _victimColumnWidths = [500, 3300, 2000, 3900, 4258];
  static const _fieldColumnWidths = [4500, 9458];

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
      'triage': victim.link.triage?.localized(_l) ?? _l.rrTriageNone,
      'injuries': listOf(ConditionKind.injury),
      'illnesses': listOf(ConditionKind.illness),
    };
  }

  /// Szám a jegyzőkönyvhöz (a beállított tizedesjellel, legfeljebb két tizedes).
  String _protoNum(double d) {
    final s = d == d.roundToDouble()
        ? d.toStringAsFixed(0)
        : double.parse(d.toStringAsFixed(2)).toString();
    return _dec(s);
  }

  /// A meteorológiai megfigyeléssel rendelkező mérési pontok sorai.
  List<String> get _areaHeaders => [
    '#',
    _l.protoColAreaName,
    _l.protoColShape,
    _l.protoColGeometry,
    _l.protoColAreaSize,
  ];
  static const _areaColumnWidths = [500, 3700, 2300, 5158, 2300];

  /// A jelölt területek sorai: név, alakzat, geometria és felület (m²).
  List<List<String>> _areaRows(List<MapArea> areas) {
    final rows = <List<String>>[];
    for (var i = 0; i < areas.length; i++) {
      final a = areas[i];
      final String kind;
      final String geometry;
      final double area;
      if (a.shape == MapAreaShape.polygon) {
        kind = _l.protoShapePolygon;
        geometry = _l.protoCornerPoints('${a.polygon.length}');
        area = _polygonAreaM2(a.polygon);
      } else {
        final c = a.center;
        final r = a.radiusMeters ?? 0;
        kind = _l.protoShapeCircle;
        geometry = c == null
            ? '—'
            : _l.protoCenterRadius(
                c[0].toStringAsFixed(5),
                c[1].toStringAsFixed(5),
                _protoNum(r),
              );
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
        m.precipitation?.localized(_l) ?? '—',
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

  String _sexText(VictimSex? s) => switch (s) {
        VictimSex.female => _l.victimSexFemale,
        VictimSex.male => _l.victimSexMale,
        VictimSex.unknown => _l.victimSexUnknown,
        null => '—',
      };

  /// Kórházi átadó adatok: érintettenként egy sor (nem, kor, súly, szennyezés,
  /// sérülések helye).
  List<List<String>> _handoverRows(List<AttachedPerson> victims) {
    String sideText(BodyMarker m) =>
        m.side == BodySide.front ? _l.victimPhantomFront : _l.victimPhantomBack;
    final rows = <List<String>>[];
    for (var i = 0; i < victims.length; i++) {
      final link = victims[i].link;
      final contamination = [
        for (final m in link.bodyMarkers)
          if (m.hasContaminant) '${m.contaminantText} (${sideText(m)})',
      ];
      final injuries = [
        for (final m in link.bodyMarkers)
          if (m.kind == MarkerKind.injury)
            m.note.isEmpty ? sideText(m) : '${sideText(m)}: ${m.note}',
      ];
      rows.add([
        '${i + 1}',
        victims[i].person.name,
        _sexText(victims[i].person.sex),
        victims[i].person.ageYears?.toString() ?? '—',
        victims[i].person.weightKg == null ? '—' : _protoNum(victims[i].person.weightKg!),
        victims[i].person.heightCm == null ? '—' : _protoNum(victims[i].person.heightCm!),
        contamination.isEmpty ? '—' : contamination.join(', '),
        injuries.isEmpty ? '—' : injuries.join('; '),
      ]);
    }
    return rows;
  }

  List<String> get _handoverHeaders => [
        '#',
        _l.protoColName,
        _l.victimSexLabel,
        _l.victimAgeLabel,
        _l.victimWeightLabel,
        _l.victimHeightLabel,
        _l.protoColContamination,
        _l.protoColInjuryLocations,
      ];
  static const _handoverColumnWidths = [450, 2200, 900, 800, 1150, 1550, 3450, 3458];

  /// Fantomrajzok: érintettenként egy PNG (elöl és hátul), ha van jelölés.
  Future<List<ProtocolFigure>> _phantomFiguresFor(
      List<AttachedPerson> victims) async {
    final out = <ProtocolFigure>[];
    for (final v in victims) {
      if (v.link.bodyMarkers.isEmpty) continue;
      final png = await renderPhantomFigure(
        markers: v.link.bodyMarkers,
        frontLabel: _l.victimPhantomFront,
        backLabel: _l.victimPhantomBack,
      );
      if (png == null) continue;
      out.add(ProtocolFigure(
        caption: '${_l.protoPhantomHeading}: ${v.person.name}',
        bytes: png,
      ));
    }
    return out;
  }

  List<String> get _identityHeaders => [
        '#',
        _l.protoColName,
        _l.rrRoleLabel,
        _l.personIdentifierLabel,
      ];
  static const _identityColumnWidths = [500, 4000, 2800, 6658];

  /// A felmérők és az érintettek azonosítója (cím nélkül), személyenként egy sor.
  List<List<String>> _identityRows(
    List<AttachedPerson> surveyors,
    List<AttachedPerson> victims,
  ) {
    final all = [...surveyors, ...victims];
    return [
      for (var i = 0; i < all.length; i++)
        [
          '${i + 1}',
          all[i].person.name,
          all[i].link.role.localized(_l),
          all[i].person.identifier ?? '—',
        ],
    ];
  }

  /// A biológiai anyagok sorai: pontonként, anyagonként egy sor.
  List<List<String>> _bioRows(List<MeasurementPoint> points) {
    final rows = <List<String>>[];
    for (var i = 0; i < points.length; i++) {
      for (final b in points[i].bioAgents) {
        rows.add([
          '${i + 1}',
          b.name,
          b.kind.localized(_l),
          b.quantity.isEmpty ? '—' : b.quantity,
        ]);
      }
    }
    return rows;
  }

  /// A mintavizsgálatok sorai: pontonként, vizsgálatonként egy sor.
  List<List<String>> _sampleRows(
    List<MeasurementPoint> points,
    Map<int, List<SampleAnalysis>> byPointId,
  ) {
    final rows = <List<String>>[];
    for (var i = 0; i < points.length; i++) {
      final id = points[i].id;
      if (id == null) continue;
      for (final a in byPointId[id] ?? const <SampleAnalysis>[]) {
        final method = a.method == SampleAnalysisMethod.other
            ? _l.analysisMethodOther
            : a.method.fixedLabel;
        rows.add([
          '${i + 1}',
          method,
          a.instrumentName ?? '—',
          _dateFormat.format(a.performedAt),
          a.operatorName ?? '—',
          (a.result ?? '—').replaceAll('\n', ' · '),
          (a.notes ?? '—').replaceAll('\n', ' · '),
        ]);
      }
    }
    return rows;
  }

  List<String> get _bioHeaders => [
        '#',
        _l.rrBioAgentName,
        _l.rrBioKindLabel,
        _l.rrBioQuantityLabel,
      ];
  static const _bioColumnWidths = [500, 5000, 3300, 5158];

  List<String> get _sampleHeaders => [
        '#',
        _l.analysisMethodLabel,
        _l.analysisInstrumentLabel,
        _l.analysisPerformedAtLabel,
        _l.analysisOperatorLabel,
        _l.analysisResultLabel,
        _l.analysisNotesLabel,
      ];
  static const _sampleColumnWidths = [500, 1800, 2000, 2200, 2000, 3000, 2458];

  /// A gázmérések sorai: pontonként, vegyületenként egy sor.
  List<List<String>> _gasRows(List<MeasurementPoint> points) {
    final rows = <List<String>>[];
    for (var i = 0; i < points.length; i++) {
      for (final g in points[i].gases) {
        rows.add([
          '${i + 1}',
          '${localizedGasName(_l, g.name)} (${g.state.localized(_l)})',
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
      '<w:r><w:t xml:space="preserve">${_xmlEscape(_l.protoVictimsHeading)}</w:t></w:r></w:p>';

  /// Tábla-szöveg mérete (fél pontban): 10 pt, a nyomtatott olvashatóságért.
  static const _tableFontSize = 20;

  /// Oldalmargó (2,54 cm) minden oldalon.
  static const _protocolPageMarginXml =
      '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
      'w:header="708" w:footer="708" w:gutter="0"/>';

  static const _protocolTableBorders =
      '<w:tblBorders>'
      '<w:top w:val="single" w:color="auto" w:sz="4"/>'
      '<w:left w:val="single" w:color="auto" w:sz="4"/>'
      '<w:bottom w:val="single" w:color="auto" w:sz="4"/>'
      '<w:right w:val="single" w:color="auto" w:sz="4"/>'
      '<w:insideH w:val="single" w:color="auto" w:sz="4"/>'
      '<w:insideV w:val="single" w:color="auto" w:sz="4"/>'
      '</w:tblBorders>';

  static const _protocolTableLayout = '<w:tblLayout w:type="fixed"/>';

  static const _protocolCellMargins =
      '<w:tblCellMar><w:top w:w="40" w:type="dxa"/>'
      '<w:left w:w="100" w:type="dxa"/>'
      '<w:bottom w:w="40" w:type="dxa"/>'
      '<w:right w:w="100" w:type="dxa"/></w:tblCellMar>';

  /// Oszlopszélességek (twip). Mindegyik összesen 13958 (A4 fekvő, 2,54 cm margóval).
  static const _pointTableWidths = [450, 1600, 1850, 1150, 1250, 1550, 1750, 1800, 2558];
  static const _sourceTableWidths = [450, 1900, 2100, 2900, 2300, 2300, 2008];
  static const _dosimeterTableWidths = [450, 2000, 2400, 2400, 3200, 1900, 1608];

  /// A sablon pontos táblázatából ezek a cellák megszűnnek: az egység az érték,
  /// a GPS-pontosság a koordináta, a fénykép a megjegyzés mellé kerül.
  static const _pointRemovedMarkers = [
    r'${points.unit}',
    r'${points.accuracy}',
    r'${points.photo}',
    r'${lbl_col_unit}',
    r'${lbl_col_gps_accuracy}',
    r'${lbl_col_photo}',
  ];

  /// A meteorológiai táblázat két részének oszlopszélessége (8 oszlop).
  static const _meteoSplitWidths = [448, 1930, 1930, 1930, 1930, 1930, 1930, 1930];

  /// Word-táblázat a jegyzőkönyv stílusában: sötét fejléc, keretes cellák,
  /// rögzített oszlopszélesség. A szöveg középre igazodik, kivéve a [leftCols]
  /// oszlopait. A sorok nem törnek két oldal közé, a fejléc minden oldalon megismétlődik.
  String _tableXml(
    List<String> headers,
    List<List<String>> rows,
    List<int> widths, {
    Set<int> leftCols = const {},
  }) {
    final total = widths.fold<int>(0, (sum, w) => sum + w);
    final sz = '<w:sz w:val="$_tableFontSize"/><w:szCs w:val="$_tableFontSize"/>';
    final out = StringBuffer(
      '<w:tbl><w:tblPr><w:tblW w:type="dxa" w:w="$total"/>'
      '$_protocolTableBorders$_protocolTableLayout$_protocolCellMargins'
      '</w:tblPr><w:tblGrid>',
    );
    for (final w in widths) {
      out.write('<w:gridCol w:w="$w"/>');
    }
    out.write('</w:tblGrid>');
    out.write('<w:tr><w:trPr><w:cantSplit/><w:tblHeader/></w:trPr>');
    for (var i = 0; i < headers.length; i++) {
      out.write(
        '<w:tc><w:tcPr><w:tcW w:type="dxa" w:w="${widths[i]}"/>'
        '<w:shd w:fill="2F2F2F" w:val="clear"/><w:vAlign w:val="center"/></w:tcPr>'
        '${_cellParagraphOpen(left: leftCols.contains(i))}'
        '<w:r><w:rPr><w:b/><w:bCs/><w:color w:val="FFFFFF"/>$sz</w:rPr>'
        '<w:t xml:space="preserve">${_xmlEscape(headers[i])}</w:t>'
        '</w:r></w:p></w:tc>',
      );
    }
    out.write('</w:tr>');
    for (final row in rows) {
      out.write('<w:tr><w:trPr><w:cantSplit/></w:trPr>');
      for (var i = 0; i < widths.length; i++) {
        final value = i < row.length ? row[i] : '—';
        out.write(
          '<w:tc><w:tcPr><w:tcW w:type="dxa" w:w="${widths[i]}"/>'
          '<w:vAlign w:val="center"/></w:tcPr>'
          '${_cellParagraphOpen(left: leftCols.contains(i))}'
          '<w:r><w:rPr>$sz</w:rPr>'
          '<w:t xml:space="preserve">${_xmlEscape(value)}</w:t>'
          '</w:r></w:p></w:tc>',
        );
      }
      out.write('</w:tr>');
    }
    out.write('</w:tbl>');
    return out.toString();
  }

  /// A cella bekezdésének nyitó tagja: kis függőleges térköz; a [left] oszlopok
  /// szövege balra, a többi középre igazodik.
  String _cellParagraphOpen({required bool left}) =>
      '<w:p><w:pPr><w:spacing w:before="40" w:after="40" w:line="240" '
      'w:lineRule="auto"/>${left ? '' : '<w:jc w:val="center"/>'}</w:pPr>';

  /// A sor nem törhet két oldal közé.
  String _withCantSplit(String row) => row.contains('<w:trPr>')
      ? row.replaceFirst('<w:trPr>', '<w:trPr><w:cantSplit/>')
      : row.replaceFirst('<w:tr>', '<w:tr><w:trPr><w:cantSplit/></w:trPr>');

  /// A sablon táblázatait a jegyzőkönyv elrendezéséhez igazítja: oszlopszélesség,
  /// függőleges és vízszintes igazítás, sortörés-tiltás, egységes betűméret.
  /// A [removeMarkers]-t tartalmazó cellákat eltávolítja.
  String _styleTemplateTables(String xml) => xml.replaceAllMapped(
        RegExp(r'<w:tbl>.*?</w:tbl>', dotAll: true),
        (m) {
          final table = m.group(0)!;
          if (table.contains(r'${points.')) {
            return _restyleTemplateTable(
              table,
              _pointTableWidths,
              leftCols: const {1, 8},
              removeMarkers: _pointRemovedMarkers,
            );
          }
          if (table.contains(r'${sources.')) {
            return _restyleTemplateTable(
              table,
              _sourceTableWidths,
              leftCols: const {1, 3},
            );
          }
          if (table.contains(r'${dosimeters.')) {
            return _restyleTemplateTable(
              table,
              _dosimeterTableWidths,
              leftCols: const {3},
            );
          }
          return table;
        },
      );

  String _restyleTemplateTable(
    String table,
    List<int> widths, {
    required Set<int> leftCols,
    List<String> removeMarkers = const [],
  }) {
    var t = table;
    if (removeMarkers.isNotEmpty) {
      t = t.replaceAllMapped(RegExp(r'<w:tc>.*?</w:tc>', dotAll: true), (m) {
        final cell = m.group(0)!;
        return removeMarkers.any((mk) => cell.contains(mk)) ? '' : cell;
      });
    }
    t = t.replaceAllMapped(RegExp(r'<w:tr>.*?</w:tr>', dotAll: true), (m) {
      var col = 0;
      final row = m.group(0)!.replaceAllMapped(
        RegExp(r'<w:tc>.*?</w:tc>', dotAll: true),
        (c) {
          final i = col++;
          if (i >= widths.length) return c.group(0)!;
          return _restyleTemplateCell(
            c.group(0)!,
            widths[i],
            leftCols.contains(i),
          );
        },
      );
      return _withCantSplit(row);
    });
    final total = widths.fold<int>(0, (sum, w) => sum + w);
    final grid = [for (final w in widths) '<w:gridCol w:w="$w"/>'].join();
    return t
        .replaceFirst(
          RegExp(r'<w:tblW [^>]*/>'),
          '<w:tblW w:type="dxa" w:w="$total"/>',
        )
        .replaceFirst(
          RegExp(r'<w:tblGrid>.*?</w:tblGrid>', dotAll: true),
          '<w:tblGrid>$grid</w:tblGrid>',
        )
        .replaceFirst(
          '</w:tblPr>',
          '$_protocolTableLayout$_protocolCellMargins</w:tblPr>',
        )
        .replaceAll(
          RegExp(r'<w:sz w:val="\d+"/><w:szCs w:val="\d+"/>'),
          '<w:sz w:val="$_tableFontSize"/><w:szCs w:val="$_tableFontSize"/>',
        );
  }

  String _restyleTemplateCell(String cell, int width, bool left) => cell
      .replaceFirst(
        RegExp(r'<w:tcW [^>]*/>'),
        '<w:tcW w:type="dxa" w:w="$width"/>',
      )
      .replaceFirst('</w:tcPr>', '<w:vAlign w:val="center"/></w:tcPr>')
      .replaceFirst('<w:p><w:r>', '${_cellParagraphOpen(left: left)}<w:r>');

  /// A jegyzőkönyv stílusai: nagyobb alapbetű és címsorok a nyomtatáshoz.
  String _withProtocolStyles(String styles) => styles
      .replaceFirst(
        '<w:docDefaults><w:rPrDefault/><w:pPrDefault/></w:docDefaults>',
        '<w:docDefaults><w:rPrDefault><w:rPr><w:sz w:val="22"/>'
        '<w:szCs w:val="22"/></w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276" '
        'w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>',
      )
      .replaceFirst(
        '<w:color w:val="2E74B5"/><w:sz w:val="32"/><w:szCs w:val="32"/>',
        '<w:color w:val="2E74B5"/><w:sz w:val="36"/><w:szCs w:val="36"/>',
      )
      .replaceFirst(
        '<w:color w:val="2E74B5"/><w:sz w:val="26"/><w:szCs w:val="26"/>',
        '<w:color w:val="2E74B5"/><w:sz w:val="30"/><w:szCs w:val="30"/>',
      );

  /// A meteorológiai táblázat két, egymás alatti részre bontva: a 15 oszlop egy
  /// sorban olvashatatlanul szűk lenne. Mindkét részben a sorszám szerepel.
  String _meteoTablesXml(List<List<String>> rows) {
    final headers = _meteoHeaders;
    const split = 8;
    String at(List<String> row, int i) => i < row.length ? row[i] : '—';
    final rest = [for (var i = split; i < headers.length; i++) i];
    final first = _tableXml(
      [for (var i = 0; i < split; i++) headers[i]],
      [for (final r in rows) [for (var i = 0; i < split; i++) at(r, i)]],
      _meteoSplitWidths,
    );
    final second = _tableXml(
      [headers[0], for (final i in rest) headers[i]],
      [for (final r in rows) [at(r, 0), for (final i in rest) at(r, i)]],
      _meteoSplitWidths,
    );
    return '$first<w:p/>$second';
  }

  String _victimTableXml(List<Map<String, String>> rows) => _tableXml(
        _victimHeaders,
        [
          for (final r in rows) [for (final k in _victimKeys) r[k] ?? '—'],
        ],
        _victimColumnWidths,
        leftCols: const {1, 3, 4},
      );

  /// A doziméter-táblázat oszlopainak kulcsai (a sablon `${dosimeters.*}` helyőrzői).
  static const _dosimeterKeys = [
    'idx', 'kind', 'identifier', 'person', 'reading', 'dose', 'counted',
  ];

  /// A doziméterek táblázatának sorai. Doziméter nélkül egyetlen, "nincs
  /// felvéve" jelzésű sor kerül a táblázatba.
  List<Map<String, String>> _dosimeterValueRows(
    List<SessionDosimeter> dosimeters,
  ) {
    if (dosimeters.isEmpty) {
      return [
        {
          'idx': '—',
          'kind': _l.protoNoDosimeter,
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
      final start = d.startUsv == null ? '—' : _dec(formatDoseText(d.startUsv!));
      final end = d.endUsv == null ? '—' : _dec(formatDoseText(d.endUsv!));
      return '$start → $end';
    }

    final dose = d.resolvedDoseUsv;
    return {
      'idx': '${index + 1}',
      'kind': d.kind.localized(_l),
      'identifier': d.identifier,
      'person': d.personName ?? '—',
      'reading': reading(),
      'dose': dose == null ? '—' : _dec(formatDoseText(dose)),
      'counted': d.includeAnnual ? _l.protoYes : _l.protoNo,
    };
  }

  /// A típus-cella: dózisteljesítménynél a mennyiség és a sugárzás, beütésszámnál
  /// a sugárzás (pl. "Beütésszám (neutron)").
  String _typeCell(MeasurementPoint point) {
    final base = point.type.localized(_l);
    final radiation = RadiationKind.fromDbValue(point.radiationKind).localized(_l);
    if (point.type == MeasurementType.doseRate) {
      final q = DoseQuantity.fromDbValue(point.doseQuantity);
      final depth = point.doseDepthMm == null ? '' : ' d=${_dec('${point.doseDepthMm}')} mm';
      return '$base (${q.symbol}$depth; $radiation)';
    }
    if (point.type == MeasurementType.countRate) {
      return '$base ($radiation)';
    }
    return base;
  }

  /// A spektrum-fájl neve a megjegyzés végén (jegyzőkönyv).
  String _withSpectrumFileNote(String notes, MeasurementPoint point) {
    final name = point.spectrumFileName;
    if (point.type != MeasurementType.spectrum || name == null) return notes;
    final line = _l.protoSpectrumFile(name);
    return (notes.isEmpty || notes == '—') ? line : '$notes\n$line';
  }

  /// Spektrum-ábra PNG-ben a megadott mappába; null, ha a fájl nem olvasható.
  Future<String?> _renderSpectrumPng(MeasurementPoint point, String dir) async {
    final path = point.spectrumPath;
    if (path == null) return null;
    final spectrum = await SpectrumService.load(path);
    if (spectrum == null) return null;
    final target = p.join(dir, 'spektrum_${point.id ?? 0}.png');
    await SpectrumService.renderPng(
      spectrum: spectrum,
      targetPath: target,
      xLabel: spectrumAxisLabel(_l, spectrum),
    );
    return target;
  }

  /// A mérési pont sorának cellaszövegei (kulcs = a sablon placeholder neve).
  /// A Word- és a PDF-jegyzőkönyv ugyanezt használja.
  /// Pozíció szövege: alaprajz módban a helyi X/Y (méter), egyébként a GPS-koordináta.
  String _positionText(double lat, double lon, PlanCalibration? plan) {
    if (plan != null && plan.localCoordinates) {
      final m = planLocalMetres(plan, lat, lon);
      return '${_l.planLocalCoordLabel}: X ${_dec(m.x.toStringAsFixed(2))} m, '
          'Y ${_dec(m.y.toStringAsFixed(2))} m';
    }
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  /// A pont helye a jegyzőkönyvben (lásd [_positionText]).
  String _pointPositionText(MeasurementPoint point, PlanCalibration? plan) =>
      _positionText(point.latitude, point.longitude, plan);

  /// A térképi források sorai a jegyzőkönyvi táblázathoz.
  List<List<String>> _mapSourceRowValues(
    List<MapSourceEntry> sources,
    PlanCalibration? plan,
  ) =>
      [
        for (var i = 0; i < sources.length; i++)
          [
            '${i + 1}',
            sources[i].identifier,
            sources[i].nuclides.isEmpty ? '—' : sources[i].nuclides,
            _positionText(sources[i].lat, sources[i].lon, plan),
          ],
      ];

  /// A térképi források szakasza a Word-jegyzőkönyvbe.
  String _mapSourcesDocxXml(List<MapSourceEntry> sources, PlanCalibration? plan) {
    final heading = '<w:p><w:r><w:rPr><w:b/><w:sz w:val="30"/></w:rPr>'
        '<w:t xml:space="preserve">${_xmlEscape(_l.protoSourcesOnMapHeading)}</w:t></w:r></w:p>';
    return '$heading${_tableXml(
      ['#', _l.protoColIdentifier, _l.nuclideLabel, _l.protoColPosition],
      _mapSourceRowValues(sources, plan),
      const [600, 2900, 3600, 6858],
      leftCols: const {1, 3},
    )}<w:p/>';
  }

  /// A térképen elhelyezett források (csak a térképi pozícióval rendelkezők).
  Future<List<MapSourceEntry>> _loadMapSources(int surveySessionId) async {
    final db = DatabaseHelper.instance;
    final placements = await db.getSurveyPlacements(surveySessionId);
    final sources = await db.getRadiationSources();
    final nuclides = await db.getNuclideNamesBySource();
    final byId = {for (final src in sources) if (src.id != null) src.id!: src};
    final out = <MapSourceEntry>[];
    for (final pl in placements) {
      final lat = pl.mapLat;
      final lon = pl.mapLon;
      final src = byId[pl.radiationSourceId];
      if (lat == null || lon == null || src == null) continue;
      final names = (nuclides[src.id] ?? [src.nuclideName])
          .where((n) => n.isNotEmpty)
          .toSet()
          .join(', ');
      out.add(MapSourceEntry(
        identifier: src.identifier,
        nuclides: names,
        lat: lat,
        lon: lon,
      ));
    }
    return out;
  }

  /// Az alaprajz a jelölésekkel: csak alaprajz módú felmérésnél, különben null.
  Future<Uint8List?> _planFigureFor(
    SurveySession session,
    List<MeasurementPoint> points,
    List<MapSourceEntry> sources,
  ) async {
    final plan = session.planCalibration;
    if (session.mapMode != SurveyMapMode.plan || plan == null) return null;
    final marks = [
      for (var i = 0; i < points.length; i++)
        PlanMark(
          lat: points[i].latitude,
          lon: points[i].longitude,
          label: '${i + 1}',
          isSource: false,
        ),
      for (final src in sources)
        PlanMark(
          lat: src.lat,
          lon: src.lon,
          label: src.identifier,
          isSource: true,
        ),
    ];
    return renderPlanFigure(plan, marks);
  }

  Map<String, String> _pointRowValues(
    int index,
    MeasurementPoint point,
    Map<int?, Instrument> instrumentById,
    Map<int, List<InstrumentCalibration>> calibrationsByInstrument,
    PlanCalibration? plan,
  ) {
    final instrument = instrumentById[point.instrumentId];
    final shown = displayValueOf(point);
    // A mértékegység az érték mellé kerül, így nincs külön egység-oszlop.
    final unitSuffix = shown.unit.isEmpty ? '' : ' ${shown.unit}';
    return {
      'idx': '${index + 1}',
      'location': _pointLocation(point),
      'type': _typeCell(point),
      'value': point.type == MeasurementType.spectrum
          ? _dec(spectrumSummaryLine(_l, point))
          : shown.value == null
          ? '—'
          : _dec(formatValueWithError(shown.value!, shown.error)) +
              unitSuffix +
              (point.averagingSamples == null
                  ? ''
                  : ' (n=${point.averagingSamples}'
                      '${point.averagingSeconds == null ? '' : ', ${_dec('${point.averagingSeconds}')} s'})'),
      'distance': point.distanceFromSourceMeters == null
          ? '—'
          : _dec(double.parse(DistanceUnitController.current
                  .fromMeters(point.distanceFromSourceMeters!)
                  .toStringAsFixed(2))
              .toString()),
      'instrument': _instrumentText(
        instrument,
        instrument?.id == null
            ? const []
            : (calibrationsByInstrument[instrument!.id!] ?? const []),
        point.timestamp,
      ),
      'gps': _gpsWithAccuracy(_pointPositionText(point, plan), point),
      'timestamp': _dateFormat.format(point.timestamp),
      'notes': _withPhotoNote(
        _withSpectrumFileNote(_notesWithNuclides(point), point),
        point,
      ),
    };
  }

  /// A GPS-koordináta a pontossággal együtt, pl. "47.4979, 19.0402 (±3.2 m)".
  String _gpsWithAccuracy(String position, MeasurementPoint point) {
    final accuracy = point.gpsAccuracyMeters;
    if (accuracy == null || position == '—') return position;
    final unit = DistanceUnitController.current;
    final value = _dec(unit.fromMeters(accuracy).toStringAsFixed(1));
    return '$position (±$value ${unit.symbol})';
  }

  /// A fénykép fájlneve a megjegyzés végére kerül (külön oszlop helyett).
  String _withPhotoNote(String notes, MeasurementPoint point) {
    if (point.photoPath == null) return notes;
    final photo = '${_l.protoColPhoto}: ${_photoFileName(point)}';
    final base = notes.trim();
    return base.isEmpty || base == '—' ? photo : '$base · $photo';
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
      'location': _pointLocation(point),
      'estimated_activity': estimatedActivity ?? '—',
      'attached': attached.isEmpty
          ? '—'
          : attached
              .map((a) =>
                  '${a.source.identifier} (${a.source.nuclideName}, '
                  '${_dec(formatDistanceMeters(a.link.distanceMeters))})')
              .join('; '),
      'calculated_total': hasCalculatedTotal
          ? _dec(formatDoseRateUSvH(calculatedTotalUSvH))
          : '—',
      'measured': measuredUSvH != null
          ? _dec(formatDoseRateUSvH(measuredUSvH))
          : (point.value == null
              ? '—'
              : '${_dec(point.value!.toStringAsFixed(2))} ${point.unit}'),
      'diff': (measuredUSvH != null && hasCalculatedTotal)
          ? _dec(formatDoseRateUSvH(measuredUSvH - calculatedTotalUSvH))
          : '—',
    };
  }

  /// A jegyzőkönyv PDF-változata: ugyanazok az adatok (fejléc, mérési pontok,
  /// sugárforrás-elemzés, aláírás-sor), a fényképek a mérési pontra utaló
  /// feliratokkal. Visszaadja a létrehozott .pdf fájlt.
  Future<File> exportSurveyPdf(
    int surveySessionId,
    AppLocalizations loc, {
    ProtocolExportOptions options = const ProtocolExportOptions(),
  }) async {
    _begin(loc, options);
    final inputs = await _loadInputs(surveySessionId);
    final session = inputs.session;
    final points = inputs.points;
    final companyName =
        await DatabaseTransferService.instance.getActiveCompanyName();
    final company = companyName.trim().isEmpty ? '—' : companyName;
    final unitSymbol = DistanceUnitController.current.symbol;

    const pointKeys = [
      'idx', 'location', 'type', 'value', 'distance', 'instrument',
      'gps', 'timestamp', 'notes',
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
        session.planCalibration,
      );
      pointRows.add([for (final k in pointKeys) values[k] ?? '—']);

      final attached =
          inputs.attachedByPointId[point.id] ?? const <AttachedSource>[];
      final sourceValues = _sourceRowValues(i, point, attached);
      if (sourceValues != null) {
        sourceRows.add([for (final k in sourceKeys) sourceValues[k] ?? '—']);
      }

      if (point.type == MeasurementType.spectrum) {
        final chart = await _renderSpectrumPng(
          point,
          (await getTemporaryDirectory()).path,
        );
        if (chart != null) {
          photos.add(ProtocolPhoto(
            caption: _l.protoSpectrumCaption(
              '${i + 1}',
              SpectrumKind.fromDbValue(point.spectrumKind).localized(_l),
              _pointLocation(point),
            ),
            path: chart,
          ));
        }
      }

      final photoPath = point.photoPath;
      if (photoPath != null && _options.includeImages) {
        photos.add(ProtocolPhoto(
          caption: _l.protoPhotoCaption(
            '${i + 1}',
            point.type.localized(_l),
            _pointLocation(point),
            _dateFormat.format(point.timestamp),
          ),
          path: photoPath,
          bytes: await _preparedImageBytes(File(photoPath), asJpeg: true),
        ));
      }
    }

    // A felméréshez mentett képernyőképek (időrendben), a PDF-be ágyazva.
    final shots = await ScreenshotService.listScreenshots(surveySessionId);
    shots.sort((a, b) => a.path.compareTo(b.path));
    final screenshotItems = <ProtocolPhoto>[];
    if (_options.includeImages) {
      for (final shot in shots) {
        screenshotItems.add(ProtocolPhoto(
          caption: _screenshotCaption(shot),
          path: shot.path,
          bytes: await _preparedImageBytes(shot, asJpeg: false),
        ));
      }
    }

    final classification = await loadSurveyClassification(surveySessionId);
    final mapSources = await _loadMapSources(surveySessionId);
    final planPng = await _planFigureFor(session, points, mapSources);
    final phantomFigures = await _phantomFiguresFor(inputs.victims);
    final data = ProtocolPdfData(
      decimalSeparator: _sep,
      planImage: planPng,
      planCaption: _l.protoPlanCaption,
      mapSourceHeaders: [
        '#',
        _l.protoColIdentifier,
        _l.nuclideLabel,
        _l.protoColPosition,
      ],
      mapSourceRows: _mapSourceRowValues(mapSources, session.planCalibration),
      protocolFields: inputs.protocolFieldPairs,
      classification: classification,
      headerFields: [
        (_l.protoCompany, company),
        (_l.protoSurveyName, session.title),
        (_l.protoLocation, session.location ?? '—'),
        (_l.protoStarted, _dateFormat.format(session.startedAt)),
        (
          _l.protoClosed,
          session.closedAt == null
              ? _l.protoOngoing
              : _dateFormat.format(session.closedAt!)
        ),
        (_l.protoNotes, session.notes ?? '—'),
      ],
      pointHeaders: [
        '#',
        _l.protoLocation,
        _l.protoColType,
        _l.protoColValue,
        _l.protoColDistance(unitSymbol),
        _l.protoColInstrument,
        session.planCalibration?.localCoordinates == true
            ? _l.planLocalCoordLabel
            : _l.protoColGps,
        _l.protoColTime,
        _l.protoNotes,
      ],
      pointRows: pointRows,
      sourceHeaders: [
        '#',
        _l.protoLocation,
        _l.protoColEstActivity,
        _l.protoColAttached,
        _l.protoColCalcTotal,
        _l.protoColMeasured,
        _l.protoColDiff,
      ],
      sourceRows: sourceRows,
      dosimeterHeaders: [
        '#',
        _l.protoColType,
        _l.protoColIdentifier,
        _l.protoColWearer,
        _l.protoColReading,
        _l.protoColDose,
        _l.protoColCounted,
      ],
      dosimeterRows: [
        for (final v in _dosimeterValueRows(inputs.dosimeters))
          [for (final k in _dosimeterKeys) v[k] ?? '—'],
      ],
      meteoHeaders: _meteoHeaders,
      meteoRows: _meteoRows(points),
      gasHeaders: _gasHeaders,
      gasRows: _gasRows(points),
      bioHeaders: _bioHeaders,
      bioRows: _bioRows(points),
      sampleHeaders: _sampleHeaders,
      sampleRows: _sampleRows(points, inputs.sampleAnalysesByPointId),
      handoverHeaders: _handoverHeaders,
      handoverRows: _handoverRows(inputs.victims),
      identityHeaders: _identityHeaders,
      identityRows: _identityRows(inputs.surveyors, inputs.victims),
      phantomFigures: phantomFigures,
      areaHeaders: _areaHeaders,
      areaRows: _areaRows(inputs.mapAreas),
      victimHeaders: _victimHeaders,
      victimRows: [
        for (final v in _victimValueRows(inputs.victims, inputs.conditionsByLink))
          [for (final k in _victimKeys) v[k] ?? '—'],
      ],
      sourceNote: _l.protoSourceNote,
      signatureFields: [
        (
          _l.protoSurveyedBy,
          inputs.personsText.isEmpty ? '—' : inputs.personsText
        ),
        (_l.protoCompany, company),
        (_l.protoDate, _dateOnlyFormat.format(DateTime.now())),
        (_l.protoSignature, '_______________________'),
      ],
      photos: photos,
      screenshots: screenshotItems,
    );

    final bytes = await ProtocolPdfBuilder.build(data, _l);
    // A PDF az ideiglenes mappába kerül; a korábbi `_jegyzokonyv` nevű exportok törlődnek.
    final tmpDir = await getTemporaryDirectory();
    await _removeOldProtocolFiles(tmpDir.path, '.pdf');
    if (Platform.isAndroid || Platform.isIOS) {
      await _removeOldProtocolFiles(
        (await getApplicationDocumentsDirectory()).path,
        '.pdf',
      );
    }
    final pdfFile = File(p.join(
      tmpDir.path,
      '${_safeFileName(session.title)}.pdf',
    ));
    await pdfFile.writeAsBytes(bytes);
    return pdfFile;
  }

  /// A képernyőkép felirata: a típus (térkép / pontlista) és a készítés ideje.
  /// A fájlnév a `<címke>_<milliszekundum>.png` formátumot követi.
  String _screenshotCaption(File shot) {
    final name = p.basename(shot.path);
    final base = name.startsWith('terkep')
        ? _l.protoShotMap
        : name.startsWith('pontok_lista')
            ? _l.protoShotList
            : name;
    final ms = RegExp(r'_(\d+)\.png$').firstMatch(name)?.group(1);
    if (ms == null) return base;
    final when = DateTime.fromMillisecondsSinceEpoch(int.parse(ms));
    return '$base · ${_dateFormat.format(when)}';
  }


  String _photoFileName(MeasurementPoint point) {
    final ext = p.extension(point.photoPath!);
    final label = (point.locationLabel ?? 'pont_${point.id}')
        .replaceAll(RegExp(r'[^\w\-]'), '_');
    return '${point.id}_$label$ext';
  }

  /// A jegyzőkönyv sablonja fix oszlopokat tartalmaz, ezért a nuklid-azonosítás
  /// a Megjegyzés oszlop elejére kerül ("Nuklid-azonosítás: ...").
  String _notesWithNuclides(MeasurementPoint point) {
    final nuclideText = nuclideSummaryText(
      status: point.nuclideStatus,
      nuclides: point.nuclides,
      statusLabel: (s) => s == NuclideIdStatus.notSpecified ? '' : s.label(_l),
    );
    final notes = point.notes;
    if (nuclideText.isEmpty) return notes ?? '—';
    return notes == null ? nuclideText : '$nuclideText. $notes';
  }

  String _safeFileName(String input) =>
      input.replaceAll(RegExp(r'[^\w\-]'), '_');

  /// Egy spektrum-ábra a Word-dokumentumban: kép (inline) és felirat.
  String _spectrumFigureXml(String rId, int id, String caption,
      {int cx = 5760000, int cy = 2880000}) {
    final fig = '<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:drawing>'
        '<wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
        '<wp:extent cx="$cx" cy="$cy"/><wp:effectExtent l="0" t="0" r="0" b="0"/>'
        '<wp:docPr id="$id" name="Spektrum $id"/>'
        '<wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr>'
        '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:nvPicPr><pic:cNvPr id="$id" name="spektrum_$id.png"/><pic:cNvPicPr/></pic:nvPicPr>'
        '<pic:blipFill><a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="$rId"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
        '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>';
    final cap = '<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:t xml:space="preserve">${_xmlEscape(caption)}</w:t></w:r></w:p>';
    return fig + cap;
  }

  String _withImageRels(String rels, List<({String rId, String target})> figs) {
    final add = StringBuffer();
    for (final f in figs) {
      add.write('<Relationship Id="${f.rId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="${f.target}"/>');
    }
    return rels.replaceFirst('</Relationships>', '$add</Relationships>');
  }

  String _withImageContentTypes(String types, Set<String> exts) {
    var out = types;
    for (final ext in exts) {
      if (out.contains('Extension="$ext"')) continue;
      out = out.replaceFirst(
          '</Types>', '<Default Extension="$ext" ContentType="image/$ext"/></Types>');
    }
    return out;
  }

  /// PNG vagy JPEG kép formátuma és pixelmérete a tartalma alapján.
  /// Más formátumnál vagy olvashatatlan fejlécnél null.
  ({String ext, int w, int h})? _embeddableImageInfo(List<int> b) {
    if (b.length >= 24 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      int be32(int o) => (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
      return (ext: 'png', w: be32(16), h: be32(20));
    }
    if (b.length >= 4 && b[0] == 0xFF && b[1] == 0xD8) {
      var i = 2;
      while (i + 9 < b.length) {
        if (b[i] != 0xFF) {
          i++;
          continue;
        }
        final marker = b[i + 1];
        if (marker == 0xFF) {
          i++;
          continue;
        }
        if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
          final h = (b[i + 5] << 8) | b[i + 6];
          final w = (b[i + 7] << 8) | b[i + 8];
          return (ext: 'jpeg', w: w, h: h);
        }
        if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
          i += 2;
          continue;
        }
        i += 2 + ((b[i + 2] << 8) | b[i + 3]);
      }
    }
    return null;
  }

  /// Az ábra mérete EMU-ban. A fotó aránya megmarad: szélessége legfeljebb
  /// 16 cm, magassága legfeljebb 12 cm, így nem torzul.
  ({int cx, int cy}) _figureExtent(String rId, List<int> bytes) {
    if (rId.startsWith('rIdPhantom')) return (cx: 3600000, cy: 3130000);
    final keepAspect = rId.startsWith('rIdPointPhoto') || rId.startsWith('rIdShot');
    final info = keepAspect ? _embeddableImageInfo(bytes) : null;
    if (info == null) return (cx: 5760000, cy: 2880000);
    const maxCx = 5760000;
    const maxCy = 4320000;
    var cx = maxCx;
    var cy = (maxCx * info.h / info.w).round();
    if (cy > maxCy) {
      cy = maxCy;
      cx = (maxCy * info.w / info.h).round();
    }
    return (cx: cx, cy: cy);
  }

  /// A felmérés besorolása WordprocessingML-ben: összesítő sorok és táblázat.
  String _classificationDocxXml(SurveyClassification c) {
    final l = _l;
    String para(String text, {bool bold = false, int halfPoints = 0}) {
      final props = StringBuffer();
      if (bold) props.write('<w:b/>');
      if (halfPoints > 0) props.write('<w:sz w:val="$halfPoints"/>');
      final rPr = props.isEmpty ? '' : '<w:rPr>$props</w:rPr>';
      return '<w:p><w:r>$rPr<w:t xml:space="preserve">'
          '${_xmlEscape(text)}</w:t></w:r></w:p>';
    }

    final t = c.total;
    final cat = t.physicalCategory;
    final rSum = t.rSum;
    final dateFormat = DateFormat('yyyy.MM.dd');
    final out = StringBuffer(
      para(l.classificationTitle, bold: true, halfPoints: 26),
    );
    out.write(para(
      rSum == null || cat == null
          ? l.surveyClassNoRSum
          : '${l.classificationTotal}: R = ${_fmtR(rSum)} · '
              '${l.classificationPhysCat}: $cat · '
              '${l.classificationProtLevel}: ${physicalProtectionLevel(cat)}',
    ));
    if (!t.isComplete) {
      out.write(para('${l.classificationUnknownCount}: ${t.unknownCount}'));
      out.write(para(l.surveyClassLowerBound));
    }
    if (c.rows.isEmpty) {
      out.write(para(l.surveyClassEmpty));
      return out.toString();
    }

    final headerRow = [
      l.sourceIdentifierLabel,
      l.nuclideLabel,
      'R',
      l.classificationPhysCat,
      l.classificationProtLevel,
      l.surveyClassIncluded,
      l.surveyClassCalcDate,
    ];
    const colWidth = 1280;
    const border = 'w:val="single" w:sz="4" w:space="0" w:color="808080"';
    final table = StringBuffer(
      '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders>'
      '<w:top $border/><w:left $border/><w:bottom $border/>'
      '<w:right $border/><w:insideH $border/><w:insideV $border/>'
      '</w:tblBorders></w:tblPr><w:tblGrid>',
    );
    for (var i = 0; i < headerRow.length; i++) {
      table.write('<w:gridCol w:w="$colWidth"/>');
    }
    table.write('</w:tblGrid>');

    void addRow(List<String> cells, {bool header = false}) {
      table.write('<w:tr>');
      for (final cell in cells) {
        table.write('<w:tc><w:tcPr><w:tcW w:w="$colWidth" w:type="dxa"/>'
            '</w:tcPr>${para(cell, bold: header, halfPoints: 16)}</w:tc>');
      }
      table.write('</w:tr>');
    }

    addRow(headerRow, header: true);
    for (final r in c.rows) {
      addRow([
        r.source.identifier,
        r.nuclides.isEmpty ? '—' : r.nuclides.map((n) => n.nuclide).join(', '),
        r.composition.rSum == null ? '—' : _fmtR(r.composition.rSum!),
        r.composition.physicalCategory?.toString() ?? '—',
        r.composition.physicalCategory == null
            ? '—'
            : physicalProtectionLevel(r.composition.physicalCategory!),
        r.placement.included ? '+' : '–',
        dateFormat.format(r.asOf),
      ]);
    }
    table.write('</w:tbl><w:p/>');
    out.write(table.toString());
    return out.toString();
  }

  String _fmtR(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e5 || a < 1e-3) return _dec(v.toStringAsExponential(2));
    return _dec(v.toStringAsPrecision(3));
  }

  /// Törli a korábbi, `_jegyzokonyv.<ext>` nevű exportokat a mappából.
  Future<void> _removeOldProtocolFiles(String dirPath, String extension) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;
    final victims = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File &&
          p.basename(entity.path).endsWith('_jegyzokonyv$extension')) {
        victims.add(entity);
      }
    }
    for (final file in victims) {
      await file.delete();
    }
  }

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
        '$nuclideName: ${_dec(formatActivityMBq(estimate.unshieldedMBq))} (${_l.protoUnshielded})');
    if (estimate.shieldedMBq != null) {
      buf.write('; ${_l.protoShieldedActivity(_dec(formatActivityMBq(estimate.shieldedMBq!)))}');
    }
    // Bemenő adatok, hogy a becslés ellenőrizhető legyen.
    buf.write('. ${_l.protoInputData(_dec(formatDoseRateUSvH(measuredUSvH)), _dec(formatDistanceMeters(distance)))}');
    if (isotope != null) {
      buf.write(', Γ = ${_plainNumber(isotope.gammaConstant)} µSv·m²/(MBq·h)');
    }
    if (point.shieldingLayers.isNotEmpty) {
      final layers = point.shieldingLayers
          .map((l) => '${shieldingMaterialLabel(_l, l.material)} '
              '${_plainNumber(l.thicknessCm)} cm')
          .join(' + ');
      buf.write(', ${_l.protoShieldingInline}: $layers');
      final t = layersTransmission(nuclideName, point.shieldingLayers);
      if (t != null) buf.write(' (${_l.protoTransmission(_plainNumber(t))})');
    }
    buf.write('.');
    return buf.toString();
  }

  String _plainNumber(double v) =>
      _dec(double.parse(v.toStringAsPrecision(4)).toString());

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
          : _l.protoInstrumentWithSerial(
              instrument.name,
              instrument.serialNumber!,
            ),
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
          kind == CalibrationKind.verification
              ? _l.calibrationKindVerification
              : _l.calibrationKindCalibration;
      final b = StringBuffer(
          '$label${_l.protoColon}${calibrationDateText(r.performedOn)}');
      if (r.validUntil != null) {
        b.write(', ${_l.protoCalibValidUntil(calibrationDateText(r.validUntil!))}');
      }
      if (r.certificateNumber != null) {
        b.write(', ${_l.protoCalibCertificate(r.certificateNumber!)}');
      }
      if (r.performedBy != null) b.write(' (${r.performedBy})');
      if (expiredAt(r.validUntil)) b.write(_l.protoCalibExpiredAtMeasure);
      parts.add(b.toString());
    }
    if (!anyRecord && instrument.nextCalibrationDate != null) {
      final d = instrument.nextCalibrationDate!;
      parts.add(_l.protoCalibFallback(calibrationDateText(d)) +
          (expiredAt(d) ? _l.protoCalibExpiredAtMeasure : ''));
    }
    return parts.join('; ');
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
    List<(String, String)> protocolFieldPairs,
    List<List<String>> bioRows,
    List<List<String>> sampleRows,
    List<List<String>> handoverRows,
    List<List<String>> identityRows,
    List<ProtocolFigure> phantomFigures,
    List<File> screenshots,
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
    var xml = _styleTemplateTables(
      utf8.decode(documentFile.content as List<int>),
    ).replaceAllMapped(
      RegExp(r'<w:pgMar [^>]*/>'),
      (_) => _protocolPageMarginXml,
    ).replaceAllMapped(
      RegExp(r'<w:spacing w:after="80"( w:before="\d+")?/>'),
      (m) => '<w:spacing w:after="160"${m.group(1) ?? ''} w:line="300" w:lineRule="auto"/>',
    );

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
      final values = _pointRowValues(
        i,
        point,
        instrumentById,
        calibrationsByInstrument,
        session.planCalibration,
      );

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
    final signIdx = xml.indexOf(r'${lbl_surveyed_by}');
    if (signIdx == -1) {
      throw StateError('A sablonban nem található az aláírás-sor.');
    }
    final signStart = xml.lastIndexOf('<w:p>', signIdx);
    final extraBlock = StringBuffer();
    if (protocolFieldPairs.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoFieldsHeading))
        ..write(_tableXml(
          [_l.protoFieldsColField, _l.protoFieldsColValue],
          [for (final (label, value) in protocolFieldPairs) [label, value]],
          _fieldColumnWidths,
          leftCols: const {0, 1},
        ));
    }
    if (areaRows.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoAreasHeading))
        ..write(_tableXml(
          _areaHeaders,
          areaRows,
          _areaColumnWidths,
          leftCols: const {1, 2, 3},
        ));
    }
    if (meteo.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoMeteoHeading))
        ..write(_meteoTablesXml(meteo));
    }
    if (gas.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoGasHeading))
        ..write(_tableXml(_gasHeaders, gas, _gasColumnWidths, leftCols: const {1}));
    }
    if (bioRows.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoBioHeading))
        ..write(_tableXml(_bioHeaders, bioRows, _bioColumnWidths, leftCols: const {1, 2}));
    }
    if (sampleRows.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoSampleAnalysesHeading))
        ..write(_tableXml(
          _sampleHeaders,
          sampleRows,
          _sampleColumnWidths,
          leftCols: const {1, 2, 4, 5, 6},
        ));
    }
    if (handoverRows.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoHandoverHeading))
        ..write(_tableXml(
          _handoverHeaders,
          handoverRows,
          _handoverColumnWidths,
          leftCols: const {1, 6, 7},
        ));
    }
    if (identityRows.isNotEmpty) {
      extraBlock
        ..write(_headingXmlFor(_l.protoIdentityHeading))
        ..write(_tableXml(
          _identityHeaders,
          identityRows,
          _identityColumnWidths,
          leftCols: const {1, 2, 3},
        ));
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
          ? _l.protoOngoing
          : _dateFormat.format(session.closedAt!),
      'survey_notes': session.notes ?? '—',
      'surveyor_name': personsText.isEmpty ? '—' : personsText,
      'export_date': _dateOnlyFormat.format(DateTime.now()),
      // A sablon statikus szövegei (címkék) — a nyelvtől függnek.
      'lbl_title': _l.protoTitle,
      'lbl_survey_name': _l.protoSurveyName,
      'lbl_location': _l.protoLocation,
      'lbl_started': _l.protoStarted,
      'lbl_closed': _l.protoClosed,
      'lbl_notes': _l.protoNotes,
      'lbl_colon': _l.protoColon,
      'lbl_points_heading': _l.protoPointsHeading,
      'lbl_col_type': _l.protoColType,
      'lbl_col_value': _l.protoColValue,
      'lbl_col_unit': _l.protoColUnit,
      'lbl_col_distance': _l.protoColDistance(DistanceUnitController.current.symbol),
      'lbl_col_instrument': _l.protoColInstrument,
      'lbl_col_gps': session.planCalibration?.localCoordinates == true
          ? _l.planLocalCoordLabel
          : _l.protoColGps,
      'lbl_col_gps_accuracy':
          _l.protoColGpsAccuracy(DistanceUnitController.current.symbol),
      'lbl_col_time': _l.protoColTime,
      'lbl_col_photo': _l.protoColPhoto,
      'lbl_source_heading': _l.protoSourceHeading,
      'lbl_col_est_activity': _l.protoColEstActivity,
      'lbl_col_attached': _l.protoColAttached,
      'lbl_col_calc_total': _l.protoColCalcTotal,
      'lbl_col_measured': _l.protoColMeasured,
      'lbl_col_diff': _l.protoColDiff,
      'lbl_source_note': _l.protoSourceNote,
      'lbl_dosimeter_heading': _l.protoDosimeterHeading,
      'lbl_col_identifier': _l.protoColIdentifier,
      'lbl_col_wearer': _l.protoColWearer,
      'lbl_col_reading': _l.protoColReading,
      'lbl_col_dose': _l.protoColDose,
      'lbl_col_counted': _l.protoColCounted,
      'lbl_surveyed_by': _l.protoSurveyedBy,
      'lbl_company': _l.protoCompany,
      'lbl_date': _l.protoDate,
      'lbl_signature': _l.protoSignature,
    };
    for (final entry in scalars.entries) {
      xml = xml.replaceAll('\${${entry.key}}', _xmlEscape(entry.value));
    }

    // Felmérés-besorolás és a térképi források a jegyzőkönyv végére (a spektrum-ábrák elé).
    final classification = await loadSurveyClassification(session.id!);
    final mapSources = await _loadMapSources(session.id!);
    final sectionXml = StringBuffer();
    if (classification != null) {
      sectionXml.write(_classificationDocxXml(classification));
    }
    if (mapSources.isNotEmpty) {
      sectionXml.write(_mapSourcesDocxXml(mapSources, session.planCalibration));
    }
    if (sectionXml.isNotEmpty) {
      final sectAt = xml.lastIndexOf('<w:sectPr');
      final insertAt = sectAt >= 0 ? sectAt : xml.lastIndexOf('</w:body>');
      xml = xml.substring(0, insertAt) + sectionXml.toString() + xml.substring(insertAt);
    }

    // Spektrum-ábrák a jegyzőkönyv végén: a PNG a docx médiatárába kerül,
    // a kapcsolatok és a tartalomtípusok ehhez igazodnak.
    final figures = <({String rId, String target, List<int> bytes, String caption, int id})>[];
    final planPng = await _planFigureFor(session, points, mapSources);
    if (planPng != null) {
      figures.add((
        rId: 'rIdPlan',
        target: 'media/plan.png',
        bytes: planPng,
        caption: _l.protoPlanCaption,
        id: 8999,
      ));
    }
    for (var i = 0; i < phantomFigures.length; i++) {
      figures.add((
        rId: 'rIdPhantom$i',
        target: 'media/phantom_$i.png',
        bytes: phantomFigures[i].bytes,
        caption: phantomFigures[i].caption,
        id: 9500 + i,
      ));
    }
    for (final point in points) {
      if (point.type != MeasurementType.spectrum) continue;
      final tmp = await getTemporaryDirectory();
      final png = await _renderSpectrumPng(point, tmp.path);
      if (png == null) continue;
      final n = figures.length + 1;
      figures.add((
        rId: 'rIdSpectrum$n',
        target: 'media/spectrum_$n.png',
        bytes: await File(png).readAsBytes(),
        caption: _l.protoSpectrumCaption(
          '${points.indexOf(point) + 1}',
          SpectrumKind.fromDbValue(point.spectrumKind).localized(_l),
          _pointLocation(point),
        ),
        id: 9000 + n,
      ));
    }
    // Minden pont fotója (JPEG/PNG) bekerül a jegyzőkönyvbe, kicsinyítve.
    // A HEIC és más formátum nem ágyazható be, ezek a jegyzőkönyvben nem jelennek meg.
    for (final point in points) {
      if (!_options.includeImages) break;
      final photo = point.photoPath;
      if (photo == null || !await File(photo).exists()) continue;
      final bytes = await _preparedImageBytes(File(photo), asJpeg: true);
      final info = bytes == null ? null : _embeddableImageInfo(bytes);
      if (bytes == null || info == null || info.w <= 0 || info.h <= 0) continue;
      final n = figures.length + 1;
      figures.add((
        rId: 'rIdPointPhoto$n',
        target: 'media/point_photo_$n.${info.ext}',
        bytes: bytes,
        caption: _l.protoPhotoCaption(
          '${points.indexOf(point) + 1}',
          point.type.localized(_l),
          _pointLocation(point),
          _dateFormat.format(point.timestamp),
        ),
        id: 9000 + n,
      ));
    }
    // A képernyőképek is az ábrák közé kerülnek (PNG), mert külön mappa nincs.
    for (final shot in screenshots) {
      if (!_options.includeImages) break;
      final bytes = await _preparedImageBytes(shot, asJpeg: false);
      final info = bytes == null ? null : _embeddableImageInfo(bytes);
      if (bytes == null || info == null || info.w <= 0 || info.h <= 0) continue;
      final n = figures.length + 1;
      figures.add((
        rId: 'rIdShot$n',
        target: 'media/screenshot_$n.${info.ext}',
        bytes: bytes,
        caption: _screenshotCaption(shot),
        id: 9800 + n,
      ));
    }
    if (figures.isNotEmpty) {
      final figuresXml = StringBuffer();
      for (final f in figures) {
        final extent = _figureExtent(f.rId, f.bytes);
        figuresXml.write(_spectrumFigureXml(f.rId, f.id, f.caption,
            cx: extent.cx, cy: extent.cy));
      }
      final sectAt = xml.lastIndexOf('<w:sectPr');
      final insertAt = sectAt >= 0 ? sectAt : xml.lastIndexOf('</w:body>');
      xml = xml.substring(0, insertAt) + figuresXml.toString() + xml.substring(insertAt);
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
      } else if (file.name == 'word/styles.xml') {
        final styles = _withProtocolStyles(utf8.decode(file.content as List<int>));
        final bytes = utf8.encode(styles);
        outputArchive.addFile(ArchiveFile(file.name, bytes.length, bytes));
      } else if (figures.isNotEmpty && file.name == 'word/_rels/document.xml.rels') {
        final rels = _withImageRels(
          utf8.decode(file.content as List<int>),
          [for (final f in figures) (rId: f.rId, target: f.target)],
        );
        final bytes = utf8.encode(rels);
        outputArchive.addFile(ArchiveFile(file.name, bytes.length, bytes));
      } else if (figures.isNotEmpty && file.name == '[Content_Types].xml') {
        final types = _withImageContentTypes(
          utf8.decode(file.content as List<int>),
          {for (final f in figures) p.extension(f.target).substring(1)},
        );
        final bytes = utf8.encode(types);
        outputArchive.addFile(ArchiveFile(file.name, bytes.length, bytes));
      } else {
        final content = file.content as List<int>;
        outputArchive.addFile(ArchiveFile(file.name, content.length, content));
      }
    }
    for (final f in figures) {
      outputArchive.addFile(ArchiveFile('word/${f.target}', f.bytes.length, f.bytes));
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
    required this.surveyors,
    required this.sampleAnalysesByPointId,
    required this.personsText,
    required this.dosimeters,
    required this.victims,
    required this.conditionsByLink,
    required this.mapAreas,
    required this.protocolFieldPairs,
  });

  final SurveySession session;
  final List<MeasurementPoint> points;
  final Map<int?, Instrument> instrumentById;
  final Map<int, List<InstrumentCalibration>> calibrationsByInstrument;
  final Map<int, List<AttachedSource>> attachedByPointId;
  final Map<int, List<SampleAnalysis>> sampleAnalysesByPointId;
  final List<AttachedPerson> surveyors;
  final String personsText;
  final List<SessionDosimeter> dosimeters;
  final List<AttachedPerson> victims;
  final Map<int, List<PersonCondition>> conditionsByLink;
  final List<MapArea> mapAreas;
  final List<(String, String)> protocolFieldPairs;
}

/// Egy térképen elhelyezett forrás a jegyzőkönyvhöz.
class MapSourceEntry {
  const MapSourceEntry({
    required this.identifier,
    required this.nuclides,
    required this.lat,
    required this.lon,
  });

  final String identifier;
  final String nuclides;
  final double lat;
  final double lon;
}
