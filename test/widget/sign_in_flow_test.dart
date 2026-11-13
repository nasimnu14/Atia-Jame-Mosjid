import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('first launch: set-up screen in Bangla; creates the Super Admin',
      (tester) async {
    final h = await AppHarness.start(tester);
    await h.launch();

    expect(find.text('আটিয়া জামে মসজিদের হিসাব অ্যাপে স্বাগতম'), findsOneWidget);
    expect(find.text('নতুনভাবে শুরু করুন'), findsOneWidget);
    expect(find.text('ব্যাকআপ থেকে ফিরিয়ে আনুন'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await h.enter(fields.at(0), 'আব্দুর রহমান');
    await h.enter(fields.at(1), 'Rahman');
    await h.enter(fields.at(2), 'secret1');
    await h.enter(fields.at(3), 'secret2'); // does not match
    await h.tapText('অ্যাকাউন্ট তৈরি করে শুরু করুন');
    expect(find.text('দুটি পাসওয়ার্ড মিলছে না'), findsOneWidget);
    expect(await tester.runAsync(() => h.services.users.hasAnyUser()), isFalse);

    await h.enter(fields.at(3), 'secret1');
    await h.tapText('অ্যাকাউন্ট তৈরি করে শুরু করুন');
    await h.settle(8);

    // Signed in as Super Admin: the dashboard menu is showing.
    expect(find.text('ড্যাশবোর্ড'), findsWidgets);
    expect(find.text('সুপার অ্যাডমিন'), findsWidgets);
    final users = await tester.runAsync(() => h.services.users.all());
    expect(users!.single.username, 'rahman'); // lower-cased
    expect(users.single.role, Role.superAdmin);
  });

  testWidgets('sign in: wrong password is refused, right password works',
      (tester) async {
    final h = await AppHarness.start(tester);
    await tester.runAsync(() => h.services.users
        .createSuperAdmin(name: 'Super', username: 'super', password: 'secret1'));
    await h.launch();

    expect(find.text('সাইন ইন করুন'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await h.enter(fields.at(0), 'super');
    await h.enter(fields.at(1), 'wrong!!');
    await h.tapText('সাইন ইন');
    await h.settle(6);
    expect(find.text('ইউজারনেম বা পাসওয়ার্ড ভুল'), findsOneWidget);

    await h.enter(fields.at(1), 'secret1');
    await h.tapText('সাইন ইন');
    await h.settle(8);
    expect(find.text('সাইন ইন করুন'), findsNothing);
    expect(find.text('Super'), findsWidgets); // the name shows in the menu
  });

  testWidgets('a disabled user cannot sign in (USR-6)', (tester) async {
    final h = await AppHarness.start(tester);
    await tester.runAsync(() async {
      final s = await h.services.users
          .createSuperAdmin(name: 'Super', username: 'super', password: 'secret1');
      final u = await h.services.users.addUser(s,
          name: 'U', username: 'u1', password: 'secret3', role: Role.user);
      await h.services.users.setActive(s, u.id, false);
    });
    await h.launch();
    final fields = find.byType(TextFormField);
    await h.enter(fields.at(0), 'u1');
    await h.enter(fields.at(1), 'secret3');
    await h.tapText('সাইন ইন');
    await h.settle(6);
    expect(find.text('এই অ্যাকাউন্টটি নিষ্ক্রিয়। সুপার অ্যাডমিনকে বলুন।'), findsOneWidget);
  });

  testWidgets('GEN-2/GEN-3: switching language changes the screen and is remembered',
      (tester) async {
    final h = await AppHarness.start(tester);
    await h.launch();
    expect(find.text('নতুনভাবে শুরু করুন'), findsOneWidget);
    await h.tapText('English');
    expect(find.text('Start fresh'), findsOneWidget);
    expect(find.text('নতুনভাবে শুরু করুন'), findsNothing);
    expect(
        await tester.runAsync(() => h.services.settingsRepo.get(SettingKey.language)),
        'en');
    await h.tapText('বাংলা');
    expect(find.text('নতুনভাবে শুরু করুন'), findsOneWidget);
  });

  testWidgets('the menu shows only what each role may use (USR-2)',
      (tester) async {
    Future<void> signInAs(AppHarness h, String user, String pass) async {
      final fields = find.byType(TextFormField);
      await h.enter(fields.at(0), user);
      await h.enter(fields.at(1), pass);
      await h.tapText('সাইন ইন');
      await h.settle(8);
    }

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

    await signInAs(h, 'usr', 'secret3');
    expect(find.text('ব্যবহারকারী'), findsNothing);
    expect(find.text('ব্যাকআপ'), findsNothing);
    expect(find.text('সেটিংস'), findsOneWidget);
  });
}
