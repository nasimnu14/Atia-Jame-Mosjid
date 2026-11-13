import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../data/database.dart';
import '../../data/db_opener.dart';
import '../../data/photo_storage.dart';
import 'backup_service.dart';
import 'drive_client.dart';
import 'drive_service.dart';

enum RestoreProblem { notConnected, damaged, tooNew, notABackup }

class RestoreException implements Exception {
  RestoreException(this.problem, [this.detail]);
  final RestoreProblem problem;
  final String? detail;
  @override
  String toString() =>
      'RestoreException(${problem.name}${detail == null ? '' : ': $detail'})';
}

class RestoreOutcome {
  const RestoreOutcome({
    required this.photosRestored,
    required this.photosMissing,
  });
  final int photosRestored;

  /// Photos the entries mention that Drive does not have (should be 0).
  final int photosMissing;
}

/// Brings all data back from a Google Drive backup (BAK-6, USR-3). Only the
/// Super Admin may start this from the Backup screen; the first-launch screen
/// has no users yet.
///
/// Order of work, so a failure never leaves the computer without data:
/// download and check the backup first; copy the current database aside; only
/// then replace it. The app opens the new file afterwards (a backup from an
/// older version is upgraded by the normal upgrade path, with its own copy).
class RestoreService {
  RestoreService({
    required this.drive,
    required this.backup,
    required this.dataDir,
  });
  final DriveService drive;
  final BackupService backup;
  final Directory dataDir;

  Future<List<DriveFile>> listBackups() => backup.listBackups();

  /// Checks that [file] is a healthy database this app version can open.
  static void validate(File file) {
    sql.Database? db;
    try {
      db = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
      final check = db.select('PRAGMA integrity_check').first.values.first;
      if (check != 'ok')
        throw RestoreException(RestoreProblem.damaged, '$check');
      final version =
          db.select('PRAGMA user_version').first.values.first as int;
      if (version > AppDatabase.currentSchemaVersion) {
        throw RestoreException(RestoreProblem.tooNew, 'v$version');
      }
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((r) => r['name'] as String)
          .toSet();
      if (version < 1 ||
          !{'users', 'entries', 'photos', 'settings'}.every(tables.contains)) {
        throw RestoreException(RestoreProblem.notABackup);
      }
    } on sql.SqliteException catch (e) {
      throw RestoreException(RestoreProblem.damaged, e.message);
    } finally {
      db?.close();
    }
  }

  /// Restores [file]. [closeDatabase] must close the app's open database; the
  /// caller opens it again afterwards.
  Future<RestoreOutcome> restore(
    DriveFile file, {
    required Future<void> Function() closeDatabase,
    bool hasLiveData = true,
    DateTime Function() now = DateTime.now,
  }) async {
    final client = await drive.client();
    if (client == null) throw RestoreException(RestoreProblem.notConnected);

    // 1. Download and check.
    final raw = Uint8List.fromList(gzip.decode(await client.download(file.id)));
    final tmp = Directory(p.join(dataDir.path, 'tmp'))
      ..createSync(recursive: true);
    final incoming = File(p.join(tmp.path, 'incoming.db'));
    await incoming.writeAsBytes(raw, flush: true);
    try {
      validate(incoming);
    } catch (_) {
      incoming.deleteSync();
      rethrow;
    }

    // 2. Keep the current data aside.
    final live = File(p.join(dataDir.path, dbFileName));
    if (hasLiveData && live.existsSync())
      backup.snapshotLiveFile('pre-restore');

    // 3. Replace.
    await closeDatabase();
    for (final ext in ['-wal', '-shm', '-journal']) {
      final side = File('${live.path}$ext');
      if (side.existsSync()) side.deleteSync();
    }
    incoming.copySync('${live.path}.new');
    File('${live.path}.new').renameSync(live.path);
    incoming.deleteSync();

    // 4. Photos the restored entries mention but this computer lacks.
    return _restorePhotos(client, live);
  }

  Future<RestoreOutcome> _restorePhotos(DriveClient client, File dbFile) async {
    final db = sql.sqlite3.open(dbFile.path, mode: sql.OpenMode.readOnly);
    final List<({String entryId, String fileName})> wanted;
    try {
      wanted = [
        for (final r in db.select('SELECT entry_id, file_name FROM photos'))
          (
            entryId: r['entry_id'] as String,
            fileName: r['file_name'] as String,
          ),
      ];
    } finally {
      db.close();
    }
    final storage = PhotoStorage(Directory(p.join(dataDir.path, 'photos')));
    final missing = [
      for (final w in wanted)
        if (!storage.exists(w.entryId, w.fileName)) w,
    ];
    if (missing.isEmpty)
      return const RestoreOutcome(photosRestored: 0, photosMissing: 0);
    final folder = await drive.folder(client, DriveFolders.photos);
    final inDrive = {for (final f in await client.list(folder)) f.name: f};
    var restored = 0, lost = 0;
    for (final w in missing) {
      final f = inDrive[BackupService.photoFileName(w.entryId, w.fileName)];
      if (f == null) {
        lost++;
        continue;
      }
      await storage.saveAs(w.entryId, w.fileName, await client.download(f.id));
      restored++;
    }
    return RestoreOutcome(photosRestored: restored, photosMissing: lost);
  }
}
