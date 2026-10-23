/// Tizedes szám beolvasása, ami a vesszőt (2,5) és a pontot (2.5) is elfogadja,
/// mert a felhasználók különböző országokban használják a két jelölést.
///
/// Ha mindkettő szerepel, az utolsó a tizedesjel, a másik ezres-elválasztó
/// (`1.234,5` és `1,234.5` is 1234.5). Szóközök (ezres-elválasztóként) törlődnek.
/// Csak vessző esetén tizedesvesszőnek tekintjük (`2,5` → 2.5); az `1,234`
/// így 1.234 lesz, ez egyértelműen nem oldható fel.
///
/// Nem szám, üres, nem véges (NaN, végtelen) bemenetre `null`.
double? parseDecimal(String raw) {
  var s = raw.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    s = lastComma > lastDot
        ? s.replaceAll('.', '').replaceAll(',', '.')
        : s.replaceAll(',', '');
  } else if (lastComma >= 0) {
    s = s.replaceAll(',', '.');
  }
  final v = double.tryParse(s);
  return (v == null || !v.isFinite) ? null : v;
}
