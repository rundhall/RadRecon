import 'package:flutter/material.dart';

/// Egy mintapont az idődiagramhoz.
class TimeSample {
  final DateTime time;
  final double value;
  const TimeSample(this.time, this.value);
}

/// Egyszerű, függőség nélküli idődiagram: vonal a mért értékekről, az
/// idő a bal szélső mintától eltelt idő (mm:ss / h:mm:ss), opcionális
/// küszöbvonallal.
class TimeSeriesChart extends StatelessWidget {
  final List<TimeSample> samples;
  final String unit;
  final double? threshold;
  final double height;

  const TimeSeriesChart({
    super.key,
    required this.samples,
    required this.unit,
    this.threshold,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          samples: samples,
          unit: unit,
          threshold: threshold,
          line: scheme.primary,
          grid: scheme.outlineVariant,
          text: scheme.onSurfaceVariant,
          warn: scheme.error,
        ),
      ),
    );
  }
}

String _fmtValue(double v) {
  final a = v.abs();
  if (a == 0) return '0';
  if (a >= 1e5 || a < 1e-3) return v.toStringAsExponential(1);
  if (a >= 100) return v.toStringAsFixed(0);
  if (a >= 1) return v.toStringAsFixed(2);
  return v.toStringAsPrecision(2);
}

String _fmtElapsed(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

class _ChartPainter extends CustomPainter {
  final List<TimeSample> samples;
  final String unit;
  final double? threshold;
  final Color line, grid, text, warn;

  _ChartPainter({
    required this.samples,
    required this.unit,
    required this.threshold,
    required this.line,
    required this.grid,
    required this.text,
    required this.warn,
  });

  TextPainter _tp(String s, {Color? color}) => TextPainter(
        text: TextSpan(
            text: s, style: TextStyle(fontSize: 10, color: color ?? text)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0, right = 8.0, top = 14.0, bottom = 22.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawRect(plot, gridPaint..style = PaintingStyle.stroke);
    _tp(unit).paint(canvas, const Offset(2, 0));
    if (samples.isEmpty) return;

    var minV = samples.first.value, maxV = samples.first.value;
    for (final s in samples) {
      if (s.value < minV) minV = s.value;
      if (s.value > maxV) maxV = s.value;
    }
    if (threshold != null) {
      if (threshold! > maxV) maxV = threshold!;
      if (threshold! < minV) minV = threshold!;
    }
    if (maxV - minV < 1e-12) {
      final pad = maxV.abs() > 0 ? maxV.abs() * 0.1 : 1.0;
      minV -= pad;
      maxV += pad;
    } else {
      final pad = (maxV - minV) * 0.05;
      minV -= pad;
      maxV += pad;
    }
    final t0 = samples.first.time;
    final int spanMs =
        samples.last.time.difference(t0).inMilliseconds.clamp(1, 1 << 40).toInt();
    double x(DateTime t) =>
        plot.left + plot.width * t.difference(t0).inMilliseconds / spanMs;
    double y(double v) =>
        plot.bottom - plot.height * (v - minV) / (maxV - minV);

    // vízszintes rácsvonalak + érték-feliratok
    for (var i = 0; i <= 4; i++) {
      final v = minV + (maxV - minV) * i / 4;
      final yy = y(v);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy),
          gridPaint..style = PaintingStyle.stroke);
      final tp = _tp(_fmtValue(v));
      tp.paint(canvas, Offset(plot.left - tp.width - 4, yy - tp.height / 2));
    }
    // idő-feliratok
    for (var i = 0; i <= 3; i++) {
      final frac = i / 3;
      final label = _fmtElapsed(Duration(milliseconds: (spanMs * frac).round()));
      final tp = _tp(label);
      final xx = plot.left + plot.width * frac;
      tp.paint(
          canvas,
          Offset(
              (xx - tp.width / 2).clamp(0.0, size.width - tp.width).toDouble(),
              plot.bottom + 4));
    }
    if (threshold != null) {
      final yy = y(threshold!);
      final p = Paint()
        ..color = warn
        ..strokeWidth = 1.2;
      for (var xx = plot.left; xx < plot.right; xx += 8) {
        canvas.drawLine(Offset(xx, yy),
            Offset((xx + 4).clamp(plot.left, plot.right).toDouble(), yy), p);
      }
    }
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final o = Offset(x(samples[i].time), y(samples[i].value));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.save();
    canvas.clipRect(plot);
    canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round);
    if (samples.length == 1) {
      canvas.drawCircle(Offset(x(samples[0].time), y(samples[0].value)), 3,
          Paint()..color = line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
