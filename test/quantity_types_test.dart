import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/count_rate_unit.dart';
import 'package:rad_recon/models/dose_quantity.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/models/radiation_kind.dart';

void main() {
  test('beütésszám: neutronnál n-előtag, az alapegység beütés/s', () {
    expect(CountRateOption.forRadiation(neutron: false).map((o) => o.symbol),
        ['cps', 'kcps', 'cpm', 'cph']);
    expect(CountRateOption.forRadiation(neutron: true).map((o) => o.symbol),
        ['ncps', 'nkcps', 'ncpm', 'ncph']);
    expect(CountRateOption.fromSymbol('ncpm')!.neutron, isTrue);
    expect(CountRateOption.fromSymbol('ncpm')!.baseFactor, closeTo(1 / 60, 1e-12));
    expect(CountRateOption.fromSymbol('kcps')!.baseFactor, 1000);
    expect(CountRateOption.fromSymbol('xyz'), isNull);
  });

  test('régi típusnevek: cps és neutron_cps a beütésszám típus', () {
    expect(MeasurementTypeX.fromDbValue('cps'), MeasurementType.countRate);
    expect(MeasurementTypeX.fromDbValue('neutron_cps'), MeasurementType.countRate);
    expect(MeasurementTypeX.legacyRadiationKind('neutron_cps'), RadiationKind.neutron);
    expect(MeasurementTypeX.legacyRadiationKind('cps'), isNull);
  });

  test('sugárzás: alapértelmezés gamma', () {
    expect(RadiationKind.fromDbValue(null), RadiationKind.gamma);
    expect(RadiationKind.fromDbValue('neutron'), RadiationKind.neutron);
  });

  test("mennyiség: Hp(d) és H'(d,Ω) mélységei; K nem dózisegyenérték", () {
    expect(DoseQuantity.fromDbValue(null), DoseQuantity.h10);
    expect(DoseQuantity.hp.depthOptionsMm, [10, 3, 0.07]);
    expect(DoseQuantity.hp.defaultDepthMm, 10);
    expect(DoseQuantity.hprime.depthOptionsMm, [3, 0.07]);
    expect(DoseQuantity.h10.depthOptionsMm, isEmpty);
    expect(DoseQuantity.kerma.isDoseEquivalent, isFalse);
    expect(DoseQuantity.h10.isDoseEquivalent, isTrue);
  });

  test('K egység: Gy/h család, alapegység µGy/h', () {
    expect(KermaRateUnit.fromSymbol('mGy/h').baseFactor, 1000);
    expect(KermaRateUnit.fromSymbol('ismeretlen'), KermaRateUnit.defaultUnit);
  });
}
