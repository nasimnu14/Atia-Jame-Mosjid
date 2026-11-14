import 'dart:convert';
import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../../data/photo_storage.dart';
import '../../data/repositories/settings_repository.dart';

/// What the desktop answers for one received entry.
class EntryReceipt {
  const EntryReceipt({
    required this.id,
    required this.duplicate,
    required this.alreadyHad,
    required this.photos,
  });
  final String id;

  /// A different entry already has this receipt number in the same series
  /// (SYN-8); the entry was still saved and is marked for an Admin to check.
  final bool duplicate;

  /// The desktop already had this very entry (it was sent before). It is not
  /// saved a second time (SYN-5).
  final bool alreadyHad;
  final int photos;

  Map<String, dynamic> toJson() => {
    'id': id,
    'saved': true,
    'duplicate': duplicate,
    'alreadyHad': alreadyHad,
    'photos': photos,
  };
}

class SyncRejectedException implements Exception {
  SyncRejectedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The desktop's side of the data: saving what a phone sends and giving the
/// phone the accounts. Separate from the network so it can be tested alone.
class SyncReceiver {
  SyncReceiver(this._db, this._photos, {this.now = DateTime.now});
  static final _plainName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$');
  final AppDatabase _db;
  final PhotoStorage _photos;
  final DateTime Function() now;

  /// Saves one entry with all its photos (SYN-4). Safe to repeat: an entry
  /// that is already here is not saved again (SYN-5, plan rule 2).
  Future<EntryReceipt> receiveEntry(Map<String, dynamic> json) async {
    final Entry sent;
    final List<({Photo row, Uint8List bytes})> photos;
    try {
      sent = Entry.fromJson(json['entry'] as Map<String, dynamic>);
      photos = [
        for (final p in (json['photos'] as List? ?? const []))
          (
            row: Photo.fromJson(p as Map<String, dynamic>),
            bytes: base64.decode(p['data'] as String),
          ),
      ];
    } catch (e) {
      throw SyncRejectedException('Unreadable entry');
    }
    if (sent.id.isEmpty ||
        sent.amount <= 0 ||
        sent.receiptNo < 1 ||
        // Photos taken off the entry stay as rows (rule 4) and do not count.
        photos.where((p) => p.row.removedAt == null).length > 10 ||
        photos.length > 200) {
      throw SyncRejectedException('Invalid entry');
    }
    // The id and the photo names become folder and file names on this
    // computer: only plain names are accepted (no '..', no separators).
    if (!_plainName.hasMatch(sent.id)) {
      throw SyncRejectedException('Invalid entry');
    }
    if (photos.any(
      (p) => p.row.entryId != sent.id || !_plainName.hasMatch(p.row.fileName),
    )) {
      throw SyncRejectedException('Invalid photo');
    }

    final existing = await (_db.select(
      _db.entries,
    )..where((e) => e.id.equals(sent.id))).getSingleOrNull();
    if (existing != null) {
      final n = await (_db.select(
        _db.photos,
      )..where((p) => p.entryId.equals(sent.id))).get();
      return EntryReceipt(
        id: sent.id,
        duplicate: existing.isDuplicate,
        alreadyHad: true,
        photos: n.length,
      );
    }

    // Photo files first. Nothing refers to them until the rows are saved, so a
    // failure here leaves no half entry.
    for (final p in photos) {
      await _photos.saveAs(sent.id, p.row.fileName, p.bytes);
    }
    final clash =
        await (_db.select(_db.entries)
              ..where(
                (e) =>
                    e.type.equalsValue(sent.type) &
                    e.receiptNo.equals(sent.receiptNo),
              )
              ..limit(1))
            .get();
    final duplicate = clash.isNotEmpty;
    await _db.transaction(() async {
      await _db
          .into(_db.entries)
          .insert(
            sent.copyWith(
              synced: true,
              syncedAt: Value(now()),
              isDuplicate: duplicate,
            ),
          );
      for (final p in photos) {
        await _db.into(_db.photos).insert(p.row);
      }
    });
    return EntryReceipt(
      id: sent.id,
      duplicate: duplicate,
      alreadyHad: false,
      photos: photos.length,
    );
  }

  /// SYN-10: the only things that go from the desktop to a phone: the user
  /// accounts (with protected passwords) and the approver list. Never entries
  /// (SYN-6).
  Future<Map<String, dynamic>> accountsPayload() async => {
    'users': [for (final u in await _db.select(_db.users).get()) u.toJson()],
    'approvers': [
      for (final a in await _db.select(_db.approvers).get()) a.toJson(),
    ],
  };

  /// SYN-9: one row per sync, updated as entries arrive, so a sync that is cut
  /// off still shows what it did receive.
  Future<void> recordSession({
    required String sessionId,
    required String phoneName,
    required DateTime startedAt,
    required int entries,
    required int photos,
    required int duplicates,
  }) async {
    await _db
        .into(_db.syncLog)
        .insertOnConflictUpdate(
          SyncLogCompanion.insert(
            id: sessionId,
            phoneName: phoneName,
            at: startedAt,
            entriesReceived: entries,
            photosReceived: photos,
            duplicates: Value(duplicates),
          ),
        );
    // The dashboard's "Sync" status: when a phone last synced with this computer.
    await SettingsRepository(_db).setDateTime(SettingKey.lastSyncAt, now());
  }

  Future<List<SyncLogData>> history({int limit = 10}) =>
      (_db.select(_db.syncLog)
            ..orderBy([(l) => OrderingTerm.desc(l.at)])
            ..limit(limit))
          .get();

  Stream<void> get changes =>
      _db.tableUpdates(TableUpdateQuery.onTable(_db.syncLog)).map((_) {});
}
