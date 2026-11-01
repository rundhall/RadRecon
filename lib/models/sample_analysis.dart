/// Mintán végzett műszeres vizsgálat (egy futtatás). A minta a mérési pont,
/// amelynek jelzője a mintavétel; egy mintán több vizsgálat is lehet.
enum SampleAnalysisMethod {
  ftir('ftir', 'FT-IR'),
  nir('nir', 'NIR'),
  raman('raman', 'Raman'),
  xrf('xrf', 'XRF'),
  pcr('pcr', 'PCR'),
  other('other', '');

  const SampleAnalysisMethod(this.dbValue, this.fixedLabel);

  final String dbValue;

  /// Műszaki módszernév; az „egyéb” címkéjét a felület adja (lokalizálva).
  final String fixedLabel;

  static SampleAnalysisMethod fromStorage(String? value) =>
      SampleAnalysisMethod.values.firstWhere(
        (m) => m.dbValue == value,
        orElse: () => SampleAnalysisMethod.other,
      );
}

/// PCR-vizsgálat eredménye.
enum PcrOutcome {
  positive('positive'),
  negative('negative'),
  invalid('invalid');

  const PcrOutcome(this.dbValue);

  final String dbValue;

  static PcrOutcome? fromStorage(String? value) {
    if (value == null) return null;
    return PcrOutcome.values.firstWhere(
      (o) => o.dbValue == value,
      orElse: () => PcrOutcome.invalid,
    );
  }
}

class SampleAnalysis {
  final int? id;
  final int measurementPointId;
  final SampleAnalysisMethod method;
  final String? instrumentName;
  final DateTime performedAt;
  final String? operatorName;
  final String? result; // az eredmény vagy az azonosítás a műszer szerint
  final String? notes;
  final String? filePath; // csatolt fájl (spektrum, export), az app mappájában
  final DateTime createdAt;
  final String? pcrTarget; // PCR: célgén vagy célkórokozó
  final PcrOutcome? pcrOutcome;
  final double? pcrCt; // PCR: Ct érték

  const SampleAnalysis({
    this.id,
    required this.measurementPointId,
    required this.method,
    this.instrumentName,
    required this.performedAt,
    this.operatorName,
    this.result,
    this.notes,
    this.filePath,
    required this.createdAt,
    this.pcrTarget,
    this.pcrOutcome,
    this.pcrCt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'measurement_point_id': measurementPointId,
        'method': method.dbValue,
        'instrument_name': instrumentName,
        'performed_at': performedAt.toIso8601String(),
        'operator_name': operatorName,
        'result': result,
        'notes': notes,
        'file_path': filePath,
        'created_at': createdAt.toIso8601String(),
        'pcr_target': pcrTarget,
        'pcr_outcome': pcrOutcome?.dbValue,
        'pcr_ct': pcrCt,
      };

  factory SampleAnalysis.fromMap(Map<String, Object?> m) => SampleAnalysis(
        id: m['id'] as int?,
        measurementPointId: m['measurement_point_id'] as int,
        method: SampleAnalysisMethod.fromStorage(m['method'] as String?),
        instrumentName: m['instrument_name'] as String?,
        performedAt: DateTime.parse(m['performed_at'] as String),
        operatorName: m['operator_name'] as String?,
        result: m['result'] as String?,
        notes: m['notes'] as String?,
        filePath: m['file_path'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        pcrTarget: m['pcr_target'] as String?,
        pcrOutcome: PcrOutcome.fromStorage(m['pcr_outcome'] as String?),
        pcrCt: (m['pcr_ct'] as num?)?.toDouble(),
      );
}
