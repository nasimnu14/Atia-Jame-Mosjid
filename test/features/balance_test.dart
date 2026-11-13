import 'package:atia_masjid_accounts/features/settings/settings_service.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:atia_masjid_accounts/shared/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());

  test('BAL-3: balance = opening + all income − all expense', () async {
    await env.settings.setOpeningBalance(env.admin, 120000, DateTime(2026, 1, 1));
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

  test('BAL-4 / EDT-4: period summary, cancelled excluded and counted apart', () async {
    final p = Period.monthOf(DateTime(2026, 11, 1));
    await env.addIncome(receipt: 1, amount: 1000, date: DateTime(2026, 11, 2));
    final x = await env.addIncome(receipt: 2, amount: 9999, date: DateTime(2026, 11, 3));
    await env.addIncome(receipt: 3, amount: 5000, date: DateTime(2026, 10, 30)); // outside
    await env.addExpense(receipt: 1, amount: 400, date: DateTime(2026, 11, 5));
    await env.entries.cancel(env.admin, x.entry.id, 'ভুল');
    final s = await env.balance.summary(p);
    expect((s.incomeTotal, s.incomeCount), (1000, 1));
    expect((s.expenseTotal, s.expenseCount), (400, 1));
    expect(s.net, 600);
    expect(s.cancelledCount, 1);
  });

  test('empty period gives zeros', () async {
    final s = await env.balance.summary(Period.day(DateTime(2020, 1, 1)));
    expect((s.incomeTotal, s.expenseTotal, s.net), (0, 0, 0));
  });

  test('BAL-1/BAL-2: only Admin or Super Admin set the opening balance', () async {
    await expectLater(env.settings.setOpeningBalance(env.user, 10, DateTime(2026)),
        throwsA(isA<PermissionDeniedException>()));
    await env.settings.setOpeningBalance(env.admin, 10, DateTime(2026, 1, 1));
    await env.settings.setOpeningBalance(env.superAdmin, 20, DateTime(2026, 2, 1));
    final ob = (await env.settings.openingBalance())!;
    expect((ob.amount, ob.date), (20, DateTime(2026, 2, 1)));
    await expectLater(env.settings.setOpeningBalance(env.admin, -1, DateTime(2026)),
        throwsA(isA<SettingsException>()));
  });

  test('approver list: Admin edits, User cannot (EXP-7), never deleted', () async {
    await expectLater(env.settings.addApprover(env.user, 'কেউ'),
        throwsA(isA<PermissionDeniedException>()));
    final a = await env.settings.addApprover(env.admin, 'ক্যাশিয়ার');
    await expectLater(env.settings.addApprover(env.admin, 'ক্যাশিয়ার'),
        throwsA(isA<SettingsException>()));
    await env.settings.setApproverActive(env.admin, a.id, false);
    expect((await env.settings.approvers()).any((x) => x.id == a.id), isFalse);
    expect((await env.settings.approvers(activeOnly: false)).any((x) => x.id == a.id),
        isTrue);
  });
}
