import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/contributors.dart';

void main() {
  test('érvényes elemek feldolgozása, hibás elemek kihagyása', () {
    final list = ContributorList.fromJson({
      'organizations': [
        {'name': 'Példa Kft.', 'roles': ['testing']},
        {'name': '  '},
        42,
      ],
      'people': [
        {'name': 'Kovács Anna', 'organization': 'Példa Kft.', 'roles': ['review', 7]},
        {'organization': 'névtelen'},
      ],
    });
    expect(list.organizations.length, 1);
    expect(list.people.length, 1);
    expect(list.people.first.organization, 'Példa Kft.');
    expect(list.people.first.roles, ['review']);
    expect(list.isEmpty, isFalse);
  });

  test('üres vagy hibás JSON üres listát ad', () {
    expect(ContributorList.fromJson(null).isEmpty, isTrue);
    expect(ContributorList.fromJson('x').isEmpty, isTrue);
    expect(ContributorList.fromJson({'people': 'x'}).isEmpty, isTrue);
  });
}
