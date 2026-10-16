/// Egy személyhez rendelt bizonyítvány (pl. sugárvédelmi vizsga, orvosi
/// alkalmasság, kezelői engedély) — tetszőleges megnevezéssel, lejárattal.
class PersonCertificate {
  final int? id;
  final int? personId;
  final String name;
  final String? number;
  final String? issuer;
  final DateTime? issuedOn;
  final DateTime? validUntil;
  final String? filePath;

  const PersonCertificate({
    this.id,
    this.personId,
    required this.name,
    this.number,
    this.issuer,
    this.issuedOn,
    this.validUntil,
    this.filePath,
  });

  bool isExpiredAt(DateTime asOf) =>
      validUntil != null && validUntil!.isBefore(asOf);

  PersonCertificate withPersonId(int personId) => PersonCertificate(
        id: id,
        personId: personId,
        name: name,
        number: number,
        issuer: issuer,
        issuedOn: issuedOn,
        validUntil: validUntil,
        filePath: filePath,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'person_id': personId,
        'name': name,
        'number': number,
        'issuer': issuer,
        'issued_on': issuedOn?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'file_path': filePath,
      };

  factory PersonCertificate.fromMap(Map<String, Object?> m) {
    DateTime? d(Object? v) => v == null ? null : DateTime.tryParse('$v');
    return PersonCertificate(
      id: m['id'] as int?,
      personId: m['person_id'] as int?,
      name: m['name'] as String,
      number: m['number'] as String?,
      issuer: m['issuer'] as String?,
      issuedOn: d(m['issued_on']),
      validUntil: d(m['valid_until']),
      filePath: m['file_path'] as String?,
    );
  }
}
