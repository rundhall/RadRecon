import 'dart:convert';

/// A térképi területjelölés alakzata.
enum MapAreaShape {
  polygon('polygon'),
  circle('circle');

  const MapAreaShape(this.dbValue);

  final String dbValue;

  static MapAreaShape fromDbValue(String? value) =>
      MapAreaShape.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => MapAreaShape.polygon,
      );
}

/// Egy felméréshez rögzített térképi terület (név, szín, alakzat).
/// A koordináták `[szélesség, hosszúság]` párok.
class MapArea {
  final int? id;
  final int surveySessionId;
  final String name;
  final int colorArgb;
  final MapAreaShape shape;
  final List<List<double>> polygon; // poligonnál a csúcspontok
  final List<double>? center; // körnél a középpont
  final double? radiusMeters; // körnél a sugár, méter

  const MapArea({
    this.id,
    required this.surveySessionId,
    required this.name,
    required this.colorArgb,
    required this.shape,
    this.polygon = const [],
    this.center,
    this.radiusMeters,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'survey_session_id': surveySessionId,
      'name': name,
      'color': colorArgb,
      'shape': shape.dbValue,
      'geometry': jsonEncode(
        shape == MapAreaShape.polygon
            ? {'points': polygon}
            : {'center': center, 'radius_m': radiusMeters},
      ),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory MapArea.fromMap(Map<String, Object?> map) {
    final geo = jsonDecode(map['geometry'] as String) as Map<String, dynamic>;
    final shape = MapAreaShape.fromDbValue(map['shape'] as String?);
    return MapArea(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      name: map['name'] as String,
      colorArgb: map['color'] as int,
      shape: shape,
      polygon: shape == MapAreaShape.polygon
          ? [
              for (final p in geo['points'] as List<dynamic>)
                [for (final v in p as List<dynamic>) (v as num).toDouble()],
            ]
          : const [],
      center: shape == MapAreaShape.circle && geo['center'] != null
          ? [
              for (final v in geo['center'] as List<dynamic>)
                (v as num).toDouble(),
            ]
          : null,
      radiusMeters:
          shape == MapAreaShape.circle ? (geo['radius_m'] as num?)?.toDouble() : null,
    );
  }
}
