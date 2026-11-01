import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/person.dart';
import 'package:rad_recon/models/session_person_link.dart';
import 'package:rad_recon/models/victim_details.dart';

void main() {
  test('jelölések JSON-ban körbeérnek', () {
    final markers = [
      const BodyMarker(side: BodySide.front, x: 0.4, y: 0.2, kind: MarkerKind.injury, note: 'égés'),
      const BodyMarker(side: BodySide.back, x: 0.5, y: 0.7, kind: MarkerKind.contamination, isotope: 'Cs-137'),
    ];
    final back = bodyMarkersFromJson(bodyMarkersToJson(markers));
    expect(back.length, 2);
    expect(back[0].kind, MarkerKind.injury);
    expect(back[0].note, 'égés');
    expect(back[1].side, BodySide.back);
    expect(back[1].isotope, 'Cs-137');
    expect(bodyMarkersToJson(const []), isNull);
  });

  test('sérülés jelöléshez vegyi és biológiai szennyező is megadható', () {
    const m = BodyMarker(
      side: BodySide.front,
      x: 0.3,
      y: 0.3,
      kind: MarkerKind.injury,
      note: 'bőrégés',
      chemical: 'Klór',
      biological: 'Egyes baktérium',
    );
    final back = bodyMarkersFromJson(bodyMarkersToJson([m])).single;
    expect(back.chemical, 'Klór');
    expect(back.biological, 'Egyes baktérium');
    expect(back.isotope, isNull);
    expect(back.contaminantText, 'Klór + Egyes baktérium');
    expect(back.hasContaminant, isTrue);
  });

  test('szennyező nélküli jelölés nem szennyezett', () {
    const m = BodyMarker(side: BodySide.back, x: 0.5, y: 0.5, kind: MarkerKind.injury);
    expect(m.hasContaminant, isFalse);
    expect(m.contaminantText, isEmpty);
  });

  test('a fantomrajz jelölései a felméréshez rendelt személyen megmaradnak', () {
    final link = SessionPersonLink(
      id: 1,
      surveySessionId: 2,
      personId: 3,
      createdAt: DateTime(2026, 11, 1),
      role: SessionPersonRole.victim,
      triage: TriageCategory.immediate,
      bodyMarkers: const [
        BodyMarker(side: BodySide.front, x: 0.1, y: 0.1, kind: MarkerKind.injury),
      ],
    );
    final back = SessionPersonLink.fromMap(link.toMap());
    expect(back.bodyMarkers.single.kind, MarkerKind.injury);
    expect(back.triage, TriageCategory.immediate);
  });

  test('nem, kor, súly és magasság a személy adatlapján megmarad', () {
    final person = Person(
      name: 'Teszt Elek',
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      sex: VictimSex.female,
      ageYears: 34,
      weightKg: 62.5,
      heightCm: 168,
    );
    final back = Person.fromMap(person.toMap());
    expect(back.sex, VictimSex.female);
    expect(back.ageYears, 34);
    expect(back.weightKg, 62.5);
    expect(back.heightCm, 168);
  });

  test('azonosító és cím a személyen megmarad', () {
    final person = Person(
      name: 'Teszt Elek',
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      identifier: 'TK-0042',
      address: 'Példa utca 1.',
    );
    final back = Person.fromMap(person.toMap());
    expect(back.identifier, 'TK-0042');
    expect(back.address, 'Példa utca 1.');
  });

  test('régi sornál nincs testi adat', () {
    expect(VictimSex.fromDbValue(null), isNull);
    expect(bodyMarkersFromJson(null), isEmpty);
  });
}
