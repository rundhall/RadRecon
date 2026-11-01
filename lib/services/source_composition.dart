import '../models/isotope.dart';
import '../models/regulatory_data.dart';
import 'source_classification.dart';
import '../models/activity_origin.dart';
export '../models/activity_origin.dart';

/// Egy nuklid aktivitás-sora egy forráson belül. Ha `activityMBq` null,
/// a sor ismeretlen aktivitású.
class CompositionRow {
  final String nuclide;
  final double? activityMBq;
  final DateTime referenceDate;
  final ActivityOrigin origin;

  const CompositionRow({
    required this.nuclide,
    required this.activityMBq,
    required this.referenceDate,
    required this.origin,
  });
}

/// Egy nuklid hozzájárulása a forrás R-jéhez.
class CompositionContribution {
  /// Normalizált nuklidnév.
  final String nuclide;

  /// A számítás dátumára korrigált aktivitás (MBq). Null, ha ismeretlen.
  final double? activityMBq;

  /// False, ha a felezési idő nem ismert, így a bomlás nem számolható.
  final bool decayCorrected;

  /// A / D. Null, ha nem számolható.
  final double? ratio;

  final bool unknown;

  const CompositionContribution({
    required this.nuclide,
    required this.activityMBq,
    required this.decayCorrected,
    required this.ratio,
    required this.unknown,
  });
}

/// Egy forrás összetételének besorolása.
class CompositionResult {
  final List<CompositionContribution> contributions;

  /// Az ismert hozzájárulások összege. Null, ha egyik nuklid sem számolható.
  final double? rSum;

  /// Ismeretlen sorok száma. Üres összetételnél 1.
  final int unknownCount;

  const CompositionResult({
    required this.contributions,
    required this.rSum,
    required this.unknownCount,
  });

  bool get isComplete => unknownCount == 0;

  /// Fizikai védelmi kategória az ismert R-ből. Hiányos összetételnél ez
  /// alsó becslés: a hiányzó sorok szigorúbb kategóriát adhatnak.
  int? get physicalCategory =>
      rSum == null ? null : physicalProtectionCategory(rSum!);
}

/// Egy forrás összetételének R-je: Σ A_i / D_i nuklidonként. A bomlás a
/// sor `referenceDate`-je és `asOf` között számol, ahol a felezési idő
/// ismert. Ahol nem, bomlás nélkül számol, és ezt a hozzájárulás jelzi.
CompositionResult classifyComposition(
    Iterable<CompositionRow> rows, DateTime asOf) {
  final contributions = <CompositionContribution>[];
  var sum = 0.0;
  var anyKnown = false;
  var unknown = 0;

  for (final row in rows) {
    final nuclide = normalizeNuclideName(row.nuclide);
    final activity = row.activityMBq;

    if (activity == null) {
      contributions.add(CompositionContribution(
        nuclide: nuclide,
        activityMBq: null,
        decayCorrected: false,
        ratio: null,
        unknown: true,
      ));
      unknown++;
      continue;
    }

    final infinite = kDInfinite.contains(nuclide);
    final d = kDValuesTBq[nuclide];
    if (!infinite && (d == null || d <= 0)) {
      contributions.add(CompositionContribution(
        nuclide: nuclide,
        activityMBq: activity,
        decayCorrected: false,
        ratio: null,
        unknown: true,
      ));
      unknown++;
      continue;
    }

    // Negatív különbségnél (asOf a referencia előtt) az aktivitás nőne:
    // a felületen ezt az esetet meg kell akadályozni.
    final days = asOf.difference(row.referenceDate).inHours / 24.0;
    final decayed = Isotope.findByName(nuclide)
        ?.decayedActivityMBq(initialActivityMBq: activity, elapsedDays: days);
    final current = days == 0 ? activity : (decayed ?? activity);
    final decayCorrected = days == 0 || decayed != null;
    final ratio = infinite ? 0.0 : (current / 1e6) / d!;

    contributions.add(CompositionContribution(
      nuclide: nuclide,
      activityMBq: current,
      decayCorrected: decayCorrected,
      ratio: ratio,
      unknown: false,
    ));
    sum += ratio;
    anyKnown = true;
  }

  return CompositionResult(
    contributions: contributions,
    rSum: anyKnown ? sum : null,
    unknownCount: contributions.isEmpty ? 1 : unknown,
  );
}

/// A felmérés összesített R-je a bekerülő források besorolásából.
class SurveyTotal {
  final double? rSum;
  final int unknownCount;
  final int sourceCount;

  const SurveyTotal({
    required this.rSum,
    required this.unknownCount,
    required this.sourceCount,
  });

  bool get isComplete => unknownCount == 0;

  int? get physicalCategory =>
      rSum == null ? null : physicalProtectionCategory(rSum!);
}

/// Felmérés összesítése. Csak a bekerülő (`included`) forrásokat kapja meg.
SurveyTotal aggregateSurvey(Iterable<CompositionResult> included) {
  var sum = 0.0;
  var anyKnown = false;
  var unknown = 0;
  var count = 0;
  for (final c in included) {
    count++;
    unknown += c.unknownCount;
    final r = c.rSum;
    if (r != null) {
      sum += r;
      anyKnown = true;
    }
  }
  return SurveyTotal(
    rSum: anyKnown ? sum : null,
    unknownCount: unknown,
    sourceCount: count,
  );
}
