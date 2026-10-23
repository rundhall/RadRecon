import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';

/// Egy fénykép a PDF-ben, a mérési pontra utaló felirattal.
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
    this.areaHeaders = const [],
    this.areaRows = const [],
    this.screenshots = const [],
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
  final List<String> victimHeaders;
  final List<List<String>> victimRows;
  final List<String> meteoHeaders;
  final List<List<String>> meteoRows;
  final List<String> gasHeaders;
  final List<List<String>> gasRows;
  final List<String> areaHeaders;
  final List<List<String>> areaRows;
  final List<ProtocolPhoto> screenshots;
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
          pw.Text(l.protoTitle, style: _style(18)),
          pw.SizedBox(height: 10),
          for (final (label, value) in data.headerFields) _field(label, value),
          pw.SizedBox(height: 14),
          _heading(l.protoPointsHeading),
          pw.SizedBox(height: 6),
          _table(data.pointHeaders, data.pointRows),
          pw.SizedBox(height: 14),
          _heading(l.protoSourceHeading),
          pw.SizedBox(height: 6),
          if (data.sourceRows.isEmpty)
            pw.Text(l.protoNoSourcePoints, style: _style(8))
          else
            _table(data.sourceHeaders, data.sourceRows),
          pw.SizedBox(height: 4),
          pw.Text(
            data.sourceNote,
            style: _style(8, color: PdfColors.grey800),
          ),
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

  static pw.TextStyle _style(double size, {PdfColor? color}) =>
      pw.TextStyle(fontSize: size, color: color);

  static pw.Widget _heading(String text) =>
      pw.Text(text, style: _style(12, color: PdfColors.grey900));

  static pw.Widget _field(String label, String value) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(label, style: _style(9, color: PdfColors.grey800)),
            ),
            pw.Expanded(child: pw.Text(value, style: _style(9))),
          ],
        ),
      );

  static pw.Widget _table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
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
            pw.Text(photo.caption, style: _style(8)),
            pw.SizedBox(height: 3),
            if (image != null)
              pw.SizedBox(
                width: width,
                height: height,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              )
            else
              pw.Text(
                l.protoPhotoUnreadable,
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
