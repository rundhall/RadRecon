import 'measurement_type.dart';

/// Egy terepen felvett mérési pont — az app alapegysége.
///
/// Egy felméréshez (surveySessionId) tartozó összes pont közösen exportálható
/// a jegyzőkönyvbe, térképre és GIS-formátumokba (KML/GPX/CSV).
class MeasurementPoint {
  final int? id;
  final int surveySessionId;

  // Hely
  final String? locationLabel; // szabadon megadható helyszín-megnevezés
  final double latitude;
  final double longitude;
  final double? gpsAccuracyMeters;

  // Mérés
  final MeasurementType type;
  final double? value; // null lehet, ha type == sample
  final String unit;
  final double? distanceFromSourceMeters;

  /// A "forrás távolság" mező melletti nuklidválasztóban kiválasztott
  /// izotóp (pl. mentéskor "Cs-137") — a mért értékből visszaszámolt
  /// aktivitás-becsléshez. Nem tartozik mentett forráshoz, csak a
  /// képernyő gyors kalkulátorának állapotát tartja meg pontonként.
  final String? activityCalcNuclide;

  final int? instrumentId; // FK -> instruments.id, manuális bevitelnél is kötelező
  final bool isSourcePosition; // "itt a forrás pozíció" jelölés

  // Mintavétel (csak type == sample esetén releváns, de bármely ponthoz köthető)
  final bool isSample;
  final String? sampleContainerId;
  final double? sampleAmount;
  final String? sampleMethod;

  // Média és megjegyzés
  final String? photoPath;
  final String? notes;

  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeasurementPoint({
    this.id,
    required this.surveySessionId,
    this.locationLabel,
    required this.latitude,
    required this.longitude,
    this.gpsAccuracyMeters,
    required this.type,
    this.value,
    required this.unit,
    this.distanceFromSourceMeters,
    this.activityCalcNuclide,
    this.instrumentId,
    this.isSourcePosition = false,
    this.isSample = false,
    this.sampleContainerId,
    this.sampleAmount,
    this.sampleMethod,
    this.photoPath,
    this.notes,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  MeasurementPoint copyWith({
    int? id,
    int? surveySessionId,
    String? locationLabel,
    double? latitude,
    double? longitude,
    double? gpsAccuracyMeters,
    MeasurementType? type,
    double? value,
    String? unit,
    double? distanceFromSourceMeters,
    String? activityCalcNuclide,
    int? instrumentId,
    bool? isSourcePosition,
    bool? isSample,
    String? sampleContainerId,
    double? sampleAmount,
    String? sampleMethod,
    String? photoPath,
    String? notes,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementPoint(
      id: id ?? this.id,
      surveySessionId: surveySessionId ?? this.surveySessionId,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      distanceFromSourceMeters:
          distanceFromSourceMeters ?? this.distanceFromSourceMeters,
      activityCalcNuclide: activityCalcNuclide ?? this.activityCalcNuclide,
      instrumentId: instrumentId ?? this.instrumentId,
      isSourcePosition: isSourcePosition ?? this.isSourcePosition,
      isSample: isSample ?? this.isSample,
      sampleContainerId: sampleContainerId ?? this.sampleContainerId,
      sampleAmount: sampleAmount ?? this.sampleAmount,
      sampleMethod: sampleMethod ?? this.sampleMethod,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'survey_session_id': surveySessionId,
      'location_label': locationLabel,
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy_meters': gpsAccuracyMeters,
      'measurement_type': type.dbValue,
      'value': value,
      'unit': unit,
      'distance_from_source_meters': distanceFromSourceMeters,
      'activity_calc_nuclide': activityCalcNuclide,
      'instrument_id': instrumentId,
      'is_source_position': isSourcePosition ? 1 : 0,
      'is_sample': isSample ? 1 : 0,
      'sample_container_id': sampleContainerId,
      'sample_amount': sampleAmount,
      'sample_method': sampleMethod,
      'photo_path': photoPath,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MeasurementPoint.fromMap(Map<String, Object?> map) {
    return MeasurementPoint(
      id: map['id'] as int?,
      surveySessionId: map['survey_session_id'] as int,
      locationLabel: map['location_label'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      gpsAccuracyMeters: (map['gps_accuracy_meters'] as num?)?.toDouble(),
      type: MeasurementTypeX.fromDbValue(map['measurement_type'] as String),
      value: (map['value'] as num?)?.toDouble(),
      unit: map['unit'] as String,
      distanceFromSourceMeters:
          (map['distance_from_source_meters'] as num?)?.toDouble(),
      activityCalcNuclide: map['activity_calc_nuclide'] as String?,
      instrumentId: map['instrument_id'] as int?,
      isSourcePosition: (map['is_source_position'] as int? ?? 0) == 1,
      isSample: (map['is_sample'] as int? ?? 0) == 1,
      sampleContainerId: map['sample_container_id'] as String?,
      sampleAmount: (map['sample_amount'] as num?)?.toDouble(),
      sampleMethod: map['sample_method'] as String?,
      photoPath: map['photo_path'] as String?,
      notes: map['notes'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}