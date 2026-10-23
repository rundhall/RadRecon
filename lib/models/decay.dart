import 'dart:math' as math;

/// Exponenciális bomlás: a megmaradt hányad az eltelt idő és a felezési idő
/// (azonos időegységben) alapján. `0,5^(t / T½)`.
double remainingFraction({
  required double elapsedSeconds,
  required double halfLifeSeconds,
}) =>
    math.pow(0.5, elapsedSeconds / halfLifeSeconds).toDouble();

/// Az idő (másodperc), amely alatt `a0`-ról `target`-re csökken az aktivitás.
/// `null`, ha nem értelmezhető (a célnak pozitívnak és kisebbnek kell lennie).
double? timeToReachSeconds({
  required double halfLifeSeconds,
  required double a0,
  required double target,
}) {
  if (a0 <= 0 || target <= 0 || target >= a0) return null;
  return halfLifeSeconds * math.log(a0 / target) / math.ln2;
}
