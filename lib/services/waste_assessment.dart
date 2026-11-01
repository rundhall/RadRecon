import 'dart:convert';

import '../models/dose_quantity.dart';
import '../models/measurement_point.dart';
import '../models/measurement_type.dart';
import '../models/regulatory_data.dart';
import 'source_classification.dart';

/// Átvételi határérték: a csomag felületétől 10 cm-re mérhető légkerma-
/// teljesítmény legfeljebb 10 mGy/h, µGy/h-ban: 10 000.
const double kWasteDoseLimitMicroGyPerH = 10000;

/// Csak ennél nem messzebb (m) mért légkerma-pont hasonlítható a határhoz.
/// Közelebbről mért érték konzervatív: nagyobb, így a megfelelés biztonságos.
const double kWasteLimitMaxDistanceM = 0.10;

/// Tizedestört beviteli mezőből; a tizedesvessző is elfogadott.
double? parseDecimalInput(String? text) {
  if (text == null) return null;
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// Egy radionuklid a csomagban: aktivitás (Bq) és felezési idő-kategória.
class WasteIsotope {
  const WasteIsotope({
    required this.nuclide,
    required this.activityBq,
    required this.halfLifeOver30y,
  });

  final String nuclide;
  // null, ha az aktivitás nincs érvényesen megadva.
  final double? activityBq;
  final bool halfLifeOver30y;

  Map<String, Object?> toJson() => {
        'nuclide': nuclide,
        'activity_bq': activityBq,
        'half_life_over_30y': halfLifeOver30y,
      };

  static String listToJson(List<WasteIsotope> items) =>
      jsonEncode([for (final item in items) item.toJson()]);

  static List<WasteIsotope> listFromJson(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          WasteIsotope(
            nuclide: (item['nuclide'] as String?) ?? '',
            activityBq: (item['activity_bq'] as num?)?.toDouble(),
            halfLifeOver30y: item['half_life_over_30y'] == true,
          ),
    ];
  }
}

/// Egy nuklid S-tagjai (2/2022. OAH rendelet 12. melléklet).
class WasteIsotopeResult {
  const WasteIsotopeResult({
    required this.isotope,
    required this.akBqPerKg,
    required this.smeakBqPerKg,
    required this.ameakBqPerKg,
    required this.si,
  });

  final WasteIsotope isotope;
  // AK = A / m (Bq/kg); null, ha a tömeg vagy az aktivitás hiányzik.
  final double? akBqPerKg;
  // SMEAK (Bq/kg): a rendelet 2. táblázata minden nuklidra ezt használja.
  final double? smeakBqPerKg;
  // ÁMEAK (Bq/kg): csak a VLLW b) feltételéhez kell (>30 év nuklidok).
  final double? ameakBqPerKg;
  // S_i = AK / SMEAK.
  final double? si;
}

/// Besorolás-kategória a 2/2022. OAH rendelet 12. melléklete szerint.
enum WasteCategory { vllw, llw, ilw }

/// A csomag besorolási számításának eredménye.
class WasteSAssessment {
  const WasteSAssessment({
    required this.results,
    required this.total,
    required this.shortLivedSum,
    required this.longLivedSum,
    required this.longLivedAmeakSum,
  });

  final List<WasteIsotopeResult> results;
  // Σ AK_i / SMEAK_i, minden nuklidra (2. táblázat).
  final double? total;
  // Σ AK_i / SMEAK_i, T½ ≤ 30 év (2.3. pont a).
  final double? shortLivedSum;
  // Σ AK_i / SMEAK_i, T½ > 30 év (2.2.1. pont).
  final double? longLivedSum;
  // Σ AK_i / ÁMEAK_i, T½ > 30 év (2.3. pont b).
  final double? longLivedAmeakSum;

  /// Rövid élettartamú: a >30 éves nuklidok Σ AK/SMEAK összege ≤ 1 (2.2.1. pont).
  bool? get isShortLived {
    final long = longLivedSum;
    if (long == null) return null;
    return long <= 1;
  }

  /// Besorolás. null, ha a számítás nem teljes. A nagyon kis aktivitású
  /// (VLLW) feltételhez az ÁMEAK-értékek is kellenek: hiányuk esetén nem
  /// adunk VLLW-t.
  WasteCategory? get category {
    final t = total;
    final long = longLivedSum;
    if (t == null || long == null) return null;
    if (t > 1000) return WasteCategory.ilw;
    final short = shortLivedSum;
    final longAmeak = longLivedAmeakSum;
    final veryLow = long <= 1 &&
        short != null &&
        short <= 50 &&
        longAmeak != null &&
        longAmeak <= 1;
    return veryLow ? WasteCategory.vllw : WasteCategory.llw;
  }
}

WasteSAssessment assessWasteS({
  required double? massKg,
  required List<WasteIsotope> isotopes,
}) {
  final mass = massKg;
  final hasMass = mass != null && mass > 0;
  final results = <WasteIsotopeResult>[];
  var complete = hasMass && isotopes.isNotEmpty;
  var ameakComplete = complete;
  var total = 0.0;
  var shortSum = 0.0;
  var longSum = 0.0;
  var longAmeakSum = 0.0;

  for (final isotope in isotopes) {
    final activity = isotope.activityBq;
    final ak = (mass != null && mass > 0 && activity != null)
        ? activity / mass
        : null;
    final values = kExemptionValues[normalizeNuclideName(isotope.nuclide)];
    final smeak = values == null ? null : values.specificBqPerG * 1000;
    final ameakPerG = values?.generalBqPerG;
    final ameak = ameakPerG == null ? null : ameakPerG * 1000;
    final si = (ak != null && smeak != null && smeak > 0) ? ak / smeak : null;
    results.add(WasteIsotopeResult(
      isotope: isotope,
      akBqPerKg: ak,
      smeakBqPerKg: smeak,
      ameakBqPerKg: ameak,
      si: si,
    ));

    if (si == null) {
      complete = false;
    } else {
      total += si;
      if (isotope.halfLifeOver30y) {
        longSum += si;
      } else {
        shortSum += si;
      }
    }

    if (isotope.halfLifeOver30y) {
      if (ak == null || ameak == null || ameak <= 0) {
        ameakComplete = false;
      } else {
        longAmeakSum += ak / ameak;
      }
    }
  }

  return WasteSAssessment(
    results: results,
    total: complete ? total : null,
    shortLivedSum: complete ? shortSum : null,
    longLivedSum: complete ? longSum : null,
    longLivedAmeakSum: (complete && ameakComplete) ? longAmeakSum : null,
  );
}

enum KermaLimitStatus { noKermaMeasurement, noValidPoint, withinLimit, exceeded }

/// A 10 cm-es légkerma-határérték ellenőrzésének eredménye.
class AirKermaLimitCheck {
  const AirKermaLimitCheck({
    required this.kermaPoints,
    required this.validPoints,
    required this.otherDosePoints,
    required this.maxMicroGyPerH,
  });

  // Légkerma (K) dózisteljesítmény-pontok száma.
  final int kermaPoints;
  // Ezek közül a legfeljebb 10 cm-re mért pontok száma.
  final int validPoints;
  // H*(10), Hp, H'(d,Ω) pontok: nem hasonlíthatók a légkerma-határhoz.
  final int otherDosePoints;
  // A legnagyobb érvényes légkerma-érték, µGy/h-ban.
  final double? maxMicroGyPerH;

  KermaLimitStatus get status {
    if (kermaPoints == 0) return KermaLimitStatus.noKermaMeasurement;
    final max = maxMicroGyPerH;
    if (max == null) return KermaLimitStatus.noValidPoint;
    return max <= kWasteDoseLimitMicroGyPerH
        ? KermaLimitStatus.withinLimit
        : KermaLimitStatus.exceeded;
  }
}

AirKermaLimitCheck checkAirKermaLimit(List<MeasurementPoint> points) {
  var kerma = 0;
  var valid = 0;
  var other = 0;
  double? max;
  for (final point in points) {
    final value = point.value;
    if (point.type != MeasurementType.doseRate || value == null) continue;
    if (point.doseQuantity != DoseQuantity.kerma.dbValue) {
      other++;
      continue;
    }
    kerma++;
    final unit = _kermaUnit(point.unit);
    final distance = point.distanceFromSourceMeters;
    if (unit == null || distance == null || distance > kWasteLimitMaxDistanceM) {
      continue;
    }
    final microGyPerH = value * unit.baseFactor;
    valid++;
    if (max == null || microGyPerH > max) max = microGyPerH;
  }
  return AirKermaLimitCheck(
    kermaPoints: kerma,
    validPoints: valid,
    otherDosePoints: other,
    maxMicroGyPerH: max,
  );
}

KermaRateUnit? _kermaUnit(String symbol) {
  for (final unit in KermaRateUnit.values) {
    if (unit.symbol == symbol) return unit;
  }
  return null;
}
