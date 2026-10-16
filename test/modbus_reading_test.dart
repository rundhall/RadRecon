import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/instrument.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/models/modbus_reading.dart';
import 'package:rad_recon/services/dose_unit_converter.dart';

void main() {
  test('régi műszerek alapértelmezése: dózisteljesítmény, nSv/h', () {
    const i = Instrument(name: 'x');
    expect(i.modbusMeasurementType, MeasurementType.doseRate);
    expect(i.modbusUnit, 'nSv/h');
    final restored = Instrument.fromMap({'name': 'x'});
    expect(restored.modbusMeasurementType, MeasurementType.doseRate);
    expect(restored.modbusUnit, 'nSv/h');
  });

  test('a mért mennyiség és az egység megmarad mentés után', () {
    const i = Instrument(
      name: 'x',
      modbusMeasurementType: MeasurementType.neutronCps,
      modbusUnit: 'cps',
    );
    final back = Instrument.fromMap(i.toMap());
    expect(back.modbusMeasurementType, MeasurementType.neutronCps);
    expect(back.modbusUnit, 'cps');
  });

  test('nem dózisteljesítménynél nincs átváltás', () {
    const i = Instrument(
      name: 'x',
      modbusMeasurementType: MeasurementType.cps,
      modbusUnit: 'cps',
    );
    expect(instrumentReadingInAppUnit(i, 123), 123);
  });

  test('regiszter-egységek', () {
    expect(modbusUnitsFor(MeasurementType.surfaceContamination), ['Bq/cm²']);
    expect(modbusUnitsFor(MeasurementType.cps), ['cps']);
    expect(modbusUnitsFor(MeasurementType.doseRate), contains('µR/h'));
    expect(defaultModbusUnitFor(MeasurementType.doseRate), 'nSv/h');
  });
}
