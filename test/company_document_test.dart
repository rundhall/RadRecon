import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/company_document.dart';

void main() {
  test('toMap / fromMap körút fájlokkal és lejárattal', () {
    final d = CompanyDocument(
      title: 'Fizikai Védelmi Terv',
      identifier: 'FVT-1',
      validUntil: DateTime(2027, 3, 1),
      filePaths: const ['/a/b.pdf', '/a/c.pdf'],
    );
    final back = CompanyDocument.fromMap(d.toMap());
    expect(back.title, 'Fizikai Védelmi Terv');
    expect(back.validUntil, DateTime(2027, 3, 1));
    expect(back.filePaths, ['/a/b.pdf', '/a/c.pdf']);
  });

  test('fájl nélkül üres lista', () {
    final back = CompanyDocument.fromMap(
        const CompanyDocument(title: 'X').toMap());
    expect(back.filePaths, isEmpty);
  });
}
