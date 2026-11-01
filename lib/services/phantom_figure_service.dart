import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../models/victim_details.dart';
import '../widgets/phantom_painter.dart';

/// Elöl- és hátulnézet egy PNG-ben a jegyzőkönyvhöz. A rajz és a jelölések
/// ugyanazok, mint a rögzítő ablakban. Ha nincs jelölés, null.
Future<Uint8List?> renderPhantomFigure({
  required List<BodyMarker> markers,
  required String frontLabel,
  required String backLabel,
}) async {
  if (markers.isEmpty) return null;
  const figW = 300.0;
  const figH = 500.0;
  const pad = 24.0;
  const labelH = 40.0;
  const w = figW * 2 + pad * 3;
  const h = figH + labelH + pad * 2;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w, h),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final sides = [
    (side: BodySide.front, label: frontLabel),
    (side: BodySide.back, label: backLabel),
  ];
  for (var i = 0; i < sides.length; i++) {
    final dx = pad + i * (figW + pad);
    canvas.save();
    canvas.translate(dx, labelH + pad);
    PhantomPainter(side: sides[i].side, markers: markers)
        .paint(canvas, const ui.Size(figW, figH));
    canvas.restore();
    final tp = TextPainter(
      text: TextSpan(
        text: sides[i].label,
        style: const TextStyle(
          color: ui.Color(0xFF212121),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ui.Offset(dx + (figW - tp.width) / 2, pad));
  }
  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}
