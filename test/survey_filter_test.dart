import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/survey_session.dart';
import 'package:rad_recon/services/survey_filter.dart';

SurveySession _s(String title,
        {DateTime? started, DateTime? closed, DateTime? archived, String? location}) =>
    SurveySession(
      title: title,
      location: location,
      startedAt: started ?? DateTime(2026, 10, 1),
      closedAt: closed,
      archivedAt: archived,
    );

void main() {
  final now = DateTime(2026, 11, 1, 12);

  test('az aktív szűrő kizárja az archiváltakat, az archivált csak azokat mutatja', () {
    final archived = _s('A', archived: now);
    final open = _s('B');
    final closed = _s('C', closed: now);
    expect(surveyMatchesStatus(archived, SurveyStatusFilter.active), isFalse);
    expect(surveyMatchesStatus(archived, SurveyStatusFilter.archived), isTrue);
    expect(surveyMatchesStatus(open, SurveyStatusFilter.open), isTrue);
    expect(surveyMatchesStatus(open, SurveyStatusFilter.closed), isFalse);
    expect(surveyMatchesStatus(closed, SurveyStatusFilter.closed), isTrue);
    expect(surveyMatchesStatus(closed, SurveyStatusFilter.active), isTrue);
  });

  test('az időszak szűrő: utolsó 7 nap és egyéni tartomány', () {
    final recent = _s('R', started: DateTime(2026, 10, 28));
    final old = _s('O', started: DateTime(2026, 9, 1));
    expect(surveyMatchesTime(recent, SurveyTimeFilter.last7, now: now), isTrue);
    expect(surveyMatchesTime(old, SurveyTimeFilter.last7, now: now), isFalse);
    expect(
      surveyMatchesTime(old, SurveyTimeFilter.custom,
          now: now, customFrom: DateTime(2026, 8, 1), customTo: DateTime(2026, 9, 2)),
      isTrue,
    );
    expect(
      surveyMatchesTime(old, SurveyTimeFilter.custom,
          now: now, customFrom: DateTime(2026, 9, 2), customTo: DateTime(2026, 10, 1)),
      isFalse,
    );
  });

  test('ABC-rendezés ékezetet figyelmen kívül hagyva', () {
    final list = [_s('Zeta'), _s('Béla'), _s('Ábel')];
    expect(sortSurveys(list, SurveySort.nameAsc).map((s) => s.title).toList(),
        ['Ábel', 'Béla', 'Zeta']);
    expect(sortSurveys(list, SurveySort.nameDesc).map((s) => s.title).toList(),
        ['Zeta', 'Béla', 'Ábel']);
  });

  test('idő szerinti rendezés: újabb és régebbi elöl', () {
    final list = [
      _s('a', started: DateTime(2026, 1, 1)),
      _s('b', started: DateTime(2026, 6, 1)),
    ];
    expect(sortSurveys(list, SurveySort.timeNewest).first.title, 'b');
    expect(sortSurveys(list, SurveySort.timeOldest).first.title, 'a');
  });

  test('keresés címre és helyszínre, ékezet- és szóköz-függetlenül', () {
    final s = _s('Ábel telephely', location: 'Budapest, Üllői út');
    expect(surveyMatchesQuery(s, 'abel'), isTrue);
    expect(surveyMatchesQuery(s, 'ÁBEL TELEP'), isTrue);
    expect(surveyMatchesQuery(s, 'ulloi'), isTrue);
    expect(surveyMatchesQuery(s, 'Debrecen'), isFalse);
    expect(surveyMatchesQuery(s, ''), isTrue);
  });
}
