import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/l10n/app_localizations.dart';
import 'package:rad_recon/l10n/domain_labels.dart';
import 'package:rad_recon/models/measurement_type.dart';

void main() {
  test('minden mérés-típusnak van jegyzőkönyv-címke, ami nem az enum-név', () {
    final loc = lookupAppLocalizations(const Locale('hu'));
    for (final t in MeasurementType.values) {
      final label = t.localized(loc);
      expect(label, isNotEmpty, reason: '${t.name} nincs fordítva');
      expect(label, isNot(t.name));
    }
  });
}
