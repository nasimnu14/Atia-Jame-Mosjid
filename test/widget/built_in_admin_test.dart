import 'package:atia_masjid_accounts/app/app_state.dart';
import 'package:atia_masjid_accounts/app/built_in_admin.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets(
    'a new computer starts with the built-in Super Admin, once, and can sign in',
    (tester) async {
      final h = await AppHarness.start(tester);
      // Opening the app on a computer with no accounts creates the account
      // (the password work needs real time, so it runs outside the fake clock).
      final state = AppState(h.services, seedBuiltInAdmin: true);
      await tester.runAsync(state.load);
      expect(state.hasUsers, isTrue);
      var users = (await tester.runAsync(() => h.services.users.all()))!;
      expect(users, hasLength(1));
      expect(
        (users.single.name, users.single.username, users.single.role),
        ('Nasim', 'nasimnu14', Role.superAdmin),
      );
      // Opening it again does not make another one.
      await tester.runAsync(AppState(h.services, seedBuiltInAdmin: true).load);
      users = (await tester.runAsync(() => h.services.users.all()))!;
      expect(users, hasLength(1));

      // No set-up screen: straight to sign-in, and the known login works.
      await h.launch();
      expect(find.text('সাইন ইন করুন'), findsOneWidget);
      final f = find.byType(TextFormField);
      await h.enter(f.at(0), builtInAdminUsername);
      await h.enter(f.at(1), builtInAdminPassword);
      await h.tapText('সাইন ইন');
      await h.settle(10);
      expect(find.text('ড্যাশবোর্ড'), findsWidgets);
      expect(find.text('সুপার অ্যাডমিন'), findsWidgets);
    },
  );

  testWidgets('without the option (and on a phone) nothing is created', (
    tester,
  ) async {
    final h = await AppHarness.start(tester);
    await tester.runAsync(AppState(h.services).load);
    expect(await tester.runAsync(() => h.services.users.hasAnyUser()), isFalse);

    final phone = await AppHarness.start(tester, isPhone: true);
    await tester.runAsync(
      AppState(phone.services, seedBuiltInAdmin: true).load,
    );
    expect(
      await tester.runAsync(() => phone.services.users.hasAnyUser()),
      isFalse,
    );
  });
}
