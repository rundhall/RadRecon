/// Honnan kapja az automatikus mérés a pozíciót egy műszerhez.
enum AutoLogPositionSource {
  /// A telefon GPS-e.
  phone('phone'),

  /// Fix, előre megadott koordináta.
  fixed('fixed'),

  /// A műszer Modbus-GPS regiszterei.
  modbus('modbus');

  const AutoLogPositionSource(this.dbValue);

  final String dbValue;

  static AutoLogPositionSource fromDb(Object? value) {
    for (final s in values) {
      if (s.dbValue == value) return s;
    }
    return AutoLogPositionSource.phone;
  }
}
