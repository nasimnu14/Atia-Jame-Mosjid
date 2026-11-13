import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:atia_masjid_accounts/shared/period_choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('FND-6: the default is the current month', () {
    expect(const PeriodChoice.currentMonth().resolve(today),
        Period(DateTime(2026, 11, 1), DateTime(2026, 11, 30)));
  });

  test('FND-4: today, this week (Sat-Fri), this month, this year', () {
    Period p(PeriodMode m) => PeriodChoice(mode: m).resolve(today)!;
    expect(p(PeriodMode.today), Period.day(today));
    expect(p(PeriodMode.week), Period(DateTime(2026, 11, 7), DateTime(2026, 11, 13)));
    expect(p(PeriodMode.month).to, DateTime(2026, 11, 30));
    expect(p(PeriodMode.year), Period(DateTime(2026, 1, 1), DateTime(2026, 12, 31)));
  });

  test('FND-4: any chosen day, week, month or year', () {
    final a = DateTime(2025, 2, 14);
    Period? p(SpecificUnit u) =>
        PeriodChoice(mode: PeriodMode.specific, unit: u, anchor: a).resolve(today);
    expect(p(SpecificUnit.day), Period.day(a));
    expect(p(SpecificUnit.week), Period(DateTime(2025, 2, 8), DateTime(2025, 2, 14)));
    expect(p(SpecificUnit.month), Period(DateTime(2025, 2, 1), DateTime(2025, 2, 28)));
    expect(p(SpecificUnit.year), Period(DateTime(2025, 1, 1), DateTime(2025, 12, 31)));
    expect(const PeriodChoice(mode: PeriodMode.specific).resolve(today), isNull);
  });

  test('FND-5: a range needs both ends, start not after end', () {
    final ok = PeriodChoice(
        mode: PeriodMode.range, from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 5));
    expect(ok.resolve(today), Period(DateTime(2026, 11, 1), DateTime(2026, 11, 5)));
    expect(PeriodChoice(mode: PeriodMode.range, from: DateTime(2026, 11, 1)).resolve(today),
        isNull);
    final reversed = PeriodChoice(
        mode: PeriodMode.range, from: DateTime(2026, 11, 9), to: DateTime(2026, 11, 5));
    expect(reversed.resolve(today), isNull);
    expect(reversed.rangeReversed, isTrue);
    final same = PeriodChoice(
        mode: PeriodMode.range, from: DateTime(2026, 11, 9), to: DateTime(2026, 11, 9));
    expect(same.resolve(today), Period.day(DateTime(2026, 11, 9)));
  });
}
