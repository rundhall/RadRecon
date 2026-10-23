import 'dart:convert';

import 'package:latlong2/latlong.dart' as ll;

/// Egy felméréshez rögzített térképi mérővonal: két pont és egy szín.
/// A pontok `[szélesség, hosszúság]` párként tárolódnak a `geometry` JSON-ban.
class MapMeasureLine {
  const MapMeasureLine({
    this.id,
    required this.surveySessionId,
    required this.colorArgb,
    required this.a,
    required this.b,
  });

  final int? id;
  final int surveySessionId;
  final int colorArgb;
  final ll.LatLng a;
  final ll.LatLng b;

  /// A két pont közötti légvonalbeli távolság méterben.
  double get meters => ll.Distance().as(ll.LengthUnit.Meter, a, b);

  /// A vonal közepe, ide kerül a távolság felirata.
  ll.LatLng get midpoint => ll.LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );

  MapMeasureLine copyWith({int? id, int? colorArgb}) => MapMeasureLine(
        id: id ?? this.id,
        surveySessionId: surveySessionId,
        colorArgb: colorArgb ?? this.colorArgb,
        a: a,
        b: b,
      );

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'survey_session_id': surveySessionId,
      'color': colorArgb,
      'geometry': jsonEncode({
        'a': [a.latitude, a.longitude],
        'b': [b.latitude, b.longitude],
      }),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory MapMeasureLine.fromMap(Map<String, Object?> map) {
    final geo = jsonDecode(map['geometry'] as String) as Map<String, dynamic>;
    ll.LatLng point(String key) {
      final v = geo[key] as List<dynamic>;
      return ll.LatLng((v[0] as num).toDouble(), (v[1] as num).toDouble());
    }

    return MapMeasureLine(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      colorArgb: map['color'] as int,
      a: point('a'),
      b: point('b'),
    );
  }
}
