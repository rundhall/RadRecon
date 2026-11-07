import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/models/modbus_reading.dart';
import 'package:rad_recon/models/radiation_kind.dart';
import 'package:rad_recon/services/dose_unit_converter.dart';

void main() {
  test('kcps-ben érkező műszer-érték cps-re váltódik', () {
    const ch = ModbusChannel(
      type: MeasurementType.countRate,
      address: 0,
      unit: 'kcps',
    );
    expect(channelReadingInAppUnit(ch, 2), closeTo(2000, 1e-9));
  });

  test('az ncps-es műszer neutron, a cpm-es gamma', () {
    const n = ModbusChannel(
      type: MeasurementType.countRate,
      address: 0,
      unit: 'ncps',
    );
    const g = ModbusChannel(
      type: MeasurementType.countRate,
      address: 0,
      unit: 'cpm',
    );
    expect(radiationForChannel(n), RadiationKind.neutron);
    expect(radiationForChannel(g), RadiationKind.gamma);
  });
}
