import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/app_harness.dart';

/// Not a check: renders screens to PNG when SHOT_DIR is set, to look at them
/// next to the designs.
void main() {
  testApp('screenshots: setup, sign in, users, settings, entries', (tester) async {
    final png = Uint8List.fromList(img.encodePng(img.fill(
        img.Image(width: 160, height: 120), color: img.ColorRgb8(150, 170, 160))));
    final h = await AppHarness.start(tester,
        picker: FakePhotoPicker([png]), now: DateTime(2026, 11, 13, 10));
    await h.launch();
    await h.shot('01_setup_bn');
    await h.tapText('English');
    await h.shot('02_setup_en');
    await h.tapText('বাংলা');

    late final User s, a;
    await tester.runAsync(() async {
      s = await h.services.users.createSuperAdmin(
          name: 'আব্দুর রহমান', username: 'rahman', password: 'secret1');
      a = await h.services.users.addUser(s,
          name: 'মোঃ ইউসুফ', username: 'yousuf', password: 'secret2', role: Role.admin);
      await h.services.users.addUser(s,
          name: 'রাশেদুল হাসান', username: 'rashed', password: 'secret3', role: Role.user);
      await h.services.settings.addApprover(s, 'সভাপতি');
      await h.services.settings.addApprover(s, 'সেক্রেটারী');
      Future<void> inc(int no, String name, int amt, DateTime d, {String? addr}) =>
          h.services.entries.create(
              s,
              EntryDraft(
                  type: EntryType.income,
                  receiptNo: no,
                  date: d,
                  name: name,
                  amount: amt,
                  address: addr ?? ''));
      await inc(6685, 'আব্দুল করিম', 5000, DateTime(2026, 11, 13), addr: 'ঘোড়াশাল বাজার');
      await inc(6684, '', 500, DateTime(2026, 11, 13));
      await inc(6683, 'ডাব বিক্রি', 1050, DateTime(2026, 11, 12), addr: 'মসজিদ প্রাঙ্গণ');
      await inc(6679, 'জসিম উদ্দিন', 10000, DateTime(2026, 11, 10), addr: 'নরসিংদী');
      final cancelled = (await h.services.entries.findByReceipt(EntryType.income, 6679)).single;
      await h.services.entries.cancel(a, cancelled.id, 'ভুল এন্ট্রি');
      await h.services.entries.create(
          s,
          EntryDraft(
              type: EntryType.expense,
              receiptNo: 593,
              date: DateTime(2026, 11, 13),
              name: 'মোঃ হানিফ',
              purpose: 'রাজমিস্ত্রির মজুরি',
              approverName: 'সভাপতি',
              amount: 12500));
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
    await h.tapText('আয়');
    await h.shot('06_income_list');
    await h.tapText('+ নতুন আয়');
    await h.settle(6);
    await h.shot('07_income_form');
    await h.tapText('ফিরে যান');
    await h.settle(6);
    await h.tapText('আব্দুল করিম');
    await h.settle(6);
    await h.shot('08_income_details');
    await h.tapText('ব্যয়');
    await h.tapText('+ নতুন ব্যয়');
    await h.settle(6);
    await h.shot('09_expense_form');
    await h.tapText('ব্যয়');
    await h.shot('10_expense_list');
  });
}
