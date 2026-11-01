import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/export_archive_names.dart';

void main() {
  test('mentés-zip nevek felismerése', () {
    expect(isExportArchiveName('Default_20261101_1312.zip'), isTrue);
    expect(isExportArchiveName('Cég Kft_20261101_0005.zip'), isTrue);
  });

  test('más zipek és nevek nem egyeznek', () {
    expect(isExportArchiveName('Default.zip'), isFalse);
    expect(isExportArchiveName('Mérés_jegyzokonyv.zip'), isFalse);
    expect(isExportArchiveName('Default_20261101_1312.zip.part'), isFalse);
    expect(isExportArchiveName('Default_2026_1312.zip'), isFalse);
  });
}
