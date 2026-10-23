import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import 'dose_integrator.dart';

/// Egy felmérés dózisteljesítmény-pontjaiból számított dózis.
class PointDoseCalculation {
  const PointDoseCalculation({
    required this.doseMicroSv,
    required this.pointCount,
  });

  final double doseMicroSv;
  final int pointCount;
}

/// A felmérés dózisteljesítmény-pontjaiból integrált dózis. Az első és az
/// utolsó pont közötti teljes időszakot a pontok között lineárisan
/// interpolált dózisteljesítménnyel integráljuk (trapéz-szabály, ugyanaz,
/// mint az auto-log integrátora). Null, ha kevesebb mint két érvényes pont van.
class SessionDoseCalculator {
  SessionDoseCalculator._();

  static PointDoseCalculation? fromPoints(List<MeasurementPoint> points) {
    final doseRatePoints = points
        .where((p) => p.type == MeasurementType.doseRate && p.value != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final integrator = DoseIntegrator();
    for (final p in doseRatePoints) {
      integrator.addSample(p.value!, p.unit, p.timestamp);
    }
    if (integrator.sampleCount < 2) return null;
    return PointDoseCalculation(
      doseMicroSv: integrator.doseMicroSv,
      pointCount: integrator.sampleCount,
    );
  }
}
