import 'quantity_unit.dart';

/// A választható dózisteljesítmény-egységek. Szándékosan zárt lista: a
/// felhasználó nem gépel mértékegységet, így az átváltás nem rontható el.
///
/// Az alapegység a µSv/h. A röntgen/rem alapú egységek a sugárvédelemben
/// szokásos közelítéssel váltódnak át: 1 rem = 0,01 Sv (pontos), és gamma-
/// sugárzásra 1 R ≈ 0,01 Sv (közelítés, ezért az R/h értékek tájékoztató
/// jellegűek).
enum DoseRateUnit implements QuantityUnit {
  nSvH('nSv/h', 'nsv_h', 0.001),
  uSvH('µSv/h', 'usv_h', 1),
  mSvH('mSv/h', 'msv_h', 1000),
  svH('Sv/h', 'sv_h', 1000000),
  uRH('µR/h', 'ur_h', 0.01),
  mRH('mR/h', 'mr_h', 10),
  rH('R/h', 'r_h', 10000),
  uRemH('µrem/h', 'urem_h', 0.01),
  mRemH('mrem/h', 'mrem_h', 10),
  remH('rem/h', 'rem_h', 10000);

  const DoseRateUnit(this.symbol, this.storageValue, this.microSvPerHourFactor);

  @override
  final String symbol;
  final String storageValue;

  /// Hány µSv/h egy ilyen egység.
  final double microSvPerHourFactor;

  @override
  double get baseFactor => microSvPerHourFactor;

  /// Az app alapértelmezett egysége, ha a felhasználó nem választott mást.
  static const defaultUnit = DoseRateUnit.uSvH;

  /// A Modbus-műszerek nyers értékét az app eddig is nSv/h-nak tekintette.
  static const instrumentNative = DoseRateUnit.nSvH;

  double toMicroSvPerHour(double value) => value * microSvPerHourFactor;
  double fromMicroSvPerHour(double microSvPerHour) =>
      microSvPerHour / microSvPerHourFactor;

  /// Átváltás másik egységre.
  double convertTo(DoseRateUnit target, double value) =>
      target.fromMicroSvPerHour(toMicroSvPerHour(value));

  static DoseRateUnit fromStorage(String? value) => DoseRateUnit.values
      .firstWhere((u) => u.storageValue == value, orElse: () => defaultUnit);

  /// Szöveges egységből (pl. régi mentésekből). Ismeretlenre `null`.
  static DoseRateUnit? fromSymbol(String? symbol) {
    if (symbol == null) return null;
    var s = symbol.trim().toLowerCase().replaceAll('μ', 'µ');
    if (s.startsWith('u')) s = 'µ${s.substring(1)}'; // "usv/h" -> "µsv/h"
    for (final u in DoseRateUnit.values) {
      if (u.symbol.toLowerCase() == s) return u;
    }
    return null;
  }
}
