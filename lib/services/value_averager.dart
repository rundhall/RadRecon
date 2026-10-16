import 'dart:math' as math;

/// Ismételt leolvasások statisztikája.
class ValueStats {
  final int n;
  final double mean;

  /// Tapasztalati (minta) szórás, n-1 nevezővel; 0, ha n < 2.
  final double stdDev;

  const ValueStats(this.n, this.mean, this.stdDev);

  /// Az átlag standard hibája (1σ): szórás / √n. Null, ha n < 2.
  double? get standardError => n < 2 ? null : stdDev / math.sqrt(n);
}

ValueStats? valueStats(List<double> values) {
  if (values.isEmpty) return null;
  final n = values.length;
  final mean = values.reduce((a, b) => a + b) / n;
  if (n < 2) return ValueStats(n, mean, 0);
  var sq = 0.0;
  for (final v in values) {
    sq += (v - mean) * (v - mean);
  }
  return ValueStats(n, mean, math.sqrt(sq / (n - 1)));
}

/// "érték ± hiba" szöveg: a hibát 2 értékes jegyre kerekíti, az értéket
/// ugyanannyi tizedesre. Hiba nélkül csak az értéket adja (4 értékes jegy).
String formatValueWithError(double value, double? error) {
  if (error == null || !(error > 0) || error.isNaN || error.isInfinite) {
    return double.parse(value.toStringAsPrecision(4)).toString();
  }
  final exp = (math.log(error) / math.ln10).floor();
  final int decimals = (1 - exp).clamp(0, 12).toInt();
  return '${value.toStringAsFixed(decimals)} ± ${error.toStringAsFixed(decimals)}';
}
