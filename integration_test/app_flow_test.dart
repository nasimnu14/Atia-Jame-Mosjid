import 'dart:io';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/app/app.dart';
import 'package:atia_masjid_accounts/app/app_services.dart';
import 'package:atia_masjid_accounts/data/photo_storage.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_form_screen.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/features/sync/sync_receiver.dart';
import 'package:atia_masjid_accounts/features/sync/sync_server.dart';
import 'package:atia_masjid_accounts/shared/file_saver.dart';
import 'package:atia_masjid_accounts/shared/password_hasher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

/// Real app, real database file, real fonts, real sockets. Run with
///   flutter test integration_test -d macos
/// (or an Android device/emulator).

class CapturingSaver implements FileSaver {
  final files = <({String name, Uint8List bytes})>[];
  @override
  Future<String?> save(
    BuildContext context, {
    required String suggestedName,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  }) async {
    files.add((name: '$suggestedName.$extension', bytes: bytes));
    return '/captured/$suggestedName.$extension';
  }
}

Future<void> pumpUntil(
  WidgetTester tester,
  Finder f, {
  int seconds = 20,
}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (f.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(f, findsWidgets, reason: 'waiting for $f');
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final f = last ? find.text(text).last : find.text(text).first;
  await pumpUntil(tester, find.text(text));
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('atia_it_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('first launch → sign in → add income → list → cancel → PDF', (
    tester,
  ) async {
    final saver = CapturingSaver();
    final services = await AppServices.open(
      Directory(p.join(tmp.path, 'data')),
      hasher: const PasswordHasher(logRounds: 4),
      fileSaver: saver,
    );
    await tester.pumpWidget(AtiaApp(services: services));
    await pumpUntil(tester, find.text('নতুনভাবে শুরু করুন'));

    // First launch: create the Super Admin (USR-3).
    final f = find.byType(TextFormField);
    await tester.enterText(f.at(0), 'আব্দুর রহমান');
    await tester.enterText(f.at(1), 'rahman');
    await tester.enterText(f.at(2), 'secret1');
    await tester.enterText(f.at(3), 'secret1');
    await tapText(tester, 'অ্যাকাউন্ট তৈরি করে শুরু করুন');
    await pumpUntil(tester, find.text('ড্যাশবোর্ড'));

    // Add an income.
    await tapText(tester, 'আয়');
    await tapText(tester, '+ নতুন আয়');
    await pumpUntil(tester, find.text('নতুন আয় যোগ করুন'));
    // The open form's fields (the list underneath has its own search box).
    final form = find.descendant(
      of: find.byType(EntryFormScreen),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(form.at(1), 'ভাঙ্গারি বিক্রি');
    await tester.enterText(form.at(2), '১০৫০');
    await tapText(tester, 'সংরক্ষণ করুন');
    await pumpUntil(tester, find.text('আয়ের বিস্তারিত'));
    expect(find.text('৳ ১,০৫০'), findsWidgets);

    // The list shows it.
    await tapText(tester, 'আয়');
    await pumpUntil(tester, find.text('১টি এন্ট্রি'));
    expect(find.text('ভাঙ্গারি বিক্রি'), findsOneWidget);

    // PDF from the details screen: a real PDF with the entry.
    await tapText(tester, 'ভাঙ্গারি বিক্রি');
    await pumpUntil(tester, find.text('পিডিএফ এক্সপোর্ট'));
    await tapText(tester, 'পিডিএফ এক্সপোর্ট');
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (saver.files.isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(saver.files, hasLength(1));
    expect(String.fromCharCodes(saver.files.single.bytes.take(5)), '%PDF-');
    expect(
      saver.files.single.bytes.length,
      greaterThan(20000),
    ); // the page image is in it

    // Cancel it with a reason; it stays but is not counted (EDT-3, EDT-4).
    await tapText(tester, 'এন্ট্রি বাতিল');
    await pumpUntil(tester, find.text('বাতিলের কারণ *'));
    final dialog = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(dialog.first, 'ভুল এন্ট্রি');
    await tester.tap(find.text('এন্ট্রি বাতিল করুন').last);
    const banner =
        'এই এন্ট্রি বাতিল করা হয়েছে। কোনো মোট বা ব্যালেন্সে এটি ধরা হয় না।';
    await pumpUntil(tester, find.text(banner));
    expect(find.textContaining('কারণ: ভুল এন্ট্রি'), findsOneWidget);
    expect(await services.balance.currentBalance(), 0);
    final row = (await services.entries.findByReceipt(
      EntryType.income,
      1,
    )).single;
    expect(row.status, EntryStatus.cancelled);

    // Sign out and back in (USR-1); everything is still there.
    await tapText(tester, 'সাইন আউট');
    await pumpUntil(tester, find.text('সাইন ইন করুন'));
    await tester.enterText(find.byType(TextFormField).at(0), 'rahman');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tapText(tester, 'সাইন ইন');
    await pumpUntil(tester, find.text('ড্যাশবোর্ড'));
    await services.close();
  });

  testWidgets(
    'sync flow: phone → desktop over real sockets, twice, with photos',
    (tester) async {
      final desktop = await AppServices.open(
        Directory(p.join(tmp.path, 'desktop')),
        hasher: const PasswordHasher(logRounds: 4),
      );
      final su = await desktop.users.createSuperAdmin(
        name: 'Super',
        username: 'super',
        password: 'secret1',
      );
      final user = await desktop.users.addUser(
        su,
        name: 'রাশেদ',
        username: 'rashed',
        password: 'secret3',
        role: Role.user,
      );

      final phone = await AppServices.open(
        Directory(p.join(tmp.path, 'phone')),
        hasher: const PasswordHasher(logRounds: 4),
        isPhone: true,
      );

      final server = SyncServer(
        receiver: SyncReceiver(
          desktop.db,
          PhotoStorage(Directory(p.join(tmp.path, 'desktop', 'photos'))),
        ),
        desktopName: 'PC',
        hostAddress: '127.0.0.1',
        bindAddress: InternetAddress.loopbackIPv4,
      );
      await server.start();

      // Pair: the accounts arrive.
      await phone.syncClient.sync(server.offer, phoneName: 'ফোন');
      final phoneUser = (await phone.users.all()).firstWhere(
        (u) => u.username == 'rashed',
      );
      expect(phoneUser.id, user.id);

      // Work on the phone, with a photo.
      final photo = Uint8List.fromList(
        List<int>.generate(2000, (i) => i % 251),
      );
      await phone.entries.create(
        phoneUser,
        EntryDraft(
          type: EntryType.income,
          receiptNo: 7,
          date: DateTime(2026, 11, 13),
          name: 'দাতা',
          amount: 500,
          photos: [PhotoDraft(bytes: photo, label: 'রশিদ')],
        ),
      );
      final r1 = await phone.syncClient.sync(server.offer, phoneName: 'ফোন');
      expect(r1.entriesSent, 1);
      final onDesktop = await desktop.entries.findByReceipt(
        EntryType.income,
        7,
      );
      expect(onDesktop.single.synced, isTrue);
      final photos = await desktop.entries.photosOf(onDesktop.single.id);
      expect(
        await desktop.photos.read(onDesktop.single.id, photos.single.fileName),
        photo,
      );

      // Sent again (e.g. the phone never heard back): still saved once.
      await phone.db.customStatement('UPDATE entries SET synced = 0');
      final r2 = await phone.syncClient.sync(server.offer, phoneName: 'ফোন');
      expect(r2.entriesSent, 1);
      expect(
        (await desktop.entries.findByReceipt(EntryType.income, 7)).length,
        1,
      );

      await server.stop();
      await desktop.close();
      await phone.close();
    },
  );
}
