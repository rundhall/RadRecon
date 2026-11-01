import 'package:flutter/material.dart';

import '../models/victim_details.dart';

/// A fantomrajz: vázlatos emberalak; rajta a jelölések sorszámmal
/// (sérülés: piros, szennyezés: sárga).
class PhantomPainter extends CustomPainter {
  const PhantomPainter({required this.side, required this.markers});

  final BodySide side;
  final List<BodyMarker> markers;

  @override
  void paint(Canvas canvas, Size size) {
    final figure = _figurePath(size);
    canvas.drawPath(figure, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawPath(
      figure,
      Paint()
        ..color = const Color(0xFF757575)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < markers.length; i++) {
      final m = markers[i];
      if (m.side != side) continue;
      final c = Offset(m.x * size.width, m.y * size.height);
      canvas.drawCircle(
        c,
        11,
        Paint()
          ..color = m.kind == MarkerKind.injury
              ? const Color(0xFFD32F2F)
              : const Color(0xFFF9A825),
      );
      canvas.drawCircle(
        c,
        11,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, c - Offset(label.width / 2, label.height / 2));
    }
  }

  Path _figurePath(Size s) {
    Rect box(double x0, double y0, double x1, double y1) => Rect.fromLTRB(
        x0 * s.width, y0 * s.height, x1 * s.width, y1 * s.height);
    RRect rr(double x0, double y0, double x1, double y1, double radius) =>
        RRect.fromRectAndRadius(box(x0, y0, x1, y1), Radius.circular(radius));
    return Path()
      ..addOval(box(0.36, 0.01, 0.64, 0.15))
      ..addRRect(rr(0.44, 0.13, 0.56, 0.20, 4))
      ..addRRect(rr(0.22, 0.19, 0.78, 0.56, 18))
      ..addRRect(rr(0.08, 0.20, 0.20, 0.55, 12))
      ..addRRect(rr(0.80, 0.20, 0.92, 0.55, 12))
      ..addRRect(rr(0.25, 0.52, 0.49, 0.98, 14))
      ..addRRect(rr(0.51, 0.52, 0.75, 0.98, 14));
  }

  @override
  bool shouldRepaint(covariant PhantomPainter old) => true;
}
