import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/activity_unit.dart';
import 'package:rad_recon/models/distance_unit.dart';
import 'package:rad_recon/models/dose_rate_unit.dart';

void main() {
  unitFamilyTests();
  test('az alapértelmezett egység µSv/h', () {
    expect(DoseRateUnit.defaultUnit, DoseRateUnit.uSvH);
    expect(DoseRateUnit.fromStorage(null), DoseRateUnit.uSvH);
  });

  test('átváltás egységek között', () {
    expect(DoseRateUnit.nSvH.convertTo(DoseRateUnit.uSvH, 1500), closeTo(1.5, 1e-9));
    expect(DoseRateUnit.uSvH.convertTo(DoseRateUnit.nSvH, 0.25), closeTo(250, 1e-9));
    expect(DoseRateUnit.mSvH.convertTo(DoseRateUnit.uSvH, 2), closeTo(2000, 1e-9));
  });

  test('szimbólumból felismerés (régi mentések, görög mű)', () {
    expect(DoseRateUnit.fromSymbol('nSv/h'), DoseRateUnit.nSvH);
    expect(DoseRateUnit.fromSymbol('μSv/h'), DoseRateUnit.uSvH);
    expect(DoseRateUnit.fromSymbol('uSv/h'), DoseRateUnit.uSvH);
    expect(DoseRateUnit.fromSymbol('cps'), isNull);
  });
}

void unitFamilyTests() {
  test('dózisteljesítmény: Sv, R, rem alapú egységek', () {
    expect(DoseRateUnit.svH.convertTo(DoseRateUnit.uSvH, 1), closeTo(1e6, 1e-6));
    expect(DoseRateUnit.remH.convertTo(DoseRateUnit.mSvH, 1), closeTo(10, 1e-9));
    expect(DoseRateUnit.mRemH.convertTo(DoseRateUnit.uSvH, 1), closeTo(10, 1e-9));
    expect(DoseRateUnit.uRH.convertTo(DoseRateUnit.nSvH, 1), closeTo(10, 1e-9));
    expect(DoseRateUnit.fromSymbol('uR/h'), DoseRateUnit.uRH);
    expect(DoseRateUnit.fromSymbol('mrem/h'), DoseRateUnit.mRemH);
    expect(DoseRateUnit.fromSymbol('R/h'), DoseRateUnit.rH);
  });

  test('aktivitás', () {
    expect(ActivityUnit.ci.convertTo(ActivityUnit.gigaBq, 1), closeTo(37, 1e-9));
    expect(ActivityUnit.milliCi.convertTo(ActivityUnit.megaBq, 1), closeTo(37, 1e-9));
    expect(ActivityUnit.microCi.convertTo(ActivityUnit.kiloBq, 1), closeTo(37, 1e-9));
    expect(ActivityUnit.teraBq.convertTo(ActivityUnit.bq, 1), closeTo(1e12, 1));
  });

  test('távolság', () {
    expect(DistanceUnit.feet.toMeters(1), closeTo(0.3048, 1e-12));
    expect(DistanceUnit.inch.convertTo(DistanceUnit.cm, 1), closeTo(2.54, 1e-9));
    expect(DistanceUnit.cm.toMeters(150), closeTo(1.5, 1e-12));
  });
}
