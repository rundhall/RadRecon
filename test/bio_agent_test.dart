import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/bio_agent.dart';
import 'package:rad_recon/models/sample_analysis.dart';

void main() {
  test('biológiai anyag lista JSON-ban körbeér', () {
    final items = [
      const BioAgentReading(name: 'Minta A', kind: BioKind.virus, quantity: '2 törlet'),
      const BioAgentReading(name: 'Minta B', kind: BioKind.other),
    ];
    final back = BioAgentReading.listFromJsonString(
      BioAgentReading.listToJsonString(items),
    );
    expect(back.length, 2);
    expect(back[0].name, 'Minta A');
    expect(back[0].kind, BioKind.virus);
    expect(back[0].quantity, '2 törlet');
    expect(back[1].quantity, '');
    expect(bioAgentsSummary(back), 'Minta A, Minta B');
  });

  test('régi sor bio_json nélkül üres lista', () {
    expect(BioAgentReading.listFromJsonString(null), isEmpty);
  });

  test('PCR mintavizsgálat mezői megmaradnak', () {
    final a = SampleAnalysis(
      measurementPointId: 1,
      method: SampleAnalysisMethod.pcr,
      performedAt: DateTime(2026, 11, 1, 10),
      createdAt: DateTime(2026, 11, 1, 10),
      pcrTarget: 'Célgén',
      pcrOutcome: PcrOutcome.positive,
      pcrCt: 24.5,
    );
    final back = SampleAnalysis.fromMap(a.toMap()..['id'] = 5);
    expect(back.method, SampleAnalysisMethod.pcr);
    expect(back.pcrTarget, 'Célgén');
    expect(back.pcrOutcome, PcrOutcome.positive);
    expect(back.pcrCt, 24.5);
  });
}
