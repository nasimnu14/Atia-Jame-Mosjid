import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/database.dart';
import '../../data/db_opener.dart';
import '../../data/photo_storage.dart';
import '../../data/repositories/settings_repository.dart';
import 'drive_client.dart';
import 'drive_service.dart';

enum BackupOutcome {
  done,
  notConnected,
  nothingToBackUp,
  failed,
  alreadyRunning,
}

class BackupResult {
  const BackupResult(
    this.outcome, {
    this.error,
    this.offline = false,
    this.newPhotos = 0,
  });
  final BackupOutcome outcome;
  final String? error;
  final bool offline;
  final int newPhotos;
  bool get ok => outcome == BackupOutcome.done;
}

/// Backs up everything to Google Drive: the database (entries, users,
/// settings) and the photos (BAK-2). See docs/atia-jame-masjid-development-plan.md,
/// Phase 4:
///
/// - Every backup uploads a snapshot of the database.
/// - A photo file is uploaded once and never deleted from Drive, so any backup
///   from the last year can be restored with all its photos.
/// - Backups older than one year are deleted automatically (BAK-7); the newest
///   is always kept.
class BackupService {
  BackupService({
    required this.db,
    required this.settings,
    required this.drive,
    required this.dataDir,
    this.now = DateTime.now,
  });

  final AppDatabase db;
  final SettingsRepository settings;
  final DriveService drive;
  final Directory dataDir;
  final DateTime Function() now;
  bool _running = false;

  /// BAK-2: a backup every 4 hours.
  static const interval = Duration(hours: 4);

  /// BAK-7: backups are kept for one year.
  static const retention = Duration(days: 365);

  static String photoFileName(String entryId, String fileName) =>
      '${entryId}__$fileName';

  static String backupFileName(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'backup-${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}.db.gz';
  }

  Future<DateTime?> lastSuccess() =>
      settings.getDateTime(SettingKey.lastBackupAt);
  Future<String?> lastError() async {
    final e = await settings.get(SettingKey.lastBackupError);
    return (e == null || e.isEmpty) ? null : e;
  }

  /// BAK-2 / BAK-4: a backup is due when none has succeeded yet, or the last
  /// success is 4 hours old or more (which also covers the app having been
  /// closed: BAK-4).
  Future<bool> isDue() async {
    final last = await lastSuccess();
    return last == null || now().difference(last) >= interval;
  }

  /// When the next automatic backup will happen.
  Future<DateTime?> nextDue() async {
    final last = await lastSuccess();
    return last?.add(interval);
  }

  /// False on a brand-new installation with no accounts yet. An empty database
  /// is never backed up: it would become the newest backup and could be
  /// restored over real data by mistake.
  Future<bool> hasData() async =>
      (await (db.select(db.users)..limit(1)).get()).isNotEmpty;

  Future<BackupResult> runBackup({String reason = 'scheduled'}) async {
    if (_running) return const BackupResult(BackupOutcome.alreadyRunning);
    _running = true;
    try {
      if (!await hasData()) {
        return const BackupResult(BackupOutcome.nothingToBackUp);
      }
      final DriveClient? client;
      try {
        client = await drive.client();
      } on DriveException catch (e) {
        return _failedOnce(reason, e.message, offline: e.offline);
      }
      if (client == null) {
        // An account is saved but its sign-in no longer works (access taken
        // away, token expired): say so instead of stopping silently (BAK-5).
        if (await drive.accountEmail() != null) {
          return _failedOnce(
            reason,
            'Google sign-in expired. Connect the account again.',
          );
        }
        return const BackupResult(BackupOutcome.notConnected);
      }
      return await _backup(client, reason);
    } finally {
      _running = false;
    }
  }

  /// A failure before the backup could start. Written once: the scheduler
  /// tries again every few minutes and must not fill (and push out) the log
  /// with the same line.
  Future<BackupResult> _failedOnce(
    String reason,
    String message, {
    bool offline = false,
  }) async {
    if (await settings.get(SettingKey.lastBackupError) != message) {
      await settings.set(SettingKey.lastBackupError, message);
      await drive.log('backup', reason, ok: false, error: message);
    }
    return BackupResult(BackupOutcome.failed, error: message, offline: offline);
  }

  Future<BackupResult> _backup(DriveClient client, String reason) async {
    final tmp = Directory(p.join(dataDir.path, 'tmp'))
      ..createSync(recursive: true);
    final snapshot = File(p.join(tmp.path, 'snapshot.db'));
    try {
      if (snapshot.existsSync()) snapshot.deleteSync();
      // A consistent copy even while the app is writing.
      await db.customStatement('VACUUM INTO ?', [snapshot.path]);
      final gz = Uint8List.fromList(gzip.encode(await snapshot.readAsBytes()));

      final backupsFolder = await drive.folder(client, DriveFolders.backups);
      final photosFolder = await drive.folder(client, DriveFolders.photos);

      // Photos first: a backup must never mention a photo that is not in Drive.
      final newPhotos = await _uploadNewPhotos(client, photosFolder);
      final at = now();
      await client.upload(
        folderId: backupsFolder,
        name: backupFileName(at),
        bytes: gz,
        mimeType: 'application/gzip',
      );
      await _deleteOldBackups(client, backupsFolder);

      await settings.setDateTime(SettingKey.lastBackupAt, at);
      await settings.set(SettingKey.lastBackupError, '');
      await drive.log('backup', '$reason · $newPhotos', ok: true);
      return BackupResult(BackupOutcome.done, newPhotos: newPhotos);
    } on DriveException catch (e) {
      return _failedOnce(reason, e.message, offline: e.offline);
    } catch (e) {
      return _failedOnce(reason, '$e');
    } finally {
      if (snapshot.existsSync()) snapshot.deleteSync();
    }
  }

  /// Uploads every photo this Google account does not have yet (once only).
  Future<int> _uploadNewPhotos(DriveClient client, String folderId) async {
    final account = client.accountEmail;
    final rows = await db.select(db.photos).get();
    final done = await (db.select(
      db.driveUploadedPhotos,
    )..where((u) => u.account.equals(account))).get();
    final have = {for (final u in done) '${u.entryId}/${u.fileName}'};
    final photos = PhotoStorage(Directory(p.join(dataDir.path, 'photos')));
    var count = 0;
    for (final ph in rows) {
      if (have.contains('${ph.entryId}/${ph.fileName}')) continue;
      final bytes = await photos.read(ph.entryId, ph.fileName);
      if (bytes == null) continue; // the file is missing on this computer
      final f = await client.upload(
        folderId: folderId,
        name: photoFileName(ph.entryId, ph.fileName),
        bytes: bytes,
        mimeType: 'image/jpeg',
      );
      await db
          .into(db.driveUploadedPhotos)
          .insertOnConflictUpdate(
            DriveUploadedPhotosCompanion.insert(
              account: account,
              entryId: ph.entryId,
              fileName: ph.fileName,
              driveFileId: f.id,
              uploadedAt: now(),
            ),
          );
      count++;
    }
    return count;
  }

  /// BAK-7: delete backups older than one year, but never the newest one.
  Future<void> _deleteOldBackups(DriveClient client, String folderId) async {
    final all = await client.list(folderId); // newest first
    final cutoff = now().subtract(retention);
    for (final f in all.skip(1)) {
      if (f.createdTime.isBefore(cutoff)) await client.delete(f.id);
    }
  }

  /// The backups in Drive, newest first (for choosing one to restore).
  Future<List<DriveFile>> listBackups() async {
    final client = await drive.client();
    if (client == null) return const [];
    final folder = await drive.folder(client, DriveFolders.backups);
    return client.list(folder);
  }

  /// Makes a consistent copy of the live database file (used before a restore).
  File snapshotLiveFile(String label) => backupDatabaseFile(
    File(p.join(dataDir.path, dbFileName)),
    Directory(p.join(dataDir.path, 'backups')),
    label: label,
    now: now(),
  );
}
