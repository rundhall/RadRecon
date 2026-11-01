import 'plan_calibration.dart';
import 'survey_purpose.dart';

/// A felmérés térképi módja: online (OpenStreetMap csempék), vagy offline,
/// feltöltött és kalibrált alaprajz.
enum SurveyMapMode {
  online,
  plan;

  static SurveyMapMode fromStorage(String? value) =>
      value == 'plan' ? SurveyMapMode.plan : SurveyMapMode.online;
}

/// Egy terepi felmérés (egy jegyzőkönyvnek megfelelő egység).
///
/// A hozzá tartozó összes [MeasurementPoint] közösen exportálható a
/// jegyzőkönyvbe és a térképre. A [purpose] határozza meg, milyen
/// kiegészítő jegyzőkönyv-mezők tartoznak a felméréshez; `null` = általános.
/// A [mapMode] `plan` értéke esetén a [planCalibration] adja az alaprajzot.
class SurveySession {
  final int? id;
  final String title; // pl. "2026-09-26 – Telephely X felmérés"
  final String? location;
  final String? notes;
  final DateTime startedAt;
  final DateTime? closedAt; // null amíg a felmérés folyamatban van
  final SurveyPurpose? purpose;
  final SurveyMapMode mapMode;
  final PlanCalibration? planCalibration;
  final DateTime? archivedAt; // null = nincs archiválva

  const SurveySession({
    this.id,
    required this.title,
    this.location,
    this.notes,
    required this.startedAt,
    this.closedAt,
    this.purpose,
    this.mapMode = SurveyMapMode.online,
    this.planCalibration,
    this.archivedAt,
  });

  bool get isClosed => closedAt != null;
  bool get isArchived => archivedAt != null;

  SurveySession copyWith({
    int? id,
    String? title,
    String? location,
    String? notes,
    DateTime? startedAt,
    DateTime? closedAt,
    SurveyPurpose? purpose,
    SurveyMapMode? mapMode,
    PlanCalibration? planCalibration,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return SurveySession(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
      purpose: purpose ?? this.purpose,
      mapMode: mapMode ?? this.mapMode,
      planCalibration: planCalibration ?? this.planCalibration,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }

  Map<String, Object?> toMap() {
    final plan = planCalibration;
    return {
      'id': id,
      'title': title,
      'location': location,
      'notes': notes,
      'started_at': startedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'purpose': purpose?.name,
      'map_mode': mapMode.name,
      'plan_image_path': plan?.imagePath,
      'plan_width_px': plan?.widthPx,
      'plan_height_px': plan?.heightPx,
      'plan_origin_lat': plan?.originLat,
      'plan_origin_lon': plan?.originLon,
      'plan_meters_per_px': plan?.metersPerPx,
      'plan_local_coords': (plan?.localCoordinates ?? false) ? 1 : 0,
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  factory SurveySession.fromMap(Map<String, Object?> map) {
    return SurveySession(
      id: map['id'] as int?,
      title: map['title'] as String,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      closedAt: map['closed_at'] == null
          ? null
          : DateTime.parse(map['closed_at'] as String),
      purpose: SurveyPurpose.fromStorage(map['purpose'] as String?),
      mapMode: SurveyMapMode.fromStorage(map['map_mode'] as String?),
      planCalibration: _planFrom(map),
      archivedAt: map['archived_at'] == null
          ? null
          : DateTime.parse(map['archived_at'] as String),
    );
  }
}

/// A tárolt alaprajz-mezőkből; hiányos adat esetén `null` (online módként kezelve).
PlanCalibration? _planFrom(Map<String, Object?> map) {
  final path = map['plan_image_path'] as String?;
  final w = map['plan_width_px'] as int?;
  final h = map['plan_height_px'] as int?;
  final lat = (map['plan_origin_lat'] as num?)?.toDouble();
  final lon = (map['plan_origin_lon'] as num?)?.toDouble();
  final mpp = (map['plan_meters_per_px'] as num?)?.toDouble();
  if (path == null || w == null || h == null || lat == null || lon == null || mpp == null) {
    return null;
  }
  return PlanCalibration(
    imagePath: path,
    widthPx: w,
    heightPx: h,
    originLat: lat,
    originLon: lon,
    metersPerPx: mpp,
    localCoordinates: (map['plan_local_coords'] as int? ?? 0) == 1,
  );
}
