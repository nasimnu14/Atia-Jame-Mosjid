import 'dart:io';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/db_opener.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// A pretend "next version" of the database whose upgrade step we control.
class _FakeNext extends AppDatabase {
  _FakeNext(super.e, {this.fail = false});
  final bool fail;
  @override
  int get schemaVersion => next;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      await customStatement('ALTER TABLE users ADD COLUMN nickname TEXT');
      await customStatement("UPDATE users SET name = 'CHANGED'");
      if (fail) throw StateError('boom');
    },
    beforeOpen: (d) async {},
  );
}

const current = AppDatabase.currentSchemaVersion;
const next = current + 1;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('atia_open_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> seedV1() async {
    final db = await openAppDatabase(dir);
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: 'u1',
            name: 'মূল নাম',
            username: 'a',
            passwordHash: 'h',
            role: Role.admin,
            createdAt: DateTime(2026),
          ),
        );
    await db.close();
  }

  Future<String> nameIn(File f) async {
    final db = AppDatabase(NativeDatabase(f));
    final n = (await db.select(db.users).getSingle()).name;
    await db.close();
    return n;
  }

  test(
    'a new data folder is created at the current version, with no backup',
    () async {
      final db = await openAppDatabase(
        Directory(p.join(dir.path, 'new', 'deeper')),
      );
      await db.close();
      expect(
        readUserVersion(File(p.join(dir.path, 'new', 'deeper', dbFileName))),
        AppDatabase.currentSchemaVersion,
      );
      expect(
        Directory(p.join(dir.path, 'new', 'deeper', 'backups')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'reopening at the same version makes no backup and keeps data',
    () async {
      await seedV1();
      final db = await openAppDatabase(dir);
      expect((await db.select(db.users).getSingle()).name, 'মূল নাম');
      await db.close();
      expect(Directory(p.join(dir.path, 'backups')).existsSync(), isFalse);
    },
  );

  test(
    'UPD-4: a copy is made before an upgrade, and data survives it',
    () async {
      await seedV1();
      final db = await openAppDatabase(
        dir,
        targetVersion: next,
        factory: (f) => _FakeNext(NativeDatabase.createInBackground(f)),
      );
      await db.close();
      final backups = Directory(
        p.join(dir.path, 'backups'),
      ).listSync().whereType<File>().toList();
      expect(backups.length, 1);
      expect(
        p.basename(backups.single.path),
        startsWith('pre-migration-v$current-to-v$next-'),
      );
      expect(readUserVersion(backups.single), current);
      expect(await nameIn(backups.single), 'মূল নাম'); // copy is the old data
      expect(readUserVersion(File(p.join(dir.path, dbFileName))), next);
    },
  );

  test(
    'UPD-5: a failed upgrade puts the copy back; the old version still opens',
    () async {
      await seedV1();
      await expectLater(
        openAppDatabase(
          dir,
          targetVersion: next,
          factory: (f) =>
              _FakeNext(NativeDatabase.createInBackground(f), fail: true),
        ),
        throwsA(isA<MigrationFailedException>()),
      );
      final file = File(p.join(dir.path, dbFileName));
      expect(readUserVersion(file), current); // still the old schema
      final db = await openAppDatabase(dir); // the previous version opens fine
      final u = await db.select(db.users).getSingle();
      expect(u.name, 'মূল নাম'); // nothing was changed
      await db.close();
    },
  );

  test('a database newer than the app is refused and left untouched', () async {
    await seedV1();
    await expectLater(
      openAppDatabase(
        dir,
        targetVersion: next,
        factory: (f) => _FakeNext(NativeDatabase.createInBackground(f)),
      ),
      completes,
    ); // upgrade to the next version
    final before = File(p.join(dir.path, dbFileName)).readAsBytesSync();
    await expectLater(
      openAppDatabase(dir),
      throwsA(isA<DatabaseTooNewException>()),
    );
    expect(File(p.join(dir.path, dbFileName)).readAsBytesSync(), before);
  });
}
