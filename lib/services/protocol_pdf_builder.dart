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
  const ProtocolPhoto({required this.caption, required this.path});

  final String caption;
  final String path;
}

/// A PDF-jegyzőkönyv tartalma. A táblázatok cellaszövegei ugyanazok, mint a
/// Word-sablonban (a ProtocolExportService állítja elő).
class ProtocolPdfData {
  const ProtocolPdfData({
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
      images.add(await _loadImage(photo.path));
    }

    // A képernyőképek (térkép, pontlista) betöltése ugyanúgy, mint a fotóké.
    final shotImages = <pw.MemoryImage?>[];
    for (final shot in data.screenshots) {
      shotImages.add(await _loadImage(shot.path));
    }

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(28),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: _style(8),
          ),
        ),
        build: (context) => [
          pw.Text(_safe(l.protoTitle), style: _style(18)),
          pw.SizedBox(height: 10),
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
          _table(data.pointHeaders, data.pointRows),
          pw.SizedBox(height: 14),
          _heading(l.protoSourceHeading),
          pw.SizedBox(height: 6),
          if (data.sourceRows.isEmpty)
            pw.Text(_safe(l.protoNoSourcePoints), style: _style(8))
          else
            _table(data.sourceHeaders, data.sourceRows),
          pw.SizedBox(height: 4),
          pw.Text(
            _safe(data.sourceNote),
            style: _style(8, color: PdfColors.grey800),
          ),
          if (data.classification != null) ...[
            pw.SizedBox(height: 14),
            _heading(l.classificationTitle),
            pw.SizedBox(height: 6),
            ..._classificationWidgets(data.classification!, l),
          ],
          if (data.planImage != null) ...[
            pw.SizedBox(height: 14),
            _heading(l.protoPlanHeading),
            pw.SizedBox(height: 6),
            pw.SizedBox(
              height: 360,
              child: pw.Image(
                pw.MemoryImage(data.planImage!),
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(_safe(data.planCaption), style: _style(8, color: PdfColors.grey800)),
          ],
          if (data.mapSourceRows.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _heading(l.protoSourcesOnMapHeading),
            pw.SizedBox(height: 6),
            _table(data.mapSourceHeaders, data.mapSourceRows),
          ],
          pw.SizedBox(height: 14),
          _heading(l.protoDosimeterHeading),
          pw.SizedBox(height: 6),
          _table(data.dosimeterHeaders, data.dosimeterRows),
          pw.SizedBox(height: 14),
          if (data.victimRows.isNotEmpty) ...[
            _heading(l.protoVictimsHeading),
            pw.SizedBox(height: 6),
            _table(data.victimHeaders, data.victimRows),
            pw.SizedBox(height: 14),
          ],
          if (data.areaRows.isNotEmpty) ...[
            _heading(l.protoAreasHeading),
            pw.SizedBox(height: 6),
            _table(data.areaHeaders, data.areaRows),
            pw.SizedBox(height: 14),
          ],
          if (data.meteoRows.isNotEmpty) ...[
            _heading(l.protoMeteoHeading),
            pw.SizedBox(height: 6),
            _table(data.meteoHeaders, data.meteoRows),
            pw.SizedBox(height: 14),
          ],
          if (data.gasRows.isNotEmpty) ...[
            _heading(l.protoGasHeading),
            pw.SizedBox(height: 6),
            _table(data.gasHeaders, data.gasRows),
            pw.SizedBox(height: 14),
          ],
          if (data.bioRows.isNotEmpty) ...[
            _heading(l.protoBioHeading),
            pw.SizedBox(height: 6),
            _table(data.bioHeaders, data.bioRows),
            pw.SizedBox(height: 14),
          ],
          if (data.sampleRows.isNotEmpty) ...[
            _heading(l.protoSampleAnalysesHeading),
            pw.SizedBox(height: 6),
            _table(data.sampleHeaders, data.sampleRows),
            pw.SizedBox(height: 14),
          ],
          if (data.handoverRows.isNotEmpty) ...[
            _heading(l.protoHandoverHeading),
            pw.SizedBox(height: 6),
            _table(data.handoverHeaders, data.handoverRows),
            pw.SizedBox(height: 14),
          ],
          if (data.identityRows.isNotEmpty) ...[
            _heading(l.protoIdentityHeading),
            pw.SizedBox(height: 6),
            _table(data.identityHeaders, data.identityRows),
            pw.SizedBox(height: 14),
          ],
          if (data.phantomFigures.isNotEmpty) ...[
            _heading(l.protoPhantomHeading),
            pw.SizedBox(height: 6),
            for (final f in data.phantomFigures) ...[
              pw.Text(_safe(f.caption), style: _style(9)),
              pw.SizedBox(height: 4),
              pw.SizedBox(
                height: 240,
                child: pw.Image(
                  pw.MemoryImage(f.bytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 10),
            ],
            pw.SizedBox(height: 14),
          ],
          for (final (label, value) in data.signatureFields)
            _field(label, value),
          if (data.photos.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _heading(l.protoPhotosHeading),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < data.photos.length; i++)
                  _photoTile(data.photos[i], images[i], l),
              ],
            ),
          ],
          if (data.screenshots.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _heading(l.protoScreenshotsHeading),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 16,
              runSpacing: 16,
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
          ],
        ],
      ),
    );
    return doc.save();
  }

  static String _fmtR(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e5 || a < 1e-3) return v.toStringAsExponential(2);
    return v.toStringAsPrecision(3);
  }

  /// Felmérés-besorolás: összesítő sorok és a forrás-táblázat.
  static List<pw.Widget> _classificationWidgets(
    SurveyClassification c,
    AppLocalizations l,
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
          r.composition.rSum == null ? '—' : _fmtR(r.composition.rSum!),
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
            : 'R = ${_fmtR(rSum)} · ${l.classificationPhysCat}: $cat · '
                '${l.classificationProtLevel}: ${physicalProtectionLevel(cat)}',
      ),
      if (!t.isComplete) ...[
        _field(l.classificationUnknownCount, '${t.unknownCount}'),
        pw.Text(
          _safe(l.surveyClassLowerBound),
          style: _style(8, color: PdfColors.grey800),
        ),
      ],
      pw.SizedBox(height: 6),
      if (rows.isEmpty)
        pw.Text(_safe(l.surveyClassEmpty), style: _style(8))
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

  static pw.Widget _heading(String text) =>
      pw.Text(_safe(text), style: _style(12, color: PdfColors.grey900));

  static pw.Widget _field(String label, String value) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(_safe(label),
                  style: _style(9, color: PdfColors.grey800)),
            ),
            pw.Expanded(child: pw.Text(_safe(value), style: _style(9))),
          ],
        ),
      );

  static pw.Widget _table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: [for (final h in headers) _safe(h)],
        data: [
          for (final row in rows) [for (final cell in row) _safe(cell)],
        ],
        headerStyle: _style(7.5),
        cellStyle: _style(7.5),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        cellPadding: pw.EdgeInsets.all(3),
        cellAlignment: pw.Alignment.topLeft,
        headerAlignment: pw.Alignment.centerLeft,
        border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      );

  static pw.Widget _photoTile(
    ProtocolPhoto photo,
    pw.MemoryImage? image,
    AppLocalizations l, {
    double width = 260,
    double height = 190,
  }) =>
      pw.SizedBox(
        width: width,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_safe(photo.caption), style: _style(8)),
            pw.SizedBox(height: 3),
            if (image != null)
              pw.SizedBox(
                width: width,
                height: height,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              )
            else
              pw.Text(
                _safe(l.protoPhotoUnreadable),
                style: _style(8, color: PdfColors.grey800),
              ),
          ],
        ),
      );

  static Future<pw.MemoryImage?> _loadImage(String path) async {
    try {
      return pw.MemoryImage(await File(path).readAsBytes());
    } catch (_) {
      return null;
    }
  }
}
