import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/measurement_type.dart';
import 'package:rad_recon/services/protocol_export_service.dart';

void main() {
  test('minden mérés-típusnak van jegyzőkönyv-címke, ami nem az enum-név', () {
    for (final t in MeasurementType.values) {
      final label = ProtocolExportService.measurementTypeHu[t];
      expect(label, isNotNull, reason: '${t.name} nincs a térképben');
      expect(label, isNot(t.name));
    }
  });
}
