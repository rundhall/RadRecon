import '../l10n/app_localizations.dart';
import 'shielding.dart';

String shieldingMaterialLabel(AppLocalizations loc, ShieldingMaterial m) {
  switch (m) {
    case ShieldingMaterial.lead:
      return loc.shieldingMaterialLead;
    case ShieldingMaterial.steel:
      return loc.shieldingMaterialSteel;
    case ShieldingMaterial.concrete:
      return loc.shieldingMaterialConcrete;
    case ShieldingMaterial.tungsten:
      return loc.shieldingMaterialTungsten;
    case ShieldingMaterial.aluminium:
      return loc.shieldingMaterialAluminium;
    case ShieldingMaterial.water:
      return loc.shieldingMaterialWater;
  }
}
