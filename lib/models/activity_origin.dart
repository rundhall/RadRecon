/// Az aktivitás eredete egy nuklid-soron. Az adatbázisban az enum-elem
/// neve tárolódik.
enum ActivityOrigin {
  /// Dózisteljesítmény-mérésből, árnyékolás nélkül (alsó becslés).
  measurement,

  /// Dózisteljesítmény-mérésből, megadott árnyékolással korrigálva.
  shieldedMeasurement,

  /// Spektrum-kiértékelésből.
  spectrum,

  /// Kézzel megadott vagy gyártói adat.
  manual,
}
