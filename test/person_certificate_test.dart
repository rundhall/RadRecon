import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/person.dart';
import 'package:rad_recon/models/person_certificate.dart';

void main() {
  final now = DateTime(2026, 10, 16);
  Person person(List<PersonCertificate> c) => Person(
        name: 'Teszt',
        certificates: c,
        createdAt: now,
        updatedAt: now,
      );

  test('lejárt bizonyítvány a személyt lejártnak jelöli', () {
    final p = person([
      PersonCertificate(name: 'Vizsga', validUntil: DateTime(2026, 1, 1)),
    ]);
    expect(p.isExpiredAt(now), isTrue);
  });

  test('lejárat nélküli vagy érvényes bizonyítvány nem jelöl lejártnak', () {
    final p = person([
      const PersonCertificate(name: 'Örökös'),
      PersonCertificate(name: 'Érvényes', validUntil: DateTime(2027, 1, 1)),
    ]);
    expect(p.isExpiredAt(now), isFalse);
  });

  test('toMap / fromMap körút', () {
    final c = PersonCertificate(
      name: 'Kezelői',
      number: '12',
      validUntil: DateTime(2027, 5, 1),
    );
    final back = PersonCertificate.fromMap(c.toMap());
    expect(back.name, 'Kezelői');
    expect(back.validUntil, DateTime(2027, 5, 1));
  });
}
