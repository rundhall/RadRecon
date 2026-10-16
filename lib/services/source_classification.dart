import '../models/radiation_source.dart';
import '../models/regulatory_data.dart';
import '../models/regulatory_data_extra.dart';

/// Egy forrás besorolási számítása (D, R, kategória, mentességi értékek).
///
/// Tájékoztató jellegű: a hatósági besorolás mindig a hatályos jogszabály és
/// a hatóság döntése alapján érvényes.

/// Nuklidnév normalizálása a táblák kulcsaihoz ("co60", "CO-60" → "Co-60").
String normalizeNuclideName(String name) {
  final t = name.trim();
  final m = RegExp(r'^([A-Za-z]{1,2})\s*-?\s*(\d{1,3}[mMgG]?)$').firstMatch(t);
  if (m == null) return t;
  final sym = m.group(1)!;
  final mass = m.group(2)!.toLowerCase();
  return '${sym[0].toUpperCase()}${sym.substring(1).toLowerCase()}-$mass';
}

/// Sugárvédelmi kategória a 2/2022. (IV. 29.) OAH rendelet 25. § szerint.
enum RadiationProtectionCategory { i, ii, iii }

/// A számítás körülményei (a 25. § (1) bekezdéséhez).
class ClassificationContext {
  /// Nyitott (nem zárt) sugárforrással végzett rendszeres munkavégzés (44. §).
  final bool unsealedRegularWork;

  /// Sugárveszélyes munkahelyen kívüli alkalmazás.
  final bool outsideWorkplace;

  const ClassificationContext({
    this.unsealedRegularWork = false,
    this.outsideWorkplace = false,
  });
}

class SourceClassification {
  final String nuclide; // normalizált
  final double? activityMBq; // aktuális (bomlással korrigált, ha ismert)
  final bool activityDecayCorrected;
  final double? dTBq;
  final bool dInfinite;
  final double? rValue; // null, ha nem számolható
  final ExemptionValues? exemption;
  final AdrValues? adr;
  final LabClassification? lab;

  const SourceClassification({
    required this.nuclide,
    required this.activityMBq,
    required this.activityDecayCorrected,
    required this.dTBq,
    required this.dInfinite,
    required this.rValue,
    required this.exemption,
    this.adr,
    this.lab,
  });

  /// 1–5. fizikai védelmi kategória a forrás R értékéből.
  int? get physicalCategory =>
      rValue == null ? null : physicalProtectionCategory(rValue!);

  /// Az aktivitás a mentességi aktivitás (MEA) alatt van-e. Null, ha nem
  /// eldönthető.
  bool? get belowExemptActivity {
    final a = activityMBq;
    final e = exemption;
    if (a == null || e == null) return null;
    return a * 1e6 <= e.exemptBq;
  }
}

SourceClassification classifySource(RadiationSource s, DateTime asOf) {
  final nuclide = normalizeNuclideName(s.nuclideName);
  final decayed = s.decayedActivityMBqAt(asOf);
  final activity = decayed ?? s.activityAtManufactureMBq;
  final infinite = kDInfinite.contains(nuclide);
  final d = kDValuesTBq[nuclide];
  double? r;
  if (infinite) {
    r = 0; // D = ∞ → R-hozzájárulás elhanyagolható
  } else if (d != null && d > 0) {
    r = (activity / 1e6) / d; // MBq → TBq
  }
  return SourceClassification(
    nuclide: nuclide,
    activityMBq: activity,
    activityDecayCorrected: decayed != null,
    dTBq: d,
    dInfinite: infinite,
    rValue: r,
    exemption: kExemptionValues[nuclide],
    adr: kAdrValues[nuclide],
    lab: classifyLab(nuclide, activity),
  );
}

/// Fizikai védelmi kategória az R összegből (3/2022. OAH rendelet, Fizvr.):
/// R≥1000 → 1; 1000>R≥10 → 2; 10>R≥1 → 3; 1>R≥0,01 → 4; 0,01>R → 5.
int physicalProtectionCategory(double r) {
  if (r >= 1000) return 1;
  if (r >= 10) return 2;
  if (r >= 1) return 3;
  if (r >= 0.01) return 4;
  return 5;
}

/// ADR: a küldemény aktivitása a mentes küldemény határa (2.2.7.7.2.1
/// táblázat, utolsó oszlop) alatt van-e. Null, ha nincs adat.
bool? adrBelowConsignmentLimit(SourceClassification c) {
  final a = c.activityMBq, v = c.adr;
  if (a == null || v == null) return null;
  return a * 1e6 <= v.exemptConsignmentBq;
}

/// A/A1 és A/A2 arány (aktivitás TBq-ben osztva az A1/A2 értékkel). Null,
/// ha nincs adat vagy az érték korlátlan.
double? adrRatioA1(SourceClassification c) {
  final a = c.activityMBq, v = c.adr;
  if (a == null || v == null || v.a1TBq == null) return null;
  return (a / 1e6) / v.a1TBq!;
}

double? adrRatioA2(SourceClassification c) {
  final a = c.activityMBq, v = c.adr;
  if (a == null || v == null || v.a2TBq == null) return null;
  return (a / 1e6) / v.a2TBq!;
}

/// MSZ 62-7 szerinti izotóplabor-besorolás az AM értékből.
/// Ipari: C < 10 AM; B: 10–10 000 AM; A: > 10 000 AM.
/// Orvosi: I (in vitro) < 1 AM; II (in vivo) < 100 AM; III (terápia)
/// < 10 000 AM. A művelettípusok (A tárolás … E száraz, porlódó) legnagyobb
/// aktivitása AM × {100, 10, 1, 0,1, 0,01}.
class LabClassification {
  final double amMBq;
  final double ratio; // aktivitás / AM
  final String industrial; // 'A' | 'B' | 'C'
  final String? medical; // 'I' | 'II' | 'III' | null (III fölött)
  final List<String> allowedOperations; // aktivitás szerint végezhető

  const LabClassification(this.amMBq, this.ratio, this.industrial,
      this.medical, this.allowedOperations);
}

const List<String> kLabOperationTypes = ['A', 'B', 'C', 'D', 'E'];
const List<double> kLabOperationMultipliers = [100, 10, 1, 0.1, 0.01];

LabClassification? classifyLab(String nuclide, double activityMBq) {
  final am = kLabAmMBq[nuclide];
  if (am == null || am <= 0) return null;
  final m = activityMBq / am;
  final industrial = m < 10 ? 'C' : (m <= 10000 ? 'B' : 'A');
  final medical = m < 1 ? 'I' : (m < 100 ? 'II' : (m < 10000 ? 'III' : null));
  final ops = <String>[
    for (var i = 0; i < kLabOperationTypes.length; i++)
      if (m <= kLabOperationMultipliers[i]) kLabOperationTypes[i],
  ];
  return LabClassification(am, m, industrial, medical, ops);
}

/// Fizikai védelmi szint a 190/2011. (IX. 19.) Korm. rendelet 7. § szerint
/// radioaktív sugárforrásra: 1. kategória → B; 2., 3. → C; 4., 5. → D.
/// (Hordozható eszközben alkalmazott zárt forrás vizsgáló laboratóriumon
/// kívüli alkalmazása a 2–5. kategóriánál kivétel.)
String physicalProtectionLevel(int physicalCategory) {
  if (physicalCategory <= 1) return 'B';
  if (physicalCategory <= 3) return 'C';
  return 'D';
}

/// A 2/2022. OAH rendelet 25. § (1) bekezdése szerinti sugárvédelmi
/// kategória a fizikai védelmi kategóriából. Zárt sugárforrásnál: 1 → I.;
/// 2, 3 → II.; 4, 5 → III. A 2. kategória munkahelyen kívüli alkalmazása
/// I.; nyitott forrással végzett rendszeres munka: 2 → I., 3 és 4 → II.
/// Az 5. kategória nyitott forrással itt III.-nak számít (nincs külön
/// előírás).
RadiationProtectionCategory protectionCategoryFor(
    int physicalCategory, ClassificationContext ctx) {
  switch (physicalCategory) {
    case 1:
      return RadiationProtectionCategory.i;
    case 2:
      if (ctx.outsideWorkplace || ctx.unsealedRegularWork) {
        return RadiationProtectionCategory.i;
      }
      return RadiationProtectionCategory.ii;
    case 3:
      return RadiationProtectionCategory.ii;
    case 4:
      return ctx.unsealedRegularWork
          ? RadiationProtectionCategory.ii
          : RadiationProtectionCategory.iii;
    default:
      return RadiationProtectionCategory.iii;
  }
}

/// A források R összege. A `unknown` azoknak a forrásoknak a száma, amelyeknél
/// az R nem számolható (ismeretlen nuklid a D-táblában).
class AggregateR {
  final double sum;
  final int unknown;
  const AggregateR(this.sum, this.unknown);
  int get category => physicalProtectionCategory(sum);
}

AggregateR aggregateR(Iterable<SourceClassification> items) {
  var sum = 0.0;
  var unknown = 0;
  for (final c in items) {
    if (c.rValue == null) {
      unknown++;
    } else {
      sum += c.rValue!;
    }
  }
  return AggregateR(sum, unknown);
}
