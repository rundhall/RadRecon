import '../models/survey_session.dart';
import 'source_search.dart';

/// Állapotszűrő. Az „aktív” az archiválatlan (nyitott és lezárt) felméréseket jelenti.
enum SurveyStatusFilter { active, open, closed, archived }

enum SurveyTimeFilter { all, last7, last30, thisYear, custom }

enum SurveySort { timeNewest, timeOldest, nameAsc, nameDesc }

bool surveyMatchesStatus(SurveySession s, SurveyStatusFilter f) => switch (f) {
      SurveyStatusFilter.active => !s.isArchived,
      SurveyStatusFilter.open => !s.isArchived && !s.isClosed,
      SurveyStatusFilter.closed => !s.isArchived && s.isClosed,
      SurveyStatusFilter.archived => s.isArchived,
    };

/// Időszak szerint: a kezdő időpont alapján. Az egyéni tartomány kezdete
/// zárt, a vége nyílt ([customTo] a tartomány utáni nap eleje).
/// Időszak szerinti szűrés egy időponton. Az egyéni tartomány kezdete zárt,
/// a vége nyílt ([customTo] a tartomány utáni nap eleje).
bool timeFilterMatches(
  DateTime t,
  SurveyTimeFilter f, {
  required DateTime now,
  DateTime? customFrom,
  DateTime? customTo,
}) {
  return switch (f) {
    SurveyTimeFilter.all => true,
    SurveyTimeFilter.last7 =>
      !t.isBefore(now.subtract(const Duration(days: 7))),
    SurveyTimeFilter.last30 =>
      !t.isBefore(now.subtract(const Duration(days: 30))),
    SurveyTimeFilter.thisYear => t.year == now.year,
    SurveyTimeFilter.custom =>
      (customFrom == null || !t.isBefore(customFrom)) &&
          (customTo == null || t.isBefore(customTo)),
  };
}

/// Felmérés időszak szerint: a kezdő időpont alapján.
bool surveyMatchesTime(
  SurveySession s,
  SurveyTimeFilter f, {
  required DateTime now,
  DateTime? customFrom,
  DateTime? customTo,
}) =>
    timeFilterMatches(s.startedAt, f,
        now: now, customFrom: customFrom, customTo: customTo);

/// Ékezetmentes, kisbetűs rendezési kulcs: á→a, é→e, ő→o, ű→u stb.
/// A magyar ABC szerinti rendezéshez és kereséshez kell.
String collationKey(String text) {
  const from = 'áéíóöőúüű';
  const to = 'aeiooouuu';
  final buf = StringBuffer();
  for (final ch in text.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString();
}

String _key(String text) => collationKey(normalizeSearchText(text));

/// Keresés címre és helyszínre (ékezetmentesen, szóköz és kötőjel nélkül).
bool surveyMatchesQuery(SurveySession s, String query) {
  final q = _key(query);
  if (q.isEmpty) return true;
  if (_key(s.title).contains(q)) return true;
  final location = s.location;
  return location != null && _key(location).contains(q);
}

List<SurveySession> sortSurveys(List<SurveySession> list, SurveySort sort) {
  final out = [...list];
  switch (sort) {
    case SurveySort.timeNewest:
      out.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    case SurveySort.timeOldest:
      out.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    case SurveySort.nameAsc:
      out.sort((a, b) => collationKey(a.title).compareTo(collationKey(b.title)));
    case SurveySort.nameDesc:
      out.sort((a, b) => collationKey(b.title).compareTo(collationKey(a.title)));
  }
  return out;
}
