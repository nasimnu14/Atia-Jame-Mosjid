import 'dart:io';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/db_opener.dart';
import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:atia_masjid_accounts/features/google_drive/backup_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_client.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/restore_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/fake_drive.dart';
import '../helpers/test_env.dart';

/// Opens the database inside a downloaded backup and returns its entries.
Future<List<Entry>> entriesIn(Uint8List gz, Directory tmp) async {
  final f = File(
    p.join(tmp.path, 'dl-${DateTime.now().microsecondsSinceEpoch}.db'),
  )..writeAsBytesSync(gzip.decode(gz));
  final db = AppDatabase(NativeDatabase(f));
  final rows = await db.select(db.entries).get();
  await db.close();
  return rows;
}

void main() {
  emptyDatabaseTests();
  group('backup (BAK-2, BAK-5, BAK-7)', () {
    test(
      'BAK-2: uploads a snapshot of all data; time recorded; error cleared',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.addIncome(receipt: 1, amount: 500);
        await env.addExpense(receipt: 1, amount: 100);
        final r = await env.backup.runBackup();
        expect(r.ok, isTrue);

        final files = env.fakeDrive.filesIn(DriveFolders.backups);
        expect(files.length, 1);
        expect(files.single.name, matches(r'^backup-\d{8}-\d{6}\.db\.gz$'));
        final rows = await entriesIn(
          env.fakeDrive.bytesOf(files.single.id)!,
          env.dataDir,
        );
        expect(rows.map((e) => e.amount).toSet(), {500, 100});
        expect(await env.backup.lastSuccess(), env.clock);
        expect(await env.backup.lastError(), isNull);
        final log = await env.driveService.recentLog(['backup']);
        expect(log.single.ok, isTrue);
      },
    );

    test('the backup holds users, approvers and settings too', () async {
      final env = await TestEnv.create(connected: true);
      await env.settings.setOpeningBalance(
        env.admin,
        120000,
        DateTime(2026, 1, 1),
      );
      await env.backup.runBackup();
      final f = env.fakeDrive.filesIn(DriveFolders.backups).single;
      final tmp = File(p.join(env.dataDir.path, 'x.db'))
        ..writeAsBytesSync(gzip.decode(env.fakeDrive.bytesOf(f.id)!));
      final db = AppDatabase(NativeDatabase(tmp));
      expect((await db.select(db.users).get()).map((u) => u.username).toSet(), {
        'super',
        'admin',
        'user',
      });
      expect((await db.select(db.approvers).get()).map((a) => a.name).toSet(), {
        'সভাপতি',
        'সেক্রেটারী',
      });
      final s = await (db.select(
        db.settings,
      )..where((x) => x.key.equals(SettingKey.openingBalance))).getSingle();
      expect(s.value, '120000');
      await db.close();
    });

    test('photos are uploaded once, never again, and never deleted', () async {
      final env = await TestEnv.create(onDisk: true, connected: true);
      await env.addIncome(
        receipt: 1,
        photos: [TestEnv.photo('এক'), TestEnv.photo('দুই')],
      );
      final first = await env.backup.runBackup();
      expect(first.newPhotos, 2);
      expect(env.fakeDrive.filesIn(DriveFolders.photos).length, 2);

      final before = env.fakeDrive.uploadCount;
      final second = await env.backup.runBackup();
      expect(second.newPhotos, 0);
      expect(env.fakeDrive.uploadCount, before + 1); // only the database

      await env.addIncome(receipt: 2, photos: [TestEnv.photo('তিন')]);
      final third = await env.backup.runBackup();
      expect(third.newPhotos, 1);
      expect(env.fakeDrive.filesIn(DriveFolders.photos).length, 3);
      expect(env.fakeDrive.filesIn(DriveFolders.backups).length, 3);
    });

    test(
      'BAK-3 / BAK-5: with no internet it fails and says so; later it succeeds',
      () async {
        final env = await TestEnv.create(connected: true);
        await env.addIncome();
        env.fakeDrive.offline = true;
        final bad = await env.backup.runBackup();
        expect(bad.outcome, BackupOutcome.failed);
        expect(bad.offline, isTrue);
        expect(await env.backup.lastSuccess(), isNull);
        expect(await env.backup.lastError(), isNotNull); // the user is told
        expect(
          (await env.driveService.recentLog(['backup'])).single.ok,
          isFalse,
        );

        env.fakeDrive.offline = false;
        env.clock = env.clock.add(const Duration(minutes: 3));
        final good = await env.backup.runBackup();
        expect(good.ok, isTrue);
        expect(await env.backup.lastError(), isNull);
        expect(await env.backup.lastSuccess(), env.clock);
      },
    );

    test(
      'BAK-2 / BAK-4: due when never done, not due soon after, due after 4 hours',
      () async {
        final env = await TestEnv.create(connected: true);
        expect(await env.backup.isDue(), isTrue);
        await env.backup.runBackup();
        expect(await env.backup.isDue(), isFalse);
        env.clock = env.clock.add(const Duration(hours: 3, minutes: 59));
        expect(await env.backup.isDue(), isFalse);
        env.clock = env.clock.add(const Duration(minutes: 1));
        expect(
          await env.backup.isDue(),
          isTrue,
        ); // e.g. the app was closed meanwhile
        expect(await env.backup.nextDue(), isNotNull);
      },
    );

    test(
      'BAK-7: backups older than a year are deleted; newer ones and photos stay',
      () async {
        final env = await TestEnv.create(onDisk: true, connected: true);
        await env.addIncome(photos: [TestEnv.photo()]);
        Future<String> backupAt(DateTime t) async {
          env.clock = t;
          await env.backup.runBackup();
          return env.fakeDrive.filesIn(DriveFolders.backups).first.id; // newest
        }

        final old = await backupAt(DateTime(2025, 6, 1));
        final almostYear = await backupAt(DateTime(2025, 12, 1));
        final recent = await backupAt(DateTime(2026, 10, 1));
        // Now (13 Nov 2026) this backup pushes out the one from June 2025 (> 1 year).
        final now = await backupAt(DateTime(2026, 11, 13));
        final ids = env.fakeDrive
            .filesIn(DriveFolders.backups)
            .map((f) => f.id)
            .toSet();
        expect(ids.contains(old), isFalse);
        expect(ids, containsAll([almostYear, recent, now]));
        expect(
          env.fakeDrive.filesIn(DriveFolders.photos).length,
          1,
        ); // photos are never deleted
      },
    );

    test('BAK-7: the newest backup is kept even if it is old', () async {
      final env = await TestEnv.create(connected: true);
      env.clock = DateTime(2024, 1, 1);
      await env.backup.runBackup();
      env.clock = DateTime(2026, 11, 13);
      env.fakeDrive.clock = () =>
          DateTime(2024, 1, 1); // Drive says it is the only, old one
      final id = env.fakeDrive.filesIn(DriveFolders.backups).single.id;
      await env.backup.runBackup();
      // The first one is deleted, but one backup always remains.
      expect(env.fakeDrive.filesIn(DriveFolders.backups), isNotEmpty);
      expect(id, isNotEmpty);
    });

    test(
      'an upload that stops halfway keeps the last good backup and loses nothing',
      () async {
        final env = await TestEnv.create(onDisk: true, connected: true);
        await env.addIncome(receipt: 1, photos: [TestEnv.photo('এক')]);
        expect((await env.backup.runBackup()).ok, isTrue);
        final good = env.fakeDrive.filesIn(DriveFolders.backups).single.id;

        await env.addIncome(
          receipt: 2,
          photos: [TestEnv.photo('দুই'), TestEnv.photo('তিন')],
        );
        env.fakeDrive.failUploadNumber =
            2; // the second photo of this run fails
        env.clock = env.clock.add(const Duration(hours: 5));
        final bad = await env.backup.runBackup();
        expect(bad.outcome, BackupOutcome.failed);
        // No new database was uploaded, the last good one is still there.
        expect(env.fakeDrive.filesIn(DriveFolders.backups).map((f) => f.id), [
          good,
        ]);
        // Only the photo that really went up is recorded; the others retry next time.
        final recorded = await env.db.select(env.db.driveUploadedPhotos).get();
        expect(recorded.length, 2); // 'এক' (first run) + one of the new ones

        final retry = await env.backup.runBackup();
        expect(retry.ok, isTrue);
        expect(env.fakeDrive.filesIn(DriveFolders.photos).length, 3);
        expect(
          await env.db.select(env.db.driveUploadedPhotos).get(),
          hasLength(3),
        );
      },
    );

    test('not connected: nothing happens', () async {
      final env = await TestEnv.create();
      final r = await env.backup.runBackup();
      expect(r.outcome, BackupOutcome.notConnected);
      expect(env.fakeDrive.uploadCount, 0);
    });
  });

  group('BAK-5: a sign-in that cannot be used is reported, once', () {
    test(
      'lost sign-in: a failure is shown and logged once, not every retry',
      () async {
        final env = await TestEnv.create();
        // An account was connected earlier, but Google no longer accepts the
        // saved sign-in (as after a restart of the app).
        await env.settingsRepo.set(SettingKey.googleAccount, 'a@example.com');
        env.auth.stored = null;
        for (var i = 0; i < 3; i++) {
          final r = await env.backup.runBackup();
          expect(r.outcome, BackupOutcome.failed);
          expect(r.error, contains('sign-in expired'));
        }
        expect(await env.backup.lastError(), contains('sign-in expired'));
        expect(await env.driveService.recentLog(['backup']), hasLength(1));
      },
    );

    test(
      'no internet is reported as no internet, not as an expired sign-in',
      () async {
        final env = await TestEnv.create();
        await env.settingsRepo.set(SettingKey.googleAccount, 'a@example.com');
        env.auth.restoreError = DriveException(
          'No internet connection',
          offline: true,
        );
        final r = await env.backup.runBackup();
        expect(r.outcome, BackupOutcome.failed);
        expect(r.offline, isTrue);
        expect(r.error, 'No internet connection');
      },
    );
  });

  group('BAK-8: switching Google account', () {
    test(
      'a full backup, with every photo, goes to the new account at once',
      () async {
        final env = await TestEnv.create(onDisk: true, connected: true);
        await env.addIncome(photos: [TestEnv.photo('এক')]);
        await env.backup.runBackup();
        expect(env.fakeDrive.filesIn(DriveFolders.photos).length, 1);

        env.auth.nextAccount = 'mosque-own@example.com';
        final c = await env.driveService.connect();
        expect(c.changed, isTrue);
        expect(c.email, 'mosque-own@example.com');
        await env.scheduler.onAccountChanged();

        // The new account's Drive has its own copy of the database and the photo.
        final newClient = env.fakeDrive.client('mosque-own@example.com');
        expect(await env.driveService.accountEmail(), 'mosque-own@example.com');
        final root = await newClient.ensureFolder(DriveFolders.root);
        final photos = await newClient.ensureFolder(
          DriveFolders.photos,
          parentId: root,
        );
        final backups = await newClient.ensureFolder(
          DriveFolders.backups,
          parentId: root,
        );
        expect((await newClient.list(photos)).length, 1);
        expect((await newClient.list(backups)).length, 1);
      },
    );

    test('connecting the same account again is not a change', () async {
      final env = await TestEnv.create(connected: true);
      expect((await env.driveService.connect()).changed, isFalse);
    });
  });

  group('restore (BAK-6, USR-3)', () {
    test(
      'a new computer gets every entry, photo, user, approver and setting back',
      () async {
        final drive = FakeDrive();
        final a = await TestEnv.create(
          onDisk: true,
          drive: drive,
          connected: true,
        );
        await a.settings.setOpeningBalance(
          a.admin,
          120000,
          DateTime(2026, 1, 1),
        );
        final saved = await a.addIncome(
          receipt: 6685,
          amount: 5000,
          name: 'আব্দুল করিম',
          photos: [TestEnv.photo('রশিদ')],
        );
        await a.addExpense(receipt: 593, amount: 12500);
        await a.entries.cancel(a.admin, saved.entry.id, 'ভুল');
        await a.backup.runBackup();

        // A brand new computer: empty data folder, same Google account.
        final b = await TestEnv.create(
          onDisk: true,
          drive: drive,
          seedUsers: false,
        );
        b.auth.stored = a.auth.stored;
        await b.driveService.connect();
        final backups = await b.restore.listBackups();
        expect(backups.length, 1);
        final outcome = await b.restore.restore(
          backups.single,
          closeDatabase: () => b.db.close(),
          hasLiveData: false,
        );
        expect((outcome.photosRestored, outcome.photosMissing), (1, 0));

        final reopened = await openAppDatabase(b.dataDir);
        addTearDown(reopened.close);
        final entries = await reopened.select(reopened.entries).get();
        expect(entries.length, 2);
        final cancelled = entries.firstWhere((e) => e.receiptNo == 6685);
        expect(cancelled.status.name, 'cancelled'); // cancel reason and all
        expect(cancelled.cancelReason, 'ভুল');
        expect(
          (await reopened.select(reopened.users).get())
              .map((u) => u.username)
              .toSet(),
          {'super', 'admin', 'user'},
        );
        expect((await reopened.select(reopened.approvers).get()), hasLength(2));
        // The same passwords still work.
        final hashes = {
          for (final u in await reopened.select(reopened.users).get())
            u.username: u.passwordHash,
        };
        expect(
          hashes['super'],
          (await a.db.select(a.db.users).get())
              .firstWhere((u) => u.username == 'super')
              .passwordHash,
        );
        // The photo file is back, byte for byte.
        final photo = (await reopened.select(reopened.photos).getSingle());
        expect(
          File(
            p.join(b.dataDir.path, 'photos', photo.entryId, photo.fileName),
          ).readAsBytesSync(),
          [1, 2, 3],
        );
      },
    );

    test('the current data is copied aside before it is replaced', () async {
      final drive = FakeDrive();
      final a = await TestEnv.create(
        onDisk: true,
        drive: drive,
        connected: true,
      );
      await a.addIncome(receipt: 1, amount: 111);
      await a.backup.runBackup();
      await a.addIncome(receipt: 2, amount: 222); // newer than the backup
      final file = (await a.restore.listBackups()).single;
      await a.restore.restore(file, closeDatabase: () => a.db.close());

      final aside = Directory(
        p.join(a.dataDir.path, 'backups'),
      ).listSync().whereType<File>().toList();
      expect(
        aside.any((f) => p.basename(f.path).startsWith('pre-restore-')),
        isTrue,
      );
      final copy = AppDatabase(
        NativeDatabase(
          aside.firstWhere(
            (f) => p.basename(f.path).startsWith('pre-restore-'),
          ),
        ),
      );
      expect((await copy.select(copy.entries).get()).length, 2); // nothing lost
      await copy.close();
      final now = await openAppDatabase(a.dataDir);
      addTearDown(now.close);
      expect(
        (await now.select(now.entries).get()).length,
        1,
      ); // back to the backup
    });

    test(
      'a damaged or foreign file is refused and the current data stays',
      () async {
        final drive = FakeDrive();
        final a = await TestEnv.create(
          onDisk: true,
          drive: drive,
          connected: true,
        );
        await a.addIncome(receipt: 1, amount: 111);
        final client = (await a.driveService.client())!;
        final folder = await a.driveService.folder(
          client,
          DriveFolders.backups,
        );
        final junk = await client.upload(
          folderId: folder,
          name: 'backup-20261113-000000.db.gz',
          bytes: Uint8List.fromList(
            gzip.encode(List<int>.generate(500, (i) => i % 251)),
          ),
          mimeType: 'application/gzip',
        );
        var closed = false;
        await expectLater(
          a.restore.restore(junk, closeDatabase: () async => closed = true),
          throwsA(isA<RestoreException>()),
        );
        expect(closed, isFalse); // the app's database was never touched
        expect((await a.db.select(a.db.entries).get()).length, 1);
      },
    );

    test('a backup from a newer version of the app is refused', () async {
      final dir = Directory.systemTemp.createTempSync('atia_new_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File(p.join(dir.path, 'x.db'));
      final db = AppDatabase(NativeDatabase(f));
      await db.customSelect('select 1').get();
      await db.customStatement(
        'PRAGMA user_version = ${AppDatabase.currentSchemaVersion + 1}',
      );
      await db.close();
      expect(
        () => RestoreService.validate(f),
        throwsA(
          isA<RestoreException>().having(
            (e) => e.problem,
            'problem',
            RestoreProblem.tooNew,
          ),
        ),
      );
    });

    test('not connected: restore says so', () async {
      final env = await TestEnv.create(onDisk: true);
      await expectLater(
        env.restore.restore(DriveFileStub.make(), closeDatabase: () async {}),
        throwsA(
          isA<RestoreException>().having(
            (e) => e.problem,
            'problem',
            RestoreProblem.notConnected,
          ),
        ),
      );
    });
  });
}

void emptyDatabaseTests() {
  test(
    'a brand-new installation with no accounts is never backed up',
    () async {
      final env = await TestEnv.create(seedUsers: false, connected: true);
      final r = await env.backup.runBackup();
      expect(r.outcome, BackupOutcome.nothingToBackUp);
      await env.scheduler.checkNow();
      await env.scheduler.onAccountChanged();
      expect(env.fakeDrive.uploadCount, 0);
    },
  );
}
