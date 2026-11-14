import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../data/database.dart';
import '../../data/photo_storage.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/tables.dart';
import 'sync_crypto.dart';
import 'sync_offer.dart';

class SyncReport {
  int entriesSent = 0;
  int photosSent = 0;
  int income = 0;
  int expense = 0;
  int duplicates = 0;

  /// Entries that were still waiting when the sync ended.
  int remaining = 0;
  bool accountsUpdated = false;
}

enum SyncFailure { offline, rejected, unauthorised, other }

class SyncException implements Exception {
  SyncException(this.failure, this.message, this.partial);
  final SyncFailure failure;
  final String message;

  /// What had been done before it stopped: those entries are safely on the
  /// desktop and marked synced; the rest are sent next time (SYN-5).
  final SyncReport partial;
  @override
  String toString() => message;
}

/// The phone's side: after scanning the desktop's QR code it sends the entries
/// that are not synced yet (with all their photos), then receives the user
/// accounts and approver list (SYN-4, SYN-5, SYN-10).
class SyncClient {
  SyncClient({
    required this.db,
    required this.photos,
    required this.settings,
    http.Client? client,
    this.now = DateTime.now,
    this.timeout = const Duration(seconds: 60),
  }) : _http = client ?? http.Client();

  final AppDatabase db;
  final PhotoStorage photos;
  final SettingsRepository settings;
  final http.Client _http;
  final DateTime Function() now;
  final Duration timeout;

  /// How many entries wait to be sent.
  Future<int> pendingCount() async {
    final cnt = db.entries.id.count();
    final q = db.selectOnly(db.entries)
      ..addColumns([cnt])
      ..where(db.entries.synced.equals(false));
    return (await q.getSingle()).read(cnt) ?? 0;
  }

  Future<DateTime?> lastSync() => settings.getDateTime(SettingKey.lastSyncAt);

  /// Runs one sync. Throws [SyncException] if it could not finish; entries
  /// already confirmed by the desktop stay synced.
  Future<SyncReport> sync(
    SyncOffer offer, {
    required String phoneName,
    void Function(SyncReport progress)? onProgress,
  }) async {
    final report = SyncReport();
    final crypto = SyncCrypto(offer.key);
    final base = Uri(scheme: 'http', host: offer.host, port: offer.port);
    String? session;

    Future<Map<String, dynamic>> call(
      String path,
      Map<String, dynamic> body,
    ) async {
      try {
        final res = await _http
            .post(
              base.replace(path: '/$path'),
              headers: {'X-Session': ?session},
              body: await crypto.sealJson(body, aad: path),
            )
            .timeout(timeout);
        if (res.statusCode == 401) {
          throw SyncException(
            SyncFailure.unauthorised,
            'The code was not accepted. Show a new code on the computer.',
            report,
          );
        }
        if (res.statusCode != 200) {
          throw SyncException(
            SyncFailure.rejected,
            'The computer refused (${res.statusCode}) ${res.body}',
            report,
          );
        }
        return await crypto.openJson(res.bodyBytes, aad: 'res:$path');
      } on SyncException {
        rethrow;
      } on SyncAuthException {
        throw SyncException(
          SyncFailure.other,
          'Damaged reply from the computer',
          report,
        );
      } on SocketException {
        throw SyncException(
          SyncFailure.offline,
          'Cannot reach the computer',
          report,
        );
      } on http.ClientException {
        throw SyncException(
          SyncFailure.offline,
          'Cannot reach the computer',
          report,
        );
      } on TimeoutException {
        throw SyncException(
          SyncFailure.offline,
          'The computer did not answer',
          report,
        );
      }
    }

    final deviceId = await settings.get(SettingKey.deviceId) ?? '';
    final hello = await call('hello', {
      'token': offer.token,
      'phoneName': phoneName,
      'phoneId': deviceId,
    });
    session = hello['session'] as String;

    // Accounts first: a new phone needs them before anyone can sign in (MOB-5).
    await _applyAccounts(await call('accounts', {}));
    report.accountsUpdated = true;

    // Oldest first. Each entry goes with all its photos; it is marked synced
    // only after the desktop says it has saved it (SYN-5).
    final pending =
        await (db.select(db.entries)
              ..where((e) => e.synced.equals(false))
              ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
            .get();
    report.remaining = pending.length;
    for (final queued in pending) {
      // The entry as it is now: it may have been edited or cancelled since the
      // list was read, and the desktop must get that version.
      final e =
          await (db.select(db.entries)
                ..where((x) => x.id.equals(queued.id) & x.synced.equals(false)))
              .getSingleOrNull();
      if (e == null) {
        report.remaining--;
        continue;
      }
      final rows =
          await (db.select(db.photos)
                ..where((p) => p.entryId.equals(e.id))
                ..orderBy([(p) => OrderingTerm.asc(p.position)]))
              .get();
      final withData = <Map<String, dynamic>>[];
      for (final p in rows) {
        final Uint8List? bytes = await photos.read(e.id, p.fileName);
        if (bytes == null) {
          continue; // the file is gone from this phone: cannot be sent
        }
        withData.add({...p.toJson(), 'data': base64.encode(bytes)});
      }
      final reply = await call('entry', {
        'entry': e.toJson(),
        'photos': withData,
      });
      if (reply['saved'] != true) {
        throw SyncException(
          SyncFailure.other,
          'The computer did not confirm the entry',
          report,
        );
      }
      // Marked synced only if it is still the version that was sent; if it
      // changed while the desktop was answering, it stays waiting.
      final marked =
          await (db.update(db.entries)..where(
                (x) =>
                    x.id.equals(e.id) &
                    x.status.equalsValue(e.status) &
                    (e.editedAt == null
                        ? x.editedAt.isNull()
                        : x.editedAt.equals(e.editedAt!)),
              ))
              .write(
                EntriesCompanion(
                  synced: const Value(true),
                  syncedAt: Value(now()),
                ),
              );
      if (marked == 0) {
        continue; // still waiting: it changed while the desktop was answering
      }
      report.entriesSent++;
      report.photosSent += withData.length;
      report.remaining--;
      e.type == EntryType.income ? report.income++ : report.expense++;
      if (reply['duplicate'] == true) {
        report.duplicates++;
      }
      onProgress?.call(report);
    }

    await call('done', {'entries': report.entriesSent});
    await settings.setDateTime(SettingKey.lastSyncAt, now());
    return report;
  }

  /// SYN-10: new users, password changes and disabled users reach the phone.
  /// Users are never deleted, so this only adds and updates.
  Future<void> _applyAccounts(Map<String, dynamic> payload) async {
    final users = [
      for (final u in payload['users'] as List)
        User.fromJson(u as Map<String, dynamic>),
    ];
    final approvers = [
      for (final a in payload['approvers'] as List)
        Approver.fromJson(a as Map<String, dynamic>),
    ];
    await db.transaction(() async {
      for (final u in users) {
        await db.into(db.users).insertOnConflictUpdate(u);
      }
      for (final a in approvers) {
        await db.into(db.approvers).insertOnConflictUpdate(a);
      }
    });
  }
}
