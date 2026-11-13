import 'package:atia_masjid_accounts/features/reports/balance_service.dart';
import 'package:atia_masjid_accounts/features/settings/settings_service.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:atia_masjid_accounts/shared/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

void main() {
  breakdownTests();
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());

  test('BAL-3: balance = opening + all income − all expense', () async {
    await env.settings.setOpeningBalance(
      env.admin,
      120000,
      DateTime(2026, 1, 1),
    );
    await env.addIncome(receipt: 1, amount: 5000);
    await env.addIncome(receipt: 2, amount: 500);
    await env.addExpense(receipt: 1, amount: 12500);
    expect(await env.balance.currentBalance(), 120000 + 5500 - 12500);
  });

  test('balance with no opening balance set starts from 0', () async {
    await env.addIncome(amount: 700);
    expect(await env.balance.currentBalance(), 700);
  });

  test('EDT-4: cancelled entries are left out of the balance', () async {
    await env.settings.setOpeningBalance(env.admin, 1000, DateTime(2026, 1, 1));
    final a = await env.addIncome(receipt: 1, amount: 5000);
    final b = await env.addExpense(receipt: 1, amount: 300);
    await env.addIncome(receipt: 2, amount: 100);
    expect(await env.balance.currentBalance(), 1000 + 5100 - 300);
    await env.entries.cancel(env.admin, a.entry.id, 'ভুল');
    expect(await env.balance.currentBalance(), 1000 + 100 - 300);
    await env.entries.cancel(env.admin, b.entry.id, 'ভুল');
    expect(await env.balance.currentBalance(), 1000 + 100);
  });

  test(
    'BAL-4 / EDT-4: period summary, cancelled excluded and counted apart',
    () async {
      final p = Period.monthOf(DateTime(2026, 11, 1));
      await env.addIncome(
        receipt: 1,
        amount: 1000,
        date: DateTime(2026, 11, 2),
      );
      final x = await env.addIncome(
        receipt: 2,
        amount: 9999,
        date: DateTime(2026, 11, 3),
      );
      await env.addIncome(
        receipt: 3,
        amount: 5000,
        date: DateTime(2026, 10, 30),
      ); // outside
      await env.addExpense(
        receipt: 1,
        amount: 400,
        date: DateTime(2026, 11, 5),
      );
      await env.entries.cancel(env.admin, x.entry.id, 'ভুল');
      final s = await env.balance.summary(p);
      expect((s.incomeTotal, s.incomeCount), (1000, 1));
      expect((s.expenseTotal, s.expenseCount), (400, 1));
      expect(s.net, 600);
      expect(s.cancelledCount, 1);
    },
  );

  test('empty period gives zeros', () async {
    final s = await env.balance.summary(Period.day(DateTime(2020, 1, 1)));
    expect((s.incomeTotal, s.expenseTotal, s.net), (0, 0, 0));
  });

  test(
    'BAL-1/BAL-2: only Admin or Super Admin set the opening balance',
    () async {
      await expectLater(
        env.settings.setOpeningBalance(env.user, 10, DateTime(2026)),
        throwsA(isA<PermissionDeniedException>()),
      );
      await env.settings.setOpeningBalance(env.admin, 10, DateTime(2026, 1, 1));
      await env.settings.setOpeningBalance(
        env.superAdmin,
        20,
        DateTime(2026, 2, 1),
      );
      final ob = (await env.settings.openingBalance())!;
      expect((ob.amount, ob.date), (20, DateTime(2026, 2, 1)));
      await expectLater(
        env.settings.setOpeningBalance(env.admin, -1, DateTime(2026)),
        throwsA(isA<SettingsException>()),
      );
    },
  );

  test(
    'approver list: Admin edits, User cannot (EXP-7), never deleted',
    () async {
      await expectLater(
        env.settings.addApprover(env.user, 'কেউ'),
        throwsA(isA<PermissionDeniedException>()),
      );
      final a = await env.settings.addApprover(env.admin, 'ক্যাশিয়ার');
      await expectLater(
        env.settings.addApprover(env.admin, 'ক্যাশিয়ার'),
        throwsA(isA<SettingsException>()),
      );
      await env.settings.setApproverActive(env.admin, a.id, false);
      expect(
        (await env.settings.approvers()).any((x) => x.id == a.id),
        isFalse,
      );
      expect(
        (await env.settings.approvers(
          activeOnly: false,
        )).any((x) => x.id == a.id),
        isTrue,
      );
    },
  );
}

void breakdownTests() {
  group('summary breakdown buckets', () {
    test(
      'a month is cut into Saturday-to-Friday weeks, clipped at the ends',
      () {
        final (unit, b) = breakdownBuckets(
          Period.monthOf(DateTime(2026, 11, 1)),
        );
        expect(unit, BreakdownUnit.week);
        expect(b.map((p) => '${p.from.day}-${p.to.day}'), [
          '1-6',
          '7-13',
          '14-20',
          '21-27',
          '28-30',
        ]);
      },
    );
    test('a week is shown day by day', () {
      final (unit, b) = breakdownBuckets(Period.weekOf(DateTime(2026, 11, 13)));
      expect(unit, BreakdownUnit.day);
      expect(b.length, 7);
    });
    test('a year is shown month by month; a leap February has 29 days', () {
      final (unit, b) = breakdownBuckets(Period.yearOf(DateTime(2024, 6, 1)));
      expect(unit, BreakdownUnit.month);
      expect(b.length, 12);
      expect(b[1].to, DateTime(2024, 2, 29));
    });
    test('buckets cover the period exactly, with no gaps or overlaps', () {
      for (final p in [
        Period(DateTime(2026, 10, 3), DateTime(2026, 11, 20)),
        Period(DateTime(2025, 12, 30), DateTime(2026, 3, 2)),
        Period.day(DateTime(2026, 1, 1)),
      ]) {
        final (_, b) = breakdownBuckets(p);
        expect(b.first.from, p.from);
        expect(b.last.to, p.to);
        for (var i = 1; i < b.length; i++) {
          expect(
            b[i].from,
            DateTime(b[i - 1].to.year, b[i - 1].to.month, b[i - 1].to.day + 1),
          );
        }
      }
    });
    test(
      'breakdown totals add up to the period summary, cancelled left out',
      () async {
        final env = await TestEnv.create();
        await env.addIncome(
          receipt: 1,
          amount: 1000,
          date: DateTime(2026, 11, 2),
        );
        await env.addIncome(
          receipt: 2,
          amount: 2000,
          date: DateTime(2026, 11, 10),
        );
        final x = await env.addIncome(
          receipt: 3,
          amount: 777,
          date: DateTime(2026, 11, 11),
        );
        await env.addExpense(
          receipt: 1,
          amount: 400,
          date: DateTime(2026, 11, 29),
        );
        await env.entries.cancel(env.admin, x.entry.id, 'ভুল');
        final month = Period.monthOf(DateTime(2026, 11, 1));
        final (_, rows) = await env.balance.breakdown(month);
        expect(rows.fold<int>(0, (a, r) => a + r.summary.incomeTotal), 3000);
        expect(rows.fold<int>(0, (a, r) => a + r.summary.expenseTotal), 400);
        expect((await env.balance.summary(month)).net, 2600);
        expect((await env.entries.recent(limit: 2)).map((e) => e.receiptNo), [
          1,
          3,
        ]);
      },
    );
  });
}
