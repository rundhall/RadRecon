import 'dart:convert';

/// Egy céghez tartozó dokumentum vagy engedély (pl. Munkahelyi
/// Sugárvédelmi Szabályzat, Fizikai Védelmi Terv) azonosítóval, lejárattal
/// és csatolt fájlokkal.
class CompanyDocument {
  final int? id;
  final String title;
  final String? identifier; // iktatószám / engedélyszám
  final String? issuer; // kiadó / hatóság
  final DateTime? issuedOn;
  final DateTime? validUntil; // érvényesség vége / következő felülvizsgálat
  final String? notes;
  final List<String> filePaths;

  const CompanyDocument({
    this.id,
    required this.title,
    this.identifier,
    this.issuer,
    this.issuedOn,
    this.validUntil,
    this.notes,
    this.filePaths = const [],
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'identifier': identifier,
        'issuer': issuer,
        'issued_on': issuedOn?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'notes': notes,
        'files': filePaths.isEmpty ? null : jsonEncode(filePaths),
      };

  factory CompanyDocument.fromMap(Map<String, Object?> m) {
    DateTime? d(Object? v) => v == null ? null : DateTime.tryParse('$v');
    var files = <String>[];
    final raw = m['files'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) files = decoded.whereType<String>().toList();
      } catch (_) {}
    }
    return CompanyDocument(
      id: m['id'] as int?,
      title: m['title'] as String,
      identifier: m['identifier'] as String?,
      issuer: m['issuer'] as String?,
      issuedOn: d(m['issued_on']),
      validUntil: d(m['valid_until']),
      notes: m['notes'] as String?,
      filePaths: files,
    );
  }
}
