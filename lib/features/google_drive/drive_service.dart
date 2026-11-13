import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../data/repositories/settings_repository.dart';
import 'drive_client.dart';

/// Names of the folders the app keeps in Google Drive.
abstract final class DriveFolders {
  static const root = 'Atia Jame Masjid Accounts';
  static const backups = 'Backups';
  static const photos = 'Photos';
  static const excel = 'Excel';
}

/// The connection to Google Drive and a log of what was done with it
/// (BAK-1, BAK-5, XLS-8).
class DriveService {
  DriveService(this._db, this._settings, this.auth, {this.now = DateTime.now});
  final AppDatabase _db;
  final SettingsRepository _settings;
  final DriveAuth auth;
  final DateTime Function() now;
  DriveClient? _client;

  /// The connected account, or null.
  Future<String?> accountEmail() => _settings.get(SettingKey.googleAccount);

  /// The ready client: restored silently from the saved sign-in. Null when no
  /// account is connected (or the sign-in was revoked).
  Future<DriveClient?> client() async {
    if (_client != null) return _client;
    if ((await accountEmail()) == null) return null;
    _client = await auth.restore();
    return _client;
  }

  /// BAK-1 / BAK-8: sign in. Returns the account and whether it is a different
  /// account from the one before (a full backup must then go there at once).
  Future<({String email, bool changed})> connect() async {
    final previous = await accountEmail();
    final c = await auth.connect();
    _client = c;
    await _settings.set(SettingKey.googleAccount, c.accountEmail);
    return (email: c.accountEmail, changed: previous != c.accountEmail);
  }

  Future<void> disconnect() async {
    await auth.disconnect();
    _client = null;
    await _settings.remove(SettingKey.googleAccount);
  }

  /// A folder inside the app's root folder, created on first use.
  Future<String> folder(DriveClient c, String name) async {
    final root = await c.ensureFolder(DriveFolders.root);
    return c.ensureFolder(name, parentId: root);
  }

  // ------------------------------------------------------------------ log

  Future<void> log(
    String kind,
    String description, {
    required bool ok,
    String? error,
  }) async {
    await _db
        .into(_db.driveLog)
        .insert(
          DriveLogCompanion.insert(
            id: const Uuid().v4(),
            at: now(),
            kind: kind,
            description: description,
            ok: ok,
            error: Value(error),
          ),
        );
    // Keep the log short.
    await _db.customStatement(
      'DELETE FROM drive_log WHERE id NOT IN (SELECT id FROM drive_log ORDER BY at DESC LIMIT 200)',
    );
  }

  Future<List<DriveLogData>> recentLog(List<String> kinds, {int limit = 10}) =>
      (_db.select(_db.driveLog)
            ..where((l) => l.kind.isIn(kinds))
            ..orderBy([(l) => OrderingTerm.desc(l.at)])
            ..limit(limit))
          .get();

  Stream<void> get logChanges =>
      _db.tableUpdates(TableUpdateQuery.onTable(_db.driveLog)).map((_) {});
}
