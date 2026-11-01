/// Egy felmérés kalibrált alaprajza: a másolt kép és a pixel ↔ koordináta
/// leképezés paraméterei (lásd [PlanGeoref]).
class PlanCalibration {
  final String imagePath; // a másolt alaprajz az app dokumentum-mappájában
  final int widthPx;
  final int heightPx;
  final double originLat; // a kép bal felső sarkának szélessége
  final double originLon; // a kép bal felső sarkának hosszúsága
  final double metersPerPx;
  /// Helyi koordináta: nincs valódi GPS-horgony, a pontok az alaprajzon belüli
  /// méterben (X/Y) értelmezendők. Ilyenkor az origó a fix (0, 0) pont.
  final bool localCoordinates;

  const PlanCalibration({
    required this.imagePath,
    required this.widthPx,
    required this.heightPx,
    required this.originLat,
    required this.originLon,
    required this.metersPerPx,
    this.localCoordinates = false,
  });
}
