/// Dózisteljesítmény-egységek átalakítása közös alapra (µSv/h), hogy a mért
/// és a számított érték összevethető legyen — az app maga nem konvertál
/// típusok/egységek között máshol, de az összehasonlításhoz szükséges.
///
/// Ismeretlen/nem felismert egységnél `null`-t ad vissza, ekkor az
/// összehasonlítás nem végezhető el.
double? toMicroSievertPerHour(double value, String unit) {
  final normalized = unit
      .trim()
      .toLowerCase()
      .replaceAll('μ', 'µ') // görög mű vs. mikro jel
      .replaceAll('us', 'µs');

  switch (normalized) {
    case 'nsv/h':
      return value / 1000;
    case 'µsv/h':
      return value;
    case 'msv/h':
      return value * 1000;
    case 'sv/h':
      return value * 1000000;
    default:
      return null;
  }
}
