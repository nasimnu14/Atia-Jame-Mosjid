import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// Not a check: renders screens to PNG when SHOT_DIR is set, to look at them.
void main() {
  testApp('screenshots: setup, sign in, users, settings', (tester) async {
    final h = await AppHarness.start(tester);
    await h.launch();
    await h.shot('01_setup_bn');
    await h.tapText('English');
    await h.shot('02_setup_en');
    await h.tapText('বাংলা');

    await tester.runAsync(() async {
      final s = await h.services.users.createSuperAdmin(
          name: 'আব্দুর রহমান', username: 'rahman', password: 'secret1');
      await h.services.users.addUser(s,
          name: 'মোঃ ইউসুফ', username: 'yousuf', password: 'secret2', role: Role.admin);
      await h.services.users.addUser(s,
          name: 'রাশেদুল হাসান', username: 'rashed', password: 'secret3', role: Role.user);
      await h.services.settings.addApprover(s, 'সভাপতি');
      await h.services.settings.addApprover(s, 'সেক্রেটারী');
    });
    await h.tester.pumpWidget(const SizedBox());
    await h.launch();
    await h.shot('03_signin');
    final fields = find.byType(TextFormField);
    await h.enter(fields.at(0), 'rahman');
    await h.enter(fields.at(1), 'secret1');
    await h.tapText('সাইন ইন');
    await h.settle(8);
    await h.tapText('ব্যবহারকারী');
    await h.shot('04_users');
    await h.tapText('সেটিংস');
    await h.shot('05_settings');
  });
}
