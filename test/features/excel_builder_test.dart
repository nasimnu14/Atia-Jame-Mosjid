import 'package:archive/archive.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/google_drive/excel_builder.dart';
import 'package:atia_masjid_accounts/l10n/app_localizations.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

Future<AppLocalizations> loadL(String lang) =>
    AppLocalizations.delegate.load(Locale(lang));

void main() {
  late TestEnv env;
  setUp(() async {
    env = await TestEnv.create();
    await env.addIncome(
      receipt: 6681,
      amount: 820,
      name: 'ভাঙ্গারি বিক্রি',
      date: DateTime(2026, 11, 11),
    );
    final bad = await env.addIncome(
      receipt: 6682,
      amount: 99999,
      name: '',
      date: DateTime(2026, 11, 12),
    );
    await env.entries.cancel(env.admin, bad.entry.id, 'ভুল এন্ট্রি');
    await env.addExpense(
      receipt: 593,
      amount: 12500,
      payee: 'মোঃ হানিফ',
      purpose: 'রাজমিস্ত্রির মজুরি',
      date: DateTime(2026, 11, 13),
    );
  });

  Future<(Excel, List<int>)> build(String lang, ExcelContent c) async {
    final l = await loadL(lang);
    final names = {for (final u in await env.users.all()) u.id: u.name};
    final bytes = buildEntriesWorkbook(
      l: l,
      entries: await env.entries.inPeriod(
        Period(DateTime(2000), DateTime(2100)),
      ),
      userNames: names,
      content: c,
    );
    return (Excel.decodeBytes(bytes), bytes);
  }

  List<CellValue?> row(Sheet s, int r) =>
      s.rows[r].map((c) => c?.value).toList();

  test(
    'XLS-5: income and expense on separate sheets, one row per entry',
    () async {
      final (x, _) = await build('bn', ExcelContent.both);
      expect(x.tables.keys.toSet(), {'আয়', 'ব্যয়'});
      expect(x['আয়'].rows.length, 3); // header + 2 entries (one cancelled)
      expect(x['ব্যয়'].rows.length, 2);
    },
  );

  test(
    'XLS-6: receipt numbers and amounts are real numbers, dates are real dates',
    () async {
      final (x, _) = await build('en', ExcelContent.both);
      final r = row(x['Income'], 1);
      expect(r[0], isA<IntCellValue>());
      expect((r[0] as IntCellValue).value, 6681);
      expect(r[1], isA<DateCellValue>());
      expect(r[1], DateCellValue(year: 2026, month: 11, day: 11));
      expect(r[4], isA<IntCellValue>());
      expect((r[4] as IntCellValue).value, 820);
      final e = row(x['Expense'], 1);
      expect(e[6], isA<IntCellValue>()); // amount
      expect((e[6] as IntCellValue).value, 12500);
      // "added at" is a real date-time too
      expect(r[8], isA<DateTimeCellValue>());
    },
  );

  test(
    'XLS-6: the file itself stores numbers and dates as numbers, with date formats',
    () async {
      final (_, bytes) = await build('bn', ExcelContent.income);
      final zip = ZipDecoder().decodeBytes(bytes);
      String read(String name) => String.fromCharCodes(
        zip.files.firstWhere((f) => f.name == name).content as List<int>,
      );
      final sheet = zip.files
          .firstWhere((f) => f.name.startsWith('xl/worksheets/sheet'))
          .name;
      final xml = read(sheet);
      // Cell A2 (receipt) and E2 (amount) are plain numeric cells (no t="s"/"str").
      final a2 = RegExp(r'<c r="A2"[^>]*>').firstMatch(xml)!.group(0)!;
      final e2 = RegExp(r'<c r="E2"[^>]*>').firstMatch(xml)!.group(0)!;
      expect(a2, isNot(contains('t="s"')));
      expect(e2, isNot(contains('t="s"')));
      expect(a2, isNot(contains('t="str"')));
      final styles = read('xl/styles.xml');
      expect(styles, contains('dd/mm/yyyy'));
    },
  );

  test(
    'XLS-5: cancelled entries are included, marked, with the reason, amount still a number',
    () async {
      final (x, _) = await build('bn', ExcelContent.income);
      final cancelled = row(x['আয়'], 2);
      expect((cancelled[4] as IntCellValue).value, 99999);
      expect(cancelled[5].toString(), 'বাতিল');
      expect(cancelled[6].toString(), 'ভুল এন্ট্রি');
      expect(cancelled[2].toString(), 'অজ্ঞাত'); // unknown donor
      expect(row(x['আয়'], 1)[5].toString(), 'সক্রিয়');
    },
  );

  test('XLS-7: headings are in the app language', () async {
    final (bn, _) = await build('bn', ExcelContent.both);
    expect(
      row(bn['আয়'], 0).map((c) => c.toString()),
      containsAll(['রশিদ নং', 'তারিখ', 'দাতার নাম', 'টাকা', 'অবস্থা']),
    );
    expect(
      row(bn['ব্যয়'], 0).map((c) => c.toString()),
      containsAll(['ভাউচার নং', 'বিবরণ', 'অনুমোদনকারী']),
    );
    final (en, _) = await build('en', ExcelContent.both);
    expect(
      row(en['Income'], 0).map((c) => c.toString()),
      containsAll(['Receipt no.', 'Date', 'Donor', 'Amount', 'Status']),
    );
    expect(
      row(en['Expense'], 0).map((c) => c.toString()),
      containsAll(['Voucher no.', 'Purpose', 'Approved by']),
    );
  });

  test('XLS-4: income only / expense only', () async {
    final (a, _) = await build('en', ExcelContent.income);
    expect(a.tables.keys.toList(), ['Income']);
    final (b, _) = await build('en', ExcelContent.expense);
    expect(b.tables.keys.toList(), ['Expense']);
  });

  test('who added it is written by name; no photos column (XLS-1)', () async {
    final (x, _) = await build('en', ExcelContent.income);
    final head = row(x['Income'], 0).map((c) => c.toString()).toList();
    expect(head, isNot(contains('Photos')));
    expect(row(x['Income'], 1)[7].toString(), 'Admin'); // added by
    expect(head.length, row(x['Income'], 1).length);
    expect(EntryType.income, isNotNull);
  });
}
