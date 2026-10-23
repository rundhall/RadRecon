import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/services/settings_service.dart';

void main() {
  group('ExpiryLeadTime.alertDayFor', () {
    test('napos előrehozás', () {
      expect(ExpiryLeadTime.oneWeek.alertDayFor(DateTime(2027, 3, 3)),
          DateTime(2027, 2, 24));
      expect(ExpiryLeadTime.twoWeeks.alertDayFor(DateTime(2027, 3, 3)),
          DateTime(2027, 2, 17));
    });

    test('hónapos előrehozás ugyanarra a napra esik', () {
      expect(ExpiryLeadTime.oneMonth.alertDayFor(DateTime(2027, 3, 15)),
          DateTime(2027, 2, 15));
      expect(ExpiryLeadTime.twelveMonths.alertDayFor(DateTime(2027, 3, 15)),
          DateTime(2026, 3, 15));
    });

    test('rövid hónapban a hónap utolsó napjára szorul', () {
      expect(ExpiryLeadTime.oneMonth.alertDayFor(DateTime(2027, 3, 31)),
          DateTime(2027, 2, 28));
    });
  });

  test('mentett érték visszaolvasása; ismeretlen esetén sameDay', () {
    expect(ExpiryLeadTime.fromStorage('month_12'), ExpiryLeadTime.twelveMonths);
    expect(ExpiryLeadTime.fromStorage('nonsense'), ExpiryLeadTime.sameDay);
  });
}
