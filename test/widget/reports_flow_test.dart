import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

final _now = DateTime(2026, 11, 13, 10);

class Ctx {
  Ctx(this.h, this.saver, this.superAdmin, this.admin);
  final AppHarness h;
  final FakeFileSaver saver;
  final User superAdmin, admin;
}

Future<Ctx> start(WidgetTester tester, {bool english = false}) async {
  final saver = FakeFileSaver();
  final h = await AppHarness.start(tester, saver: saver, now: _now);
  late User s, a;
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
    await h.services.settings.addApprover(a, 'সভাপতি');
    await h.services.settings.setOpeningBalance(
      a,
      120000,
      DateTime(2026, 1, 1),
    );
    Future<EntryWithPhotos> inc(int no, int amt, String name, DateTime d) =>
        h.services.entries.create(
          s,
          EntryDraft(
            type: EntryType.income,
            receiptNo: no,
            date: d,
            name: name,
            amount: amt,
          ),
        );
    await inc(6681, 820, 'ভাঙ্গারি বিক্রি', DateTime(2026, 11, 11));
    await inc(6682, 5000, 'আব্দুল করিম', DateTime(2026, 11, 13));
    final bad = await inc(6683, 99999, 'ভুল দাতা', DateTime(2026, 11, 12));
    await h.services.entries.cancel(a, bad.entry.id, 'ভুল');
    await inc(6600, 2000, 'অক্টোবরের দাতা', DateTime(2026, 10, 20));
    await h.services.entries.create(
      s,
      EntryDraft(
        type: EntryType.expense,
        receiptNo: 593,
        date: DateTime(2026, 11, 13),
        name: 'মোঃ হানিফ',
        purpose: 'রাজমিস্ত্রির মজুরি',
        approverName: 'সভাপতি',
        amount: 12500,
      ),
    );
  });
  await h.launch();
  if (english) await h.tapText('English');
  final f = find.byType(TextFormField);
  await h.enter(f.at(0), 'super');
  await h.enter(f.at(1), 'secret1');
  if (english) {
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await h.settle(2);
  } else {
    await h.tapText('সাইন ইন');
  }
  await h.settle(10);
  return Ctx(h, saver, s, a);
}

void main() {
  testApp(
    'dashboard: balance = opening + income − expense, cancelled left out (BAL-3)',
    (tester) async {
      final c = await start(tester);
      // 120000 + (820 + 5000 + 2000) − 12500; the cancelled ৳ 99,999 is not counted.
      expect(find.text('৳ ১,১৫,৩২০'), findsOneWidget);
      expect(
        find.textContaining('প্রারম্ভিক ব্যালেন্স ৳ ১,২০,০০০ (০১/০১/২০২৬)'),
        findsOneWidget,
      );
      expect(find.text('শুক্রবার, ১৩ নভেম্বর ২০২৬'), findsOneWidget);
      // today: income 5,000 (1 entry), expense 12,500 (1 entry)
      expect(find.text('আজকের আয়'), findsOneWidget);
      expect(find.text('৳ ৫,০০০'), findsWidgets);
      expect(find.text('৳ ১২,৫০০'), findsWidgets);
      // this month income 820 + 5000 = 5,820 (2 entries; cancelled excluded)
      expect(find.text('৳ ৫,৮২০'), findsOneWidget);
      expect(find.text('সাম্প্রতিক এন্ট্রি'), findsOneWidget);
      expect(
        await tester.runAsync(() => c.h.services.balance.currentBalance()),
        115320,
      );
    },
  );

  testApp(
    'dashboard in English: English words and English digits (GEN-2, GEN-4)',
    (tester) async {
      await start(tester, english: true);
      expect(find.text('Current balance'), findsOneWidget);
      expect(find.text('৳ 1,15,320'), findsOneWidget);
      expect(find.text('Friday, 13 November 2026'), findsOneWidget);
      expect(find.text('Recent entries'), findsOneWidget);
      expect(find.text('Income today'), findsOneWidget);
    },
  );

  testApp('dashboard: a new entry updates the balance at once', (tester) async {
    final c = await start(tester);
    await tester.runAsync(
      () => c.h.services.entries.create(
        c.superAdmin,
        EntryDraft(
          type: EntryType.income,
          receiptNo: 7000,
          date: DateTime(2026, 11, 13),
          name: 'নতুন',
          amount: 1000,
        ),
      ),
    );
    await c.h.settle(6);
    expect(find.text('৳ ১,১৬,৩২০'), findsOneWidget);
  });

  testApp(
    'summary: income, expense and income − expense for the month (BAL-4)',
    (tester) async {
      final c = await start(tester);
      await c.h.tapText('সারাংশ');
      expect(find.text('মোট আয়'), findsWidgets);
      expect(find.text('৳ ৫,৮২০'), findsWidgets); // income
      expect(find.text('৳ ১২,৫০০'), findsWidgets); // expense
      expect(find.text('− ৳ ৬,৬৮০'), findsWidgets); // 5,820 − 12,500
      expect(
        find.text('২টি এন্ট্রি'),
        findsOneWidget,
      ); // income count; cancelled not counted
      expect(
        find.textContaining('বাতিল এন্ট্রি কোনো মোটে ধরা হয়নি'),
        findsOneWidget,
      );
      expect(find.textContaining('সপ্তাহ অনুযায়ী'), findsOneWidget);
      // The current total balance is on the page, whatever the period is.
      expect(find.text('বর্তমান মোট ব্যালেন্স'), findsOneWidget);
      final balance = await tester.runAsync(
        () => c.h.services.balance.currentBalance(),
      );
      expect(find.text(const Fmt.bn().money(balance!)), findsWidgets);
      // October is not in the November summary.
      expect(find.text('৳ ২,০০০'), findsNothing);
    },
  );

  testApp('summary: switch to this year', (tester) async {
    final c = await start(tester);
    await c.h.tapText('সারাংশ');
    await c.h.tapText('এই বছর');
    expect(find.text('৳ ৭,৮২০'), findsWidgets); // 820 + 5000 + 2000
    expect(find.textContaining('মাস অনুযায়ী'), findsOneWidget);
  });

  testApp(
    'PDF report: income only, saved where the user chooses (PDF-1, PDF-2, PDF-5)',
    (tester) async {
      final c = await start(tester);
      await c.h.tapText('পিডিএফ রিপোর্ট');
      expect(find.text('রিপোর্টে কী থাকবে'), findsOneWidget);
      expect(find.textContaining('ভাষা: বাংলা'), findsOneWidget);
      await c.h.tapText('শুধু আয়');
      await c.h.tapText('পিডিএফ তৈরি করুন');
      await c.h.settle(30);
      expect(c.saver.saved.length, 1);
      final f = c.saver.saved.single;
      expect(f.name, 'report-income-20261101-20261130');
      expect(f.extension, 'pdf');
      expect(String.fromCharCodes(f.bytes.take(5)), '%PDF-');
      expect(find.textContaining('পিডিএফ সংরক্ষিত হয়েছে'), findsOneWidget);
      expect(find.byType(Image), findsWidgets); // first page preview
    },
  );

  testApp('PDF report: cancelling the save dialog saves nothing', (
    tester,
  ) async {
    final c = await start(tester);
    c.saver.cancel = true;
    await c.h.tapText('পিডিএফ রিপোর্ট');
    await c.h.tapText('পিডিএফ তৈরি করুন');
    await c.h.settle(30);
    expect(c.saver.saved, isEmpty);
    expect(find.text('পিডিএফ সংরক্ষণ করা হয়নি'), findsOneWidget);
  });

  testApp('PDF report: an unfinished date range cannot be made yet', (
    tester,
  ) async {
    final c = await start(tester);
    await c.h.tapText('পিডিএফ রিপোর্ট');
    await c.h.tapText('তারিখের পরিসর');
    // from/to start filled with the month; clear the end date.
    final to = find
        .descendant(of: find.byType(Column), matching: find.byType(TextField))
        .last;
    await tester.enterText(to, '');
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'পিডিএফ তৈরি করুন'),
    );
    expect(button.onPressed, isNull);
  });

  testApp('entry PDF from the details screen (DET-2, DET-3)', (tester) async {
    final c = await start(tester);
    await c.h.tapText('আয়');
    await c.h.tapText('আব্দুল করিম');
    await c.h.tapText('পিডিএফ এক্সপোর্ট');
    await c.h.settle(30);
    expect(c.saver.saved.length, 1);
    expect(c.saver.saved.single.name, 'income-6682-20261113');
    expect(String.fromCharCodes(c.saver.saved.single.bytes.take(5)), '%PDF-');
  });
}
