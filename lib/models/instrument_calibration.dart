import 'instrument.dart';

/// A bizonylat típusa: hatósági hitelesítés vagy kalibrálás.
enum CalibrationKind {
  verification('verification'), // hitelesítés (hatósági / jogi metrológia)
  calibration('calibration'); // kalibrálás (gyártói / akkreditált labor)

  const CalibrationKind(this.dbValue);
  final String dbValue;

  static CalibrationKind fromDb(Object? v) {
    for (final k in values) {
      if (k.dbValue == v) return k;
    }
    return CalibrationKind.calibration;
  }
}

/// Egy műszer egy hitelesítési vagy kalibrálási bejegyzése.
class InstrumentCalibration {
  final int? id;
  final int? instrumentId;
  final CalibrationKind kind;
  final DateTime performedOn;
  final DateTime? validUntil;
  final String? certificateNumber;
  final String? performedBy; // labor / hatóság
  final String? filePath; // csatolt bizonylat (app-könyvtárba másolva)

  const InstrumentCalibration({
    this.id,
    this.instrumentId,
    required this.kind,
    required this.performedOn,
    this.validUntil,
    this.certificateNumber,
    this.performedBy,
    this.filePath,
  });

  InstrumentCalibration copyWith({
    int? instrumentId,
    CalibrationKind? kind,
    DateTime? performedOn,
    DateTime? validUntil,
    bool clearValidUntil = false,
    String? certificateNumber,
    String? performedBy,
    String? filePath,
    bool clearFile = false,
  }) {
    return InstrumentCalibration(
      id: id,
      instrumentId: instrumentId ?? this.instrumentId,
      kind: kind ?? this.kind,
      performedOn: performedOn ?? this.performedOn,
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
      certificateNumber: certificateNumber ?? this.certificateNumber,
      performedBy: performedBy ?? this.performedBy,
      filePath: clearFile ? null : (filePath ?? this.filePath),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'instrument_id': instrumentId,
        'kind': kind.dbValue,
        'performed_on': performedOn.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'certificate_number': certificateNumber,
        'performed_by': performedBy,
        'file_path': filePath,
      };

  factory InstrumentCalibration.fromMap(Map<String, Object?> m) {
    DateTime? d(Object? v) => v == null ? null : DateTime.tryParse('$v');
    return InstrumentCalibration(
      id: m['id'] as int?,
      instrumentId: m['instrument_id'] as int?,
      kind: CalibrationKind.fromDb(m['kind']),
      performedOn: d(m['performed_on']) ?? DateTime.now(),
      validUntil: d(m['valid_until']),
      certificateNumber: m['certificate_number'] as String?,
      performedBy: m['performed_by'] as String?,
      filePath: m['file_path'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'kind': kind.dbValue,
        'performed_on': performedOn.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'certificate_number': certificateNumber,
        'performed_by': performedBy,
      };

  static InstrumentCalibration? fromJson(Object? v) {
    if (v is! Map) return null;
    final performed = DateTime.tryParse('${v['performed_on']}');
    if (performed == null) return null;
    final until = v['valid_until'] == null
        ? null
        : DateTime.tryParse('${v['valid_until']}');
    return InstrumentCalibration(
      kind: CalibrationKind.fromDb(v['kind']),
      performedOn: performed,
      validUntil: until,
      certificateNumber: v['certificate_number'] as String?,
      performedBy: v['performed_by'] as String?,
    );
  }
}

/// Az adott típus legutolsó (legkésőbbi `performedOn`) bejegyzése,
/// opcionálisan csak az `at` időpontig elvégzettek közül.
InstrumentCalibration? latestOfKind(
  List<InstrumentCalibration> records,
  CalibrationKind kind, {
  DateTime? at,
}) {
  InstrumentCalibration? best;
  for (final r in records) {
    if (r.kind != kind) continue;
    if (at != null && r.performedOn.isAfter(at)) continue;
    if (best == null || r.performedOn.isAfter(best.performedOn)) best = r;
  }
  return best;
}

/// A műszer érvényességének határideje a bejegyzésekből: típusonként a
/// legutolsó bejegyzés lejárata, és ezek közül a legkorábbi (a konzervatív,
/// előbb lejáró számít). Null, ha egyik bejegyzésnek sincs lejárata.
DateTime? effectiveValidUntil(List<InstrumentCalibration> records) {
  DateTime? result;
  for (final k in CalibrationKind.values) {
    final v = latestOfKind(records, k)?.validUntil;
    if (v == null) continue;
    if (result == null || v.isBefore(result)) result = v;
  }
  return result;
}

DateTime? latestPerformedOn(List<InstrumentCalibration> records) {
  DateTime? result;
  for (final r in records) {
    if (result == null || r.performedOn.isAfter(result)) {
      result = r.performedOn;
    }
  }
  return result;
}

enum CalibrationStatus { unknown, valid, expiringSoon, expired }

CalibrationStatus calibrationStatusFor(
  DateTime? validUntil, {
  DateTime? now,
  int soonDays = 30,
}) {
  if (validUntil == null) return CalibrationStatus.unknown;
  final today = now ?? DateTime.now();
  final end = DateTime(validUntil.year, validUntil.month, validUntil.day, 23, 59, 59);
  if (today.isAfter(end)) return CalibrationStatus.expired;
  if (end.difference(today).inDays <= soonDays) {
    return CalibrationStatus.expiringSoon;
  }
  return CalibrationStatus.valid;
}

CalibrationStatus instrumentCalibrationStatus(Instrument i, {DateTime? now}) =>
    calibrationStatusFor(i.nextCalibrationDate, now: now);
