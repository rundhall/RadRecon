import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';

/// Elmenti egy [RepaintBoundary]-vel körülvett képernyőrészlet aktuálisan
/// látható tartalmát PNG képként.
///
/// A képek nem kerülnek az adatbázisba — a jegyzőkönyv export a felmérés
/// azonosítója alapján, a fájlrendszerből gyűjti össze őket exportáláskor.
/// Csak a ténylegesen látható (renderelt) terület kerül képre — pl. egy
/// listánál a görgetéssel nem látszó rész nem lesz a képen.
class ScreenshotService {
  static Future<Directory> _sessionDir(int surveySessionId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(docs.path, 'rad_recon_screenshots', 'session_$surveySessionId'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Lefotózza a [boundaryKey]-hez tartozó [RenderRepaintBoundary] aktuális
  /// tartalmát, és elmenti a felméréshez rendelt könyvtárba.
  static Future<File> capture({
    required GlobalKey boundaryKey,
    required int surveySessionId,
    required String label,
    required AppLocalizations l10n,
  }) async {
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(l10n.noDisplayableContentForScreenshot);
    }

    final image = await renderObject.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError(l10n.failedToConvertScreenshotToPng);
    }

    final dir = await _sessionDir(surveySessionId);
    final fileName = '${label}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  /// A felméréshez eddig elmentett képernyőképek listája (lehet üres).
  static Future<List<File>> listScreenshots(int surveySessionId) async {
    final dir = await _sessionDir(surveySessionId);
    if (!await dir.exists()) return [];
    final entries = await dir.list().toList();
    return entries
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .toList();
  }
}