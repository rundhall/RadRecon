/// Keresési szöveg normalizálása: kis- és nagybetű, szóköz, kötőjel és pont
/// nélkül, így a "Cs-137", a "cs137" és a "CS 137" ugyanaz.
String normalizeSearchText(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[\s\-_.–]'), '');

/// Igaz, ha a forrás azonosítója vagy valamelyik nuklidja tartalmazza a keresőszöveget.
/// Üres keresésnél minden forrás megfelel.
bool sourceMatchesQuery({
  required String identifier,
  required Iterable<String> nuclides,
  required String query,
}) {
  final q = normalizeSearchText(query);
  if (q.isEmpty) return true;
  if (normalizeSearchText(identifier).contains(q)) return true;
  for (final n in nuclides) {
    if (normalizeSearchText(n).contains(q)) return true;
  }
  return false;
}
