import '../models/activity_origin.dart';
import '../models/radiation_source.dart';
import '../models/source_nuclide.dart';
import 'source_classification.dart' show normalizeNuclideName;

/// Egy nuklid-sor a talált forrás űrlapon (még nem mentett adat).
class FoundNuclideDraft {
  final String nuclide;
  final double? activityMBq;
  final ActivityOrigin origin;

  const FoundNuclideDraft({
    required this.nuclide,
    required this.activityMBq,
    required this.origin,
  });
}

/// Talált forrás azonosítója: `T-ÉÉÉÉHHNN-ÓÓPPMM`.
String foundSourceIdentifier(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${now.year}${two(now.month)}${two(now.day)}';
  final time = '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  return 'T-$date-$time';
}

/// A mentendő nuklid-sorok. Az üres nuklidnevű sor kimarad, a többi
/// normalizált névvel kerül be.
List<SourceNuclide> buildFoundNuclideRows({
  required List<FoundNuclideDraft> drafts,
  required DateTime referenceDate,
  required DateTime now,
}) {
  return [
    for (final d in drafts)
      if (d.nuclide.trim().isNotEmpty)
        SourceNuclide(
          radiationSourceId: 0,
          nuclide: normalizeNuclideName(d.nuclide),
          activityMBq: d.activityMBq,
          referenceDate: referenceDate,
          origin: d.origin,
          createdAt: now,
        ),
  ];
}

/// A talált forrás nyilvántartási rekordja. Gyártási adat nincs, az `origin`
/// `found`. Az elsődleges nuklid a kompatibilitási mezőkbe kerül.
RadiationSource buildFoundSource({
  required String identifier,
  required List<SourceNuclide> nuclides,
  required DateTime now,
}) {
  final primary = nuclides.isEmpty ? null : nuclides.first;
  return RadiationSource(
    identifier: identifier,
    nuclideName: primary?.nuclide ?? '',
    activityAtManufactureMBq: primary?.activityMBq,
    origin: 'found',
    createdAt: now,
    updatedAt: now,
  );
}
