import '../models/isotope.dart';
import '../models/shielding.dart';

/// Egynuklidos aktivitás-becslés eredménye.
class ActivityEstimate {
  /// A mért értékből, árnyékolás nélkül feltételezve számolt aktivitás (MBq).
  final double unshieldedMBq;

  /// Az árnyékolt forrás becsült tényleges aktivitása (MBq). Null, ha nincs
  /// megadva árnyékolás, vagy nincs HVL-adat az anyag/nuklid párosra.
  final double? shieldedMBq;

  const ActivityEstimate(this.unshieldedMBq, this.shieldedMBq);
}

/// Visszaszámolt aktivitás egy mért dózisteljesítményből. Árnyékolás nélkül:
/// A = D·d²/Γ. Ha árnyékolás is meg van adva, a forrás tényleges aktivitása
/// az árnyékolás nélküli érték osztva az áteresztéssel (félértékréteg-
/// modell, a szórt sugárzás/buildup elhanyagolva → tájékoztató becslés).
ActivityEstimate? estimateActivity({
  required String nuclide,
  required double doseRateUSvH,
  required double distanceM,
  List<ShieldingLayer> layers = const [],
}) {
  final isotope = Isotope.findByName(nuclide);
  if (isotope == null || distanceM <= 0) return null;
  final unshielded =
      isotope.activityFrom(doseRateUSvH: doseRateUSvH, distanceM: distanceM);
  double? shielded;
  if (layers.isNotEmpty) {
    final t = layersTransmission(nuclide, layers);
    if (t != null && t > 0) shielded = unshielded / t;
  }
  return ActivityEstimate(unshielded, shielded);
}
