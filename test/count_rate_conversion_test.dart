import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/instrument.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/models/radiation_kind.dart';
import 'package:rad_recon/services/dose_unit_converter.dart';

void main() {
  test('kcps-ben érkező műszer-érték cps-re váltódik', () {
    const i = Instrument(
      name: 'x',
      modbusMeasurementType: MeasurementType.countRate,
      modbusUnit: 'kcps',
    );
    expect(instrumentReadingInAppUnit(i, 2), closeTo(2000, 1e-9));
  });

  test('az ncps-es műszer neutron, a cpm-es gamma', () {
    const n = Instrument(
      name: 'x',
      modbusMeasurementType: MeasurementType.countRate,
      modbusUnit: 'ncps',
    );
    const g = Instrument(
      name: 'y',
      modbusMeasurementType: MeasurementType.countRate,
      modbusUnit: 'cpm',
    );
    expect(radiationForInstrument(n), RadiationKind.neutron);
    expect(radiationForInstrument(g), RadiationKind.gamma);
  });
}
