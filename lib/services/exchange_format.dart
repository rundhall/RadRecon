/// Export-formátumok verziói.
///
/// JSON: a régi import csak a `format` mezőt ellenőrzi, a `version`-t nem.
/// Ezért az újabb formátum saját azonosítót kap. Különben a régi app csendben
/// kihagyná a forrásokat és a hozzájuk kötött hivatkozásokat.
///
/// CSV: az újabb fájlban van `format_version` oszlop, és nincs `nuclide_name`
/// oszlop. A régi import a hiányzó oszlopnál hibával áll meg.
class ExchangeFormat {
  ExchangeFormat._();

  static const jsonV1Id = 'rad_recon_export';
  static const jsonV2Id = 'rad_recon_export.v2';
  static const jsonV3Id = 'rad_recon_export.v3';
  static const jsonCurrentId = jsonV3Id;
  static const jsonCurrentVersion = 3;

  static const csvCurrentVersion = 2;
  static const csvVersionColumn = 'format_version';

  /// A JSON-fájl verziója a `format` azonosító alapján. Null, ha nem
  /// RadRecon-export.
  static int? jsonVersion(String? formatId) {
    if (formatId == jsonV1Id) return 1;
    if (formatId == jsonV2Id) return 2;
    if (formatId == jsonV3Id) return 3;
    return null;
  }

  /// A CSV `format_version` értékének ellenőrzése. Újabb verziónál hibát dob.
  static int checkCsvVersion(String? raw) {
    final version = int.tryParse(raw?.trim() ?? '');
    if (version == null || version < 1) {
      throw const FormatException('Hibás format_version a CSV-ben.');
    }
    if (version > csvCurrentVersion) {
      throw const FormatException(
        'Ez a CSV újabb RadRecon verzióval készült. Frissítsd az appot.',
      );
    }
    return version;
  }

  /// Azonos azonosítójú sorok csoportosítása. A csoportok sorrendje megmarad.
  static Map<String, List<Map<String, String>>> groupRowsByIdentifier(
    List<Map<String, String>> rows,
  ) {
    final groups = <String, List<Map<String, String>>>{};
    for (final row in rows) {
      final identifier = (row['identifier'] ?? '').trim();
      groups.putIfAbsent(identifier, () => []).add(row);
    }
    return groups;
  }
}
