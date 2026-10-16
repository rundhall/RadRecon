import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Melyik ország szabályozása szerint jelenjenek meg a besorolások.
/// A nemzetközi profil csak az IAEA-alapú számokat (D, R, 1–5. fizikai
/// védelmi kategória, mentességi értékek) mutatja; a magyar profil ezen felül
/// a 2/2022. (IV. 29.) OAH rendelet szerinti I./II./III. sugárvédelmi
/// kategóriát is.
enum RegulatoryProfile {
  international,
  hungary;

  static RegulatoryProfile fromStorage(String? v) => RegulatoryProfile.values
      .firstWhere((e) => e.name == v, orElse: () => RegulatoryProfile.international);
}

class RegulatoryProfileController {
  RegulatoryProfileController._();

  static const _key = 'regulatory_profile';

  static final ValueNotifier<RegulatoryProfile> profile =
      ValueNotifier<RegulatoryProfile>(RegulatoryProfile.international);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    profile.value = RegulatoryProfile.fromStorage(prefs.getString(_key));
  }

  static Future<void> setProfile(RegulatoryProfile value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
    profile.value = value;
  }
}
