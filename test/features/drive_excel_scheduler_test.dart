import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_client.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/excel_builder.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

void main() {
  group('Excel upload (XLS-1 to XLS-9)', () {
    test(
      'a daily upload that keeps failing is logged once, and a lost sign-in is reported',
      () async {
        final env = await TestEnv.create();
        await env.settingsRepo.set(SettingKey.googleAccount, 'a@example.com');
        // Offline: the same failure on every retry.
        env.auth.restoreError = DriveException(
          'No internet connection',
          offline: true,
        );
        for (var i = 0; i < 3; i++) {
          final r = await env.excel.uploadDaily();
          expect(r.ok, isFalse);
          expect(r.error, 'No internet connection');
        }
        expect(await env.driveService.recentLog(['excel_daily']), hasLength(1));
        // Back online but Google no longer accepts the sign-in: reported, not
        // "not connected".
        env.auth.restoreError = null;
        env.auth.stored = null;
        final r = await env.excel.uploadDaily();
        expect(r.notConnected, isFalse);
        expect(r.error, contains('sign-in expired'));
      },
    );

    test(
      'XLS-1 / XLS-9: the daily file has all entries and is named with the date',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.addIncome(
          receipt: 1,
          amount: 500,
          date: DateTime(2020, 5, 5),
        );
        await env.addExpense(
          receipt: 1,
          amount: 100,
          date: DateTime(2026, 11, 13),
        );
        final r = await env.excel.uploadDaily();
        expect(r.ok, isTrue);
        expect(r.fileName, 'আয়-ব্যয়_2026-11-13.xlsx');
        final f = env.fakeDrive.filesIn(DriveFolders.excel).single;
        expect(f.name, 'আয়-ব্যয়_2026-11-13.xlsx');
        final x = Excel.decodeBytes(env.fakeDrive.bytesOf(f.id)!.toList());
        expect(x['আয়'].rows.length, 2); // header + the 2020 entry (all dates)
        expect(x['ব্যয়'].rows.length, 2);
        expect(await env.excel.lastDailyUpload(), env.clock);
      },
    );

    test(
      'XLS-9: each day is a new file; earlier files are not replaced',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.addIncome();
        await env.excel.uploadDaily();
        env.clock = DateTime(2026, 11, 14, 0, 5);
        await env.excel.uploadDaily();
        env.clock = DateTime(2026, 11, 15, 0, 5);
        await env.excel.uploadDaily();
        final names = env.fakeDrive
            .filesIn(DriveFolders.excel)
            .map((f) => f.name)
            .toSet();
        expect(names, {
          'আয়-ব্যয়_2026-11-13.xlsx',
          'আয়-ব্যয়_2026-11-14.xlsx',
          'আয়-ব্যয়_2026-11-15.xlsx',
        });
      },
    );

    test(
      'XLS-9: a second upload on the same day does not replace the first',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.excel.uploadDaily();
        env.clock = env.clock.add(const Duration(hours: 3));
        final second = await env.excel.uploadDaily();
        final names = env.fakeDrive
            .filesIn(DriveFolders.excel)
            .map((f) => f.name)
            .toList();
        expect(names.length, 2);
        expect(second.fileName, isNot('আয়-ব্যয়_2026-11-13.xlsx'));
        expect(names.toSet().length, 2);
      },
    );

    test(
      'XLS-2: due when no upload happened today; a missed day is caught up once',
      () async {
        final env = await TestEnv.create(connected: true);
        expect(await env.excel.isDailyDue(), isTrue);
        await env.excel.uploadDaily();
        expect(await env.excel.isDailyDue(), isFalse);
        env.clock = DateTime(2026, 11, 14, 0, 0, 1); // just past midnight
        expect(await env.excel.isDailyDue(), isTrue);
        env.clock = DateTime(2026, 11, 18, 9); // app was closed for days
        expect(await env.excel.isDailyDue(), isTrue);
        await env.excel.uploadDaily();
        expect(await env.excel.isDailyDue(), isFalse);
        expect(
          env.fakeDrive.filesIn(DriveFolders.excel).length,
          2,
        ); // one file, not one per missed day
      },
    );

    test(
      'XLS-8: a failed upload is recorded and the last success time is kept',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.excel.uploadDaily();
        final okAt = env.clock;
        env.clock = DateTime(2026, 11, 14, 9);
        env.fakeDrive.offline = true;
        final r = await env.excel.uploadDaily();
        expect(r.ok, isFalse);
        expect(r.error, isNotNull);
        expect(await env.excel.lastDailyUpload(), okAt);
        expect(
          await env.settingsRepo.get(SettingKey.lastExcelError),
          isNotEmpty,
        );
        final log = await env.driveService.recentLog([
          'excel_daily',
          'excel_manual',
        ]);
        expect(log.first.ok, isFalse);
        expect(log.last.ok, isTrue);
        env.fakeDrive.offline = false;
        expect((await env.excel.uploadDaily()).ok, isTrue);
        expect(await env.settingsRepo.get(SettingKey.lastExcelError), '');
      },
    );

    test('XLS-3 / XLS-4: a chosen period and content, any time', () async {
      final env = await TestEnv.create(connected: true);
      await env.addIncome(receipt: 1, amount: 1, date: DateTime(2026, 11, 2));
      await env.addIncome(receipt: 2, amount: 2, date: DateTime(2026, 10, 2));
      await env.addExpense(receipt: 1, amount: 3, date: DateTime(2026, 11, 3));
      final r = await env.excel.uploadManual(
        period: Period.monthOf(DateTime(2026, 11, 1)),
        content: ExcelContent.income,
        periodName: 'মাস: নভেম্বর ২০২৬',
      );
      expect(r.ok, isTrue);
      expect(r.fileName, startsWith('আয়-ব্যয়_2026-11-01_2026-11-30_income'));
      final f = env.fakeDrive.filesIn(DriveFolders.excel).single;
      final x = Excel.decodeBytes(env.fakeDrive.bytesOf(f.id)!.toList());
      expect(x.tables.keys.toList(), ['আয়']); // income only
      expect(x['আয়'].rows.length, 2); // header + the November entry only
      // Manual uploads never touch the daily bookkeeping.
      expect(await env.excel.isDailyDue(), isTrue);
      expect(
        (await env.driveService.recentLog(['excel_manual'])).single.description,
        contains('নিজে'),
      );
    });

    test('XLS-7: the file follows the language setting', () async {
      final env = await TestEnv.create(connected: true);
      await env.settingsRepo.set(SettingKey.language, 'en');
      await env.addIncome();
      final r = await env.excel.uploadDaily();
      expect(r.fileName, 'income-expense_2026-11-13.xlsx');
      final f = env.fakeDrive.filesIn(DriveFolders.excel).single;
      final x = Excel.decodeBytes(env.fakeDrive.bytesOf(f.id)!.toList());
      expect(x.tables.keys.toSet(), {'Income', 'Expense'});
    });

    test(
      'not connected: nothing is uploaded and no error is recorded',
      () async {
        final env = await TestEnv.create();
        final r = await env.excel.uploadDaily();
        expect(r.notConnected, isTrue);
        expect(env.fakeDrive.uploadCount, 0);
        expect(await env.settingsRepo.get(SettingKey.lastExcelError), isNull);
      },
    );
  });

  group('scheduler (BAK-2, BAK-3, BAK-4, XLS-2)', () {
    test(
      'BAK-4: on start, an overdue backup and the daily upload run at once',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.addIncome();
        await env.scheduler.checkNow();
        expect(env.fakeDrive.filesIn(DriveFolders.backups), hasLength(1));
        expect(env.fakeDrive.filesIn(DriveFolders.excel), hasLength(1));
        // Nothing more is due right away.
        final n = env.fakeDrive.uploadCount;
        await env.scheduler.checkNow();
        expect(env.fakeDrive.uploadCount, n);
      },
    );

    test(
      'BAK-2: 4 hours later the next backup runs, and the day rolls over at midnight',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.scheduler.checkNow();
        env.clock = env.clock.add(const Duration(hours: 4));
        await env.scheduler.checkNow();
        expect(env.fakeDrive.filesIn(DriveFolders.backups), hasLength(2));
        expect(
          env.fakeDrive.filesIn(DriveFolders.excel),
          hasLength(1),
        ); // same day
        env.clock = DateTime(2026, 11, 14, 0, 0, 5);
        await env.scheduler.checkNow();
        expect(
          env.fakeDrive.filesIn(DriveFolders.excel),
          hasLength(2),
        ); // new day, new file
      },
    );

    test(
      'BAK-3 / XLS-2: after a failure it waits, then retries until it works',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.addIncome();
        env.fakeDrive.offline = true;
        await env.scheduler.checkNow();
        expect(env.fakeDrive.filesIn(DriveFolders.backups), isEmpty);
        expect(await env.backup.lastError(), isNotNull);

        // One minute later, still offline: it does not hammer Drive.
        env.clock = env.clock.add(const Duration(minutes: 1));
        final attempts = (await env.driveService.recentLog(['backup'])).length;
        await env.scheduler.checkNow();
        expect((await env.driveService.recentLog(['backup'])).length, attempts);

        // The connection comes back; after the wait it tries again and succeeds.
        env.fakeDrive.offline = false;
        env.clock = env.clock.add(const Duration(minutes: 2));
        await env.scheduler.checkNow();
        expect(env.fakeDrive.filesIn(DriveFolders.backups), hasLength(1));
        expect(env.fakeDrive.filesIn(DriveFolders.excel), hasLength(1));
        expect(await env.backup.lastError(), isNull);
      },
    );

    test('with no Google account connected it does nothing', () async {
      final env = await TestEnv.create();
      await env.scheduler.checkNow();
      expect(env.fakeDrive.uploadCount, 0);
    });
  });
}
