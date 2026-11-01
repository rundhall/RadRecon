import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../models/plan_calibration.dart';
import 'plan_georeference.dart';

/// Egy jelölés az alaprajzon: mérési pont (sorszám), vagy térképi forrás (azonosító).
class PlanMark {
  const PlanMark({
    required this.lat,
    required this.lon,
    required this.label,
    required this.isSource,
  });

  final double lat;
  final double lon;
  final String label;
  final bool isSource;
}

/// Az alaprajz PNG-ben, a jelölésekkel (a jegyzőkönyvbe). A kép legnagyobb
/// oldala [maxSidePx]; a jelölések a koordinátából számolt helyre kerülnek.
/// Null, ha a képfájl nem olvasható.
Future<Uint8List?> renderPlanFigure(
  PlanCalibration plan,
  List<PlanMark> marks, {
  int maxSidePx = 1400,
}) async {
  final file = File(plan.imagePath);
  if (!await file.exists()) return null;
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  final frame = await codec.getNextFrame();
  final img = frame.image;
  final w = img.width.toDouble();
  final h = img.height.toDouble();
  final scale = math.min(1.0, maxSidePx / math.max(w, h));
  final outW = math.max(1, (w * scale).round());
  final outH = math.max(1, (h * scale).round());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
  );
  canvas.drawImageRect(
    img,
    ui.Rect.fromLTWH(0, 0, w, h),
    ui.Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );

  final geo = PlanGeoref(plan);
  for (final m in marks) {
    final px = geo.latLonToPixel(m.lat, m.lon);
    if (px.x < 0 || px.y < 0 || px.x > w || px.y > h) continue;
    final c = ui.Offset(px.x * scale, px.y * scale);
    final r = m.isSource ? 7.0 : 5.0;
    final fill = m.isSource
        ? const ui.Color(0xFFE65100)
        : const ui.Color(0xFF1565C0);
    canvas.drawCircle(c, r, ui.Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const ui.Color(0xFFFFFFFF),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: m.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ui.Color(0xFF000000),
          backgroundColor: ui.Color(0xCCFFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ui.Offset(c.dx + r + 2, c.dy - tp.height / 2));
  }

  final picture = recorder.endRecording();
  final out = await picture.toImage(outW, outH);
  final png = await out.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  out.dispose();
  picture.dispose();
  return png?.buffer.asUint8List();
}
