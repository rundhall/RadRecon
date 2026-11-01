import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_concentration.dart';

/// Koncentráció-számításhoz alapértelmezett minta-egységek (tömeg, térfogat,
/// felület). A Beállításokban választhatók, kindenként külön.
class BasisUnitController {
  BasisUnitController._();

  static const _keyPrefix = 'basis_unit_';

  static final ValueNotifier<BasisUnit> _mass =
      ValueNotifier<BasisUnit>(BasisUnit.kilogram);
  static final ValueNotifier<BasisUnit> _volume =
      ValueNotifier<BasisUnit>(BasisUnit.litre);
  static final ValueNotifier<BasisUnit> _area =
      ValueNotifier<BasisUnit>(BasisUnit.squareMetre);

  static ValueNotifier<BasisUnit> notifierOf(BasisKind kind) => switch (kind) {
        BasisKind.mass => _mass,
        BasisKind.volume => _volume,
        BasisKind.area => _area,
      };

  static BasisUnit of(BasisKind kind) => notifierOf(kind).value;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final kind in BasisKind.values) {
      final stored =
          BasisUnit.fromSymbol(prefs.getString('$_keyPrefix${kind.name}'));
      if (stored != null && stored.kind == kind) {
        notifierOf(kind).value = stored;
      }
    }
  }

  static Future<void> setUnit(BasisUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${unit.kind.name}', unit.symbol);
    notifierOf(unit.kind).value = unit;
  }
}
