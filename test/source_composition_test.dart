import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/source_composition.dart';

CompositionRow row(String nuclide, double? mbq, DateTime ref,
        {ActivityOrigin origin = ActivityOrigin.manual}) =>
    CompositionRow(
        nuclide: nuclide,
        activityMBq: mbq,
        referenceDate: ref,
        origin: origin);

void main() {
  final asOf = DateTime(2026, 11, 1);

  test('egy nuklid: R = A / D, kategória az R-ből', () {
    final r = classifyComposition([row('co60', 1e6, asOf)], asOf);
    expect(r.isComplete, isTrue);
    expect(r.rSum, closeTo(1 / 0.03, 1e-6));
    expect(r.physicalCategory, 2);
  });

  test('több nuklid R-je összeadódik', () {
    final r = classifyComposition(
        [row('Co-60', 3e4, asOf), row('Cs-137', 1e5, asOf)], asOf);
    expect(r.rSum, closeTo(2.0, 1e-9));
    expect(r.physicalCategory, 3);
  });

  test('ismeretlen aktivitású sor kimarad, de jelzett', () {
    final r = classifyComposition(
        [row('Co-60', 3e4, asOf), row('Cs-137', null, asOf)], asOf);
    expect(r.isComplete, isFalse);
    expect(r.unknownCount, 1);
    expect(r.rSum, closeTo(1.0, 1e-9));
  });

  test('D-táblán kívüli nuklid ismeretlen', () {
    final r = classifyComposition([row('Xx-1', 1e6, asOf)], asOf);
    expect(r.unknownCount, 1);
    expect(r.rSum, isNull);
    expect(r.physicalCategory, isNull);
  });

  test('végtelen D-jű nuklid R-je 0, nem ismeretlen', () {
    final r = classifyComposition([row('K-40', 1e9, asOf)], asOf);
    expect(r.isComplete, isTrue);
    expect(r.rSum, 0.0);
    expect(r.physicalCategory, 5);
  });

  test('üres összetétel ismeretlen forrás', () {
    final r = classifyComposition(const [], asOf);
    expect(r.isComplete, isFalse);
    expect(r.rSum, isNull);
  });

  test('bomlás: egy felezési idő után a fele', () {
    final ref = DateTime(2020, 1, 1);
    final later = ref.add(Duration(hours: (1925.3 * 24).round()));
    final r = classifyComposition([row('Co-60', 2e6, ref)], later);
    expect(r.contributions.single.decayCorrected, isTrue);
    expect(r.rSum, closeTo(1 / 0.03, 0.05));
  });

  test('felezési idő nélküli nuklidnál bomlás nélkül, jelzéssel', () {
    final ref = DateTime(2020, 1, 1);
    final r = classifyComposition([row('Sr-90', 1e6, ref)], asOf);
    expect(r.contributions.single.decayCorrected, isFalse);
    expect(r.rSum, closeTo(1.0, 1e-9));
  });

  test('felmérés összesítése: a hiányos forrás jelzi a hiányt', () {
    final a = classifyComposition([row('Co-60', 3e4, asOf)], asOf);
    final b = classifyComposition([row('Cs-137', null, asOf)], asOf);
    final t = aggregateSurvey([a, b]);
    expect(t.sourceCount, 2);
    expect(t.unknownCount, 1);
    expect(t.isComplete, isFalse);
    expect(t.rSum, closeTo(1.0, 1e-9));
  });
}
