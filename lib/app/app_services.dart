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
import '../features/sync/sync_client.dart';
import '../features/sync/local_address.dart';
import '../features/sync/sync_receiver.dart';
import '../features/sync/sync_server.dart';
import '../features/updates/update_installer.dart';
import '../features/updates/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    required this.updates,
    required this.updateInstaller,
    required this.isPhone,
    required this.syncReceiver,
    required this.syncClient,
    required this.createSyncHost,
    required this.useCameraScanner,
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
  final UpdateService updates;
  final UpdateInstaller updateInstaller;

  /// True on the Android app (phone), false on the desktop.
  final bool isPhone;
  final SyncReceiver syncReceiver;
  final SyncClient syncClient;

  /// Makes the desktop's sync server (started and stopped by the Sync screen).
  final Future<SyncHost> Function() createSyncHost;

  /// Whether the phone scans the QR code with its camera (tests turn it off and
  /// type the code instead).
  final bool useCameraScanner;

  /// Opens the database (copying it first if an upgrade is needed) and wires
  /// the services. [hasher] is only replaced in tests.
  static Future<AppServices> open(
    Directory dataDir, {
    PasswordHasher hasher = const PasswordHasher(),
    FileSaver fileSaver = const PlatformFileSaver(),
    DriveAuth? driveAuth,
    PhotoPicker photoPicker = const PlatformPhotoPicker(),
    UpdateService Function(SettingsRepository settings)? updatesBuilder,
    UpdateInstaller? updateInstaller,
    bool? isPhone,
  }) async {
    final db = await openAppDatabase(dataDir);
    return fromDatabase(
      db,
      dataDir,
      hasher: hasher,
      fileSaver: fileSaver,
      driveAuth: driveAuth,
      photoPicker: photoPicker,
      updatesBuilder: updatesBuilder,
      updateInstaller: updateInstaller,
      isPhone: isPhone,
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
    UpdateService Function(SettingsRepository settings)? updatesBuilder,
    UpdateInstaller? updateInstaller,
    bool? isPhone,
    bool useCameraScanner = true,
    Future<SyncHost> Function(SyncReceiver receiver)? syncHostFactory,
    SyncClient Function(
      AppDatabase db,
      PhotoStorage photos,
      SettingsRepository settings,
    )?
    syncClientBuilder,
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
    final phone = isPhone ?? Platform.isAndroid;
    final balance = BalanceService(db, settings, isPhone: phone);
    final receiver = SyncReceiver(db, photos, now: now);
    final entries = EntryService(
      db,
      photos,
      deviceId,
      now: now,
      isPhone: phone,
    );
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
      balance: balance,
      photos: photos,
      deviceId: deviceId,
      now: now,
      photoPicker: photoPicker,
      photoShrinker: photoShrinker,
      fileSaver: fileSaver,
      reports: ReportPdfService(entries, users, now, balance),
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
      updates:
          updatesBuilder?.call(repo) ??
          UpdateService(
            settings: repo,
            currentVersion: _installedVersion,
            now: now,
          ),
      updateInstaller: updateInstaller ?? PlatformUpdateInstaller(),
      isPhone: phone,
      useCameraScanner: useCameraScanner,
      syncReceiver: receiver,
      syncClient:
          syncClientBuilder?.call(db, photos, repo) ??
          SyncClient(db: db, photos: photos, settings: repo, now: now),
      createSyncHost: () =>
          (syncHostFactory ?? _defaultSyncHost(now))(receiver),
    );
  }

  static Future<SyncHost> Function(SyncReceiver) _defaultSyncHost(
    DateTime Function() now,
  ) => (receiver) async {
    final host = await bestLocalAddress();
    if (host == null) {
      throw const SocketException('No network');
    }
    return SyncServer(
      receiver: receiver,
      desktopName: Platform.localHostname,
      hostAddress: host,
      now: now,
    );
  };

  /// The installed version. If it cannot be read (it always can on a real
  /// device) this answers 0.0.0 rather than failing a screen.
  static Future<String> _installedVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return '0.0.0';
    }
  }

  Future<void> close() async {
    scheduler.stop();
    await db.close();
  }
}
