import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/photo_storage.dart';
import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/features/sync/sync_client.dart';
import 'package:atia_masjid_accounts/features/sync/sync_crypto.dart';
import 'package:atia_masjid_accounts/features/sync/sync_offer.dart';
import 'package:atia_masjid_accounts/features/sync/sync_receiver.dart';
import 'package:atia_masjid_accounts/features/sync/sync_server.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/test_env.dart';

/// Lets a test break the network: drop the answer to the n-th request (the
/// desktop DID get it), or cut the connection from some request on.
class FlakyClient extends http.BaseClient {
  FlakyClient(this._inner);
  final http.Client _inner;
  int calls = 0;
  int? dropResponseOfCall;
  int? cutFromCall;
  final sent = <List<int>>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    final n = calls;
    if (cutFromCall != null && n >= cutFromCall!) {
      throw const SocketException('Wi-Fi is off');
    }
    final body = await request.finalize().toBytes();
    sent.add(body);
    final req = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = body;
    final res = await _inner.send(req);
    if (dropResponseOfCall == n) {
      await res.stream.drain<void>();
      throw const SocketException('connection lost before the answer arrived');
    }
    return res;
  }
}

class Rig {
  Rig(this.desktop, this.phone, this.server, this.http);
  final TestEnv desktop;
  final TestEnv phone;
  final SyncServer server;
  final FlakyClient http;

  SyncClient get client => SyncClient(
    db: phone.db,
    photos: PhotoStorage(phone.photoDir),
    settings: phone.settingsRepo,
    client: http,
    now: () => phone.clock,
  );

  Future<SyncReport> sync([SyncOffer? offer]) =>
      client.sync(offer ?? server.offer, phoneName: 'রাশেদের ফোন');

  Future<User> phoneUser([String username = 'user']) async =>
      (await phone.users.all()).firstWhere((u) => u.username == username);

  Future<Entry> phoneIncome(
    int no,
    int amount, {
    String name = 'দাতা',
    List<PhotoDraft> photos = const [],
  }) async {
    final u = await phoneUser();
    final r = await phone.entries.create(
      u,
      EntryDraft(
        type: EntryType.income,
        receiptNo: no,
        date: DateTime(2026, 11, 13),
        name: name,
        amount: amount,
        photos: photos,
      ),
    );
    return r.entry;
  }

  Future<List<Entry>> desktopEntries() =>
      desktop.db.select(desktop.db.entries).get();
  Future<List<Entry>> phoneEntries() => phone.db.select(phone.db.entries).get();
}

Future<Rig> makeRig() async {
  final desktop = await TestEnv.create();
  final phone = await TestEnv.create(isPhone: true, seedUsers: false);
  final server = SyncServer(
    receiver: SyncReceiver(
      desktop.db,
      PhotoStorage(desktop.photoDir),
      now: () => desktop.clock,
    ),
    desktopName: 'মসজিদের কম্পিউটার',
    hostAddress: '127.0.0.1',
    bindAddress: InternetAddress.loopbackIPv4,
    now: () => desktop.clock,
  );
  await server.start();
  addTearDown(server.stop);
  return Rig(desktop, phone, server, FlakyClient(http.Client()));
}

Uint8List bytes(int n, [int seed = 7]) {
  final r = Random(seed);
  return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
}

void main() {
  group('pairing and the first sync (MOB-5, SYN-10)', () {
    test(
      'a new phone has no accounts until it syncs; then the desktop accounts arrive',
      () async {
        final r = await makeRig();
        expect(
          await r.phone.users.hasAnyUser(),
          isFalse,
        ); // nobody can sign in yet
        final report = await r.sync();
        expect(report.accountsUpdated, isTrue);
        expect(report.entriesSent, 0);
        final users = await r.phone.users.all();
        expect(users.map((u) => u.username).toSet(), {
          'super',
          'admin',
          'user',
        });
        // The same protected passwords: the desktop password works on the phone.
        expect((await r.phone.users.signIn('user', 'secret3')).role, Role.user);
        expect(
          (await r.phone.settings.approvers()).map((a) => a.name).toSet(),
          {'সভাপতি', 'সেক্রেটারী'},
        );
        expect(await r.client.lastSync(), r.phone.clock);
      },
    );

    test(
      'SYN-6: the desktop sends accounts and approvers, never entries',
      () async {
        final r = await makeRig();
        await r.desktop.addIncome(receipt: 1, amount: 5000);
        await r.sync();
        expect(await r.phoneEntries(), isEmpty); // nothing came back
        final payload = await SyncReceiver(
          r.desktop.db,
          PhotoStorage(r.desktop.photoDir),
        ).accountsPayload();
        expect(payload.keys.toSet(), {'users', 'approvers'});
      },
    );

    test(
      'later changes reach the phone at its next sync: new user, new password, disabled user',
      () async {
        final r = await makeRig();
        await r.sync();
        await r.desktop.users.addUser(
          r.desktop.superAdmin,
          name: 'নতুন',
          username: 'newbie',
          password: 'secret7',
          role: Role.user,
        );
        await r.desktop.users.resetPassword(
          r.desktop.superAdmin,
          r.desktop.user.id,
          'brandnew1',
        );
        await r.desktop.settings.addApprover(r.desktop.admin, 'ক্যাশিয়ার');
        await r.desktop.users.setActive(
          r.desktop.superAdmin,
          r.desktop.admin.id,
          false,
        );
        // Until the phone syncs, it still has the old accounts.
        expect(
          (await r.phone.users.signIn('user', 'secret3')).username,
          'user',
        );
        r.server.newOffer();
        await r.sync();
        expect((await r.phone.users.signIn('newbie', 'secret7')).name, 'নতুন');
        expect(
          (await r.phone.users.signIn('user', 'brandnew1')).username,
          'user',
        );
        await expectLater(
          r.phone.users.signIn('user', 'secret3'),
          throwsA(anything),
        );
        await expectLater(
          r.phone.users.signIn('admin', 'secret2'),
          throwsA(anything),
        ); // disabled
        expect(
          (await r.phone.settings.approvers()).map((a) => a.name),
          contains('ক্যাশিয়ার'),
        );
      },
    );
  });

  group('sending entries (SYN-1, SYN-4, SYN-5, SYN-9)', () {
    test(
      'SYN-1: a new phone entry starts as not synced; desktop entries need no syncing',
      () async {
        final r = await makeRig();
        await r.sync();
        final e = await r.phoneIncome(1, 100);
        expect(e.synced, isFalse);
        expect(e.deviceId, 'phone-1');
        expect((await r.desktop.addIncome(receipt: 1)).entry.synced, isTrue);
        expect(await r.client.pendingCount(), 1);
      },
    );

    test(
      'only not-synced entries are sent, each with all its photos; the desktop saves them',
      () async {
        final r = await makeRig();
        await r.sync();
        final big = bytes(1500 * 1024); // a 1.5 MB photo
        final a = await r.phoneIncome(
          6690,
          2000,
          name: 'আব্দুল করিম',
          photos: [
            PhotoDraft(bytes: big, label: 'রশিদ'),
            PhotoDraft(bytes: bytes(50, 3), label: 'মালামাল'),
          ],
        );
        final u = await r.phoneUser();
        final b = (await r.phone.entries.create(
          u,
          EntryDraft(
            type: EntryType.expense,
            receiptNo: 595,
            date: DateTime(2026, 11, 13),
            name: 'মোঃ সেলিম',
            purpose: 'ঝাড়ু ও রশি',
            approverName: 'সভাপতি',
            amount: 650,
          ),
        )).entry;

        r.server.newOffer();
        final events = <SyncEvent>[];
        final sub = r.server.events.listen(events.add);
        final report = await r.sync();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await sub.cancel();

        expect(
          (
            report.entriesSent,
            report.photosSent,
            report.income,
            report.expense,
          ),
          (2, 2, 1, 1),
        );
        expect(report.remaining, 0);
        // Desktop: both entries, synced, with the sync time; photos on disk.
        final got = {for (final e in await r.desktopEntries()) e.id: e};
        expect(got.keys, containsAll([a.id, b.id]));
        expect(got[a.id]!.synced, isTrue);
        expect(got[a.id]!.syncedAt, r.desktop.clock);
        expect(
          (got[a.id]!.receiptNo, got[a.id]!.amount, got[a.id]!.name),
          (6690, 2000, 'আব্দুল করিম'),
        );
        expect(
          got[a.id]!.createdBy,
          (await r.phoneUser()).id,
        ); // who added it is kept
        expect(got[b.id]!.approverName, 'সভাপতি');
        final photos = await r.desktop.entries.photosOf(a.id);
        expect(photos.map((p) => p.label), ['রশিদ', 'মালামাল']);
        final saved = await r.desktop.entries.photoStorage.read(
          a.id,
          photos.first.fileName,
        );
        expect(saved, big); // byte for byte
        // Phone: now marked synced.
        expect((await r.phoneEntries()).every((e) => e.synced), isTrue);
        expect(await r.client.pendingCount(), 0);
        // SYN-9: the desktop knows how many it received.
        final finished = events.whereType<SyncFinished>().single;
        expect(
          (
            finished.entries,
            finished.photos,
            finished.income,
            finished.expense,
          ),
          (2, 2, 1, 1),
        );
        final log = (await r.desktop.db.select(r.desktop.db.syncLog).get())
            .where((l) => l.entriesReceived > 0)
            .single;
        expect(
          (log.phoneName, log.entriesReceived, log.photosReceived),
          ('রাশেদের ফোন', 2, 2),
        );
        expect(
          (await r.desktop.db.select(r.desktop.db.syncLog).get()).length,
          2,
        ); // the first (accounts only) too
        // And it counts in the desktop's balance like any other entry.
        expect(await r.desktop.balance.currentBalance(), 2000 - 650);
      },
    );

    test(
      'an entry with 10 photos and a removed one still syncs; the removed one stays on the desktop (rule 4)',
      () async {
        final r = await makeRig();
        await r.sync();
        final e = await r.phoneIncome(
          1,
          500,
          photos: [
            for (var i = 0; i < 10; i++)
              PhotoDraft(bytes: bytes(40, i + 1), label: 'ছবি $i'),
          ],
        );
        // One photo is taken off, another put on: 11 rows, 10 of them shown.
        final rows = await r.phone.db.select(r.phone.db.photos).get();
        await (r.phone.db.update(r.phone.db.photos)
              ..where((x) => x.id.equals(rows.first.id)))
            .write(PhotosCompanion(removedAt: Value(DateTime(2026, 11, 14))));
        await PhotoStorage(
          r.phone.photoDir,
        ).saveAs(e.id, 'extra.jpg', bytes(30, 99));
        await r.phone.db
            .into(r.phone.db.photos)
            .insert(
              PhotosCompanion.insert(
                id: 'px',
                entryId: e.id,
                fileName: 'extra.jpg',
                label: 'নতুন',
                position: 10,
              ),
            );
        r.server.newOffer();
        final report = await r.sync();
        expect(report.entriesSent, 1);
        final got = await r.desktop.db.select(r.desktop.db.photos).get();
        expect(got, hasLength(11));
        expect(got.where((x) => x.removedAt != null), hasLength(1));
      },
    );

    test(
      'the computer remembers when a phone last synced (dashboard)',
      () async {
        final r = await makeRig();
        expect(
          await r.desktop.settingsRepo.getDateTime(SettingKey.lastSyncAt),
          isNull,
        );
        await r.sync();
        expect(
          await r.desktop.settingsRepo.getDateTime(SettingKey.lastSyncAt),
          isNotNull,
        );
      },
    );

    test('a second sync sends nothing again', () async {
      final r = await makeRig();
      await r.sync();
      await r.phoneIncome(1, 100);
      r.server.newOffer();
      await r.sync();
      r.server.newOffer();
      final again = await r.sync();
      expect(again.entriesSent, 0);
      expect((await r.desktopEntries()).length, 1);
    });

    test(
      'SYN-5: the answer is lost after the desktop saved it: nothing lost, saved once',
      () async {
        final r = await makeRig();
        await r.sync();
        final e = await r.phoneIncome(1, 100, photos: [TestEnv.photo()]);
        r.server.newOffer();
        // calls so far: 3 (hello, accounts, ... ) -> the 4th request is the entry
        r.http.calls = 0;
        r.http.dropResponseOfCall = 3; // hello=1, accounts=2, entry=3
        await expectLater(
          r.sync(),
          throwsA(
            isA<SyncException>().having(
              (x) => x.failure,
              'f',
              SyncFailure.offline,
            ),
          ),
        );
        // The desktop has it, but the phone could not know: still "not synced".
        expect(
          (await r.desktopEntries()).where((x) => x.id == e.id),
          hasLength(1),
        );
        expect((await r.phoneEntries()).single.synced, isFalse);

        // Sent again next time: the desktop recognises it and does not save it twice.
        r.http.dropResponseOfCall = null;
        r.server.newOffer();
        final report = await r.sync();
        expect(report.entriesSent, 1);
        expect((await r.desktopEntries()).length, 1);
        expect((await r.desktop.entries.photosOf(e.id)).length, 1);
        expect((await r.phoneEntries()).single.synced, isTrue);
        // Only the first receipt is counted as "received".
        final log = await r.desktop.db.select(r.desktop.db.syncLog).get();
        expect(log.fold<int>(0, (a, l) => a + l.entriesReceived), 1);
      },
    );

    test(
      'SYN-5: Wi-Fi off halfway: the first entries are kept, the rest go next time, none twice',
      () async {
        final r = await makeRig();
        await r.sync();
        final all = <Entry>[];
        for (var i = 1; i <= 5; i++) {
          r.phone.clock = r.phone.clock.add(const Duration(minutes: 1));
          all.add(
            await r.phoneIncome(
              100 + i,
              10 * i,
              photos: [TestEnv.photo('ছবি $i')],
            ),
          );
        }
        r.server.newOffer();
        r.http.calls = 0;
        r.http.cutFromCall =
            5; // hello, accounts, entry1, entry2, then the network dies
        SyncException? failure;
        try {
          await r.sync();
        } on SyncException catch (e) {
          failure = e;
        }
        expect(failure!.failure, SyncFailure.offline);
        expect(failure.partial.entriesSent, 2);
        expect(failure.partial.remaining, 3);
        expect((await r.phoneEntries()).where((e) => e.synced).length, 2);
        expect((await r.desktopEntries()).length, 2);

        // The network comes back; a new code; the other three go.
        r.http.cutFromCall = null;
        r.server.newOffer();
        final report = await r.sync();
        expect(report.entriesSent, 3);
        final onDesktop = await r.desktopEntries();
        expect(onDesktop.length, 5);
        expect(
          onDesktop.map((e) => e.id).toSet(),
          all.map((e) => e.id).toSet(),
        ); // none twice, none missing
        expect(await r.client.pendingCount(), 0);
        for (final e in all) {
          expect((await r.desktop.entries.photosOf(e.id)).length, 1);
        }
      },
    );

    test(
      'SYN-8: a receipt number the desktop already has is saved and flagged for an Admin',
      () async {
        final r = await makeRig();
        await r.desktop.addIncome(receipt: 589, amount: 100, name: 'আগের');
        await r.sync();
        final e = await r.phoneIncome(589, 850, name: 'ফোনের');
        await r.phoneIncome(590, 10);
        r.server.newOffer();
        final report = await r.sync();
        expect(report.duplicates, 1);
        final dup = (await r.desktopEntries()).firstWhere((x) => x.id == e.id);
        expect(dup.isDuplicate, isTrue);
        expect(dup.synced, isTrue);
        expect(
          (await r.desktopEntries()).where((x) => x.receiptNo == 589).length,
          2,
        ); // both kept
        expect((await r.desktop.entries.duplicateCount(EntryType.income)), 1);
        expect(
          (await r.desktopEntries())
              .firstWhere((x) => x.receiptNo == 590)
              .isDuplicate,
          isFalse,
        );
        // The same number in the OTHER series is not a clash.
        expect(
          (await r.desktop.entries.findByReceipt(EntryType.income, 589)).length,
          2,
        );
      },
    );

    test(
      'a cancelled phone entry is sent as cancelled, with its reason',
      () async {
        final r = await makeRig();
        await r.sync();
        final e = await r.phoneIncome(1, 100);
        final admin = await r.phoneUser('admin');
        await r.phone.entries.cancel(admin, e.id, 'ভুল');
        r.server.newOffer();
        await r.sync();
        final got = (await r.desktopEntries()).single;
        expect(
          (got.status, got.cancelReason, got.cancelledBy),
          (EntryStatus.cancelled, 'ভুল', admin.id),
        );
      },
    );
  });

  group('phone rules (SYN-7, MOB-3)', () {
    test(
      'SYN-7: a synced entry is read-only on the phone; an unsynced one is not',
      () async {
        final r = await makeRig();
        await r.sync();
        final a = await r.phoneIncome(1, 100);
        final b = await r.phoneIncome(2, 200);
        // Sync only... both go; make a third afterwards.
        r.server.newOffer();
        await r.sync();
        final c = await r.phoneIncome(3, 300);
        final admin = await r.phoneUser('admin');

        for (final synced in [a, b]) {
          await expectLater(
            r.phone.entries.cancel(admin, synced.id, 'কারণ'),
            throwsA(
              isA<EntryActionException>().having(
                (e) => e.problem,
                'p',
                EntryActionProblem.syncedReadOnly,
              ),
            ),
          );
          await expectLater(
            r.phone.entries.update(
              admin,
              synced.id,
              EntryDraft(
                type: EntryType.income,
                receiptNo: synced.receiptNo,
                date: DateTime(2026, 11, 13),
                name: 'বদল',
                amount: 999,
              ),
            ),
            throwsA(isA<EntryActionException>()),
          );
        }
        // The desktop (master) can still correct it.
        final onDesktop = (await r.desktopEntries()).firstWhere(
          (e) => e.id == a.id,
        );
        await r.desktop.entries.cancel(
          r.desktop.admin,
          onDesktop.id,
          'ঠিক করা',
        );
        // An entry not yet synced may still be cancelled on the phone.
        await r.phone.entries.cancel(admin, c.id, 'ভুল');
        expect(
          (await r.phoneEntries()).firstWhere((e) => e.id == c.id).status,
          EntryStatus.cancelled,
        );
      },
    );

    test(
      'MOB-3: the phone balance counts only entries made on the phone, no opening balance',
      () async {
        final r = await makeRig();
        await r.desktop.settings.setOpeningBalance(
          r.desktop.admin,
          120000,
          DateTime(2026, 1, 1),
        );
        await r.desktop.addIncome(receipt: 1, amount: 99999);
        await r.sync();
        await r.phoneIncome(1, 700);
        expect(await r.phone.balance.currentBalance(), 700);
        expect(
          await r.desktop.balance.currentBalance(),
          120000 + 99999,
        ); // before the phone entry arrives
      },
    );
  });

  group('the QR code and the Wi-Fi link (SYN-2, SYN-3, plan Risk 7)', () {
    test('SYN-3: each code works for one sync only', () async {
      final r = await makeRig();
      final offer = r.server.offer;
      await r.sync(offer);
      // The same code again is refused, and the screen now has a new code.
      expect(r.server.offer.token, isNot(offer.token));
      await expectLater(
        r.sync(offer),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'f',
            SyncFailure.unauthorised,
          ),
        ),
      );
      await r.sync(r.server.offer); // the new one works
    });

    test('a code that was replaced by "new code" no longer works', () async {
      final r = await makeRig();
      final old = r.server.offer;
      r.server.newOffer();
      await expectLater(r.sync(old), throwsA(isA<SyncException>()));
      expect(await r.phone.users.hasAnyUser(), isFalse);
    });

    test(
      'someone without the key (wrong key, right token) gets nothing and saves nothing',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        final forged = SyncOffer(
          host: o.host,
          port: o.port,
          key: bytes(32, 99),
          token: o.token,
          desktopName: '',
        );
        await expectLater(
          r.sync(forged),
          throwsA(
            isA<SyncException>().having(
              (e) => e.failure,
              'f',
              SyncFailure.unauthorised,
            ),
          ),
        );
        expect(await r.phone.users.hasAnyUser(), isFalse);
        // The real code is not spent by the failed attempts.
        await r.sync(o);
      },
    );

    test(
      'a request with the right key but the wrong token is refused',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        final res = await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/hello'),
          body: await SyncCrypto(
            o.key,
          ).sealJson({'token': 'nope', 'phoneName': 'x'}, aad: 'hello'),
        );
        expect(res.statusCode, 401);
      },
    );

    test(
      'nothing readable crosses the Wi-Fi: names, amounts and passwords are sealed',
      () async {
        final r = await makeRig();
        await r.sync();
        await r.phoneIncome(1, 123456, name: 'গোপন দাতার নাম');
        r.server.newOffer();
        r.http.sent.clear();
        await r.sync();
        final wire = r.http.sent.expand((b) => b).toList();
        final text = latin1.decode(wire, allowInvalid: true);
        expect(text, isNot(contains('123456')));
        expect(
          utf8.decode(wire, allowMalformed: true),
          isNot(contains('গোপন দাতার নাম')),
        );
        expect(text, isNot(contains('income')));
      },
    );

    test(
      'a request changed on the way is refused (tampering is detected)',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        final sealed = await SyncCrypto(
          o.key,
        ).sealJson({'token': o.token, 'phoneName': 'x'}, aad: 'hello');
        sealed[sealed.length - 1] ^= 0x01;
        final res = await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/hello'),
          body: sealed,
        );
        expect(res.statusCode, 401);
      },
    );

    test(
      'a message cannot be replayed to another endpoint (it is bound to its path)',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        final c = SyncCrypto(o.key);
        final hello = await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/hello'),
          body: await c.sealJson({
            'token': o.token,
            'phoneName': 'x',
          }, aad: 'hello'),
        );
        final session =
            (await c.openJson(hello.bodyBytes, aad: 'res:hello'))['session']
                as String;
        // An "entry" message sealed for /accounts is not accepted at /entry.
        final res = await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/entry'),
          headers: {'X-Session': session},
          body: await c.sealJson({}, aad: 'accounts'),
        );
        expect(res.statusCode, 401);
      },
    );

    test(
      'two phones using the same code at the same moment: only one gets in (SYN-3)',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        final c = SyncCrypto(o.key);
        Future<int> hello() async => (await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/hello'),
          body: await c.sealJson({
            'token': o.token,
            'phoneName': 'x',
          }, aad: 'hello'),
        )).statusCode;
        final codes = await Future.wait([hello(), hello()]);
        expect(codes..sort(), [200, 401]);
      },
    );

    test(
      'an entry or photo name that would leave the photo folder is refused',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        final c = SyncCrypto(o.key);
        final hello = await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/hello'),
          body: await c.sealJson({
            'token': o.token,
            'phoneName': 'x',
          }, aad: 'hello'),
        );
        final session =
            (await c.openJson(hello.bodyBytes, aad: 'res:hello'))['session']
                as String;
        await r.sync(); // pairs a phone so it has a valid entry to copy
        final e = await r.phoneIncome(1, 500);
        Future<int> send(String id, String file) async => (await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/entry'),
          headers: {'X-Session': session},
          body: await c.sealJson({
            'entry': {...e.toJson(), 'id': id},
            'photos': [
              {
                'id': 'p1',
                'entryId': id,
                'fileName': file,
                'label': 'x',
                'position': 0,
                'removedAt': null,
                'data': base64.encode([1, 2, 3]),
              },
            ],
          }, aad: 'entry'),
        )).statusCode;
        expect(await send('..', 'atia_accounts.db'), 422);
        expect(await send('ok-1', '../x.jpg'), 422);
        expect(await send('ok-1', '..'), 422);
        expect(await send('a/b', 'x.jpg'), 422);
        expect(await r.desktopEntries(), isEmpty);
      },
    );

    test(
      'only POST, only known paths, and unknown sessions are refused',
      () async {
        final r = await makeRig();
        final o = r.server.offer;
        expect(
          (await http.get(
            Uri.parse('http://127.0.0.1:${o.port}/accounts'),
          )).statusCode,
          405,
        );
        expect(
          (await http.post(
            Uri.parse('http://127.0.0.1:${o.port}/accounts'),
            body: 'x',
          )).statusCode,
          401,
        );
        expect(
          (await http.post(
            Uri.parse('http://127.0.0.1:${o.port}/entry'),
            headers: {'X-Session': 'made-up'},
            body: 'x',
          )).statusCode,
          401,
        );
      },
    );

    test('a session expires if the phone goes quiet', () async {
      final r = await makeRig();
      final o = r.server.offer;
      final c = SyncCrypto(o.key);
      final hello = await http.post(
        Uri.parse('http://127.0.0.1:${o.port}/hello'),
        body: await c.sealJson({
          'token': o.token,
          'phoneName': 'x',
        }, aad: 'hello'),
      );
      final session =
          (await c.openJson(hello.bodyBytes, aad: 'res:hello'))['session']
              as String;
      Future<int> accounts() async => (await http.post(
        Uri.parse('http://127.0.0.1:${o.port}/accounts'),
        headers: {'X-Session': session},
        body: await c.sealJson({}, aad: 'accounts'),
      )).statusCode;
      expect(await accounts(), 200);
      r.desktop.clock = r.desktop.clock.add(const Duration(minutes: 11));
      expect(await accounts(), 401);
    });

    test(
      'a rejected entry (amount 0) is refused with a clear status, nothing saved',
      () async {
        final r = await makeRig();
        await r.sync();
        final e = await r.phoneIncome(1, 100);
        // Corrupt the phone's copy so it sends an invalid entry.
        await r.phone.db.customStatement(
          'UPDATE entries SET amount = 0 WHERE id = ?',
          [e.id],
        );
        r.server.newOffer();
        await expectLater(
          r.sync(),
          throwsA(
            isA<SyncException>().having(
              (x) => x.failure,
              'f',
              SyncFailure.rejected,
            ),
          ),
        );
        expect(await r.desktopEntries(), isEmpty);
        expect((await r.phoneEntries()).single.synced, isFalse);
      },
    );

    test('the offer survives being turned into a code and back', () {
      final o = SyncOffer.generate(
        host: '192.168.1.20',
        port: 51234,
        desktopName: 'মসজিদের কম্পিউটার',
      );
      final back = SyncOffer.tryDecode(o.encode())!;
      expect(
        (back.host, back.port, back.token, back.desktopName),
        ('192.168.1.20', 51234, o.token, 'মসজিদের কম্পিউটার'),
      );
      expect(back.key, o.key);
      expect(SyncOffer.tryDecode('hello'), isNull);
      expect(SyncOffer.tryDecode('ATIA1.@@@'), isNull);
      expect(
        SyncOffer.generate(host: 'a', port: 1, desktopName: '').token,
        isNot(SyncOffer.generate(host: 'a', port: 1, desktopName: '').token),
      );
    });

    test(
      'the server cannot be asked for entries: there is no such path',
      () async {
        final r = await makeRig();
        await r.desktop.addIncome(receipt: 1, amount: 777);
        final o = r.server.offer;
        final c = SyncCrypto(o.key);
        final hello = await http.post(
          Uri.parse('http://127.0.0.1:${o.port}/hello'),
          body: await c.sealJson({
            'token': o.token,
            'phoneName': 'x',
          }, aad: 'hello'),
        );
        final session =
            (await c.openJson(hello.bodyBytes, aad: 'res:hello'))['session']
                as String;
        for (final path in ['entries', 'export', 'list', 'entry/1']) {
          final res = await http.post(
            Uri.parse('http://127.0.0.1:${o.port}/$path'),
            headers: {'X-Session': session},
            body: await c.sealJson({}, aad: path),
          );
          expect(res.statusCode, anyOf(401, 404), reason: path);
        }
      },
    );
  });
}
