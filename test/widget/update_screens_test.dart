import 'dart:convert';
import 'dart:io';

import 'package:atia_masjid_accounts/features/google_drive/drive_service.dart';
import 'package:atia_masjid_accounts/features/updates/update_installer.dart';
import 'package:atia_masjid_accounts/features/updates/update_service.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import '../helpers/app_harness.dart';
import '../helpers/fake_drive.dart';

final _now = DateTime(2026, 11, 13, 10);

http.Response jsonResponse(String body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(body),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

String release(String tag) => jsonEncode({
  'tag_name': tag,
  'html_url': 'https://github.com/o/r/releases/tag/$tag',
  'body': '## বাংলা\nছবি দেখা আরও সহজ\n\n## English\nEasier photo viewing',
  'assets': [
    {'name': 'Atia-Setup-1.3.0.exe', 'browser_download_url': 'https://x/w.exe'},
  ],
});

Future<(AppHarness, FakeUpdateInstaller, FakeDrive)> start(
  WidgetTester tester, {
  required Future<http.Response> Function(http.Request) handler,
  bool onDisk = false,
  bool connectDrive = false,
  String repo = 'o/r',
}) async {
  final installer = FakeUpdateInstaller();
  final drive = FakeDrive();
  drive.clock = () => _now;
  final auth = FakeDriveAuth(drive);
  final h = await AppHarness.start(
    tester,
    now: _now,
    onDisk: onDisk,
    updateInstaller: installer,
    driveAuth: auth,
    updatesBuilder: (settings) => UpdateService(
      settings: settings,
      currentVersion: () async => '1.2.0',
      repo: repo,
      platform: UpdatePlatform.windows,
      client: MockClient(handler),
      now: () => _now,
    ),
  );
  await h.run(() async {
    final s = await h.services.users.createSuperAdmin(
      name: 'Super',
      username: 'super',
      password: 'secret1',
    );
    await h.services.settings.addApprover(s, 'সভাপতি');
    // A second user, so there is something worth backing up.
    await h.services.users.addUser(
      s,
      name: 'User',
      username: 'user',
      password: 'secret3',
      role: Role.user,
    );
    if (connectDrive) {
      await h.services.drive.connect();
    }
  });
  await h.launch();
  final f = find.byType(TextFormField);
  await h.enter(f.at(0), 'super');
  await h.enter(f.at(1), 'secret1');
  await h.tapText('সাইন ইন');
  await h.settle(10);
  await h.tapText('সেটিংস');
  return (h, installer, drive);
}

void main() {
  testApp(
    'Settings: check for updates finds a new version and shows what changed (UPD-1)',
    (tester) async {
      final (h, _, _) = await start(
        tester,
        handler: (r) async => jsonResponse(release('v1.3.0')),
      );
      expect(find.text('সংস্করণ: ১.২.০'), findsOneWidget);
      expect(find.text('শেষবার দেখা হয়েছে: কখনো না'), findsOneWidget);
      await h.tapText('আপডেট আছে কিনা দেখুন');
      await h.settle(6);
      expect(find.text('নতুন সংস্করণ পাওয়া গেছে'), findsOneWidget);
      expect(find.text('সংস্করণ ১.৩.০ · এখন চালু আছে ১.২.০'), findsOneWidget);
      expect(
        find.textContaining('ছবি দেখা আরও সহজ'),
        findsOneWidget,
      ); // Bangla notes
      // The three promises from the design.
      expect(
        find.text('আপডেটের আগে সব তথ্যের ব্যাকআপ নেওয়া হবে'),
        findsOneWidget,
      );
      expect(find.textContaining('যেমন আছে তেমন থাকবে'), findsOneWidget);
      expect(
        find.textContaining('আগের সংস্করণ সব তথ্যসহ চালু থাকবে'),
        findsOneWidget,
      );
      await h.tapText('পরে');
      await h.settle(6);
      expect(find.text('নতুন সংস্করণ পাওয়া গেছে'), findsNothing);
      expect(
        find.textContaining('শেষবার দেখা হয়েছে: ১৩/১১/২০২৬'),
        findsOneWidget,
      );
    },
  );

  testApp('the notes follow the app language', (tester) async {
    final (h, _, _) = await start(
      tester,
      handler: (r) async => jsonResponse(release('v1.3.0')),
    );
    await h.tapText('English');
    await h.tapText('Check for updates');
    await h.settle(6);
    expect(find.text('A new version is available'), findsOneWidget);
    expect(find.textContaining('Easier photo viewing'), findsOneWidget);
    expect(find.text('Version 1.3.0 · you are running 1.2.0'), findsOneWidget);
  });

  testApp('up to date and failures are said plainly', (tester) async {
    var status = 200;
    final (h, _, _) = await start(
      tester,
      handler: (r) async {
        if (status == 0) {
          throw const SocketException('down');
        }
        return jsonResponse(release('v1.2.0'), status);
      },
    );
    await h.tapText('আপডেট আছে কিনা দেখুন');
    await h.settle(6);
    expect(find.text('অ্যাপ সর্বশেষ সংস্করণে আছে'), findsOneWidget);
    status = 0;
    await h.tapText('আপডেট আছে কিনা দেখুন');
    await h.settle(6);
    expect(find.textContaining('আপডেট দেখা যায়নি'), findsOneWidget);
  });

  testApp('not set up: the build says so', (tester) async {
    final (h, _, _) = await start(
      tester,
      repo: '',
      handler: (r) async => http.Response('', 200),
    );
    await h.tapText('আপডেট আছে কিনা দেখুন');
    await h.settle(4);
    expect(find.textContaining('আপডেট পরীক্ষা সেট করা নেই'), findsOneWidget);
  });

  testApp(
    'Update now: data is copied aside and backed up first, then the installer runs (UPD-2, UPD-4)',
    (tester) async {
      final (h, installer, drive) = await start(
        tester,
        onDisk: true,
        connectDrive: true,
        handler: (r) async => jsonResponse(release('v1.3.0')),
      );
      await h.tapText('আপডেট আছে কিনা দেখুন');
      await h.settle(6);
      await tester.tap(find.widgetWithText(FilledButton, 'এখনই আপডেট করুন'));
      await h.settleUntil(
        find.text('নতুন সংস্করণ পাওয়া গেছে').evaluate().isEmpty
            ? find.byType(SizedBox) // dialog already closed
            : find.text('__never__'),
        maxRounds: 40,
      );
      await h.settle(10);

      expect(installer.installed.single.version.toString(), '1.3.0');
      // A local copy of the data, and a Google Drive backup, both made before.
      final aside = Directory(p.join(h.dir.path, 'backups'));
      expect(
        aside.listSync().map((f) => p.basename(f.path)),
        anyElement(startsWith('pre-update-1.3.0-')),
      );
      expect(drive.filesIn(DriveFolders.backups), hasLength(1));
      expect(find.text('নতুন সংস্করণ পাওয়া গেছে'), findsNothing); // closed
    },
  );

  testApp(
    'an install that fails keeps the dialog open with the reason; nothing is lost',
    (tester) async {
      final (h, installer, _) = await start(
        tester,
        handler: (r) async => jsonResponse(release('v1.3.0')),
      );
      installer.failWith = UpdateException('checksum does not match');
      await h.tapText('আপডেট আছে কিনা দেখুন');
      await h.settle(6);
      await tester.tap(find.widgetWithText(FilledButton, 'এখনই আপডেট করুন'));
      await h.settle(15);
      expect(
        find.textContaining('আপডেট করা যায়নি: checksum does not match'),
        findsOneWidget,
      );
      expect(
        find.text('নতুন সংস্করণ পাওয়া গেছে'),
        findsOneWidget,
      ); // still there to retry
      expect(installer.installed, isEmpty);
      // The app still works.
      await h.tapText('পরে');
      expect(find.text('সেটিংস'), findsWidgets);
    },
  );

  testApp(
    'the dashboard shows a banner when the daily check found a new version',
    (tester) async {
      final (h, _, _) = await start(
        tester,
        handler: (r) async => jsonResponse(release('v1.3.0')),
      );
      await h.run(() => h.services.updates.check());
      await h.tapText('ড্যাশবোর্ড');
      expect(find.text('সংস্করণ ১.৩.০ পাওয়া গেছে'), findsOneWidget);
      await h.tapText('দেখুন');
      await h.settle(6);
      expect(find.text('নতুন সংস্করণ পাওয়া গেছে'), findsOneWidget);
    },
  );
}
