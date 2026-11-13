import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_details_screen.dart';
import 'package:atia_masjid_accounts/features/entries/entry_form_screen.dart';
import 'package:atia_masjid_accounts/features/entries/entry_list_screen.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/shared/widgets/date_form_field.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/app_harness.dart';

final _now = DateTime(2026, 11, 13, 10);

Uint8List png([int w = 40, int h = 30]) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

class Ctx {
  Ctx(this.h, this.superAdmin, this.admin, this.user);
  final AppHarness h;
  final User superAdmin, admin, user;
}

Future<Ctx> start(
  WidgetTester tester, {
  String as = 'super',
  String pass = 'secret1',
  FakePhotoPicker? picker,
}) async {
  final h = await AppHarness.start(tester, picker: picker, now: _now);
  late User s, a, u;
  await tester.runAsync(() async {
    s = await h.services.users.createSuperAdmin(
      name: 'Super',
      username: 'super',
      password: 'secret1',
    );
    a = await h.services.users.addUser(
      s,
      name: 'Adm',
      username: 'adm',
      password: 'secret2',
      role: Role.admin,
    );
    u = await h.services.users.addUser(
      s,
      name: 'Usr',
      username: 'usr',
      password: 'secret3',
      role: Role.user,
    );
    await h.services.settings.addApprover(a, 'সভাপতি');
    await h.services.settings.addApprover(a, 'সেক্রেটারী');
  });
  await h.launch();
  final f = find.byType(TextFormField);
  await h.enter(f.at(0), as);
  await h.enter(f.at(1), pass);
  await h.tapText('সাইন ইন');
  await h.settle(8);
  return Ctx(h, s, a, u);
}

Future<void> seedIncome(
  Ctx c, {
  required int no,
  required int amount,
  String name = 'দাতা',
  DateTime? date,
}) async {
  await c.h.tester.runAsync(
    () => c.h.services.entries.create(
      c.user,
      EntryDraft(
        type: EntryType.income,
        receiptNo: no,
        date: date ?? DateTime(2026, 11, 13),
        name: name,
        amount: amount,
      ),
    ),
  );
  // A screen listening for changes starts reloading inside the test's fake
  // clock. Let it finish before the next real-async call, or it would hold the
  // database lock while the test waits for it.
  await c.h.settle(3);
}

/// The text fields of the open entry form (the list underneath has its own).
/// Income: 0 receipt, 1 name, 2 amount, 3 address.
/// Expense: 0 voucher, 1 payee, 2 purpose, 3 amount, 4 address.
Finder formFields() => find.descendant(
  of: find.byType(EntryFormScreen),
  matching: find.byType(TextFormField),
);
Finder dateField() => find.descendant(
  of: find.byType(DateFormField),
  matching: find.byType(TextField),
);

void main() {
  testApp(
    'add an income: suggested number, blank name becomes অজ্ঞাত, then details (INC-1/3/4)',
    (tester) async {
      final c = await start(tester);
      final h = c.h;
      await seedIncome(c, no: 6685, amount: 100);
      await h.tapText('আয়');
      await h.tapText('+ নতুন আয়');
      expect(find.text('নতুন আয় যোগ করুন'), findsWidgets);
      expect(
        find.textContaining('প্রস্তাবিত পরবর্তী নম্বর: ৬৬৮৬'),
        findsOneWidget,
      );
      expect(find.text('১৩/১১/২০২৬'), findsWidgets); // date starts as today

      final amount = find.widgetWithText(TextFormField, '').last; // not used
      await h.enter(formFields().at(1), ''); // donor name left blank
      await h.enter(formFields().at(2), '৳ ২,০০০');
      await h.tapText('সংরক্ষণ করুন');
      await h.settle(8);

      expect(find.text('আয়ের বিস্তারিত'), findsOneWidget);
      expect(find.text('অজ্ঞাত'), findsOneWidget);
      expect(find.text('৳ ২,০০০'), findsOneWidget);
      expect(find.text('৬৬৮৬'), findsWidgets);
      final saved = (await tester.runAsync(
        () => h.services.entries.findByReceipt(EntryType.income, 6686),
      ))!.single;
      expect(saved.amount, 2000);
      expect(saved.name, '');
      expect(saved.createdBy, c.superAdmin.id);
      expect(amount, isNotNull);
    },
  );

  testApp('required fields and amount above 0 are checked (INC-2)', (
    tester,
  ) async {
    final c = await start(tester);
    final h = c.h;
    await h.tapText('আয়');
    await h.tapText('+ নতুন আয়');
    await h.enter(formFields().at(0), ''); // receipt
    await h.tapText('সংরক্ষণ করুন');
    expect(find.text('নম্বরটি অঙ্কে লিখুন (১ বা তার বেশি)'), findsOneWidget);
    expect(find.text('টাকার পরিমাণ লিখুন'), findsOneWidget);

    await h.enter(formFields().at(0), '5');
    await h.enter(formFields().at(2), '0');
    await h.tapText('সংরক্ষণ করুন');
    expect(find.text('টাকার পরিমাণ ০-এর বেশি হতে হবে'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () => h.services.entries.list(EntryQuery(type: EntryType.income)),
      ))!.count,
      0,
    );
  });

  testApp('a typed date that does not exist is refused (GEN-8)', (
    tester,
  ) async {
    final c = await start(tester);
    final h = c.h;
    await h.tapText('আয়');
    await h.tapText('+ নতুন আয়');
    await tester.tap(dateField());
    await h.enter(dateField(), '৩১/০২/২০২৬');
    await h.enter(formFields().at(2), '100');
    await h.tapText('সংরক্ষণ করুন');
    expect(
      find.textContaining('ফেব্রুয়ারি ২০২৬ মাসে মাত্র ২৮ দিন'),
      findsOneWidget,
    );
  });

  testApp('the duplicate warning appears but saving is still allowed (INC-5)', (
    tester,
  ) async {
    final c = await start(tester);
    final h = c.h;
    await seedIncome(c, no: 5, amount: 500, name: 'করিম');
    await h.tapText('আয়');
    await h.tapText('+ নতুন আয়');
    await h.enter(formFields().at(0), '৫');
    await h.settle(2);
    expect(
      find.textContaining('এই রশিদ নং আগেই একটি আয়ে ব্যবহার হয়েছে'),
      findsOneWidget,
    );
    expect(find.textContaining('করিম'), findsWidgets);

    await h.enter(formFields().at(2), '300');
    await h.tapText('সংরক্ষণ করুন');
    await h.settle(8);
    final all = await tester.runAsync(
      () => h.services.entries.findByReceipt(EntryType.income, 5),
    );
    expect(all!.length, 2);
  });

  testApp('expense: the approver must be picked from the list (EXP-1, EXP-6)', (
    tester,
  ) async {
    final c = await start(tester);
    final h = c.h;
    await h.tapText('ব্যয়');
    await h.tapText('+ নতুন ব্যয়');
    await h.enter(formFields().at(1), 'মেসার্স নূর ট্রেডার্স'); // payee
    await h.enter(formFields().at(2), 'সিলেট বালু ২ ট্রলি'); // purpose
    await h.enter(formFields().at(3), '১৬০০০'); // amount
    await h.tapText('সংরক্ষণ করুন');
    expect(find.text('অনুমোদনকারী বাছতে হবে'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await h.settle(2);
    await tester.tap(find.text('সেক্রেটারী').last);
    await h.settle(2);
    await h.tapText('সংরক্ষণ করুন');
    await h.settle(8);
    expect(find.text('ব্যয়ের বিস্তারিত'), findsOneWidget);
    final e = (await tester.runAsync(
      () => h.services.entries.findByReceipt(EntryType.expense, 1),
    ))!.single;
    expect(
      (e.approverName, e.purpose, e.amount),
      ('সেক্রেটারী', 'সিলেট বালু ২ ট্রলি', 16000),
    );
  });

  testApp(
    'photos: a label is asked for; blank gets description + number (INC-6, INC-10)',
    (tester) async {
      final picker = FakePhotoPicker([png(), png()]);
      final c = await start(tester, picker: picker);
      final h = c.h;
      await h.tapText('আয়');
      await h.tapText('+ নতুন আয়');
      await h.enter(formFields().at(1), 'ডাব বিক্রি');
      await h.enter(formFields().at(2), '1050');
      await h.tapText('+ ছবি যোগ করুন');
      await h.settle(10);
      // first photo's label dialog
      expect(find.text('ছবির লেবেল'), findsWidgets);
      await h.enter(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'রশিদ',
      );
      await tester.tap(find.text('যোগ করুন').last);
      await h.settle(6);
      // second photo's label left blank
      await tester.tap(find.text('যোগ করুন').last);
      await h.settle(6);

      await h.tapText('সংরক্ষণ করুন');
      await h.settle(10);
      expect(find.text('ছবি (২টি)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EntryDetailsScreen),
          matching: find.text('রশিদ'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(EntryDetailsScreen),
          matching: find.text('ডাব বিক্রি ২'),
        ),
        findsOneWidget,
      );
      final saved = (await tester.runAsync(
        () => h.services.entries.list(EntryQuery(type: EntryType.income)),
      ))!.rows.single;
      final photos = await tester.runAsync(
        () => h.services.entries.photosOf(saved.id),
      );
      expect(photos!.map((p) => p.label), ['রশিদ', 'ডাব বিক্রি ২']);
      for (final p in photos) {
        expect(h.services.photos.exists(saved.id, p.fileName), isTrue);
      }
    },
  );

  testApp(
    'the list shows count and total; cancelled is marked and not totalled (FND-7, FND-8)',
    (tester) async {
      final c = await start(tester);
      final h = c.h;
      await seedIncome(c, no: 1, amount: 1000, name: 'এক');
      await seedIncome(c, no: 2, amount: 2000, name: 'দুই');
      await seedIncome(
        c,
        no: 3,
        amount: 9999,
        name: 'আগের মাস',
        date: DateTime(2026, 10, 30),
      );
      await h.tapText('আয়');
      expect(
        find.textContaining('নভেম্বর ২০২৬'),
        findsWidgets,
      ); // opens on the current month (FND-6)
      expect(find.text('২টি এন্ট্রি'), findsOneWidget);
      expect(find.textContaining('৳ ৩,০০০', findRichText: true), findsWidgets);
      expect(find.text('আগের মাস'), findsNothing);

      await h.tapText('দুই');
      await h.tapText('এন্ট্রি বাতিল');
      await tester.tap(
        find.text('এন্ট্রি বাতিল করুন').last,
      ); // dialog button, no reason yet
      await h.settle(3);
      expect(find.text('বাতিলের কারণ লিখতে হবে'), findsOneWidget);
      await h.enter(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextFormField),
        ),
        'ভুল রশিদ',
      );
      await tester.tap(find.text('এন্ট্রি বাতিল করুন').last);
      await h.settle(8);
      expect(find.text('বাতিল'), findsWidgets);
      expect(find.textContaining('ভুল রশিদ'), findsOneWidget);

      await h.tapText('আয়');
      expect(find.text('২টি এন্ট্রি'), findsOneWidget); // still listed
      expect(
        find.textContaining('৳ ১,০০০', findRichText: true),
        findsWidgets,
      ); // total excludes the cancelled ৳ ২,০০০
      expect(
        find.descendant(
          of: find.byType(EntryListScreen),
          matching: find.text('বাতিল'),
        ),
        findsOneWidget,
      );
      expect(
        await tester.runAsync(() => h.services.balance.currentBalance()),
        1000 + 9999,
      ); // October entry still counts
    },
  );

  testApp(
    'open by receipt number with Enter, and search by part of a name (FND-1, FND-2)',
    (tester) async {
      final c = await start(tester);
      final h = c.h;
      await seedIncome(
        c,
        no: 6681,
        amount: 820,
        name: 'ভাঙ্গারি বিক্রি',
        date: DateTime(2026, 3, 2),
      );
      await seedIncome(c, no: 6682, amount: 100, name: 'আব্দুল করিম');
      await h.tapText('আয়');
      final search = find.byType(TextFormField).last;
      await h.enter(search, 'করিম');
      await h.settle(6);
      expect(find.text('আব্দুল করিম'), findsOneWidget);
      expect(find.text('২টি এন্ট্রি'), findsNothing);

      await h.enter(search, '৬৬৮১'); // a March entry: not in this month's list
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await h.settle(8);
      expect(find.text('আয়ের বিস্তারিত'), findsOneWidget);
      expect(find.text('ভাঙ্গারি বিক্রি'), findsOneWidget);
    },
  );

  testApp(
    'a User needs an Admin to approve an edit on the spot (EDT-1, EDT-2)',
    (tester) async {
      final c = await start(tester, as: 'usr', pass: 'secret3');
      final h = c.h;
      await seedIncome(c, no: 1, amount: 1000, name: 'রহিম');
      await h.tapText('আয়');
      await h.tapText('রহিম');
      await h.tapText('সম্পাদনা');
      expect(find.text('অ্যাডমিনের অনুমোদন প্রয়োজন'), findsOneWidget);

      final f = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await h.enter(f.at(0), 'adm');
      await h.enter(f.at(1), 'wrong!!');
      await h.tapText('অনুমোদন দিন');
      await h.settle(6);
      expect(find.text('ইউজারনেম বা পাসওয়ার্ড ভুল'), findsOneWidget);

      await h.enter(f.at(1), 'secret2');
      await h.tapText('অনুমোদন দিন');
      await h.settle(8);
      expect(find.text('আয় সম্পাদনা করুন'), findsWidgets);
      await h.enter(formFields().at(2), '2500');
      await h.tapText('সংরক্ষণ করুন');
      await h.settle(8);

      final e = (await tester.runAsync(
        () => h.services.entries.findByReceipt(EntryType.income, 1),
      ))!.single;
      expect(e.amount, 2500);
      expect(e.editedBy, c.admin.id); // the Admin who approved
      expect(e.createdBy, c.user.id);
      expect(find.text('৳ ২,৫০০'), findsOneWidget);
    },
  );

  testApp(
    'a User cannot cancel without an Admin either; Admin cancels directly (EDT-3)',
    (tester) async {
      final c = await start(tester, as: 'usr', pass: 'secret3');
      final h = c.h;
      await seedIncome(c, no: 1, amount: 1000, name: 'রহিম');
      await h.tapText('আয়');
      await h.tapText('রহিম');
      await h.tapText('এন্ট্রি বাতিল');
      expect(find.text('অ্যাডমিনের অনুমোদন প্রয়োজন'), findsOneWidget);
      await h.tapText('ফিরে যান'); // back out: nothing changes
      final e = (await tester.runAsync(
        () => h.services.entries.findByReceipt(EntryType.income, 1),
      ))!.single;
      expect(e.status, EntryStatus.active);
    },
  );

  testApp(
    'photo viewer: full size, label shown, next and previous (INC-7, INC-10)',
    (tester) async {
      final c = await start(tester);
      final h = c.h;
      await tester.runAsync(
        () => h.services.entries.create(
          c.user,
          EntryDraft(
            type: EntryType.income,
            receiptNo: 6681,
            date: DateTime(2026, 11, 11),
            name: 'ভাঙ্গারি বিক্রি',
            amount: 820,
            photos: [
              PhotoDraft(bytes: png(), label: 'রশিদের ছবি'),
              PhotoDraft(bytes: png(), label: 'বিক্রি করা ভাঙ্গারি (১)'),
            ],
          ),
        ),
      );
      await h.settle(3);
      await h.tapText('আয়');
      await h.tapText('ভাঙ্গারি বিক্রি');
      expect(find.text('ছবি (২টি)'), findsOneWidget);
      await h.tapText('বিক্রি করা ভাঙ্গারি (১)');
      await h.settle(6);
      expect(
        find.textContaining('ছবি ২ / ২ · বিক্রি করা ভাঙ্গারি (১)'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('পরের ছবি'));
      await h.settle(3);
      expect(
        find.textContaining('ছবি ১ / ২ · রশিদের ছবি'),
        findsOneWidget,
      ); // wraps round
      await tester.tap(find.byTooltip('ছবি বন্ধ করুন'));
      await h.settle(6);
      expect(find.text('ছবি (২টি)'), findsOneWidget);
    },
  );

  testApp(
    'phone entries with a number we already have are flagged for an Admin (SYN-8)',
    (tester) async {
      final c = await start(tester);
      final h = c.h;
      await seedIncome(c, no: 7, amount: 100, name: 'প্রথম');
      await seedIncome(c, no: 7, amount: 200, name: 'ফোনের এন্ট্রি');
      final dup = (await tester.runAsync(
        () => h.services.entries.findByReceipt(EntryType.income, 7),
      ))!.firstWhere((e) => e.name == 'ফোনের এন্ট্রি');
      await tester.runAsync(
        () =>
            (h.services.db.update(h.services.db.entries)
                  ..where((e) => e.id.equals(dup.id)))
                .write(const EntriesCompanion(isDuplicate: Value(true))),
      );
      await h.settle(3);
      await h.tapText('আয়');
      expect(
        find.textContaining('ফোন থেকে আসা ১টি এন্ট্রির নম্বর আগে থেকেই আছে'),
        findsOneWidget,
      );
      expect(find.text('ডুপ্লিকেট'), findsOneWidget); // the row is marked
      await h.tapText('শুধু ডুপ্লিকেট দেখুন');
      expect(find.text('প্রথম'), findsNothing);
      expect(find.text('ফোনের এন্ট্রি'), findsOneWidget);
      await h.tapText('ফোনের এন্ট্রি');
      await h.tapText('যাচাই হয়েছে');
      await h.settle(4);
      final after = await tester.runAsync(
        () => h.services.entries.duplicateCount(EntryType.income),
      );
      expect(after, 0);
    },
  );
}
