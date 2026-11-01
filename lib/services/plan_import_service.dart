import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'plan_georeference.dart';

/// Az app alaprajz-mappája (`plans/`), létrehozva, ha még nincs.
Future<Directory> _plansDirectory() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'plans'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Az alaprajz másolása az app dokumentum-mappájába. A felmérés a másolatra
/// hivatkozik, így az eredeti fájl törlése nem töri meg.
Future<String> copyPlanIntoAppStorage(String sourcePath) async {
  final dir = await _plansDirectory();
  final ext = p.extension(sourcePath).toLowerCase();
  final target = p.join(
    dir.path,
    'plan_${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  await File(sourcePath).copy(target);
  return target;
}

/// Az alaprajz pixelmérete. Nem képfájl esetén kivételt dob.
Future<({int width, int height})> planImageSize(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final size = (width: frame.image.width, height: frame.image.height);
  frame.image.dispose();
  return size;
}

/// Generált alaprajz-háttér: egyszínű lap 1 m-es rácsozással, PNG-ként a
/// `plans/` mappában. A méretarány a [blankPlanGeometry] szerint fix.
Future<({String path, int widthPx, int heightPx, double metersPerPx})>
    generateBlankPlan({
  required double widthM,
  required double heightM,
  required int backgroundArgb,
}) async {
  final geometry = blankPlanGeometry(widthM: widthM, heightM: heightM);
  final w = geometry.widthPx.toDouble();
  final h = geometry.heightPx.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w, h),
    ui.Paint()..color = ui.Color(backgroundArgb),
  );
  final grid = ui.Paint()
    ..color = const ui.Color(0x33000000)
    ..strokeWidth = 1;
  final pixelsPerMetre = 1 / geometry.metersPerPx;
  for (var x = 0.0; x <= w; x += pixelsPerMetre) {
    canvas.drawLine(ui.Offset(x, 0), ui.Offset(x, h), grid);
  }
  for (var y = 0.0; y <= h; y += pixelsPerMetre) {
    canvas.drawLine(ui.Offset(0, y), ui.Offset(w, y), grid);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(geometry.widthPx, geometry.heightPx);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (bytes == null) {
    throw StateError('A generált alaprajz kódolása sikertelen.');
  }

  final dir = await _plansDirectory();
  final path = p.join(
    dir.path,
    'generated_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await File(path).writeAsBytes(bytes.buffer.asUint8List());
  return (
    path: path,
    widthPx: geometry.widthPx,
    heightPx: geometry.heightPx,
    metersPerPx: geometry.metersPerPx,
  );
}
