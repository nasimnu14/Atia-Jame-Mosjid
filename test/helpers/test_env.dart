import 'dart:io';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/db_opener.dart';
import 'package:atia_masjid_accounts/features/google_drive/backup_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_scheduler.dart';
import 'package:atia_masjid_accounts/features/google_drive/drive_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/excel_upload_service.dart';
import 'package:atia_masjid_accounts/features/google_drive/restore_service.dart';
import 'package:path/path.dart' as p;
import 'fake_drive.dart';
import 'package:atia_masjid_accounts/data/photo_storage.dart';
import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/features/reports/balance_service.dart';
import 'package:atia_masjid_accounts/features/settings/settings_service.dart';
import 'package:atia_masjid_accounts/features/users/user_service.dart';
import 'package:atia_masjid_accounts/shared/password_hasher.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory database with every service wired up, a fixed clock, and a
/// temp folder for photos. Passwords hash with a low cost to keep tests fast.
class TestEnv {
  TestEnv._(this.db, this.photoDir, this.dataDir);
  final AppDatabase db;
  final Directory photoDir;

  /// The app-data folder (holds the database file when [create] was called
  /// with `onDisk: true`).
  final Directory dataDir;
  DateTime clock = DateTime(2026, 11, 13, 10, 0);

  late final UserService users = UserService(
    db,
    hasher: const PasswordHasher(logRounds: 4),
    now: () => clock,
  );
  late final SettingsRepository settingsRepo = SettingsRepository(db);
  late final SettingsService settings = SettingsService(db, settingsRepo);
  late final EntryService entries = EntryService(
    db,
    PhotoStorage(photoDir),
    'desktop-1',
    now: () => clock,
  );
  late final BalanceService balance = BalanceService(db, settings);

  // Google Drive pieces, wired to a fake Drive that can be shared between
  // two "computers" (pass the same [FakeDrive] to both).
  late FakeDrive fakeDrive;
  late FakeDriveAuth auth;
  late final DriveService driveService = DriveService(
    db,
    settingsRepo,
    auth,
    now: () => clock,
  );
  late final BackupService backup = BackupService(
    db: db,
    settings: settingsRepo,
    drive: driveService,
    dataDir: dataDir,
    now: () => clock,
  );
  late final ExcelUploadService excel = ExcelUploadService(
    drive: driveService,
    entries: entries,
    users: users,
    settings: settingsRepo,
    now: () => clock,
  );
  late final RestoreService restore = RestoreService(
    drive: driveService,
    backup: backup,
    dataDir: dataDir,
  );
  late final DriveScheduler scheduler = DriveScheduler(
    drive: driveService,
    backup: backup,
    excel: excel,
    now: () => clock,
  );

  late User superAdmin;
  late User admin;
  late User user;

  /// [onDisk] keeps the database in a real file (needed to test restore).
  /// [drive] is the shared fake Google Drive; [connected] signs in to it.
  static Future<TestEnv> create({
    bool onDisk = false,
    bool seedUsers = true,
    FakeDrive? drive,
    bool connected = false,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = Directory.systemTemp.createTempSync('atia_test_');
    final dataDir = Directory(p.join(dir.path, 'data'))..createSync();
    final db = onDisk
        ? await openAppDatabase(dataDir)
        : AppDatabase(NativeDatabase.memory());
    final photoDir = Directory(
      onDisk ? p.join(dataDir.path, 'photos') : dir.path,
    );
    final env = TestEnv._(db, photoDir, dataDir);
    env.fakeDrive = drive ?? FakeDrive();
    env.fakeDrive.clock = () => env.clock;
    env.auth = FakeDriveAuth(env.fakeDrive);
    addTearDown(() async {
      await env.db.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    if (connected) await env.driveService.connect();
    if (!seedUsers) return env;
    env.superAdmin = await env.users.createSuperAdmin(
      name: 'Super',
      username: 'super',
      password: 'secret1',
    );
    env.admin = await env.users.addUser(
      env.superAdmin,
      name: 'Admin',
      username: 'admin',
      password: 'secret2',
      role: Role.admin,
    );
    env.user = await env.users.addUser(
      env.superAdmin,
      name: 'User',
      username: 'user',
      password: 'secret3',
      role: Role.user,
    );
    await env.settings.addApprover(env.admin, 'সভাপতি');
    await env.settings.addApprover(env.admin, 'সেক্রেটারী');
    return env;
  }

  Future<EntryWithPhotos> addIncome({
    int receipt = 1,
    int amount = 1000,
    String name = 'দাতা',
    DateTime? date,
    User? by,
    List<PhotoDraft> photos = const [],
  }) => entries.create(
    by ?? user,
    EntryDraft(
      type: EntryType.income,
      receiptNo: receipt,
      date: date ?? DateTime(2026, 11, 13),
      name: name,
      amount: amount,
      photos: photos,
    ),
  );

  Future<EntryWithPhotos> addExpense({
    int receipt = 1,
    int amount = 500,
    String payee = 'দোকান',
    String purpose = 'বালু',
    String approver = 'সভাপতি',
    DateTime? date,
    User? by,
  }) => entries.create(
    by ?? user,
    EntryDraft(
      type: EntryType.expense,
      receiptNo: receipt,
      date: date ?? DateTime(2026, 11, 13),
      name: payee,
      purpose: purpose,
      approverName: approver,
      amount: amount,
    ),
  );

  static PhotoDraft photo([String label = 'রশিদ']) =>
      PhotoDraft(bytes: Uint8List.fromList([1, 2, 3]), label: label);
}
