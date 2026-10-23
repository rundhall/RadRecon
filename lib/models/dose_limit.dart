import '../services/regulatory_profile.dart';

/// Kire vonatkozik az éves dózis-keret.
enum DoseLimitCategory { occupational, public }

/// Az éves effektív dózis határértéke (mSv).
///
/// Forrás: 2/2022. (IV. 29.) OAH rendelet, 12. § (2): foglalkozásszerűen
/// sugárnak kitett személy 20 mSv/év; 16. § (1): lakosság 1 mSv/év.
/// Az IAEA GSR Part 3 ugyanezeket az értékeket adja. A profil a hivatkozott
/// forrást jelzi; ha a két profil eltérő számot kapna, itt kell módosítani.
/// A szem-lencse és a bőr határai nincsenek figyelembe véve.
double annualLimitMsv(RegulatoryProfile profile, DoseLimitCategory category) {
  return switch (profile) {
    RegulatoryProfile.hungary || RegulatoryProfile.international =>
      switch (category) {
        DoseLimitCategory.occupational => 20.0,
        DoseLimitCategory.public => 1.0,
      },
  };
}

/// A határ kihasználtságának szintje.
enum DoseLimitStatus { ok, warning, exceeded }

/// Az éves figyelmeztetési szint a határ hányadában (50%).
const double kDoseLimitWarningFraction = 0.5;

DoseLimitStatus doseLimitStatus(double usedMsv, double limitMsv) {
  final ratio = usedMsv / limitMsv;
  if (ratio >= 1) return DoseLimitStatus.exceeded;
  if (ratio >= kDoseLimitWarningFraction) return DoseLimitStatus.warning;
  return DoseLimitStatus.ok;
}
