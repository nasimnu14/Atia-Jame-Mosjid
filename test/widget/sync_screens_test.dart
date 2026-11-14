import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/photo_storage.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/sync/sync_client.dart';
import 'package:atia_masjid_accounts/features/sync/sync_receiver.dart';
import 'package:atia_masjid_accounts/features/sync/sync_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/app_harness.dart';
import '../helpers/test_env.dart';

final _now = DateTime(2026, 11, 13, 10);
const _phoneSize = Size(390, 844);

Uint8List png() => Uint8List.fromList(
  img.encodePng(
    img.fill(
      img.Image(width: 30, height: 20),
      color: img.ColorRgb8(90, 160, 130),
    ),
  ),
);

/// A desktop (its own database and photo folder) with a sync server that
/// phones reach without a network socket.
class Desktop {
  Desktop(this.env, this.server);
  final TestEnv env;
  final SyncServer server;
  String get code => server.offer.encode();
}

Future<Desktop> makeDesktop(WidgetTester tester) async {
  late Desktop d;
  await tester.runAsync(() async {
    final env = await TestEnv.create();
    final server = SyncServer(
      receiver: SyncReceiver(
        env.db,
        PhotoStorage(env.photoDir),
        now: () => _now,
      ),
      desktopName: 'PC',
      hostAddress: '127.0.0.1',
      now: () => _now,
    );
    await server.startInProcess();
    d = Desktop(env, server);
  });
  return d;
}

Future<AppHarness> startPhone(
  WidgetTester tester,
  Desktop desktop, {
  FakePhotoPicker? picker,
  http.Client? client,
}) => AppHarness.start(
  tester,
  size: _phoneSize,
  now: _now,
  isPhone: true,
  picker: picker,
  syncClientBuilder: (db, photos, repo) => SyncClient(
    db: db,
    photos: photos,
    settings: repo,
    client: client ?? InProcessHttp(desktop.server.handler),
    now: () => _now,
  ),
);

/// Types a code on the phone's scan screen and presses Connect.
Future<void> syncWith(
  AppHarness h,
  WidgetTester tester,
  String code, {
  String until = '',
}) async {
  await tester.enterText(find.byKey(const Key('code-field')), code);
  await tester.pump();
  await h.tapText('যুক্ত হন');
  await h.settleUntil(
    find.text(until.isEmpty ? 'সিঙ্ক সম্পন্ন' : until),
    maxRounds: 200,
  );
}

Future<void> signIn(AppHarness h, String user, String pass) async {
  final f = find.byType(TextFormField);
  await h.enter(f.at(0), user);
  await h.enter(f.at(1), pass);
  await h.tapText('সাইন ইন');
  await h.settle(10);
}

void main() {
  group('desktop Sync page (SYN-2, SYN-9)', () {
    Future<(AppHarness, FakeSyncHost)> startDesktop(WidgetTester tester) async {
      final host = FakeSyncHost();
      final h = await AppHarness.start(
        tester,
        now: _now,
        syncHostFactory: (_) async => host,
      );
      await h.run(
        () => h.services.users.createSuperAdmin(
          name: 'Super',
          username: 'super',
          password: 'secret1',
        ),
      );
      await h.launch();
      await signIn(h, 'super', 'secret1');
      await h.tapText('ফোন সিঙ্ক');
      await h.settle(6);
      return (h, host);
    }

    testApp(
      'shows a QR code that carries the one-time code; the server runs only here',
      (tester) async {
        final (h, host) = await startDesktop(tester);
        expect(host.started, isTrue);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(
          find.byKey(ValueKey('sync-qr-${host.offer.token}')),
          findsOneWidget,
        );
        expect(
          find.text('অ্যান্ড্রয়েড অ্যাপে ‘সিঙ্ক’ খুলে এই কোডটি স্ক্যান করুন'),
          findsOneWidget,
        );
        expect(find.text('ফোনের অপেক্ষায়…'), findsOneWidget);
        expect(find.text('এই কোড শুধু একবার ব্যবহার করা যাবে'), findsOneWidget);
        // Leaving the page stops the server (it must not keep listening).
        await h.tapText('সেটিংস');
        await h.settle(4);
        expect(host.stopped, isTrue);
      },
    );

    testApp('a new code replaces the old one', (tester) async {
      final (h, host) = await startDesktop(tester);
      final before = host.offer.encode();
      await h.tapText('নতুন কোড তৈরি করুন');
      await h.settle(4);
      expect(host.offer.encode(), isNot(before));
      expect(
        find.byKey(ValueKey('sync-qr-${host.offer.token}')),
        findsOneWidget,
      );
    });

    testApp(
      'shows the phone while it is connected, then how many entries were received (SYN-9)',
      (tester) async {
        final (h, host) = await startDesktop(tester);
        host.emit(const PhoneConnected('রাশেদুল হাসানের ফোন'));
        await h.settle(3);
        expect(
          find.textContaining('রাশেদুল হাসানের ফোন যুক্ত হয়েছে'),
          findsOneWidget,
        );
        host.emit(const EntryReceived('রাশেদুল হাসানের ফোন', 4, 6));
        await h.settle(3);
        expect(find.textContaining('৪টি এন্ট্রি পাওয়া গেছে'), findsOneWidget);
        host.emit(
          const SyncFinished(
            phoneName: 'রাশেদুল হাসানের ফোন',
            entries: 12,
            photos: 14,
            duplicates: 1,
            income: 9,
            expense: 3,
          ),
        );
        await h.settle(3);
        expect(
          find.text('শেষ সিঙ্ক সম্পন্ন: ১২টি এন্ট্রি পাওয়া গেছে'),
          findsOneWidget,
        );
        expect(find.text('আয় ৯টি · ব্যয় ৩টি · ছবি ১৪টি'), findsOneWidget);
        expect(
          find.textContaining('১টি এন্ট্রির নম্বর আগে থেকেই ছিল'),
          findsOneWidget,
        );
        expect(find.text('ফোনের অপেক্ষায়…'), findsOneWidget);
      },
    );

    testApp('lists earlier syncs from the sync log', (tester) async {
      final (h, _) = await startDesktop(tester);
      await h.run(
        () => h.services.syncReceiver.recordSession(
          sessionId: 's1',
          phoneName: 'মোঃ ইউসুফের ফোন',
          startedAt: DateTime(2026, 11, 10, 14, 45),
          entries: 5,
          photos: 7,
          duplicates: 0,
        ),
      );
      await h.settle(4);
      expect(find.text('মোঃ ইউসুফের ফোন'), findsOneWidget);
      expect(find.text('৫টি এন্ট্রি'), findsOneWidget);
    });

    testApp('says what goes each way: entries only phone to computer (SYN-6)', (
      tester,
    ) async {
      await startDesktop(tester);
      expect(find.textContaining('কোনো এন্ট্রি যায় না'), findsOneWidget);
    });
  });

  group('the phone', () {
    testApp(
      'MOB-5: a new phone must be paired first; then the desktop accounts let people sign in (MOB-4)',
      (tester) async {
        final d = await makeDesktop(tester);
        final h = await startPhone(tester, d);
        await h.launch();
        expect(find.text('ফোনটি কম্পিউটারের সাথে যুক্ত করুন'), findsOneWidget);
        expect(
          find.text('যুক্ত না করা পর্যন্ত এই ফোনে কেউ সাইন ইন করতে পারবেন না।'),
          findsOneWidget,
        );
        expect(find.text('সাইন ইন'), findsNothing); // nobody can sign in yet

        await h.tapText('কিউআর কোড স্ক্যান করুন');
        await h.settle(4);
        // A wrong code is refused with a clear message.
        await tester.enterText(find.byKey(const Key('code-field')), 'hello');
        await tester.pump();
        await h.tapText('যুক্ত হন');
        expect(find.text('এটি সিঙ্ক কোড নয়'), findsOneWidget);

        await syncWith(h, tester, d.code);
        expect(
          find.text('ব্যবহারকারীর অ্যাকাউন্ট হালনাগাদ হয়েছে'),
          findsOneWidget,
        );
        await h.tapText('হোমে ফিরে যান');
        await h.settle(6);
        // Now the sign-in screen, with the desktop's users.
        expect(find.text('সাইন ইন করুন'), findsOneWidget);
        expect(
          find.textContaining('অ্যাকাউন্টের তথ্য শেষবার এসেছে'),
          findsOneWidget,
        );
        await signIn(
          h,
          'user',
          'secret3',
        ); // the same password as on the desktop
        expect(
          find.text(
            'এখানের হিসাব শুধু এই ফোনে যোগ করা এন্ট্রির। মসজিদের আসল ব্যালেন্স কম্পিউটারে দেখুন।',
          ),
          findsOneWidget,
        );
        expect(find.text('হোম'), findsOneWidget); // the bottom bar
      },
    );

    testApp(
      'MOB-3: the phone balance counts only this phone\'s entries, not the opening balance',
      (tester) async {
        final d = await makeDesktop(tester);
        await d.env.settings.setOpeningBalance(
          d.env.admin,
          500000,
          DateTime(2026, 1, 1),
        );
        final h = await startPhone(tester, d);
        await h.launch();
        await h.tapText('কিউআর কোড স্ক্যান করুন');
        await syncWith(h, tester, d.code);
        await h.tapText('হোমে ফিরে যান');
        await h.settle(6);
        await signIn(h, 'user', 'secret3');
        expect(
          find.byKey(const Key('phone-balance')).evaluate().isNotEmpty,
          isTrue,
        );
        expect(find.text('৳ ০'), findsWidgets); // not ৳ 5,00,000
        expect(find.textContaining('৫,০০,০০০'), findsNothing);
      },
    );

    testApp(
      'add an entry on the phone with a photo, sync it, then it is view-only (MOB-1, MOB-2, SYN-1, SYN-4, SYN-7)',
      (tester) async {
        final d = await makeDesktop(tester);
        final h = await startPhone(tester, d, picker: FakePhotoPicker([png()]));
        await h.launch();
        await h.tapText('কিউআর কোড স্ক্যান করুন');
        await syncWith(h, tester, d.code);
        await h.tapText('হোমে ফিরে যান');
        await h.settle(6);
        await signIn(h, 'user', 'secret3');

        // New income with a photo.
        await h.tapText('+ নতুন আয়');
        await h.settle(6);
        final fields = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(TextFormField),
        );
        await h.enter(fields.at(1), 'আব্দুল করিম'); // name
        await h.enter(fields.at(2), '2000'); // amount
        await h.tapText('+ ছবি যোগ করুন');
        await h.settle(12);
        await tester.tap(
          find.text('যোগ করুন').last,
        ); // label dialog, blank label
        await h.settle(6);
        await h.tapText('সংরক্ষণ করুন');
        await h.settle(12);
        expect(find.text('আয়ের বিস্তারিত'), findsOneWidget);
        // Made on this phone, so it says "from phone", not "from computer".
        expect(find.textContaining('ফোন থেকে'), findsOneWidget);
        expect(find.textContaining('কম্পিউটার থেকে'), findsNothing);
        // Saved on the phone as "not synced" (SYN-1), and editable for now.
        var e = (await h.run(
          () => h.services.entries.findByReceipt(EntryType.income, 1),
        ))!.single;
        expect(e.synced, isFalse);
        expect(find.text('সম্পাদনা'), findsOneWidget);

        // Sync from the Home page.
        await h.tapText('আয়'); // the breadcrumb goes back
        await h.settle(6);
        await h.tapText('হোম');
        await h.settle(4);
        expect(find.text('সিঙ্ক বাকি: ১টি এন্ট্রি'), findsOneWidget);
        await h.tapText('সিঙ্ক করুন');
        await h.settle(4);
        expect(find.byKey(const Key('will-send')), findsOneWidget);
        await syncWith(h, tester, d.code);
        expect(
          find.text('১টি এন্ট্রি ও ১টি ছবি পাঠানো হয়েছে'),
          findsOneWidget,
        );
        expect(find.text('এই এন্ট্রিগুলো এখন শুধু দেখা যাবে'), findsOneWidget);

        // The desktop has it, with the photo.
        final onDesktop = await tester.runAsync(
          () => d.env.entries.findByReceipt(EntryType.income, 1),
        );
        expect(onDesktop!.single.name, 'আব্দুল করিম');
        expect(onDesktop.single.synced, isTrue);
        expect(
          (await tester.runAsync(
            () => d.env.entries.photosOf(onDesktop.single.id),
          ))!.length,
          1,
        );

        // Back on the phone: synced entries show it and cannot be changed (SYN-7).
        await h.tapText('হোমে ফিরে যান');
        await h.tapText('হোম');
        await h.settleUntil(
          find.text('সিঙ্ক বাকি: ০টি এন্ট্রি'),
          maxRounds: 40,
        );
        expect(find.text('সিঙ্ক বাকি: ০টি এন্ট্রি'), findsOneWidget);
        await h.tapText('আব্দুল করিম');
        await h.settle(6);
        expect(
          find.textContaining('সিঙ্ক হওয়া এন্ট্রি ফোনে বদলানো যায় না'),
          findsOneWidget,
        );
        expect(find.text('সম্পাদনা'), findsNothing);
        expect(find.text('এন্ট্রি বাতিল'), findsNothing);
        e = (await h.run(
          () => h.services.entries.findByReceipt(EntryType.income, 1),
        ))!.single;
        expect(e.synced, isTrue);
      },
    );

    testApp('an unexpected error shows a message and does not hang', (
      tester,
    ) async {
      final d = await makeDesktop(tester);
      final h = await startPhone(tester, d, client: _BrokenHttp());
      await h.launch();
      await h.tapText('কিউআর কোড স্ক্যান করুন');
      await tester.enterText(find.byKey(const Key('code-field')), d.code);
      await tester.pump();
      await h.tapText('যুক্ত হন');
      await h.settleUntil(find.textContaining('disk is full'));
      expect(find.textContaining('disk is full'), findsOneWidget);
      // Not stuck: the code can be tried again.
      expect(find.text('যুক্ত হন'), findsOneWidget);
    });

    testApp('a used or wrong code is refused and nothing changes', (
      tester,
    ) async {
      final d = await makeDesktop(tester);
      final h = await startPhone(tester, d);
      await h.launch();
      await h.tapText('কিউআর কোড স্ক্যান করুন');
      final used = d.code;
      await syncWith(h, tester, used);
      await h.tapText('হোমে ফিরে যান');
      await h.settle(6);
      await signIn(h, 'user', 'secret3');
      await h.tapText('আরও');
      await h.settle(4);
      await h.tapText('কম্পিউটারের সাথে সিঙ্ক');
      await h.settle(4);
      await syncWith(h, tester, used, until: 'কোডটি নেওয়া হয়নি');
      expect(find.textContaining('কোডটি নেওয়া হয়নি'), findsOneWidget);
    });

    testApp(
      'SYN-10: a user disabled on the computer is signed out by the next sync',
      (tester) async {
        final d = await makeDesktop(tester);
        final h = await startPhone(tester, d);
        await h.launch();
        await h.tapText('কিউআর কোড স্ক্যান করুন');
        await syncWith(h, tester, d.code);
        await h.tapText('হোমে ফিরে যান');
        await h.settle(6);
        await signIn(h, 'user', 'secret3');
        await tester.runAsync(
          () => d.env.users.setActive(d.env.superAdmin, d.env.user.id, false),
        );
        await h.settleUntil(find.text('সিঙ্ক করুন'));
        await h.tapText('সিঙ্ক করুন');
        await h.settle(4);
        // The sync learns the user is disabled: they are signed out at once.
        await syncWith(h, tester, d.code, until: 'সাইন ইন করুন');
        expect(find.text('সাইন ইন করুন'), findsOneWidget); // signed out
        await signIn(h, 'user', 'secret3');
        expect(
          find.text('এই অ্যাকাউন্টটি নিষ্ক্রিয়। সুপার অ্যাডমিনকে বলুন।'),
          findsOneWidget,
        );
      },
    );

    testApp(
      'Summary on the phone says it is only this phone, and has no Excel upload',
      (tester) async {
        final d = await makeDesktop(tester);
        final h = await startPhone(tester, d);
        await h.launch();
        await h.tapText('কিউআর কোড স্ক্যান করুন');
        await syncWith(h, tester, d.code);
        await h.tapText('হোমে ফিরে যান');
        await h.settle(6);
        await signIn(h, 'user', 'secret3');
        await h.tapText('সারাংশ');
        await h.settle(6);
        expect(
          find.textContaining('শুধু এই ফোনে যোগ করা এন্ট্রির'),
          findsOneWidget,
        );
        expect(find.text('এক্সেল আপলোড'), findsNothing);
        expect(find.text('পিডিএফ তৈরি করুন'), findsOneWidget);
      },
    );

    testApp('More: language, sign out', (tester) async {
      final d = await makeDesktop(tester);
      final h = await startPhone(tester, d);
      await h.launch();
      await h.tapText('কিউআর কোড স্ক্যান করুন');
      await syncWith(h, tester, d.code);
      await h.tapText('হোমে ফিরে যান');
      await h.settle(6);
      await signIn(h, 'user', 'secret3');
      await h.tapText('আরও');
      await h.settle(4);
      expect(find.text('ইউজার · user'), findsOneWidget);
      await h.tapText('ভাষা');
      await h.settle(4);
      expect(find.text('More'), findsWidgets);
      await h.tapText('Sign out');
      await h.settle(6);
      expect(find.text('Sign in'), findsWidgets);
    });
  });
}

/// Fails with something the sync client does not expect.
class _BrokenHttp extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw StateError('disk is full');
}
