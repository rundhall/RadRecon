import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import 'source_classification.dart';
import 'survey_source_total.dart';

/// Egy fénykép a PDF-ben, a mérési pontra utaló felirattal.
/// Egy jegyzőkönyvi ábra (PNG) feliratával.
class ProtocolFigure {
  const ProtocolFigure({required this.caption, required this.bytes});

  final String caption;
  final Uint8List bytes;
}

class ProtocolPhoto {
  const ProtocolPhoto({required this.caption, required this.path, this.bytes});

  final String caption;
  final String path;

  /// Az előkészített (kicsinyített/forgatott) képbájtok; ha nincs, a path-ból töltődik.
  final Uint8List? bytes;
}

/// A PDF-jegyzőkönyv tartalma. A táblázatok cellaszövegei ugyanazok, mint a
/// Word-sablonban (a ProtocolExportService állítja elő).
class ProtocolPdfData {
  const ProtocolPdfData({
    this.decimalSeparator = '.',
    required this.headerFields,
    required this.pointHeaders,
    required this.pointRows,
    required this.sourceHeaders,
    required this.sourceRows,
    required this.sourceNote,
    required this.dosimeterHeaders,
    required this.dosimeterRows,
    required this.signatureFields,
    required this.photos,
    this.victimHeaders = const [],
    this.victimRows = const [],
    this.meteoHeaders = const [],
    this.meteoRows = const [],
    this.gasHeaders = const [],
    this.gasRows = const [],
    this.bioHeaders = const [],
    this.bioRows = const [],
    this.sampleHeaders = const [],
    this.sampleRows = const [],
    this.handoverHeaders = const [],
    this.handoverRows = const [],
    this.identityHeaders = const [],
    this.identityRows = const [],
    this.phantomFigures = const [],
    this.areaHeaders = const [],
    this.areaRows = const [],
    this.screenshots = const [],
    this.protocolFields = const [],
    this.classification,
    this.planImage,
    this.planCaption = '',
    this.mapSourceHeaders = const [],
    this.mapSourceRows = const [],
  });

  final List<(String, String)> headerFields;
  final List<String> pointHeaders;
  final List<List<String>> pointRows;
  final List<String> sourceHeaders;
  final List<List<String>> sourceRows;
  final String sourceNote;
  final List<String> dosimeterHeaders;
  final List<List<String>> dosimeterRows;
  final List<(String, String)> signatureFields;
  final List<ProtocolPhoto> photos;
  /// Az alaprajz PNG-ben, a jelölésekkel (alaprajz módú felmérésnél).
  final Uint8List? planImage;
  final String planCaption;
  final List<String> mapSourceHeaders;
  final List<List<String>> mapSourceRows;
  final List<String> victimHeaders;
  final List<List<String>> victimRows;
  final List<String> meteoHeaders;
  final List<List<String>> meteoRows;
  final List<String> gasHeaders;
  final List<List<String>> gasRows;
  final List<String> bioHeaders;
  final List<List<String>> bioRows;
  final List<String> sampleHeaders;
  final List<List<String>> sampleRows;
  final List<String> handoverHeaders;
  final List<List<String>> handoverRows;
  final List<String> identityHeaders;
  final List<List<String>> identityRows;
  final List<ProtocolFigure> phantomFigures;
  final List<String> areaHeaders;
  final List<List<String>> areaRows;
  final List<ProtocolPhoto> screenshots;
  final List<(String, String)> protocolFields;
  /// Felmérés-besorolás (bekerülő források R-je), ha van.
  final SurveyClassification? classification;
  /// Tizedesjel a számokhoz (a Beállítások szerint; a szövegeket az exporter adja).
  final String decimalSeparator;
}

/// Jegyzőkönyv PDF-et készít a `pdf` csomaggal.
///
/// A szövegek (címsorok, feliratok) az aktuális nyelven jönnek az
/// [AppLocalizations]-ből. Az ékezetes karakterekhez (ő, ű, ç, ñ stb.) a
/// beágyazott Noto Sans betűtípus kell: a PDF alapbetűkészletei nem
/// tartalmazzák ezeket.
class ProtocolPdfBuilder {
  ProtocolPdfBuilder._();

  static const _fontAsset = 'assets/fonts/NotoSans-Variable.ttf';

  /// Táblázat-szöveg mérete (pont): a nyomtatott jegyzőkönyv olvashatóságáért.
  static const double _tableFontSize = 9.5;

  static Future<Uint8List> build(
    ProtocolPdfData data,
    AppLocalizations l,
  ) async {
    final font = pw.Font.ttf(await rootBundle.load(_fontAsset));
    final theme = pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    );

    // A fényképeket előre beolvassuk: egy sérült vagy nem támogatott fájl ne
    // állítsa le az egész exportot (ilyenkor a képhelyre figyelmeztetés kerül).
    final images = <pw.MemoryImage?>[];
    for (final photo in data.photos) {
      images.add(await _loadImage(photo.path, photo.bytes));
    }

    // A képernyőképek (térkép, pontlista) betöltése ugyanúgy, mint a fotóké.
    final shotImages = <pw.MemoryImage?>[];
    for (final shot in data.screenshots) {
      shotImages.add(await _loadImage(shot.path, shot.bytes));
    }

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(72),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: _style(9.5),
          ),
        ),
        build: (context) => [
          pw.Text(_safe(l.protoTitle), style: _style(22)),
          pw.SizedBox(height: 14),
          for (final (label, value) in data.headerFields) _field(label, value),
          if (data.protocolFields.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _heading(l.protoFieldsHeading),
            pw.SizedBox(height: 6),
            for (final (label, value) in data.protocolFields)
              _field(label, value),
          ],
          pw.SizedBox(height: 14),
          _heading(l.protoPointsHeading),
          pw.SizedBox(height: 6),
          _table(
            data.pointHeaders,
            data.pointRows,
            leftColumns: const {1, 8},
            columnWidths: _pointColumnWidths,
          ),
          pw.SizedBox(height: 14),
          _section(
            [
              _heading(l.protoSourceHeading),
              pw.SizedBox(height: 6),
              if (data.sourceRows.isEmpty)
                pw.Text(_safe(l.protoNoSourcePoints), style: _style(9.5))
              else
                _table(
                  data.sourceHeaders,
                  data.sourceRows,
                  leftColumns: const {1, 3},
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                _safe(data.sourceNote),
                style: _style(9.5, color: PdfColors.grey800),
              ),
            ],
            keep: data.sourceRows.length <= _keepRows,
          ),
          if (data.classification != null) ...[
            pw.SizedBox(height: 14),
            _section(
              [
                _heading(l.classificationTitle),
                pw.SizedBox(height: 6),
                ..._classificationWidgets(
                  data.classification!,
                  l,
                  data.decimalSeparator,
                ),
              ],
              keep: data.classification!.rows.length <= _keepRows,
            ),
          ],
          if (data.planImage != null) ...[
            pw.SizedBox(height: 14),
            _section(
              [
                _heading(l.protoPlanHeading),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.SizedBox(
                    height: 360,
                    child: pw.Image(
                      pw.MemoryImage(data.planImage!),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    _safe(data.planCaption),
                    style: _style(9.5, color: PdfColors.grey800),
                  ),
                ),
              ],
              keep: true,
            ),
          ],
          if (data.mapSourceRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoSourcesOnMapHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.mapSourceHeaders,
                  data.mapSourceRows,
                  leftColumns: const {1, 3},
                ),
              ],
              keep: data.mapSourceRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          pw.SizedBox(height: 14),
          _section(
            [
              _heading(l.protoDosimeterHeading),
              pw.SizedBox(height: 6),
              _table(
                data.dosimeterHeaders,
                data.dosimeterRows,
                leftColumns: const {3},
              ),
            ],
            keep: data.dosimeterRows.length <= _keepRows,
          ),
          pw.SizedBox(height: 14),
          if (data.victimRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoVictimsHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.victimHeaders,
                  data.victimRows,
                  leftColumns: const {1, 3, 4},
                ),
              ],
              keep: data.victimRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.areaRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoAreasHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.areaHeaders,
                  data.areaRows,
                  leftColumns: const {1, 2, 3},
                ),
              ],
              keep: data.areaRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.meteoRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoMeteoHeading),
                pw.SizedBox(height: 6),
                ..._meteoTables(data.meteoHeaders, data.meteoRows),
              ],
              keep: data.meteoRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.gasRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoGasHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.gasHeaders,
                  data.gasRows,
                  leftColumns: const {1},
                ),
              ],
              keep: data.gasRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.bioRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoBioHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.bioHeaders,
                  data.bioRows,
                  leftColumns: const {1, 2},
                ),
              ],
              keep: data.bioRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.sampleRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoSampleAnalysesHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.sampleHeaders,
                  data.sampleRows,
                  leftColumns: const {1, 2, 4, 5, 6},
                ),
              ],
              keep: data.sampleRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.handoverRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoHandoverHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.handoverHeaders,
                  data.handoverRows,
                  leftColumns: const {1, 6, 7},
                ),
              ],
              keep: data.handoverRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.identityRows.isNotEmpty) ...[
            _section(
              [
                _heading(l.protoIdentityHeading),
                pw.SizedBox(height: 6),
                _table(
                  data.identityHeaders,
                  data.identityRows,
                  leftColumns: const {1, 2, 3},
                ),
              ],
              keep: data.identityRows.length <= _keepRows,
            ),
            pw.SizedBox(height: 14),
          ],
          if (data.phantomFigures.isNotEmpty) ...[
            for (var i = 0; i < data.phantomFigures.length; i++)
              _keepTogether([
                if (i == 0) ...[
                  _heading(l.protoPhantomHeading),
                  pw.SizedBox(height: 6),
                ],
                pw.Center(
                  child: pw.Text(
                    _safe(data.phantomFigures[i].caption),
                    style: _style(11),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.SizedBox(
                    height: 240,
                    child: pw.Image(
                      pw.MemoryImage(data.phantomFigures[i].bytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
              ]),
            pw.SizedBox(height: 14),
          ],
          for (final (label, value) in data.signatureFields)
            _field(label, value),
          if (data.photos.isNotEmpty) ...[
            pw.NewPage(),
            _heading(l.protoPhotosHeading),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: pw.WrapAlignment.center,
                children: [
                  for (var i = 0; i < data.photos.length; i++)
                    _photoTile(data.photos[i], images[i], l),
                ],
              ),
            ),
          ],
          if (data.screenshots.isNotEmpty) ...[
            pw.NewPage(),
            _heading(l.protoScreenshotsHeading),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: pw.WrapAlignment.center,
                children: [
                  for (var i = 0; i < data.screenshots.length; i++)
                    _photoTile(
                      data.screenshots[i],
                      shotImages[i],
                      l,
                      width: 380,
                      height: 260,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static String _fmtR(double v, String sep) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e5 || a < 1e-3) return v.toStringAsExponential(2).replaceAll('.', sep);
    return v.toStringAsPrecision(3).replaceAll('.', sep);
  }

  /// Felmérés-besorolás: összesítő sorok és a forrás-táblázat.
  static List<pw.Widget> _classificationWidgets(
    SurveyClassification c,
    AppLocalizations l,
    String sep,
  ) {
    final t = c.total;
    final cat = t.physicalCategory;
    final rSum = t.rSum;
    final dateFormat = DateFormat('yyyy.MM.dd');
    final rows = <List<String>>[
      for (final r in c.rows)
        [
          r.source.identifier,
          r.nuclides.isEmpty
              ? '—'
              : r.nuclides.map((n) => n.nuclide).join(', '),
          r.composition.rSum == null ? '—' : _fmtR(r.composition.rSum!, sep),
          r.composition.physicalCategory?.toString() ?? '—',
          r.composition.physicalCategory == null
              ? '—'
              : physicalProtectionLevel(r.composition.physicalCategory!),
          r.placement.included ? '+' : '–',
          dateFormat.format(r.asOf),
        ],
    ];
    return [
      _field(
        l.classificationTotal,
        rSum == null || cat == null
            ? l.surveyClassNoRSum
            : 'R = ${_fmtR(rSum, sep)} · ${l.classificationPhysCat}: $cat · '
                '${l.classificationProtLevel}: ${physicalProtectionLevel(cat)}',
      ),
      if (!t.isComplete) ...[
        _field(l.classificationUnknownCount, '${t.unknownCount}'),
        pw.Text(
          _safe(l.surveyClassLowerBound),
          style: _style(9.5, color: PdfColors.grey800),
        ),
      ],
      pw.SizedBox(height: 6),
      if (rows.isEmpty)
        pw.Text(_safe(l.surveyClassEmpty), style: _style(9.5))
      else
        _table(
          [
            l.sourceIdentifierLabel,
            l.nuclideLabel,
            'R',
            l.classificationPhysCat,
            l.classificationProtLevel,
            l.surveyClassIncluded,
            l.surveyClassCalcDate,
          ],
          rows,
          leftColumns: const {0, 1},
        ),
    ];
  }

  /// A beágyazott Noto Sans betűkészlet nem tartalmazza ezeket a jeleket:
  /// a PDF-ben négyzet jelenne meg, ezért ASCII-megfelelőre cseréljük őket.
  static const _glyphFallbacks = <String, String>{
    '≤': '<=',
    '≥': '>=',
    '→': '->',
    '∞': 'inf',
    '☐': '[ ]',
  };

  static String _safe(String text) {
    var out = text;
    for (final entry in _glyphFallbacks.entries) {
      out = out.replaceAll(entry.key, entry.value);
    }
    return out;
  }

  static pw.TextStyle _style(double size, {PdfColor? color}) =>
      pw.TextStyle(fontSize: size, color: color);

  /// Rövid szakaszok (címsor + kis táblázat) ennyi sorig egy blokkban maradnak.
  static const _keepRows = 8;

  /// Szakasz: a címsor és a tartalma egy blokk. A `keep` esetén a blokk nem
  /// törik két oldalra, így a címsor nem marad egyedül az oldal alján.
  static pw.Widget _section(List<pw.Widget> parts, {required bool keep}) =>
      keep
          ? _keepTogether(parts)
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: parts,
            );

  /// Egyetlen táblázat-sorban lévő blokk: a PDF-motor a sort nem töri ketté,
  /// így a hozzá tartozó elemek (pl. képaláírás és kép) együtt maradnak.
  /// A `width` megadásával fix szélességű (pl. fotócsempe) lesz.
  static pw.Widget _keepTogether(List<pw.Widget> parts, {double? width}) =>
      pw.Table(
        columnWidths: {
          0: width == null ? pw.FlexColumnWidth() : pw.FixedColumnWidth(width),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: parts,
              ),
            ],
          ),
        ],
      );

  static pw.Widget _heading(String text) =>
      pw.Text(_safe(text), style: _style(15, color: PdfColors.grey900));

  static pw.Widget _field(String label, String value) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 190,
              child: pw.Text(_safe(label),
                  style: _style(11, color: PdfColors.grey800)),
            ),
            pw.Expanded(child: pw.Text(_safe(value), style: _style(11))),
          ],
        ),
      );

  /// Mérési pontok táblázata: a sorszám fix szélességű (hogy látszódjon), a
  /// többi oszlop a maradék helyet arányosan osztja el.
  static final Map<int, pw.TableColumnWidth> _pointColumnWidths = {
    0: pw.FixedColumnWidth(26),
    1: pw.FlexColumnWidth(1.1),
    2: pw.FlexColumnWidth(1.6),
    3: pw.FlexColumnWidth(2.6),
    4: pw.FlexColumnWidth(1.2),
    5: pw.FlexColumnWidth(1.3),
    6: pw.FlexColumnWidth(1.9),
    7: pw.FlexColumnWidth(1.3),
    8: pw.FlexColumnWidth(2.6),
  };

  /// Jegyzőkönyv-táblázat: a fejléc és a cellák középre igazodnak, kivéve a
  /// [leftColumns] oszlopait (szöveges mezők), amelyek balra igazodnak.
  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    Set<int> leftColumns = const {},
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    final leftAlignments = {
      for (final c in leftColumns) c: pw.Alignment.centerLeft,
    };
    return pw.TableHelper.fromTextArray(
      headers: [for (final h in headers) _safe(h)],
      data: [
        for (final row in rows) [for (final cell in row) _safe(cell)],
      ],
      headerStyle: _style(_tableFontSize),
      cellStyle: _style(_tableFontSize),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
      cellAlignments: leftAlignments,
      headerAlignments: leftAlignments,
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  /// A meteorológiai táblázat két, egymás alatti részre bontva, hogy a 15 oszlop
  /// olvasható maradjon. Mindkét részben a sorazonosító szerepel.
  static List<pw.Widget> _meteoTables(
    List<String> headers,
    List<List<String>> rows,
  ) {
    const split = 8;
    String at(List<String> row, int i) => i < row.length ? row[i] : '—';
    final rest = [for (var i = split; i < headers.length; i++) i];
    return [
      _table(
        [for (var i = 0; i < split; i++) headers[i]],
        [for (final r in rows) [for (var i = 0; i < split; i++) at(r, i)]],
      ),
      pw.SizedBox(height: 8),
      _table(
        [headers[0], for (final i in rest) headers[i]],
        [for (final r in rows) [at(r, 0), for (final i in rest) at(r, i)]],
      ),
    ];
  }

  static pw.Widget _photoTile(
    ProtocolPhoto photo,
    pw.MemoryImage? image,
    AppLocalizations l, {
    double width = 260,
    double height = 190,
  }) =>
      // Rögzített szélesség: a táblázat különben kitölti a teljes sort, és a
      // csempék egymás alá kerülnek.
      pw.SizedBox(
        width: width,
        child: _keepTogether(
          [
            pw.Center(
              child: pw.Text(
                _safe(photo.caption),
                style: _style(9.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 3),
            if (image != null)
              pw.Center(
                child: pw.SizedBox(
                  width: width,
                  height: height,
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              )
            else
              pw.Center(
                child: pw.Text(
                  _safe(l.protoPhotoUnreadable),
                  style: _style(9.5, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.center,
                ),
              ),
          ],
          width: width,
        ),
      );

  static Future<pw.MemoryImage?> _loadImage(String path, Uint8List? bytes) async {
    try {
      final data = bytes ?? await File(path).readAsBytes();
      return pw.MemoryImage(data);
    } catch (_) {
      return null;
    }
  }
}
