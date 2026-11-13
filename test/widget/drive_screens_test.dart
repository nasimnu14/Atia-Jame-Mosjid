import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_drive.dart';
import '../helpers/test_env.dart';

final _now = DateTime(2026, 11, 13, 10);

Future<(AppHarness, FakeDrive, FakeDriveAuth, User)> startAs(
  WidgetTester tester, {
  String user = 'super',
  String pass = 'secret1',
  bool connected = true,
  bool onDisk = false,
}) async {
  final drive = FakeDrive();
  drive.clock = () => _now;
  final auth = FakeDriveAuth(drive);
  final h = await AppHarness.start(
    tester,
    now: _now,
    driveAuth: auth,
    onDisk: onDisk,
  );
  late User s;
  await h.run(() async {
    s = await h.services.users.createSuperAdmin(
      name: 'Super',
      username: 'super',
      password: 'secret1',
    );
    await h.services.users.addUser(
      s,
      name: 'Adm',
      username: 'adm',
      password: 'secret2',
      role: Role.admin,
    );
    await h.services.users.addUser(
      s,
      name: 'Usr',
      username: 'usr',
      password: 'secret3',
      role: Role.user,
    );
    await h.services.settings.addApprover(s, 'সভাপতি');
    if (connected) await h.services.drive.connect();
    await h.services.entries.create(
      s,
      EntryDraft(
        type: EntryType.income,
        receiptNo: 6685,
        date: DateTime(2026, 11, 13),
        name: 'আব্দুল করিম',
        amount: 5000,
      ),
    );
  });
  await h.launch();
  final f = find.byType(TextFormField);
  await h.enter(f.at(0), user);
  await h.enter(f.at(1), pass);
  await h.tapText('সাইন ইন');
  await h.settle(10);
  return (h, drive, auth, s);
}

void main() {
  testApp('Backup page: connect a Google account (BAK-1)', (tester) async {
    final (h, drive, auth, _) = await startAs(tester, connected: false);
    await h.tapText('ব্যাকআপ');
    expect(find.text('ব্যাকআপ ও গুগল ড্রাইভ'), findsOneWidget);
    expect(find.text('সংযুক্ত নেই'), findsOneWidget);
    await h.tapText('গুগল অ্যাকাউন্টে সংযুক্ত হন');
    await h.settle(20);
    expect(auth.connectCalls, 1);
    expect(find.text('সংযুক্ত: mosque@example.com'), findsOneWidget);
    // BAK-8: the first connection makes a full backup straight away.
    expect(drive.filesIn(DriveFolders.backups), hasLength(1));
    expect(find.text('এখনো ব্যাকআপ হয়নি'), findsNothing);
  });

  testApp(
    'Backup page: last backup time and a clear message when it failed (BAK-5)',
    (tester) async {
      final (h, drive, _, _) = await startAs(tester);
      await h.run(() => h.services.backup.runBackup());
      await h.tapText('ব্যাকআপ');
      await h.settle(4);
      expect(find.text('১৩/১১/২০২৬, সকাল ১০:০০'), findsWidgets); // last success
      expect(find.textContaining('ব্যর্থ হয়েছে'), findsNothing);

      drive.offline = true;
      await h.run(() async {
        // make it due again, then fail
        await h.services.settingsRepo.set(
          'last_backup_at',
          DateTime(2026, 11, 13, 1).toIso8601String(),
        );
        await h.services.backup.runBackup();
      });
      await h.settle(6);
      expect(
        find.textContaining('সর্বশেষ চেষ্টায় ব্যাকআপ ব্যর্থ হয়েছে'),
        findsOneWidget,
      );
      expect(find.text('ব্যর্থ'), findsWidgets);
    },
  );

  testApp('Backup page: without a Google client id the build says so', (
    tester,
  ) async {
    final (h, _, auth, _) = await startAs(tester, connected: false);
    auth.configured = false;
    await h.tapText('ব্যাকআপ');
    expect(find.textContaining('গুগল সাইন-ইন সেট করা নেই'), findsOneWidget);
    await h.tapText('গুগল অ্যাকাউন্টে সংযুক্ত হন');
    expect(auth.connectCalls, 0);
  });

  testApp('only the Super Admin sees the restore card (BAK-6)', (tester) async {
    final (h, _, _, _) = await startAs(tester, user: 'adm', pass: 'secret2');
    await h.tapText('ব্যাকআপ');
    expect(find.text('ব্যাকআপ থেকে ফিরিয়ে আনুন'), findsNothing);
    expect(find.text('স্বয়ংক্রিয় ব্যাকআপ — প্রতি ৪ ঘণ্টা'), findsOneWidget);
  });

  testApp('the Super Admin sees it, with its warning', (tester) async {
    final (h, _, _, _) = await startAs(tester);
    await h.tapText('ব্যাকআপ');
    expect(find.text('ব্যাকআপ থেকে ফিরিয়ে আনুন'), findsOneWidget);
    expect(find.text('শুধু সুপার অ্যাডমিন'), findsOneWidget);
    expect(find.textContaining('সাবধান'), findsOneWidget);
  });

  testApp('Excel page: upload a chosen period by hand (XLS-3, XLS-4, XLS-8)', (
    tester,
  ) async {
    final (h, drive, _, _) = await startAs(tester);
    await h.tapText('এক্সেল আপলোড');
    expect(find.text('এক্সেল আপলোড (গুগল ড্রাইভ)'), findsOneWidget);
    expect(find.text('দৈনিক স্বয়ংক্রিয় আপলোড'), findsOneWidget);
    expect(
      find.textContaining('আয়-ব্যয়_2026-11-01_2026-11-30_both.xlsx'),
      findsOneWidget,
    );

    await h.tapText('শুধু আয়');
    expect(
      find.textContaining('আয়-ব্যয়_2026-11-01_2026-11-30_income.xlsx'),
      findsOneWidget,
    );
    await h.tapText('গুগল ড্রাইভে আপলোড করুন');
    await h.settle(20);
    final files = drive.filesIn(DriveFolders.excel);
    expect(
      files.single.name,
      startsWith('আয়-ব্যয়_2026-11-01_2026-11-30_income'),
    );
    expect(find.textContaining('আপলোড হয়েছে'), findsOneWidget);
    expect(
      find.textContaining('নিজে · মাস: নভেম্বর ২০২৬ · শুধু আয়'),
      findsOneWidget,
    );
    expect(find.text('সফল'), findsWidgets);
  });

  testApp('Excel page: a failed upload says so and is listed (XLS-8)', (
    tester,
  ) async {
    final (h, drive, _, _) = await startAs(tester);
    drive.offline = true;
    await h.tapText('এক্সেল আপলোড');
    await h.tapText('গুগল ড্রাইভে আপলোড করুন');
    await h.settle(20);
    expect(find.textContaining('আপলোড হয়নি'), findsOneWidget);
    expect(find.text('ব্যর্থ'), findsWidgets);
    expect(drive.filesIn(DriveFolders.excel), isEmpty);
  });

  testApp('Excel page: shows the last successful daily upload', (tester) async {
    final (h, _, _, _) = await startAs(tester);
    await h.tapText('এক্সেল আপলোড');
    expect(find.text('এখনো হয়নি'), findsOneWidget);
    await h.run(() => h.services.excel.uploadDaily());
    await h.settle(6);
    expect(find.text('১৩/১১/২০২৬, সকাল ১০:০০'), findsWidgets);
    expect(find.textContaining('দৈনিক · সব আয় ও ব্যয়'), findsWidgets);
  });

  testApp('Excel page: not connected, the button stays off and says why', (
    tester,
  ) async {
    final (h, _, _, _) = await startAs(tester, connected: false);
    await h.tapText('এক্সেল আপলোড');
    expect(
      find.text('আগে গুগল অ্যাকাউন্টে সংযুক্ত হন (ব্যাকআপ পাতায়)'),
      findsOneWidget,
    );
    final b = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'গুগল ড্রাইভে আপলোড করুন'),
    );
    expect(b.onPressed, isNull);
  });

  testApp('dashboard shows the backup and Excel status (BAK-5, XLS-8)', (
    tester,
  ) async {
    final (h, _, _, _) = await startAs(tester);
    expect(find.text('শেষ ব্যাকআপ (প্রতি ৪ ঘণ্টা)'), findsOneWidget);
    await h.run(() => h.services.backup.runBackup());
    await h.run(() => h.services.excel.uploadDaily());
    await h.settle(6);
    expect(find.text('১৩/১১/২০২৬, সকাল ১০:০০ · সফল'), findsNWidgets(2));
  });

  testApp(
    'first launch: restore every entry from Google Drive, then sign in (USR-3, BAK-6)',
    (tester) async {
      // The old computer: made entries and a backup.
      final drive = FakeDrive();
      await tester.runAsync(() async {
        final old = await TestEnv.create(
          onDisk: true,
          drive: drive,
          connected: true,
        );
        await old.addIncome(receipt: 6685, amount: 5000, name: 'আব্দুল করিম');
        await old.backup.runBackup();
      });

      // The new computer: a brand-new installation.
      final auth = FakeDriveAuth(drive);
      final h = await AppHarness.start(
        tester,
        now: _now,
        driveAuth: auth,
        onDisk: true,
      );
      await h.launch();
      expect(find.text('ব্যাকআপ থেকে ফিরিয়ে আনুন'), findsOneWidget);
      await h.tapText(
        'গুগল অ্যাকাউন্টে সংযুক্ত হন',
      ); // opens the restore screen
      await tester.tap(
        find.text('গুগল অ্যাকাউন্টে সংযুক্ত হন').last,
      ); // signs in to Google
      await h.settle(10);
      expect(find.text('সংযুক্ত: mosque@example.com'), findsOneWidget);
      // Nothing is backed up from an empty installation.
      expect(drive.filesIn(DriveFolders.backups), hasLength(1));

      // The list of backups is loaded as soon as the account is connected.
      await h.settleUntil(find.widgetWithText(FilledButton, 'ফিরিয়ে আনুন'));
      expect(find.text('ফিরিয়ে আনুন'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'ফিরিয়ে আনুন'));
      await h.settle(4);
      expect(find.text('সত্যিই ফিরিয়ে আনবেন?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'ফিরিয়ে আনুন').last);
      await h.settleUntil(find.textContaining('সব তথ্য ফিরিয়ে আনা হয়েছে'));

      // Back on the sign-in screen, with the result.
      expect(find.textContaining('সব তথ্য ফিরিয়ে আনা হয়েছে'), findsOneWidget);
      final f = find.byType(TextFormField);
      await h.enter(f.at(0), 'super');
      await h.enter(f.at(1), 'secret1'); // the old Super Admin's password
      await h.tapText('সাইন ইন');
      await h.settle(10);
      expect(find.text('৳ ৫,০০০'), findsWidgets);
      final restored = await h.run(
        () => h.currentServices.entries.findByReceipt(EntryType.income, 6685),
      );
      expect(restored!.single.name, 'আব্দুল করিম');
    },
  );
}
