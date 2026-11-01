import '../models/measurement_point.dart';
import '../models/survey_source_placement.dart';
import '../models/measurement_type.dart';
import 'source_search.dart';
import 'survey_filter.dart';

/// Rendezési mód a mérési listában.
enum MeasurementSort { timeNewest, timeOldest, valueHighest, valueLowest, nameAsc, nameDesc }

/// A pont kategóriája: a mintavétel a jelzőből, különben a típusából.
MeasurementType measurementKindOf(MeasurementPoint p) =>
    p.isSample ? MeasurementType.sample : p.type;

/// A pont megjelenített neve: a helyszín, vagy a koordináta.
String measurementName(MeasurementPoint p) =>
    p.locationLabel ??
    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

bool measurementMatchesKind(MeasurementPoint p, MeasurementType? kind) =>
    kind == null || measurementKindOf(p) == kind;

bool measurementMatchesSourceOnly(MeasurementPoint p, bool sourceOnly) =>
    !sourceOnly || p.isSourcePosition;

bool measurementMatchesTime(
  MeasurementPoint p,
  SurveyTimeFilter f, {
  required DateTime now,
  DateTime? customFrom,
  DateTime? customTo,
}) =>
    timeFilterMatches(p.timestamp, f,
        now: now, customFrom: customFrom, customTo: customTo);

/// Keresés helyszínre, megjegyzésre, nuklidra, spektrumfájlra és tartálykódra
/// (ékezetmentesen, szóköz és kötőjel nélkül).
bool measurementMatchesQuery(MeasurementPoint p, String query) {
  final q = collationKey(normalizeSearchText(query));
  if (q.isEmpty) return true;
  final fields = [
    measurementName(p),
    p.notes,
    p.activityCalcNuclide,
    p.spectrumFileName,
    p.sampleContainerId,
  ];
  for (final f in fields) {
    if (f != null && collationKey(normalizeSearchText(f)).contains(q)) {
      return true;
    }
  }
  return false;
}

List<MeasurementPoint> sortMeasurements(
  List<MeasurementPoint> list,
  MeasurementSort sort,
) {
  final out = [...list];
  int byValue(MeasurementPoint a, MeasurementPoint b) =>
      (a.value ?? double.negativeInfinity)
          .compareTo(b.value ?? double.negativeInfinity);
  switch (sort) {
    case MeasurementSort.timeNewest:
      out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    case MeasurementSort.timeOldest:
      out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    case MeasurementSort.valueHighest:
      out.sort((a, b) => byValue(b, a));
    case MeasurementSort.valueLowest:
      out.sort(byValue);
    case MeasurementSort.nameAsc:
      out.sort((a, b) =>
          collationKey(measurementName(a)).compareTo(collationKey(measurementName(b))));
    case MeasurementSort.nameDesc:
      out.sort((a, b) =>
          collationKey(measurementName(b)).compareTo(collationKey(measurementName(a))));
  }
  return out;
}

/// A mérési lista egy sora: mérési pont, vagy a térképen elhelyezett forrás.
class SurveyListItem {
  final MeasurementPoint? point;
  final SurveySourcePlacement? placement;
  final String sourceIdentifier; // forrás-sornál az azonosító, pontnál üres
  final List<String> nuclides; // forrás-sornál a nuklidok

  SurveyListItem._(this.point, this.placement, this.sourceIdentifier, this.nuclides);

  factory SurveyListItem.point(MeasurementPoint p) =>
      SurveyListItem._(p, null, '', const []);

  factory SurveyListItem.source(
    SurveySourcePlacement pl,
    String identifier,
    List<String> nuclides,
  ) =>
      SurveyListItem._(null, pl, identifier, nuclides);

  bool get isSourceRow => placement != null;

  DateTime get time => point?.timestamp ?? placement!.createdAt;

  double? get value => point?.value;

  String get name => point != null ? measurementName(point!) : sourceIdentifier;

  /// Forrás-sor, vagy a „forrás-pozíció” jelölésű mérési pont.
  bool get isSourceOnly => isSourceRow || (point?.isSourcePosition ?? false);
}

bool itemMatchesKind(SurveyListItem it, MeasurementType? kind) =>
    kind == null || (it.point != null && measurementKindOf(it.point!) == kind);

bool itemMatchesSourceOnly(SurveyListItem it, bool sourceOnly) =>
    !sourceOnly || it.isSourceOnly;

bool itemMatchesTime(
  SurveyListItem it,
  SurveyTimeFilter f, {
  required DateTime now,
  DateTime? customFrom,
  DateTime? customTo,
}) =>
    timeFilterMatches(it.time, f,
        now: now, customFrom: customFrom, customTo: customTo);

/// Keresés: név (helyszín vagy azonosító), megjegyzés, nuklidok, spektrumfájl, tartálykód.
bool itemMatchesQuery(SurveyListItem it, String query) {
  final q = collationKey(normalizeSearchText(query));
  if (q.isEmpty) return true;
  final fields = <String?>[
    it.name,
    ...it.nuclides,
    if (it.point != null) ...[
      it.point!.notes,
      it.point!.activityCalcNuclide,
      it.point!.spectrumFileName,
      it.point!.sampleContainerId,
    ],
  ];
  for (final f in fields) {
    if (f != null && collationKey(normalizeSearchText(f)).contains(q)) {
      return true;
    }
  }
  return false;
}

List<SurveyListItem> sortItems(List<SurveyListItem> list, MeasurementSort sort) {
  final out = [...list];
  int byValue(SurveyListItem a, SurveyListItem b) =>
      (a.value ?? double.negativeInfinity)
          .compareTo(b.value ?? double.negativeInfinity);
  switch (sort) {
    case MeasurementSort.timeNewest:
      out.sort((a, b) => b.time.compareTo(a.time));
    case MeasurementSort.timeOldest:
      out.sort((a, b) => a.time.compareTo(b.time));
    case MeasurementSort.valueHighest:
      out.sort((a, b) => byValue(b, a));
    case MeasurementSort.valueLowest:
      out.sort(byValue);
    case MeasurementSort.nameAsc:
      out.sort((a, b) => collationKey(a.name).compareTo(collationKey(b.name)));
    case MeasurementSort.nameDesc:
      out.sort((a, b) => collationKey(b.name).compareTo(collationKey(a.name)));
  }
  return out;
}
