import 'dart:math' as math;

import '../models/measurement_point.dart';

/// Egy gradiens-becslés eredménye.
class GradientSearchResult {
  final bool success;
  final String? errorMessage;
  final double? bearingDegrees; // 0-360°, É-tól óramutató járása szerint
  final double? gradientMagnitudePerMeter; // mértékegység / méter
  final int pointCount;
  final bool lowConfidence;

  const GradientSearchResult._({
    required this.success,
    this.errorMessage,
    this.bearingDegrees,
    this.gradientMagnitudePerMeter,
    required this.pointCount,
    this.lowConfidence = false,
  });

  factory GradientSearchResult.error(String message, int pointCount) =>
      GradientSearchResult._(
        success: false,
        errorMessage: message,
        pointCount: pointCount,
      );

  factory GradientSearchResult.ok({
    required double bearingDegrees,
    required double gradientMagnitudePerMeter,
    required int pointCount,
    required bool lowConfidence,
  }) =>
      GradientSearchResult._(
        success: true,
        bearingDegrees: bearingDegrees,
        gradientMagnitudePerMeter: gradientMagnitudePerMeter,
        pointCount: pointCount,
        lowConfidence: lowConfidence,
      );
}

/// Egyszerű, lineáris gradiens-becslés a felmérésen belül eddig rögzített,
/// azonos típusú mérési pontokból.
///
/// Síkot illeszt az `érték = a*x + b*y + c` modellre legkisebb négyzetek
/// módszerével, ahol x/y a pontok helyi, méterben számolt (kelet/észak)
/// eltérése egy referenciaponttól (egyszerű, rövid távolságra elfogadható
/// egyenközű vetítés). Az (a, b) vektor iránya adja a "merre nő az érték"
/// javaslatot.
///
/// Csak tájékoztató jellegű: zajos terepi adatoknál, kevés vagy majdnem
/// egy vonalban lévő pontnál pontatlan vagy numerikusan instabil lehet —
/// ezt a felhasználói felület is jelzi.
class GradientSearchService {
  static GradientSearchResult estimate(List<MeasurementPoint> points) {
    final valid = points.where((p) => p.value != null).toList();
    if (valid.length < 2) {
      return GradientSearchResult.error(
        'Legalább 2 mérési pont kell ehhez a típushoz ezen a felmérésen belül.',
        valid.length,
      );
    }

    final refLat = valid.first.latitude;
    final refLon = valid.first.longitude;
    final refLatRad = refLat * math.pi / 180.0;
    const metersPerDegLat = 111320.0;
    final metersPerDegLon = 111320.0 * math.cos(refLatRad);

    final xs = <double>[];
    final ys = <double>[];
    final zs = <double>[];
    for (final p in valid) {
      xs.add((p.longitude - refLon) * metersPerDegLon);
      ys.add((p.latitude - refLat) * metersPerDegLat);
      zs.add(p.value!);
    }

    final n = valid.length.toDouble();
    double sx = 0, sy = 0, sz = 0, sxx = 0, syy = 0, sxy = 0, sxz = 0, syz = 0;
    for (var i = 0; i < xs.length; i++) {
      sx += xs[i];
      sy += ys[i];
      sz += zs[i];
      sxx += xs[i] * xs[i];
      syy += ys[i] * ys[i];
      sxy += xs[i] * ys[i];
      sxz += xs[i] * zs[i];
      syz += ys[i] * zs[i];
    }

    // Síkillesztés a*x + b*y + c = z, legkisebb négyzetek, normálegyenletek:
    // [sxx sxy sx] [a]   [sxz]
    // [sxy syy sy] [b] = [syz]
    // [sx  sy  n ] [c]   [sz ]
    final det = sxx * (syy * n - sy * sy) -
        sxy * (sxy * n - sy * sx) +
        sx * (sxy * sy - syy * sx);

    if (det.abs() < 1e-9) {
      return GradientSearchResult.error(
        'A pontok túl közel vannak egymáshoz vagy egy vonalban helyezkednek '
        'el — nem számolható megbízható irány. Vegyél fel pontokat a '
        'terület más-más helyein.',
        valid.length,
      );
    }

    final detA = sxz * (syy * n - sy * sy) -
        sxy * (syz * n - sy * sz) +
        sx * (syz * sy - syy * sz);
    final detB = sxx * (syz * n - sy * sz) -
        sxz * (sxy * n - sy * sx) +
        sx * (sxy * sz - syz * sx);

    final a = detA / det;
    final b = detB / det;

    final magnitude = math.sqrt(a * a + b * b);
    if (magnitude < 1e-9) {
      return GradientSearchResult.error(
        'A rögzített pontok között gyakorlatilag nincs érzékelhető '
        'változás az értékben.',
        valid.length,
      );
    }

    var bearing = math.atan2(a, b) * 180.0 / math.pi;
    if (bearing < 0) bearing += 360.0;

    return GradientSearchResult.ok(
      bearingDegrees: bearing,
      gradientMagnitudePerMeter: magnitude,
      pointCount: valid.length,
      lowConfidence: valid.length < 4,
    );
  }
}