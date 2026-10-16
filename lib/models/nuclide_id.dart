import '../l10n/app_localizations.dart';

/// Egy mérési ponthoz megadott nuklid-azonosítás állapota.
///
/// - [notSpecified]: nem történt azonosítás / nincs megadva (alapértelmezett)
/// - [identified]: azonosított nuklid(ok) a listából (azonosító műszer vagy
///   kézi megadás alapján)
/// - [unknown]: a forrás nuklidja ismeretlen
/// - [other]: ismert nuklid, de nem szerepel a listában (név szabadon)
/// - [mixture]: feltételezhetően több forrás (keverék)
enum NuclideIdStatus {
  notSpecified('none'),
  identified('identified'),
  unknown('unknown'),
  other('other'),
  mixture('mixture');

  const NuclideIdStatus(this.dbValue);

  /// Adatbázisban/exportban tárolt stabil azonosító (ne változtasd meg).
  final String dbValue;

  /// Van-e értelme nuklid-névlistának ennél az állapotnál.
  bool get hasNuclideList =>
      this == identified || this == other || this == mixture;

  static NuclideIdStatus fromDb(Object? value) => NuclideIdStatus.values
      .firstWhere((s) => s.dbValue == value, orElse: () => notSpecified);

  String label(AppLocalizations loc) {
    switch (this) {
      case NuclideIdStatus.notSpecified:
        return loc.nuclideStatusNone;
      case NuclideIdStatus.identified:
        return loc.nuclideStatusIdentified;
      case NuclideIdStatus.unknown:
        return loc.nuclideStatusUnknown;
      case NuclideIdStatus.other:
        return loc.nuclideStatusOther;
      case NuclideIdStatus.mixture:
        return loc.nuclideStatusMixture;
    }
  }
}

/// Rövid, olvasható összefoglaló (CSV-hez, jegyzőkönyvhöz, felugró infóhoz):
/// pl. "Azonosított nuklid(ok): Cs-137, Co-60".
/// Üres szöveg, ha nincs megadva azonosítás.
String nuclideSummaryText({
  required NuclideIdStatus status,
  required List<String> nuclides,
  required String Function(NuclideIdStatus) statusLabel,
}) {
  if (status == NuclideIdStatus.notSpecified) return '';
  final buffer = StringBuffer(statusLabel(status));
  if (status.hasNuclideList && nuclides.isNotEmpty) {
    buffer.write(': ${nuclides.join(', ')}');
  }
  return buffer.toString();
}

/// Azonosításnál választható nuklidok: az app ismert izotópjai (ezekre van
/// számítás is) kiegészítve néhány gyakori nuklid nevével. Ami nincs a
/// listában, az "Egyéb" állapottal szabadon megadható.
const List<String> kIdentifiableNuclideNames = [
  'Am-241',
  'Ba-133',
  'Co-57',
  'Co-60',
  'Cs-137',
  'Eu-152',
  'I-131',
  'Ir-192',
  'K-40',
  'Na-22',
  'Pu-239',
  'Ra-226',
  'Se-75',
  'Sr-90',
  'Tc-99m',
  'Th-232',
  'U-235',
  'U-238',
];
