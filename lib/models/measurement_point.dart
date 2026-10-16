import 'dart:convert';

import 'measurement_type.dart';
import 'nuclide_id.dart';
import 'shielding.dart';

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

  /// A mért érték hibája (±, ugyanabban az egységben, mint az érték). Átlagolt
  /// mérésnél az átlag standard hibája (1σ), egyébként kézzel megadott.
  final double? valueError;
  final int? averagingSamples; // átlagolt mérés mintáinak száma
  final int? averagingSeconds; // az átlagolás időtartama
  final String unit;
  final double? distanceFromSourceMeters;

  /// A "forrás távolság" mező melletti nuklidválasztóban kiválasztott
  /// izotóp (pl. mentéskor "Cs-137") — a mért értékből visszaszámolt
  /// aktivitás-becsléshez. Nem tartozik mentett forráshoz, csak a
  /// képernyő gyors kalkulátorának állapotát tartja meg pontonként.
  final String? activityCalcNuclide;

  final int? instrumentId; // FK -> instruments.id, manuális bevitelnél is kötelező

  // Nuklid-azonosítás: azonosított nuklid(ok) / ismeretlen / egyéb / keverék.
  final NuclideIdStatus nuclideStatus;
  final List<String> nuclides; // nuklid nevek (listából vagy szabadon megadva)
  // Opcionális árnyékolás a forrás és a mérőpont között (aktivitás-becsléshez).
  final List<ShieldingLayer> shieldingLayers;
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
    this.valueError,
    this.averagingSamples,
    this.averagingSeconds,
    required this.unit,
    this.distanceFromSourceMeters,
    this.activityCalcNuclide,
    this.instrumentId,
    this.nuclideStatus = NuclideIdStatus.notSpecified,
    this.nuclides = const [],
    this.shieldingLayers = const [],
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
    double? valueError,
    int? averagingSamples,
    int? averagingSeconds,
    String? unit,
    double? distanceFromSourceMeters,
    String? activityCalcNuclide,
    int? instrumentId,
    NuclideIdStatus? nuclideStatus,
    List<String>? nuclides,
    List<ShieldingLayer>? shieldingLayers,
    bool clearShielding = false,
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
      valueError: valueError ?? this.valueError,
      averagingSamples: averagingSamples ?? this.averagingSamples,
      averagingSeconds: averagingSeconds ?? this.averagingSeconds,
      unit: unit ?? this.unit,
      distanceFromSourceMeters:
          distanceFromSourceMeters ?? this.distanceFromSourceMeters,
      activityCalcNuclide: activityCalcNuclide ?? this.activityCalcNuclide,
      instrumentId: instrumentId ?? this.instrumentId,
      nuclideStatus: nuclideStatus ?? this.nuclideStatus,
      nuclides: nuclides ?? this.nuclides,
      shieldingLayers: clearShielding
          ? const []
          : (shieldingLayers ?? this.shieldingLayers),
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
      'value_error': valueError,
      'averaging_samples': averagingSamples,
      'averaging_seconds': averagingSeconds,
      'unit': unit,
      'distance_from_source_meters': distanceFromSourceMeters,
      'activity_calc_nuclide': activityCalcNuclide,
      'instrument_id': instrumentId,
      'nuclide_status': nuclideStatus.dbValue,
      'nuclides': nuclides.isEmpty ? null : jsonEncode(nuclides),
      'shielding_layers': shieldingLayers.isEmpty
          ? null
          : jsonEncode([for (final l in shieldingLayers) l.toJson()]),
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
      valueError: (map['value_error'] as num?)?.toDouble(),
      averagingSamples: (map['averaging_samples'] as num?)?.toInt(),
      averagingSeconds: (map['averaging_seconds'] as num?)?.toInt(),
      unit: map['unit'] as String,
      distanceFromSourceMeters:
          (map['distance_from_source_meters'] as num?)?.toDouble(),
      activityCalcNuclide: map['activity_calc_nuclide'] as String?,
      instrumentId: map['instrument_id'] as int?,
      nuclideStatus: NuclideIdStatus.fromDb(map['nuclide_status']),
      nuclides: _decodeNuclides(map['nuclides']),
      shieldingLayers: _decodeLayers(map['shielding_layers']),
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

  /// Az aktivitás-becsléshez használható nuklid: csak akkor van, ha az
  /// azonosítás "Azonosított" és pontosan egy nuklid szerepel.
  String? get estimationNuclide =>
      nuclideStatus == NuclideIdStatus.identified && nuclides.length == 1
          ? nuclides.first
          : null;

  static List<ShieldingLayer> _decodeLayers(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      return ShieldingLayer.listFromJson(jsonDecode(raw));
    } catch (_) {}
    return const [];
  }

  static List<String> _decodeNuclides(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {}
    return const [];
  }
}
