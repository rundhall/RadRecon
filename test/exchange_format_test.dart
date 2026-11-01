import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/exchange_format.dart';

void main() {
  test('JSON: v1 és v2 azonosító, ismeretlen null', () {
    expect(ExchangeFormat.jsonVersion('rad_recon_export'), 1);
    expect(ExchangeFormat.jsonVersion('rad_recon_export.v2'), 2);
    expect(ExchangeFormat.jsonVersion('rad_recon_export.v3'), 3);
    expect(ExchangeFormat.jsonVersion('valami_mas'), isNull);
    expect(ExchangeFormat.jsonVersion(null), isNull);
  });

  test('CSV: format_version értéke, újabb verzió hibát ad', () {
    expect(ExchangeFormat.checkCsvVersion('2'), 2);
    expect(ExchangeFormat.checkCsvVersion(' 1 '), 1);
    expect(() => ExchangeFormat.checkCsvVersion('3'), throwsFormatException);
    expect(() => ExchangeFormat.checkCsvVersion(''), throwsFormatException);
    expect(() => ExchangeFormat.checkCsvVersion(null), throwsFormatException);
  });

  test('csoportosítás: azonos azonosító egy csoport, a sorrend megmarad', () {
    final rows = [
      {'identifier': 'A', 'nuclide': 'Co-60'},
      {'identifier': 'B', 'nuclide': 'Cs-137'},
      {'identifier': 'A', 'nuclide': 'Am-241'},
    ];
    final groups = ExchangeFormat.groupRowsByIdentifier(rows);
    expect(groups.keys.toList(), ['A', 'B']);
    expect(groups['A']!.length, 2);
    expect(groups['A']!.last['nuclide'], 'Am-241');
  });
}
