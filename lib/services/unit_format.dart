import 'dose_unit_controller.dart';

/// Megjelenítési segédek: az adatbázisban tárolt alapegységű értékeket
/// (µSv/h, MBq, m) az aktuálisan választott alapegységben írják ki.

String _fmt(double v) {
  if (v.abs() >= 1000 || (v != 0 && v.abs() < 0.01)) {
    return v.toStringAsExponential(3);
  }
  return v.toStringAsFixed(3);
}

String formatDoseRateUSvH(double microSvPerHour) {
  final u = DoseUnitController.current;
  return '${_fmt(u.fromMicroSvPerHour(microSvPerHour))} ${u.symbol}';
}

/// Csak a szám (egység nélkül), a hibasáv kiírásához.
String formatActivityNumberMBq(double mbq) =>
    _fmt(ActivityUnitController.current.fromMBq(mbq));

String formatActivityMBq(double mbq) =>
    '${formatActivityNumberMBq(mbq)} ${ActivityUnitController.current.symbol}';

String formatDistanceMeters(double meters) {
  final u = DistanceUnitController.current;
  final v = double.parse(u.fromMeters(meters).toStringAsFixed(2));
  return '$v ${u.symbol}';
}
