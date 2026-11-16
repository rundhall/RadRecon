/// Fájlnévbe írható név: az ékezetes magyar betűk ékezet nélküli párjukra
/// cserélődnek (é→e, ő→o stb.), a nem [A-Za-z0-9_-] karakterek egymás melletti
/// sorozata pedig egyetlen `_`.
String safeFileName(String input) {
  const from = 'áéíóöőúüűÁÉÍÓÖŐÚÜŰ';
  const to = 'aeiooouuuAEIOOOUUU';
  final ascii = input.split('').map((c) {
    final i = from.indexOf(c);
    return i >= 0 ? to[i] : c;
  }).join();
  return ascii.replaceAll(RegExp(r'[^\w\-]+'), '_');
}
