import '../models/dose_quantity.dart';
import '../models/dose_rate_unit.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';

/// 2/2022. (IV. 29.) OAH rendelet 10. melléklet 3.4. pontja: a felülettől
/// 10 cm-re mérhető környezeti dózisegyenérték-teljesítmény megengedett
/// értéke 1 µSv/h (a foltokban mérhető fixált szennyeződésből származó dózisra).
const double kDecomDoseLimitMicroSvPerH = 1.0;

/// Csak ennél nem messzebb (m) mért H*(10) pont hasonlítható a határhoz.
const double kDecomLimitMaxDistanceM = 0.10;

/// A felületi szennyezettség mértékegysége az appban.
const String kSurfaceContaminationUnit = 'Bq/cm²';

enum DecomLimitStatus { noH10Measurement, noValidPoint, withinLimit, exceeded }

/// A 10 cm-es környezeti dózisegyenérték-határ ellenőrzésének eredménye.
class H10LimitCheck {
  const H10LimitCheck({
    required this.h10Points,
    required this.validPoints,
    required this.otherDosePoints,
    required this.maxMicroSvPerH,
  });

  // H*(10) dózisteljesítmény-pontok száma.
  final int h10Points;
  // Ezek közül a legfeljebb 10 cm-re mért pontok száma.
  final int validPoints;
  // Más mennyiségű (K, Hp, H'(d,Ω)) pontok: nem hasonlíthatók össze.
  final int otherDosePoints;
  // A legnagyobb érvényes érték, µSv/h-ban.
  final double? maxMicroSvPerH;

  DecomLimitStatus get status {
    if (h10Points == 0) return DecomLimitStatus.noH10Measurement;
    final max = maxMicroSvPerH;
    if (max == null) return DecomLimitStatus.noValidPoint;
    return max <= kDecomDoseLimitMicroSvPerH
        ? DecomLimitStatus.withinLimit
        : DecomLimitStatus.exceeded;
  }
}

H10LimitCheck checkH10Limit(List<MeasurementPoint> points) {
  var h10 = 0;
  var valid = 0;
  var other = 0;
  double? max;
  for (final point in points) {
    final value = point.value;
    if (point.type != MeasurementType.doseRate || value == null) continue;
    if (point.doseQuantity != DoseQuantity.h10.dbValue) {
      other++;
      continue;
    }
    h10++;
    final unit = DoseRateUnit.fromSymbol(point.unit);
    final distance = point.distanceFromSourceMeters;
    if (unit == null || distance == null || distance > kDecomLimitMaxDistanceM) {
      continue;
    }
    final microSvPerH = value * unit.microSvPerHourFactor;
    valid++;
    if (max == null || microSvPerH > max) max = microSvPerH;
  }
  return H10LimitCheck(
    h10Points: h10,
    validPoints: valid,
    otherDosePoints: other,
    maxMicroSvPerH: max,
  );
}

/// A felületi szennyezettség-pontok összegzése (csak Bq/cm² egységű pontok).
class SurfaceSummary {
  const SurfaceSummary({required this.points, required this.maxBqPerCm2});

  final int points;
  final double? maxBqPerCm2;
}

SurfaceSummary summarizeSurfaceContamination(List<MeasurementPoint> points) {
  var count = 0;
  double? max;
  for (final point in points) {
    final value = point.value;
    if (point.type != MeasurementType.surfaceContamination || value == null) {
      continue;
    }
    if (point.unit != kSurfaceContaminationUnit) continue;
    count++;
    if (max == null || value > max) max = value;
  }
  return SurfaceSummary(points: count, maxBqPerCm2: max);
}
