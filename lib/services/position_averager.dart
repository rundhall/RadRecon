import 'dart:math' as math;

/// Egy GPS-minta az átlagoláshoz.
class GpsSample {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  const GpsSample(this.latitude, this.longitude, this.accuracyMeters);
}

class AveragedPosition {
  final double latitude;
  final double longitude;

  /// Becsült vízszintes pontosság (m). Konzervatív: a GPS-hiba időben
  /// korrelált, ezért nem csökken a minták számának négyzetgyökével.
  final double accuracyMeters;
  final int used;
  final int total;
  const AveragedPosition(
      this.latitude, this.longitude, this.accuracyMeters, this.used, this.total);
}

const _mPerDegLat = 111320.0;

/// Pontosság-súlyozott átlag kiugró minták elhagyásával.
///
/// 1. Súly = 1/pontosság² (a pontosabb minta többet számít).
/// 2. Súlyozott átlag, majd a medián-távolságnál (min. 3 m) 3-szor messzebb
///    eső minták elhagyása és újraszámolás.
/// 3. Becsült pontosság = max(szórás a mintákban, a mediánpontosság osztva
///    √(max(1, N/10)) értékkel).
AveragedPosition? averagePositions(List<GpsSample> samples) {
  final valid = samples.where((s) => s.accuracyMeters > 0).toList();
  if (valid.isEmpty) return null;
  final lat0 = valid.first.latitude;
  final lon0 = valid.first.longitude;
  final mPerDegLon = _mPerDegLat * math.cos(lat0 * math.pi / 180);

  double x(GpsSample s) => (s.longitude - lon0) * mPerDegLon;
  double y(GpsSample s) => (s.latitude - lat0) * _mPerDegLat;

  (double, double) weightedMean(List<GpsSample> list) {
    var sw = 0.0, sx = 0.0, sy = 0.0;
    for (final s in list) {
      final w = 1 / (s.accuracyMeters * s.accuracyMeters);
      sw += w;
      sx += w * x(s);
      sy += w * y(s);
    }
    return (sx / sw, sy / sw);
  }

  var kept = valid;
  var (mx, my) = weightedMean(kept);
  if (valid.length >= 5) {
    final dists = [for (final s in valid) math.sqrt(math.pow(x(s) - mx, 2) + math.pow(y(s) - my, 2))]
      ..sort();
    final median = dists[dists.length ~/ 2];
    final limit = math.max(3.0, 3 * median);
    final filtered = [
      for (final s in valid)
        if (math.sqrt(math.pow(x(s) - mx, 2) + math.pow(y(s) - my, 2)) <= limit) s
    ];
    if (filtered.length >= 3) {
      kept = filtered;
      (mx, my) = weightedMean(kept);
    }
  }

  var sq = 0.0;
  for (final s in kept) {
    sq += math.pow(x(s) - mx, 2) + math.pow(y(s) - my, 2);
  }
  final spread = math.sqrt(sq / kept.length);
  final accs = [for (final s in kept) s.accuracyMeters]..sort();
  final medianAcc = accs[accs.length ~/ 2];
  final effN = math.max(1.0, kept.length / 10);
  final accuracy = math.max(spread, medianAcc / math.sqrt(effN));

  return AveragedPosition(
    lat0 + my / _mPerDegLat,
    lon0 + mx / mPerDegLon,
    accuracy,
    kept.length,
    valid.length,
  );
}
