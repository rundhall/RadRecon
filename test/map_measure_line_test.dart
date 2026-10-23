import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:rad_recon/models/map_measure_line.dart';

void main() {
  test('mérővonal mentése és visszaolvasása megőrzi a pontokat és a színt', () {
    final line = MapMeasureLine(
      surveySessionId: 3,
      colorArgb: 0xFF1E88E5,
      a: ll.LatLng(47.5, 19.0),
      b: ll.LatLng(47.5, 19.01),
    );
    final map = line.toMap()..['id'] = 7;
    final back = MapMeasureLine.fromMap(map);

    expect(back.id, 7);
    expect(back.surveySessionId, 3);
    expect(back.colorArgb, 0xFF1E88E5);
    expect(back.a.latitude, 47.5);
    expect(back.b.longitude, 19.01);
    expect(back.meters, closeTo(line.meters, 1e-6));
    // 0,01° hosszúság 47,5° szélességen kb. 750 m.
    expect(back.meters, greaterThan(500));
  });
}
