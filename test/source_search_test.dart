import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/source_search.dart';

void main() {
  test('üres keresés minden forrásra illeszkedik', () {
    expect(
      sourceMatchesQuery(identifier: 'T-1', nuclides: const ['Cs-137'], query: '  '),
      isTrue,
    );
  });

  test('a nuklid írásmódja nem számít (kötőjel, szóköz, kis/nagybetű)', () {
    for (final q in ['cs137', 'CS 137', 'cs-137', 'Cs-137']) {
      expect(
        sourceMatchesQuery(identifier: 'T-1', nuclides: const ['Cs-137'], query: q),
        isTrue,
        reason: q,
      );
    }
  });

  test('a többnuklidos forrás másodlagos nuklidjára is talál', () {
    expect(
      sourceMatchesQuery(
        identifier: 'T-2',
        nuclides: const ['Co-60', 'Cs-137'],
        query: 'cs137',
      ),
      isTrue,
    );
  });

  test('az azonosító részletére is talál', () {
    expect(
      sourceMatchesQuery(identifier: 'T-20260101-120000', nuclides: const [], query: '0101-12'),
      isTrue,
    );
  });

  test('nem egyező keresésre nem talál', () {
    expect(
      sourceMatchesQuery(identifier: 'T-1', nuclides: const ['Am-241'], query: 'cs137'),
      isFalse,
    );
  });
}
