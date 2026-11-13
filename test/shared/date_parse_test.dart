import 'package:atia_masjid_accounts/shared/date_parse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('typed dates (GEN-7, GEN-8)', () {
    test('English digits', () {
      expect(parseTypedDate('13/11/2026').date, DateTime(2026, 11, 13));
    });
    test('Bangla digits', () {
      expect(parseTypedDate('১৩/১১/২০২৬').date, DateTime(2026, 11, 13));
    });
    test('mixed digits and other separators', () {
      expect(parseTypedDate('১৩-11-২০২৬').date, DateTime(2026, 11, 13));
      expect(parseTypedDate('1.2.2026').date, DateTime(2026, 2, 1));
      expect(parseTypedDate(' 5 / 3 / 2026 ').date, DateTime(2026, 3, 5));
    });
    test('31/02/2026 does not exist and says why', () {
      final r = parseTypedDate('31/02/2026');
      expect(r.isOk, isFalse);
      expect(r.problem, DateParseProblem.dayNotInMonth);
      expect(r.maxDay, 28);
      expect(r.month, 2);
    });
    test('31/04 and 30/02 and Bangla 31/02 are refused', () {
      expect(
        parseTypedDate('31/04/2026').problem,
        DateParseProblem.dayNotInMonth,
      );
      expect(
        parseTypedDate('30/02/2024').problem,
        DateParseProblem.dayNotInMonth,
      );
      expect(
        parseTypedDate('৩১/০২/২০২৬').problem,
        DateParseProblem.dayNotInMonth,
      );
    });
    test('leap day', () {
      expect(parseTypedDate('29/02/2024').date, DateTime(2024, 2, 29));
      expect(
        parseTypedDate('29/02/2026').problem,
        DateParseProblem.dayNotInMonth,
      );
    });
    test('month 13, day 0, bad shapes, empty', () {
      expect(parseTypedDate('10/13/2026').problem, DateParseProblem.month);
      expect(
        parseTypedDate('00/10/2026').problem,
        DateParseProblem.dayNotInMonth,
      );
      expect(parseTypedDate('13/11/26').problem, DateParseProblem.format);
      expect(parseTypedDate('hello').problem, DateParseProblem.format);
      expect(parseTypedDate('').problem, DateParseProblem.empty);
      expect(parseTypedDate('   ').problem, DateParseProblem.empty);
      expect(parseTypedDate('13/11/1800').problem, DateParseProblem.year);
    });
  });
}
