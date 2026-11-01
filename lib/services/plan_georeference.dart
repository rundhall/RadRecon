import 'dart:math' as math;

import '../models/plan_calibration.dart';

/// Közelítő Föld-sugár (méter). Kis területen (telephely, épület) a helyi,
/// egyenlítői vetítés hibája elhanyagolható.
const double _earthRadiusM = 6371000.0;

const double _radToDeg = 180.0 / math.pi;
const double _degToRad = math.pi / 180.0;

/// A kalibrált alaprajz pixel ↔ (szélesség, hosszúság) leképezése.
///
/// Az alaprajz nincs elforgatva: a vízszintes tengely keletre, a függőleges
/// délre mutat, a bal felső sarok a [PlanCalibration] origója. Mivel a
/// pontok koordinátát kapnak, a meglévő lat/lon-alapú számítások (távolság,
/// térkép, export) az alaprajzon kijelölt pontokra is változatlanul működnek.
class PlanGeoref {
  final PlanCalibration calibration;

  const PlanGeoref(this.calibration);

  /// Pixel (x jobbra, y lefelé) → (szélesség, hosszúság).
  ({double lat, double lon}) pixelToLatLon(double x, double y) {
    final c = calibration;
    final lat = c.originLat - (y * c.metersPerPx) / _earthRadiusM * _radToDeg;
    final lon = c.originLon +
        (x * c.metersPerPx) /
            (_earthRadiusM * math.cos(c.originLat * _degToRad)) *
            _radToDeg;
    return (lat: lat, lon: lon);
  }

  /// (szélesség, hosszúság) → pixel. A kép határain kívüli pont is
  /// kiszámolható (negatív, illetve a méretnél nagyobb koordináta).
  ({double x, double y}) latLonToPixel(double lat, double lon) {
    final c = calibration;
    final y = (c.originLat - lat) * _degToRad * _earthRadiusM / c.metersPerPx;
    final x = (lon - c.originLon) *
        _degToRad *
        _earthRadiusM *
        math.cos(c.originLat * _degToRad) /
        c.metersPerPx;
    return (x: x, y: y);
  }

  /// Az alaprajz földrajzi határa az overlayhez (dél, nyugat, észak, kelet).
  ({double south, double west, double north, double east}) get bounds {
    final c = calibration;
    final corner = pixelToLatLon(c.widthPx.toDouble(), c.heightPx.toDouble());
    return (
      south: corner.lat,
      west: c.originLon,
      north: c.originLat,
      east: corner.lon,
    );
  }

  /// A kép közepe (kezdő kamera- és pickerpozíció).
  ({double lat, double lon}) get centre => pixelToLatLon(
        calibration.widthPx / 2,
        calibration.heightPx / 2,
      );
}

/// Méter/pixel arány két megjelölt pont és a közöttük mért valós távolság alapján.
double metersPerPixelFromCalibration({
  required double pixelDistance,
  required double realMeters,
}) {
  if (pixelDistance <= 0) {
    throw ArgumentError.value(pixelDistance, 'pixelDistance', 'must be > 0');
  }
  if (realMeters <= 0) {
    throw ArgumentError.value(realMeters, 'realMeters', 'must be > 0');
  }
  return realMeters / pixelDistance;
}

/// Két pixelpont távolsága pixelben.
double pixelDistance(double x1, double y1, double x2, double y2) =>
    math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));

/// A bal felső sarok (origó) koordinátája egy horgonypontból: a horgony
/// pixelkoordinátája és a hozzá mért GPS-koordináta alapján.
({double lat, double lon}) originFromAnchor({
  required double anchorX,
  required double anchorY,
  required double anchorLat,
  required double anchorLon,
  required double metersPerPx,
}) {
  final lat = anchorLat + (anchorY * metersPerPx) / _earthRadiusM * _radToDeg;
  final lon = anchorLon -
      (anchorX * metersPerPx) /
          (_earthRadiusM * math.cos(anchorLat * _degToRad)) *
          _radToDeg;
  return (lat: lat, lon: lon);
}

/// Generált háttér geometriája: a méretarány legalább 0,05 m/px, a kép
/// oldalhossza legfeljebb 2000 px. A pixelméret és a méretarány együtt adja
/// a valós méretet, így a generált lap is kalibrálható.
({double metersPerPx, int widthPx, int heightPx}) blankPlanGeometry({
  required double widthM,
  required double heightM,
}) {
  if (widthM <= 0 || heightM <= 0) {
    throw ArgumentError('A méretnek pozitívnak kell lennie.');
  }
  const minMetersPerPx = 0.05;
  const maxSidePx = 2000;
  final mpp = math.max(minMetersPerPx, math.max(widthM, heightM) / maxSidePx);
  return (
    metersPerPx: mpp,
    widthPx: math.max(1, (widthM / mpp).round()),
    heightPx: math.max(1, (heightM / mpp).round()),
  );
}

/// Helyi koordinátarendszer origója (GPS nélküli alaprajz): a fix (0, 0) pont.
const double localPlanOriginLat = 0.0;
const double localPlanOriginLon = 0.0;

/// Helyi koordináta méterben: X jobbra, Y lefelé, a kép bal felső sarkától.
({double x, double y}) planLocalMetres(
  PlanCalibration calibration,
  double lat,
  double lon,
) {
  final px = PlanGeoref(calibration).latLonToPixel(lat, lon);
  return (
    x: px.x * calibration.metersPerPx,
    y: px.y * calibration.metersPerPx,
  );
}
