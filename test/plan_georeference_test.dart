import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/plan_calibration.dart';
import 'package:rad_recon/services/plan_georeference.dart';

// 1° hosszúság az egyenlítőn: 2πR/360 méter, R = 6371 km.
const double _metersPerDegreeAtEquator = 111194.9266;

PlanGeoref _georef({
  double originLat = 0,
  double originLon = 0,
  double mpp = 0.1,
  int w = 2000,
  int h = 1000,
}) =>
    PlanGeoref(PlanCalibration(
      imagePath: 'plan.png',
      widthPx: w,
      heightPx: h,
      originLat: originLat,
      originLon: originLon,
      metersPerPx: mpp,
    ));

void main() {
  test('az origó a bal felső sarok', () {
    final p = _georef(originLat: 47.5, originLon: 19.0).pixelToLatLon(0, 0);
    expect(p.lat, closeTo(47.5, 1e-12));
    expect(p.lon, closeTo(19.0, 1e-12));
  });

  test('1000 px = 100 m keletre az egyenlítőn', () {
    final p = _georef(mpp: 0.1).pixelToLatLon(1000, 0);
    expect(p.lon, closeTo(100 / _metersPerDegreeAtEquator, 1e-9));
    expect(p.lat, closeTo(0, 1e-12));
  });

  test('1000 px lefelé = 100 m délre', () {
    final p = _georef(mpp: 0.1).pixelToLatLon(0, 1000);
    expect(p.lat, closeTo(-100 / _metersPerDegreeAtEquator, 1e-9));
  });

  test('pixel → koordináta → pixel visszaadja az eredeti pontot', () {
    final g = _georef(originLat: 47.5, originLon: 19.0, mpp: 0.05);
    for (final (x, y) in [(0.0, 0.0), (123.5, 456.25), (1999.0, 999.0), (-40.0, 1200.0)]) {
      final ll = g.pixelToLatLon(x, y);
      final back = g.latLonToPixel(ll.lat, ll.lon);
      expect(back.x, closeTo(x, 1e-6));
      expect(back.y, closeTo(y, 1e-6));
    }
  });

  test('m/px kalibráció: 25 m 500 px-nek felel meg', () {
    expect(
      metersPerPixelFromCalibration(pixelDistance: 500, realMeters: 25),
      closeTo(0.05, 1e-12),
    );
    expect(pixelDistance(0, 0, 300, 400), closeTo(500, 1e-9));
  });

  test('nulla vagy negatív távolságot nem fogad el', () {
    expect(
      () => metersPerPixelFromCalibration(pixelDistance: 0, realMeters: 5),
      throwsArgumentError,
    );
    expect(
      () => metersPerPixelFromCalibration(pixelDistance: 10, realMeters: 0),
      throwsArgumentError,
    );
  });

  test('horgonypontból számolt origó visszaadja a horgonyt', () {
    final origin = originFromAnchor(
      anchorX: 400,
      anchorY: 300,
      anchorLat: 47.5,
      anchorLon: 19.0,
      metersPerPx: 0.05,
    );
    final g = PlanGeoref(PlanCalibration(
      imagePath: 'plan.png',
      widthPx: 1000,
      heightPx: 800,
      originLat: origin.lat,
      originLon: origin.lon,
      metersPerPx: 0.05,
    ));
    final back = g.pixelToLatLon(400, 300);
    expect(back.lat, closeTo(47.5, 1e-9));
    expect(back.lon, closeTo(19.0, 1e-7));
  });

  test('az overlay határa az origóval kezdődik és rendezett', () {
    final b = _georef(originLat: 47.5, originLon: 19.0).bounds;
    expect(b.north, closeTo(47.5, 1e-12));
    expect(b.west, closeTo(19.0, 1e-12));
    expect(b.south, lessThan(b.north));
    expect(b.east, greaterThan(b.west));
  });

  test('generált háttér: a pixelméret és a méretarány valós méretet ad', () {
    final g = blankPlanGeometry(widthM: 20, heightM: 10);
    expect(g.metersPerPx, closeTo(0.05, 1e-12));
    expect(g.widthPx, 400);
    expect(g.heightPx, 200);
  });

  test('generált háttér: nagy lap esetén a pixelméret 2000 px-ben marad', () {
    final g = blankPlanGeometry(widthM: 500, heightM: 100);
    expect(g.metersPerPx, closeTo(0.25, 1e-12));
    expect(g.widthPx, 2000);
    expect(g.heightPx, 400);
  });

  test('generált háttér: nem pozitív méret hibát ad', () {
    expect(() => blankPlanGeometry(widthM: 0, heightM: 10), throwsArgumentError);
  });

  test('helyi koordináta: az X/Y méter a kép bal felső sarkától számolódik', () {
    final c = PlanCalibration(
      imagePath: 'plan.png',
      widthPx: 1000,
      heightPx: 800,
      originLat: localPlanOriginLat,
      originLon: localPlanOriginLon,
      metersPerPx: 0.1,
      localCoordinates: true,
    );
    final ll = PlanGeoref(c).pixelToLatLon(100, 50);
    final m = planLocalMetres(c, ll.lat, ll.lon);
    expect(m.x, closeTo(10, 1e-6));
    expect(m.y, closeTo(5, 1e-6));
  });
}
