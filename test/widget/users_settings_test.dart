import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Future<AppHarness> startSignedIn(WidgetTester tester,
    {String user = 'super', String pass = 'secret1'}) async {
  final h = await AppHarness.start(tester);
  await tester.runAsync(() async {
    final s = await h.services.users
        .createSuperAdmin(name: 'Super', username: 'super', password: 'secret1');
    await h.services.users.addUser(s,
        name: 'Adm', username: 'adm', password: 'secret2', role: Role.admin);
    await h.services.users.addUser(s,
        name: 'Usr', username: 'usr', password: 'secret3', role: Role.user);
  });
  await h.launch();
  final fields = find.byType(TextFormField);
  await h.enter(fields.at(0), user);
  await h.enter(fields.at(1), pass);
  await h.tapText('সাইন ইন');
  await h.settle(8);
  return h;
}

void main() {
  testApp('Super Admin adds a user from the Users screen (USR-4)', (tester) async {
    final h = await startSignedIn(tester);
    await h.tapText('ব্যবহারকারী');
    expect(find.text('Adm'), findsOneWidget);
    expect(find.text('Usr'), findsOneWidget);

    await h.tapText('+ নতুন ব্যবহারকারী');
    final dialogFields = find.descendant(
        of: find.byType(Dialog), matching: find.byType(TextFormField));
    await h.enter(dialogFields.at(0), 'সাইফুল ইসলাম');
    await h.enter(dialogFields.at(1), 'Saiful');
    await h.enter(dialogFields.at(2), 'secret9');
    await h.enter(dialogFields.at(3), 'secret9');
    await h.tapText('যোগ করুন');
    await h.settle(8);

    expect(find.text('সাইফুল ইসলাম'), findsOneWidget);
    final all = await tester.runAsync(() => h.services.users.all());
    final saiful = all!.firstWhere((u) => u.username == 'saiful');
    expect(saiful.role, Role.user); // default role
  });

  testApp('adding a user with a taken username shows the reason', (tester) async {
    final h = await startSignedIn(tester);
    await h.tapText('ব্যবহারকারী');
    await h.tapText('+ নতুন ব্যবহারকারী');
    final f = find.descendant(of: find.byType(Dialog), matching: find.byType(TextFormField));
    await h.enter(f.at(0), 'অন্য');
    await h.enter(f.at(1), 'ADM');
    await h.enter(f.at(2), 'secret9');
    await h.enter(f.at(3), 'secret9');
    await h.tapText('যোগ করুন');
    await h.settle(8);
    expect(find.text('এই ইউজারনেমটি আগেই নেওয়া হয়েছে'), findsOneWidget);
  });

  testApp('Super Admin disables a user; the Super Admin row has no actions',
      (tester) async {
    final h = await startSignedIn(tester);
    await h.tapText('ব্যবহারকারী');
    expect(find.text('নিষ্ক্রিয় করুন'), findsNWidgets(2)); // Adm and Usr
    expect(find.textContaining('আপনি —'), findsOneWidget);
    await tester.tap(find.text('নিষ্ক্রিয় করুন').last);
    await h.settle(6);
    final u = (await tester.runAsync(() => h.services.users.all()))!
        .firstWhere((u) => u.username == 'usr');
    expect(u.isActive, isFalse);
    expect(find.text('নিষ্ক্রিয়'), findsOneWidget);
  });

  testApp('Admin: opening balance and approver list work (BAL-1, EXP-7)',
      (tester) async {
    final h = await startSignedIn(tester, user: 'adm', pass: 'secret2');
    expect(find.text('ব্যবহারকারী'), findsNothing); // Super Admin only
    await h.tapText('সেটিংস');

    final amount = find.byType(TextField).first;
    await h.enter(amount, '৳ ১,২০,০০০');
    await h.tapText('সংরক্ষণ করুন');
    final ob = await tester.runAsync(() => h.services.settings.openingBalance());
    expect(ob!.amount, 120000);

    await h.enter(find.widgetWithText(TextField, 'অনুমোদনকারীর নাম'), 'ক্যাশিয়ার');
    await h.tapText('অনুমোদনকারী যোগ করুন');
    await h.settle(6);
    expect(find.text('ক্যাশিয়ার'), findsOneWidget);
    final names = (await tester.runAsync(() => h.services.settings.approvers()))!
        .map((a) => a.name);
    expect(names, contains('ক্যাশিয়ার'));
  });

  testApp('a User sees only language, password and app cards in Settings',
      (tester) async {
    final h = await startSignedIn(tester, user: 'usr', pass: 'secret3');
    await h.tapText('সেটিংস');
    expect(find.text('প্রারম্ভিক ব্যালেন্স'), findsNothing);
    expect(find.text('ব্যয় অনুমোদনকারী'), findsNothing);
    expect(find.text('আমার পাসওয়ার্ড'), findsOneWidget);
    expect(find.text('ভাষা'), findsWidgets);
  });

  testApp('change own password needs the current one (USR-7)', (tester) async {
    final h = await startSignedIn(tester, user: 'usr', pass: 'secret3');
    await h.tapText('সেটিংস');
    final f = find.byType(TextFormField);
    await h.enter(f.at(0), 'wrong!!');
    await h.enter(f.at(1), 'newpass1');
    await h.enter(f.at(2), 'newpass1');
    await h.tapText('পাসওয়ার্ড বদলান');
    await h.settle(6);
    expect(find.text('বর্তমান পাসওয়ার্ড ভুল'), findsOneWidget);

    await h.enter(f.at(0), 'secret3');
    await h.tapText('পাসওয়ার্ড বদলান');
    await h.settle(8);
    final ok = await tester.runAsync(() => h.services.users.signIn('usr', 'newpass1'));
    expect(ok!.username, 'usr');
  });
}
