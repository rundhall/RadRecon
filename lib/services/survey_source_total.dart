import '../database/database_helper.dart';
import '../models/radiation_source.dart';
import '../models/source_nuclide.dart';
import '../models/survey_source_placement.dart';
import 'source_composition.dart';

/// Egy elhelyezés besorolása: a forrás nuklid-soraiból számolt R és a
/// számítás dátuma.
class PlacementClassification {
  final SurveySourcePlacement placement;
  final RadiationSource source;
  final List<SourceNuclide> nuclides;

  /// A számítás dátuma: az elhelyezés felülírása, vagy a felmérés kezdete.
  final DateTime asOf;
  final CompositionResult composition;

  const PlacementClassification({
    required this.placement,
    required this.source,
    required this.nuclides,
    required this.asOf,
    required this.composition,
  });
}

/// Egy felmérés besorolása: az összes elhelyezés és az összegzett R.
class SurveyClassification {
  final DateTime startedAt;
  final List<PlacementClassification> rows;
  final SurveyTotal total;

  const SurveyClassification({
    required this.startedAt,
    required this.rows,
    required this.total,
  });
}

/// A felmérés összesítése: csak a bekerülő (included) elhelyezések számítanak.
SurveyTotal surveyTotalFromRows(Iterable<PlacementClassification> rows) =>
    aggregateSurvey([
      for (final r in rows)
        if (r.placement.included) r.composition,
    ]);

/// Egy felmérés besorolása. Az elhelyezéseket a pontokhoz rendelt források
/// adják (ensureDefaultPlacements). A számítás dátuma a felmérés kezdete,
/// elhelyezésenként felülírható. Null, ha a felmérés nem található.
Future<SurveyClassification?> loadSurveyClassification(
  int surveySessionId,
) async {
  final db = DatabaseHelper.instance;
  final session = await db.getSurveySession(surveySessionId);
  if (session == null) return null;

  await db.ensureDefaultPlacements(surveySessionId);
  final placements = await db.getSurveyPlacements(surveySessionId);
  final sourcesById = {
    for (final s in await db.getRadiationSources())
      if (s.id != null) s.id!: s,
  };

  final rows = <PlacementClassification>[];
  for (final placement in placements) {
    final source = sourcesById[placement.radiationSourceId];
    if (source == null) continue;
    final nuclides = await db.getSourceNuclides(placement.radiationSourceId);
    final asOf = placement.calcDateOverride ?? session.startedAt;
    final composition = classifyComposition(
      [
        for (final n in nuclides)
          CompositionRow(
            nuclide: n.nuclide,
            activityMBq: n.activityMBq,
            referenceDate: n.referenceDate,
            origin: n.origin,
          ),
      ],
      asOf,
    );
    rows.add(PlacementClassification(
      placement: placement,
      source: source,
      nuclides: nuclides,
      asOf: asOf,
      composition: composition,
    ));
  }

  return SurveyClassification(
    startedAt: session.startedAt,
    rows: rows,
    total: surveyTotalFromRows(rows),
  );
}

/// Egy felmérés összesített R-je a bekerülő elhelyezésekből.
Future<SurveyTotal> computeSurveyTotal(int surveySessionId) async {
  final data = await loadSurveyClassification(surveySessionId);
  return data?.total ?? aggregateSurvey(const []);
}
