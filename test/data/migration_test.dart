import 'dart:io';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/db_opener.dart';
import 'package:drift/drift.dart'
    show
        OpeningDetails,
        QueryExecutor,
        QueryExecutorUser,
        Value,
        driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;
import '../generated_migrations/schema_v2.dart' as v2;

/// Every database upgrade step has a test here (UPD-3, UPD-4). Add a case for
/// each new schema version: dump it with `dart run drift_dev schema dump`,
/// regenerate with `schema generate`, then write the test below.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  /// Puts realistic data into a database at schema 1 (plain SQL, because the
  /// old schema has no generated insert helpers).
  Future<void> seedV1(v1.DatabaseAtV1 db) async {
    await db.customStatement(
      'INSERT INTO users (id, name, username, password_hash, role, is_active, created_at) '
      "VALUES ('u1', 'আব্দুর রহমান', 'rahman', 'hash', 'superAdmin', 1, ${secs(DateTime(2026, 1, 1))})",
    );
    await db.customStatement(
      'INSERT INTO entries (id, type, receipt_no, entry_date, name, amount, status, created_by, created_at, device_id, synced, is_duplicate) '
      "VALUES ('e1', 'income', 6685, '2026-11-13', 'আব্দুল করিম', 5000, 'active', 'u1', ${secs(DateTime(2026, 11, 13, 10))}, 'desktop-1', 1, 0)",
    );
    await db.customStatement(
      'INSERT INTO photos (id, entry_id, file_name, label, position) '
      "VALUES ('p1', 'e1', 'a.jpg', 'রশিদ', 0)",
    );
    await db.customStatement(
      "INSERT INTO approvers (id, name, is_active) VALUES ('a1', 'সভাপতি', 1)",
    );
    await db.customStatement(
      "INSERT INTO settings (key, value) VALUES ('opening_balance', '120000')",
    );
  }

  test(
    'schema 1 -> newest: every row is kept and the new tables are empty and usable',
    () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await seedV1(oldDb);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(
        db,
        3,
      ); // the tables match schema 3 exactly

      final user = await db.select(db.users).getSingle();
      expect(
        (user.name, user.username, user.role.name),
        ('আব্দুর রহমান', 'rahman', 'superAdmin'),
      );
      expect(user.lastSignInAt, isNull);
      final e = await db.select(db.entries).getSingle();
      expect(
        (e.receiptNo, e.amount, e.name, e.synced),
        (6685, 5000, 'আব্দুল করিম', true),
      );
      final photo = await db.select(db.photos).getSingle();
      expect((photo.label, photo.removedAt), ('রশিদ', null));
      expect((await db.select(db.approvers).getSingle()).name, 'সভাপতি');
      expect((await db.select(db.settings).getSingle()).value, '120000');

      expect(await db.select(db.driveLog).get(), isEmpty);
      expect(await db.select(db.driveUploadedPhotos).get(), isEmpty);
      await db
          .into(db.driveLog)
          .insert(
            DriveLogCompanion.insert(
              id: 'l1',
              at: DateTime(2026),
              kind: 'backup',
              description: 'x',
              ok: true,
            ),
          );
      expect(await db.select(db.driveLog).get(), hasLength(1));
      await db.close();
    },
  );

  test('schema 2 -> 3: photos keep their rows and can be marked removed', () async {
    final schema = await verifier.schemaAt(2);
    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb.customStatement(
      'INSERT INTO users (id, name, username, password_hash, role, is_active, created_at) '
      "VALUES ('u1', 'আব্দুর রহমান', 'rahman', 'hash', 'superAdmin', 1, ${secs(DateTime(2026, 1, 1))})",
    );
    await oldDb.customStatement(
      'INSERT INTO entries (id, type, receipt_no, entry_date, name, amount, status, created_by, created_at, device_id, synced, is_duplicate) '
      "VALUES ('e1', 'income', 1, '2026-11-13', 'x', 700, 'active', 'u1', ${secs(DateTime(2026, 11, 13, 10))}, 'd', 0, 0)",
    );
    await oldDb.customStatement(
      'INSERT INTO photos (id, entry_id, file_name, label, position) '
      "VALUES ('p1', 'e1', 'a.jpg', 'রশিদ', 0)",
    );
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    final photo = await db.select(db.photos).getSingle();
    expect((photo.id, photo.fileName, photo.removedAt), ('p1', 'a.jpg', null));
    await (db.update(db.photos)..where((x) => x.id.equals('p1'))).write(
      PhotosCompanion(removedAt: Value(DateTime(2026, 11, 14))),
    );
    expect((await db.select(db.photos).getSingle()).removedAt, isNotNull);
    await db.close();
  });

  test('a fresh database is created directly at the newest schema', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('select 1').get();
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
    await db.close();
  });

  test(
    'the file opener copies a schema-1 file first, then upgrades it (UPD-4)',
    () async {
      final dir = Directory.systemTemp.createTempSync('atia_mig_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, dbFileName));
      final old = v1.DatabaseAtV1(NativeDatabase(file));
      await seedV1(old);
      await old.close();
      expect(readUserVersion(file), 1);

      final db = await openAppDatabase(dir);
      expect((await db.select(db.entries).getSingle()).receiptNo, 6685);
      expect(await db.select(db.driveLog).get(), isEmpty);
      await db.close();
      expect(readUserVersion(file), 3);

      final backups = Directory(
        p.join(dir.path, 'backups'),
      ).listSync().whereType<File>().toList();
      expect(backups.length, 1);
      expect(
        p.basename(backups.single.path),
        startsWith('pre-migration-v1-to-v3-'),
      );
      expect(readUserVersion(backups.single), 1);
      final copy = v1.DatabaseAtV1(NativeDatabase(backups.single));
      final rows = await copy.customSelect('SELECT amount FROM entries').get();
      expect(rows.single.read<int>('amount'), 5000); // old data intact
      await copy.close();
    },
  );

  test('UPD-5: if the upgrade breaks, the schema-1 copy is put back', () async {
    final dir = Directory.systemTemp.createTempSync('atia_mig_fail_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, dbFileName));
    final old = v1.DatabaseAtV1(NativeDatabase(file));
    await seedV1(old);
    await old.close();
    // Make the upgrade fail: a table with a clashing name already exists.
    final raw = NativeDatabase(file);
    await raw.ensureOpen(_NoUser());
    await raw.runCustom('CREATE TABLE drive_log (x INTEGER)');
    await raw.close();

    await expectLater(
      openAppDatabase(dir),
      throwsA(isA<MigrationFailedException>()),
    );
    expect(readUserVersion(file), 1); // still the old version
    final reopened = v1.DatabaseAtV1(NativeDatabase(file));
    final rows = await reopened
        .customSelect('SELECT amount FROM entries')
        .get();
    expect(rows.single.read<int>('amount'), 5000);
    await reopened.close();
  });
}

class _NoUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
