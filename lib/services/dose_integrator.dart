import 'dose_unit_converter.dart';

/// Dózisteljesítmény-mintákból dózist integrál az eltelt idő szerint
/// (trapézszabály a két egymást követő sikeres olvasás között).
///
/// Tisztán számítási osztály (nincs benne I/O), hogy külön tesztelhető legyen.
/// A mintavételi kiesések (sikertelen olvasások) hosszú szakaszát a két
/// szomszédos sikeres minta közötti lineáris interpolációval töltjük fel;
/// a [gapThreshold]-nál hosszabb réseket külön számoljuk ([gapCount]), hogy
/// a felhasználó láthassa, mennyire hézagos a mérés.
class DoseIntegrator {
  DoseIntegrator({this.gapThreshold = const Duration(seconds: 30)});

  final Duration gapThreshold;

  double _doseMicroSv = 0;
  double? _lastRateUsvPerHour;
  DateTime? _lastTime;
  int _gapCount = 0;
  int _sampleCount = 0;

  /// Eddig összegzett dózis µSv-ben.
  double get doseMicroSv => _doseMicroSv;
  int get gapCount => _gapCount;
  int get sampleCount => _sampleCount;
  bool get hasData => _sampleCount > 1;

  /// Egy sikeres olvasás. A [value] a műszer [unit] egységében van; ha az
  /// egység nem ismert (nem dózisteljesítmény), a minta figyelmen kívül marad
  /// és `false`-t adunk vissza.
  bool addSample(double value, String unit, DateTime time) {
    final rate = toMicroSievertPerHour(value, unit);
    if (rate == null) return false;

    final lastTime = _lastTime;
    final lastRate = _lastRateUsvPerHour;
    if (lastTime != null && lastRate != null) {
      final dt = time.difference(lastTime);
      if (!dt.isNegative) {
        if (dt > gapThreshold) _gapCount++;
        final hours = dt.inMicroseconds / Duration.microsecondsPerHour;
        _doseMicroSv += (lastRate + rate) / 2 * hours;
      }
    }
    _lastTime = time;
    _lastRateUsvPerHour = rate;
    _sampleCount++;
    return true;
  }

  void reset() {
    _doseMicroSv = 0;
    _lastRateUsvPerHour = null;
    _lastTime = null;
    _gapCount = 0;
    _sampleCount = 0;
  }
}
