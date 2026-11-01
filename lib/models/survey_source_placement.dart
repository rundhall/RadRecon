/// Egy forrás elhelyezése egy felmérésben: hol van, és bekerül-e a
/// felmérés R-jébe. Egy forrás egy felmérésben egyszer szerepel.
class SurveySourcePlacement {
  final int? id;
  final int surveySessionId;
  final int radiationSourceId;

  /// A pont, amelyhez a forrás a felmérésben kötődik (ha van).
  final int? measurementPointId;

  /// Régi, alaprajz-módú pozíció (méter). Az új pozíció a [mapLat]/[mapLon].
  final double? planX;
  final double? planY;

  /// Pozíció a térképen (szélesség, hosszúság). Online és alaprajz módban is ez.
  final double? mapLat;
  final double? mapLon;

  /// Bekerül-e a felmérés összegébe.
  final bool included;

  /// A számítás dátuma, ha a felmérés kezdő dátumától eltér. Null esetén a
  /// felmérés kezdő dátuma.
  final DateTime? calcDateOverride;
  final DateTime createdAt;

  const SurveySourcePlacement({
    this.id,
    required this.surveySessionId,
    required this.radiationSourceId,
    this.measurementPointId,
    this.planX,
    this.planY,
    this.mapLat,
    this.mapLon,
    this.included = true,
    this.calcDateOverride,
    required this.createdAt,
  });

  bool get hasMapPosition => mapLat != null && mapLon != null;

  SurveySourcePlacement copyWith({
    double? mapLat,
    double? mapLon,
    bool clearMapPosition = false,
    bool? included,
    DateTime? calcDateOverride,
    bool clearCalcDateOverride = false,
  }) {
    return SurveySourcePlacement(
      id: id,
      surveySessionId: surveySessionId,
      radiationSourceId: radiationSourceId,
      measurementPointId: measurementPointId,
      planX: planX,
      planY: planY,
      mapLat: clearMapPosition ? null : (mapLat ?? this.mapLat),
      mapLon: clearMapPosition ? null : (mapLon ?? this.mapLon),
      included: included ?? this.included,
      calcDateOverride: clearCalcDateOverride
          ? null
          : (calcDateOverride ?? this.calcDateOverride),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'survey_session_id': surveySessionId,
        'radiation_source_id': radiationSourceId,
        'measurement_point_id': measurementPointId,
        'plan_x': planX,
        'plan_y': planY,
        'map_lat': mapLat,
        'map_lon': mapLon,
        'included': included ? 1 : 0,
        'calc_date_override': calcDateOverride?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory SurveySourcePlacement.fromMap(Map<String, Object?> map) {
    return SurveySourcePlacement(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      radiationSourceId: map['radiation_source_id'] as int,
      measurementPointId: map['measurement_point_id'] as int?,
      planX: (map['plan_x'] as num?)?.toDouble(),
      planY: (map['plan_y'] as num?)?.toDouble(),
      mapLat: (map['map_lat'] as num?)?.toDouble(),
      mapLon: (map['map_lon'] as num?)?.toDouble(),
      included: (map['included'] as int) == 1,
      calcDateOverride: map['calc_date_override'] == null
          ? null
          : DateTime.parse(map['calc_date_override'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
