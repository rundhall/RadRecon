import 'dart:math' as math;

/// Egy izotóp gamma-állandója (Γ), amivel aktivitás és dózisteljesítmény
/// egymásból számolható: dózisteljesítmény (µSv/h) = Γ × aktivitás (MBq) / táv² (m²)
///
/// FONTOS: az itt szereplő Γ-értékek tájékoztató jellegű, széles körben
/// idézett referenciaértékek. Éles/hatósági jegyzőkönyvhöz ellenőrizd őket
/// egy hiteles forrás (pl. IAEA vagy a hazai mérésügyi hatóság táblázata)
/// alapján, mielőtt a kalkulátor eredményét dokumentálod.
class Isotope {
  final String name;
  final double gammaConstant; // µSv·m² / (MBq·h)

  /// Felezési idő napokban. Null, ha nem ismert (pl. egyedi/kézzel felvitt
  /// nuklid) — ekkor bomlás-számítás nem végezhető.
  final double? halfLifeDays;

  const Isotope(this.name, this.gammaConstant, [this.halfLifeDays]);

  /// Dózisteljesítmény (µSv/h) adott aktivitásból (MBq) és távolságból (m).
  double doseRateAt({required double activityMBq, required double distanceM}) {
    if (distanceM <= 0) throw ArgumentError('A távolságnak pozitívnak kell lennie.');
    return gammaConstant * activityMBq / (distanceM * distanceM);
  }

  /// Aktivitás (MBq) egy mért dózisteljesítményből (µSv/h) és távolságból (m).
  double activityFrom({required double doseRateUSvH, required double distanceM}) {
    if (gammaConstant <= 0) throw ArgumentError('Érvénytelen gamma-állandó.');
    return doseRateUSvH * distanceM * distanceM / gammaConstant;
  }

  /// Exponenciális bomlással számolt aktivitás (MBq) `elapsedDays` nap
  /// elteltével, ha a felezési idő ismert. Null, ha nem.
  double? decayedActivityMBq({
    required double initialActivityMBq,
    required double elapsedDays,
  }) {
    final t2 = halfLifeDays;
    if (t2 == null || t2 <= 0) return null;
    final lambda = math.ln2 / t2;
    return initialActivityMBq * math.exp(-lambda * elapsedDays);
  }

  /// Megkeresi az ismert izotópot név szerint (pontos egyezés).
  static Isotope? findByName(String name) {
    for (final i in kKnownIsotopes) {
      if (i.name == name) return i;
    }
    return null;
  }
}

/// Tájékoztató jellegű Γ-értékek (µSv·m²/(MBq·h)) és felezési idők (nap)
/// gyakori izotópokra.
const List<Isotope> kKnownIsotopes = [
  Isotope('Co-60', 0.351, 1925.3), // T½ = 5.2711 év
  Isotope('Cs-137', 0.0900, 10986.7), // T½ = 30.08 év
  Isotope('Ir-192', 0.130, 73.83), // T½ = 73.83 nap
  Isotope('Ra-226', 0.195, 584400), // T½ = 1600 év
  Isotope('I-131', 0.0578, 8.02), // T½ = 8.02 nap
  Isotope('Na-22', 0.359, 950.4), // T½ = 2.6019 év
  Isotope('Am-241', 0.0043, 157861.1), // T½ = 432.2 év
];