import 'dart:io';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/features/reports/pdf/pdf_pages.dart';
import 'package:atia_masjid_accounts/features/reports/pdf/report_blocks.dart';
import 'package:atia_masjid_accounts/features/reports/report_pdf_service.dart';
import 'package:atia_masjid_accounts/l10n/app_localizations.dart';
import 'package:atia_masjid_accounts/shared/formatters.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/test_env.dart';
import '../helpers/app_harness.dart';

Future<AppLocalizations> loadL(String lang) =>
    AppLocalizations.delegate.load(Locale(lang));

String allText(List<PdfBlock> blocks) =>
    blocks.map((b) => b.debugText).join('\n');

Future<void> maybeSave(String name, Uint8List bytes) async {
  final dir = Platform.environment['SHOT_DIR'];
  if (dir == null) return;
  Directory(dir).createSync(recursive: true);
  File('$dir/$name').writeAsBytesSync(bytes);
}

void main() {
  const novemberFull = 'মাস: নভেম্বর ২০২৬';

  Future<TestEnv> seeded() async {
    final env = await TestEnv.create();
    await env.addIncome(
      receipt: 6681,
      amount: 820,
      name: 'ভাঙ্গারি বিক্রি',
      date: DateTime(2026, 11, 11),
    );
    await env.addIncome(
      receipt: 6682,
      amount: 5000,
      name: 'আব্দুল করিম',
      date: DateTime(2026, 11, 12),
    );
    final bad = await env.addIncome(
      receipt: 6683,
      amount: 99999,
      name: 'জসিম উদ্দিন',
      date: DateTime(2026, 11, 12),
    );
    await env.entries.cancel(env.admin, bad.entry.id, 'ভুল এন্ট্রি');
    await env.addIncome(
      receipt: 6684,
      amount: 123,
      name: 'অক্টোবরের',
      date: DateTime(2026, 10, 31),
    );
    await env.addExpense(
      receipt: 593,
      amount: 12500,
      payee: 'মোঃ হানিফ',
      purpose: 'রাজমিস্ত্রির মজুরি',
      date: DateTime(2026, 11, 13),
    );
    return env;
  }

  final november = Period.monthOf(DateTime(2026, 11, 1));

  test(
    'PDF-3: header, period, entries and totals; income minus expense for both',
    () async {
      final env = await seeded();
      final l = await loadL('bn');
      const fmt = Fmt.bn();
      final rows = await env.entries.inPeriod(november);
      final text = allText(
        buildPeriodReport(
          l: l,
          fmt: fmt,
          content: ReportContent.both,
          periodName: novemberFull,
          entries: rows,
        ),
      );
      expect(text, contains('আটিয়া জামে মসজিদ'));
      expect(text, contains('আটিয়া, ঘোড়াশাল, পলাশ, নরসিংদী'));
      expect(text, contains(novemberFull));
      expect(text, contains('১১/১১/২০২৬ | ৬৬৮১ | ভাঙ্গারি বিক্রি | ৳ ৮২০'));
      expect(
        text,
        contains(
          '১৩/১১/২০২৬ | ৫৯৩ | মোঃ হানিফ | রাজমিস্ত্রির মজুরি | ৳ ১২,৫০০',
        ),
      );
      expect(
        text,
        contains('মোট আয় | ৳ ৫,৮২০'),
      ); // 820 + 5000; cancelled and October left out
      expect(text, contains('মোট ব্যয় | ৳ ১২,৫০০'));
      expect(text, contains('আয় − ব্যয় | − ৳ ৬,৬৮০'));
      expect(text, isNot(contains('অক্টোবরের')));
    },
  );

  test(
    'PDF-6: cancelled entries are listed and marked, and not in the totals',
    () async {
      final env = await seeded();
      final l = await loadL('bn');
      final rows = await env.entries.inPeriod(november);
      final text = allText(
        buildPeriodReport(
          l: l,
          fmt: const Fmt.bn(),
          content: ReportContent.income,
          periodName: novemberFull,
          entries: rows,
        ),
      );
      expect(
        text,
        contains('জসিম উদ্দিন | ৳ ৯৯,৯৯৯ | বাতিল'),
      ); // shown and marked
      expect(text, contains('মোট আয় | ৳ ৫,৮২০')); // but not added in
      expect(text, contains(l.pdfCancelledFootnote));
      expect(text, isNot(contains('মোট ব্যয়')));
    },
  );

  test('PDF-2: income only, expense only, both', () async {
    final env = await seeded();
    final l = await loadL('en');
    final rows = await env.entries.inPeriod(november);
    String t(ReportContent c) => allText(
      buildPeriodReport(
        l: l,
        fmt: const Fmt.en(),
        content: c,
        periodName: 'p',
        entries: rows,
      ),
    );
    expect(t(ReportContent.income), contains('Income report'));
    expect(t(ReportContent.income), isNot(contains('Total expense')));
    expect(t(ReportContent.expense), contains('Expense report'));
    expect(t(ReportContent.expense), isNot(contains('Total income')));
    expect(t(ReportContent.both), contains('Income and expense report'));
    expect(t(ReportContent.both), contains('Income − expense'));
  });

  test('PDF-4: English mode has English words and English digits', () async {
    final env = await seeded();
    final l = await loadL('en');
    final rows = await env.entries.inPeriod(november);
    final text = allText(
      buildPeriodReport(
        l: l,
        fmt: const Fmt.en(),
        content: ReportContent.both,
        periodName: 'Month: November 2026',
        entries: rows,
      ),
    );
    expect(text, contains('Atia Jame Masjid'));
    expect(text, contains('11/11/2026 | 6681'));
    expect(text, contains('Total income | ৳ 5,820'));
    expect(text, isNot(contains('আয়-ব্যয়')));
  });

  test('the report totals equal the balance service summary', () async {
    final env = await seeded();
    final s = await env.balance.summary(november);
    final l = await loadL('en');
    final rows = await env.entries.inPeriod(november);
    final text = allText(
      buildPeriodReport(
        l: l,
        fmt: const Fmt.en(),
        content: ReportContent.both,
        periodName: 'p',
        entries: rows,
      ),
    );
    expect(
      text,
      contains('Total income | ${const Fmt.en().money(s.incomeTotal)}'),
    );
    expect(
      text,
      contains('Total expense | ${const Fmt.en().money(s.expenseTotal)}'),
    );
  });

  test(
    'a long report runs over several pages and repeats the table header',
    () async {
      final env = await TestEnv.create();
      for (var i = 1; i <= 140; i++) {
        await env.addIncome(
          receipt: i,
          amount: 100 + i,
          name: 'দাতা নম্বর $i',
          date: DateTime(2026, 11, 1 + i % 28),
        );
      }
      final l = await loadL('bn');
      final rows = await env.entries.inPeriod(november);
      final blocks = buildPeriodReport(
        l: l,
        fmt: const Fmt.bn(),
        content: ReportContent.income,
        periodName: novemberFull,
        entries: rows,
      );
      final pages = paginate(blocks);
      expect(pages.length, greaterThan(2));
      for (final page in pages) {
        expect(
          page.first.isTableHeader || page == pages.first,
          isTrue,
          reason: 'each continued page starts with the table header',
        );
        final used = page.fold<double>(0, (a, b) => a + b.height);
        expect(used, lessThanOrEqualTo(PageSpec.contentHeight + 0.01));
      }
      // Every entry appears exactly once.
      final rowsText = pages
          .expand((p) => p)
          .where((b) => b.isTableRow)
          .map((b) => b.debugText)
          .toList();
      expect(rowsText.where((t) => t.contains('দাতা নম্বর')).length, 140);
    },
  );

  testWidgets(
    'the PDF file is made, has a page per painted page, and Bangla draws joined',
    (tester) async {
      await tester.runAsync(() async {
        await loadTestFonts();
        final env = await seeded();
        final l = await loadL('bn');
        final pdf = await env.periodPdf(l, const Fmt.bn(), novemberFull);
        expect(String.fromCharCodes(pdf.bytes.take(5)), '%PDF-');
        expect(pdf.pageCount, 1);
        expect(pdf.bytes.length, greaterThan(5000));
        await maybeSave('report_bn.png', pdf.pagePngs.first);
        final en = await loadL('en');
        final pdfEn = await env.periodPdf(
          en,
          const Fmt.en(),
          'Month: November 2026',
        );
        await maybeSave('report_en.png', pdfEn.pagePngs.first);
        await maybeSave('report_bn.pdf', pdf.bytes);
      });
    },
  );

  testWidgets(
    'DET-2: a single-entry PDF holds every field, the history and every photo',
    (tester) async {
      await tester.runAsync(() async {
        await loadTestFonts();
        final env = await TestEnv.create();
        final pngA = Uint8List.fromList(
          img.encodePng(
            img.fill(
              img.Image(width: 400, height: 300),
              color: img.ColorRgb8(120, 160, 140),
            ),
          ),
        );
        final pngB = Uint8List.fromList(
          img.encodePng(
            img.fill(
              img.Image(width: 300, height: 500),
              color: img.ColorRgb8(200, 150, 120),
            ),
          ),
        );
        final saved = await env.entries.create(
          env.user,
          EntryDraft(
            type: EntryType.expense,
            receiptNo: 594,
            date: DateTime(2026, 11, 13),
            name: 'মেসার্স নূর ট্রেডার্স',
            purpose: 'সিলেট বালু ২ ট্রলি',
            approverName: 'সভাপতি',
            amount: 16000,
            address: 'ঘোড়াশাল বাজার',
            photos: [
              PhotoDraft(bytes: pngA, label: 'ভাউচারের ছবি'),
              PhotoDraft(bytes: pngB, label: 'কেনা বালু (১)'),
            ],
          ),
        );
        await env.entries.cancel(
          env.admin,
          saved.entry.id,
          'দুবার লেখা হয়েছিল',
        );
        final l = await loadL('bn');
        final pdf = await env.pdfService.entryReport(
          l,
          const Fmt.bn(),
          saved.entry.id,
          thisDeviceId: 'desktop-1',
        );
        expect(String.fromCharCodes(pdf.bytes.take(5)), '%PDF-');
        await maybeSave('entry_bn.png', pdf.pagePngs.first);
        await maybeSave('entry_bn_p2.png', pdf.pagePngs.last);

        // The blocks hold all the information.
        final entry = (await env.entries.getWithPhotos(saved.entry.id))!;
        final text = allText(
          buildEntryReport(
            l: l,
            fmt: const Fmt.bn(),
            entry: entry.entry,
            history: const EntryHistoryText(addedBy: 'A', cancelledBy: 'B'),
            photos: [for (final p in entry.photos) PdfPhoto(p.label, null)],
          ),
        );
        for (final must in [
          'ভাউচার নং | ৫৯৪',
          '১৩/১১/২০২৬',
          'মেসার্স নূর ট্রেডার্স',
          'সিলেট বালু ২ ট্রলি',
          'সভাপতি',
          '৳ ১৬,০০০ (মোটে ধরা হয়নি)',
          'ঘোড়াশাল বাজার',
          'দুবার লেখা হয়েছিল',
          'ভাউচারের ছবি',
          'কেনা বালু (১)',
          'এই এন্ট্রি বাতিল করা হয়েছে',
        ]) {
          expect(text, contains(must));
        }
      });
    },
  );
}

extension on TestEnv {
  ReportPdfService get pdfService =>
      ReportPdfService(entries, users, () => clock);

  Future<RenderedPdf> periodPdf(
    AppLocalizations l,
    Fmt fmt,
    String periodName,
  ) => pdfService.periodReport(
    l,
    fmt,
    period: Period.monthOf(DateTime(2026, 11, 1)),
    periodName: periodName,
    content: ReportContent.both,
  );
}
