import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/spectrum.dart';

/// Spektrum-diagram. Oszloponként a csatornák maximumát rajzolja, így nagy
/// csatornaszámnál is olvasható marad. Kalibráció esetén energia-tengelyt ad.
class SpectrumChartPainter extends CustomPainter {
  SpectrumChartPainter({
    required this.spectrum,
    required this.xLabel,
    required this.lineColor,
    required this.axisColor,
    required this.textColor,
    this.backgroundColor,
    this.logScale = false,
  });

  final Spectrum spectrum;
  final String xLabel;
  final Color lineColor;
  final Color axisColor;
  final Color textColor;
  final Color? backgroundColor;
  final bool logScale;

  static const _left = 56.0;
  static const _right = 12.0;
  static const _top = 10.0;
  static const _bottom = 36.0;

  double _y(int count) =>
      logScale ? math.log(count + 1) / math.ln10 : count.toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = backgroundColor;
    if (bg != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    }
    final plot =
        Rect.fromLTRB(_left, _top, size.width - _right, size.height - _bottom);
    if (plot.width <= 0 || plot.height <= 0) return;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    final counts = spectrum.counts;
    if (counts.isEmpty) return;

    var maxCount = 0;
    var maxY = 0.0;
    for (final c in counts) {
      if (c > maxCount) maxCount = c;
      final y = _y(c);
      if (y > maxY) maxY = y;
    }
    if (maxY <= 0) maxY = 1;

    _text(canvas, '0', Offset(plot.left - 6, plot.bottom),
        alignRight: true, centerY: true);
    _text(canvas, '$maxCount', Offset(plot.left - 6, plot.top),
        alignRight: true, centerY: true);

    final columns = math.max(1, plot.width.floor());
    final perColumn = counts.length / columns;
    final path = Path();
    for (var x = 0; x < columns; x++) {
      final start = (x * perColumn).floor();
      final end = math.min(
        counts.length,
        math.max(start + 1, ((x + 1) * perColumn).ceil()),
      );
      var m = 0;
      for (var i = start; i < end; i++) {
        if (counts[i] > m) m = counts[i];
      }
      final px = plot.left + x + 0.5;
      final py = plot.bottom - (_y(m) / maxY) * plot.height;
      if (x == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final n = counts.length;
    for (final frac in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final channel = (frac * (n - 1)).round();
      final x = plot.left + plot.width * frac;
      final energy = spectrum.energyOfChannel(channel.toDouble());
      final label = energy == null
          ? '$channel'
          : energy.toStringAsFixed(energy.abs() < 100 ? 1 : 0);
      _text(canvas, label, Offset(x, plot.bottom + 4), centerX: true);
    }
    _text(canvas, xLabel, Offset(plot.center.dx, size.height - 14),
        centerX: true);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool centerX = false,
    bool centerY = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = anchor.dx;
    var dy = anchor.dy;
    if (alignRight) dx -= tp.width;
    if (centerX) dx -= tp.width / 2;
    if (centerY) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant SpectrumChartPainter old) =>
      old.spectrum != spectrum ||
      old.logScale != logScale ||
      old.xLabel != xLabel ||
      old.lineColor != lineColor ||
      old.textColor != textColor;
}

/// Spektrum-diagram a Flutter-felületen (színek a témából).
class SpectrumChart extends StatelessWidget {
  const SpectrumChart({
    super.key,
    required this.spectrum,
    required this.xLabel,
    this.logScale = false,
    this.height = 200,
  });

  final Spectrum spectrum;
  final String xLabel;
  final bool logScale;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: SpectrumChartPainter(
          spectrum: spectrum,
          xLabel: xLabel,
          logScale: logScale,
          lineColor: scheme.primary,
          axisColor: scheme.onSurfaceVariant,
          textColor: scheme.onSurface,
        ),
        size: Size.infinite,
      ),
    );
  }
}
