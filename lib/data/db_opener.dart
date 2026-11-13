import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;

import 'database.dart';

/// The installed app is older than the data on disk (user installed an older
/// version over a newer one). We refuse rather than risk damaging the data.
class DatabaseTooNewException implements Exception {
  DatabaseTooNewException(this.found, this.supported);
  final int found;
  final int supported;
  @override
  String toString() =>
      'Database version $found is newer than this app supports ($supported).';
}

/// The upgrade failed. The copy made before the upgrade has been put back, so
/// the previous version of the app still opens with all its data (UPD-5).
class MigrationFailedException implements Exception {
  MigrationFailedException(this.cause, {required this.restoredFrom});
  final Object cause;
  final File restoredFrom;
  @override
  String toString() => 'Database upgrade failed ($cause). '
      'Restored the copy ${restoredFrom.path}.';
}

const dbFileName = 'atia_accounts.db';

/// Opens the app database stored in [dataDir] (an app-data folder, never the
/// install folder: plan rule 1).
///
/// Plan rule 5: if the file is at an older schema version than this app, a
/// consistent copy is made first (UPD-4). If the upgrade fails the copy is put
/// back (UPD-5).
Future<AppDatabase> openAppDatabase(
  Directory dataDir, {
  DateTime Function() now = DateTime.now,
  AppDatabase Function(File file)? factory,
  int targetVersion = AppDatabase.currentSchemaVersion,
}) async {
  dataDir.createSync(recursive: true);
  final file = File(p.join(dataDir.path, dbFileName));
  final make = factory ?? (f) => AppDatabase(NativeDatabase.createInBackground(f));
  final target = targetVersion;

  File? backup;
  if (file.existsSync() && file.lengthSync() > 0) {
    final found = readUserVersion(file);
    if (found > target) throw DatabaseTooNewException(found, target);
    if (found > 0 && found < target) {
      backup = backupDatabaseFile(
        file,
        Directory(p.join(dataDir.path, 'backups')),
        label: 'pre-migration-v$found-to-v$target',
        now: now(),
      );
    }
  }

  final db = make(file);
  try {
    // Forces the lazy open, which runs onCreate / onUpgrade.
    await db.customSelect('SELECT 1').get();
  } catch (e) {
    await db.close();
    if (backup != null) {
      backup.copySync(file.path);
      throw MigrationFailedException(e, restoredFrom: backup);
    }
    rethrow;
  }
  return db;
}

/// `PRAGMA user_version` of a database file (0 for a new / empty file).
/// Drift stores its schema version there.
int readUserVersion(File file) {
  final db = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
  try {
    return db.select('PRAGMA user_version').first.values.first as int;
  } finally {
    db.close();
  }
}

/// Makes a consistent copy of a database file with `VACUUM INTO` (safe even if
/// the app is writing). Returns the copy.
File backupDatabaseFile(
  File source,
  Directory targetDir, {
  required String label,
  required DateTime now,
}) {
  targetDir.createSync(recursive: true);
  final stamp = now
      .toIso8601String()
      .replaceAll(RegExp(r'[^0-9T]'), '')
      .replaceAll('T', '-');
  final target = File(p.join(targetDir.path, '$label-$stamp.db'));
  if (target.existsSync()) target.deleteSync();
  final db = sql.sqlite3.open(source.path);
  try {
    db.execute('VACUUM INTO ?', [target.path]);
  } finally {
    db.close();
  }
  return target;
}
