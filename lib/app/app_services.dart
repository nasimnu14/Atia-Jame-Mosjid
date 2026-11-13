import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../data/db_opener.dart';
import '../data/photo_storage.dart';
import '../data/repositories/settings_repository.dart';
import '../features/entries/entry_service.dart';
import '../features/entries/photo_picker.dart';
import '../features/entries/photo_shrinker.dart';
import '../features/reports/balance_service.dart';
import '../features/google_drive/backup_service.dart';
import '../features/google_drive/drive_client.dart';
import '../features/google_drive/drive_scheduler.dart';
import '../features/google_drive/drive_service.dart';
import '../features/google_drive/excel_upload_service.dart';
import '../features/google_drive/google_drive_auth.dart';
import '../features/google_drive/restore_service.dart';
import '../features/reports/report_pdf_service.dart';
import '../features/settings/settings_service.dart';
import '../features/users/user_service.dart';
import '../shared/file_saver.dart';
import '../shared/password_hasher.dart';

/// Everything the screens need, built once at start-up.
class AppServices {
  AppServices._({
    required this.dataDir,
    required this.db,
    required this.settingsRepo,
    required this.users,
    required this.settings,
    required this.entries,
    required this.balance,
    required this.photos,
    required this.deviceId,
    required this.now,
    required this.photoPicker,
    required this.photoShrinker,
    required this.fileSaver,
    required this.reports,
    required this.drive,
    required this.backup,
    required this.excel,
    required this.restore,
    required this.scheduler,
  });

  /// App-data folder (outside the install folder, plan rule 1).
  final Directory dataDir;
  final AppDatabase db;
  final SettingsRepository settingsRepo;
  final UserService users;
  final SettingsService settings;
  final EntryService entries;
  final BalanceService balance;
  final PhotoStorage photos;
  final String deviceId;

  /// The clock; tests replace it.
  final DateTime Function() now;
  final PhotoPicker photoPicker;
  final PhotoShrinker photoShrinker;
  final FileSaver fileSaver;
  final ReportPdfService reports;
  final DriveService drive;
  final BackupService backup;
  final ExcelUploadService excel;
  final RestoreService restore;
  final DriveScheduler scheduler;

  /// Opens the database (copying it first if an upgrade is needed) and wires
  /// the services. [hasher] is only replaced in tests.
  static Future<AppServices> open(
    Directory dataDir, {
    PasswordHasher hasher = const PasswordHasher(),
    FileSaver fileSaver = const PlatformFileSaver(),
    DriveAuth? driveAuth,
    PhotoPicker photoPicker = const PlatformPhotoPicker(),
  }) async {
    final db = await openAppDatabase(dataDir);
    return fromDatabase(
      db,
      dataDir,
      hasher: hasher,
      fileSaver: fileSaver,
      driveAuth: driveAuth,
      photoPicker: photoPicker,
    );
  }

  static Future<AppServices> fromDatabase(
    AppDatabase db,
    Directory dataDir, {
    PasswordHasher hasher = const PasswordHasher(),
    DateTime Function() now = DateTime.now,
    PhotoPicker photoPicker = const PlatformPhotoPicker(),
    PhotoShrinker photoShrinker = const PhotoShrinker(),
    FileSaver fileSaver = const PlatformFileSaver(),
    DriveAuth? driveAuth,
  }) async {
    final repo = SettingsRepository(db);
    var deviceId = await repo.get(SettingKey.deviceId);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await repo.set(SettingKey.deviceId, deviceId);
    }
    final photos = PhotoStorage(Directory(p.join(dataDir.path, 'photos')));
    final settings = SettingsService(db, repo);
    final users = UserService(db, hasher: hasher, now: now);
    final entries = EntryService(db, photos, deviceId, now: now);
    final drive = DriveService(
      db,
      repo,
      driveAuth ?? GoogleDriveAuth(),
      now: now,
    );
    final backup = BackupService(
      db: db,
      settings: repo,
      drive: drive,
      dataDir: dataDir,
      now: now,
    );
    final excel = ExcelUploadService(
      drive: drive,
      entries: entries,
      users: users,
      settings: repo,
      now: now,
    );
    return AppServices._(
      dataDir: dataDir,
      db: db,
      settingsRepo: repo,
      users: users,
      settings: settings,
      entries: entries,
      balance: BalanceService(db, settings),
      photos: photos,
      deviceId: deviceId,
      now: now,
      photoPicker: photoPicker,
      photoShrinker: photoShrinker,
      fileSaver: fileSaver,
      reports: ReportPdfService(entries, users, now),
      drive: drive,
      backup: backup,
      excel: excel,
      restore: RestoreService(drive: drive, backup: backup, dataDir: dataDir),
      scheduler: DriveScheduler(
        drive: drive,
        backup: backup,
        excel: excel,
        now: now,
      ),
    );
  }

  Future<void> close() async {
    scheduler.stop();
    await db.close();
  }
}
