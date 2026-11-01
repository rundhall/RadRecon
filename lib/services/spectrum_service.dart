import '../database/database_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/spectrum.dart';
import '../widgets/spectrum_chart.dart';

/// Spektrumfájlok: másolás az app-mappába, visszaolvasás, és PNG-ábra a
/// jegyzőkönyvhöz.
class SpectrumService {
  SpectrumService._();

  /// Az eredeti fájl másolata az app-mappában; visszaadja az új elérési utat.
  static Future<String> importFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory(p.join(dir.path, 'spectra'));
    await target.create(recursive: true);
    final saved = File(
      p.join(target.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName'),
    );
    await saved.writeAsBytes(bytes);
    return saved.path;
  }

  /// Mentett spektrum visszaolvasása; null, ha a fájl hiányzik vagy hibás.
  static Future<Spectrum?> load(String path) async {
    try {
      final text =
          utf8.decode(await File(path).readAsBytes(), allowMalformed: true);
      return N42Parser.parse(text);
    } catch (_) {
      return null;
    }
  }

  /// Árva spektrumfájlok törlése: az app-mappában, de egyetlen mérési pont
  /// sem hivatkozik rájuk (pl. megszakított felvétel). Indításkor fut.
  static Future<int> sweepOrphans() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'spectra'));
      if (!await dir.exists()) return 0;
      final used = (await DatabaseHelper.instance.spectrumPathsInUse()).toSet();
      var removed = 0;
      await for (final entity in dir.list()) {
        if (entity is File && !used.contains(entity.path)) {
          await entity.delete();
          removed++;
        }
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  /// Spektrum-ábra PNG-ben (fehér háttér, fix színek).
  static Future<File> renderPng({
    required Spectrum spectrum,
    required String targetPath,
    required String xLabel,
    bool logScale = false,
    int width = 1200,
    int height = 600,
  }) async {
    final size = ui.Size(width.toDouble(), height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
    SpectrumChartPainter(
      spectrum: spectrum,
      xLabel: xLabel,
      logScale: logScale,
      lineColor: const ui.Color(0xFF3949AB),
      axisColor: const ui.Color(0xFF616161),
      textColor: const ui.Color(0xFF212121),
      backgroundColor: const ui.Color(0xFFFFFFFF),
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(targetPath);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file;
  }
}
