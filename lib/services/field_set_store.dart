import 'package:shared_preferences/shared_preferences.dart';

/// Egy képernyő megjelenítendő mezőkészletének mentése ezen az eszközön
/// (SharedPreferences). Ismeretlen mentett nevet figyelmen kívül hagy.
class FieldSetStore<T extends Enum> {
  const FieldSetStore({
    required this.key,
    required this.values,
    required this.defaults,
  });

  final String key;
  final List<T> values;
  final Set<T> defaults;

  Future<Set<T>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key);
    if (raw == null) return <T>{...defaults};
    return values.where((f) => raw.contains(f.name)).toSet();
  }

  Future<void> save(Set<T> fields) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, [
      for (final f in values)
        if (fields.contains(f)) f.name,
    ]);
  }
}
