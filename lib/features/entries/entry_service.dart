import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../data/photo_storage.dart';
import '../../data/tables.dart';
import '../../shared/bangla.dart';
import '../../shared/formatters.dart';
import '../../shared/period.dart';
import '../../shared/permissions.dart';
import '../users/user_service.dart';

const maxPhotosPerEntry = 10;

enum EntryField { receiptNo, date, name, purpose, approver, amount, photos }

enum EntryProblem {
  required,
  notPositive,
  tooMany, // more than 10 photos (INC-6)
  blankLabel,
  notInApproverList, // EXP-6
}

class EntryValidationException implements Exception {
  EntryValidationException(this.errors);
  final Map<EntryField, EntryProblem> errors;
  @override
  String toString() => 'EntryValidationException($errors)';
}

enum EntryActionProblem { notFound, alreadyCancelled, reasonRequired }

class EntryActionException implements Exception {
  EntryActionException(this.problem);
  final EntryActionProblem problem;
  @override
  String toString() => 'EntryActionException(${problem.name})';
}

/// One photo in a draft: either already saved ([existingId] set) or new
/// ([bytes] set, already shrunk).
class PhotoDraft {
  const PhotoDraft({
    this.existingId,
    this.existingFileName,
    this.bytes,
    required this.label,
  });
  final String? existingId;
  final String? existingFileName;
  final Uint8List? bytes;
  final String label;

  PhotoDraft withLabel(String l) => PhotoDraft(
    existingId: existingId,
    existingFileName: existingFileName,
    bytes: bytes,
    label: l,
  );
}

/// What the user typed into an income or expense form.
class EntryDraft {
  EntryDraft({
    required this.type,
    this.receiptNo,
    this.date,
    this.name = '',
    this.purpose = '',
    this.approverName = '',
    this.amount,
    this.address = '',
    this.photos = const [],
  });
  final EntryType type;
  int? receiptNo;
  DateTime? date;
  String name;
  String purpose;
  String approverName;
  int? amount;
  String address;
  List<PhotoDraft> photos;

  /// The entry's description, used to label photos (INC-10): purpose for an
  /// expense, name for an income. Empty when there is none.
  String get description => (type == EntryType.expense ? purpose : name).trim();
}

class EntryWithPhotos {
  const EntryWithPhotos(this.entry, this.photos);
  final Entry entry;
  final List<Photo> photos;
}

class EntryQuery {
  const EntryQuery({
    required this.type,
    this.period,
    this.text = '',
    this.onlyDuplicates = false,
  });
  final EntryType type;
  final Period? period;

  /// Only entries flagged as duplicate receipt numbers (SYN-8).
  final bool onlyDuplicates;

  /// Part of a name, or a receipt number (FND-1, FND-2).
  final String text;
}

class EntryPage {
  const EntryPage({
    required this.rows,
    required this.count,
    required this.total,
    required this.cancelledCount,
    required this.photoCounts,
  });

  /// The rows on this page.
  final List<Entry> rows;

  /// All entries the query matches, cancelled ones included (FND-7).
  final int count;

  /// Sum of the matching entries that are not cancelled (FND-8).
  final int total;
  final int cancelledCount;
  final Map<String, int> photoCounts;
}

/// Add, find, edit and cancel entries (INC, EXP, FND, DET, EDT, USR-8).
/// Role rules are enforced here.
class EntryService {
  EntryService(
    this._db,
    this._photos,
    this.deviceId, {
    this.now = DateTime.now,
  });

  final AppDatabase _db;
  final PhotoStorage _photos;
  final String deviceId;
  final DateTime Function() now;
  static const _uuid = Uuid();

  PhotoStorage get photoStorage => _photos;

  /// Fires after any change to entries or photos.
  Stream<void> get changes => _db
      .tableUpdates(TableUpdateQuery.onAllTables([_db.entries, _db.photos]))
      .map((_) {});

  // ---------------------------------------------------------------- numbers

  /// INC-4 / EXP-3: the highest receipt number in this series + 1. Income and
  /// expense are separate series. Cancelled entries count: their number is
  /// still used in the paper book.
  Future<int> suggestReceiptNo(EntryType type) async {
    final maxNo = _db.entries.receiptNo.max();
    final q = _db.selectOnly(_db.entries)
      ..addColumns([maxNo])
      ..where(_db.entries.type.equalsValue(type));
    final row = await q.getSingle();
    return (row.read(maxNo) ?? 0) + 1;
  }

  /// INC-5: the other entry already using this receipt number, if any.
  Future<Entry?> findDuplicate(
    EntryType type,
    int receiptNo, {
    String? exceptId,
  }) async {
    final q = _db.select(_db.entries)
      ..where((e) => e.type.equalsValue(type) & e.receiptNo.equals(receiptNo))
      ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]);
    for (final e in await q.get()) {
      if (e.id != exceptId) return e;
    }
    return null;
  }

  /// FND-1: entries with this receipt number (normally one).
  Future<List<Entry>> findByReceipt(EntryType type, int receiptNo) =>
      (_db.select(_db.entries)..where(
            (e) => e.type.equalsValue(type) & e.receiptNo.equals(receiptNo),
          ))
          .get();

  /// How many entries of this type are flagged as duplicates (SYN-8).
  Future<int> duplicateCount(EntryType type) async {
    final cnt = _db.entries.id.count();
    final q = _db.selectOnly(_db.entries)
      ..addColumns([cnt])
      ..where(
        _db.entries.type.equalsValue(type) &
            _db.entries.isDuplicate.equals(true),
      );
    return (await q.getSingle()).read(cnt) ?? 0;
  }

  // ------------------------------------------------------------- validation

  Future<Map<EntryField, EntryProblem>> validate(
    EntryDraft d, {
    String? existingApprover,
  }) async {
    final errors = <EntryField, EntryProblem>{};
    if (d.receiptNo == null || d.receiptNo! < 1) {
      errors[EntryField.receiptNo] = EntryProblem.required;
    }
    if (d.date == null) errors[EntryField.date] = EntryProblem.required;
    if (d.amount == null) {
      errors[EntryField.amount] = EntryProblem.required;
    } else if (d.amount! <= 0) {
      errors[EntryField.amount] = EntryProblem.notPositive;
    }
    if (d.type == EntryType.expense) {
      if (d.name.trim().isEmpty) {
        errors[EntryField.name] = EntryProblem.required;
      }
      if (d.purpose.trim().isEmpty) {
        errors[EntryField.purpose] = EntryProblem.required;
      }
      final approver = d.approverName.trim();
      if (approver.isEmpty) {
        errors[EntryField.approver] = EntryProblem.required;
      } else if (approver != existingApprover) {
        final ok =
            await (_db.select(_db.approvers)..where(
                  (a) => a.name.equals(approver) & a.isActive.equals(true),
                ))
                .get();
        if (ok.isEmpty) {
          errors[EntryField.approver] = EntryProblem.notInApproverList;
        }
      }
    }
    if (d.photos.length > maxPhotosPerEntry) {
      errors[EntryField.photos] = EntryProblem.tooMany;
    } else if (d.photos.any((p) => p.label.trim().isEmpty)) {
      errors[EntryField.photos] = EntryProblem.blankLabel;
    }
    return errors;
  }

  // ------------------------------------------------------------------ create

  /// GEN-6: any signed-in user can add an entry (INC-1, EXP-1).
  Future<EntryWithPhotos> create(User actor, EntryDraft draft) async {
    final live = await _liveActor(actor);
    requirePermission(live.role, Permission.addEntry);
    final errors = await validate(draft);
    if (errors.isNotEmpty) throw EntryValidationException(errors);

    final id = _uuid.v4();
    final savedFiles = <String, String>{}; // index -> file name
    try {
      for (var i = 0; i < draft.photos.length; i++) {
        savedFiles['$i'] = await _photos.save(id, draft.photos[i].bytes!);
      }
      await _db.transaction(() async {
        await _db
            .into(_db.entries)
            .insert(
              EntriesCompanion.insert(
                id: id,
                type: draft.type,
                receiptNo: draft.receiptNo!,
                entryDate: dayKey(draft.date!),
                name: Value(draft.name.trim()),
                purpose: Value(
                  _nullIfEmpty(
                    draft.type == EntryType.expense ? draft.purpose : '',
                  ),
                ),
                approverName: Value(
                  _nullIfEmpty(
                    draft.type == EntryType.expense ? draft.approverName : '',
                  ),
                ),
                amount: draft.amount!,
                address: Value(_nullIfEmpty(draft.address)),
                createdBy: live.id,
                createdAt: now(),
                deviceId: deviceId,
              ),
            );
        for (var i = 0; i < draft.photos.length; i++) {
          await _db
              .into(_db.photos)
              .insert(
                PhotosCompanion.insert(
                  id: _uuid.v4(),
                  entryId: id,
                  fileName: savedFiles['$i']!,
                  label: draft.photos[i].label.trim(),
                  position: i,
                ),
              );
        }
      });
    } catch (_) {
      // Remove files from a failed save; nothing refers to them.
      for (final name in savedFiles.values) {
        final f = _photos.fileFor(id, name);
        if (f.existsSync()) f.deleteSync();
      }
      rethrow;
    }
    return (await getWithPhotos(id))!;
  }

  // -------------------------------------------------------------------- edit

  /// EDT-1 / EDT-2 / INC-8: an Admin or the Super Admin edits; a User needs an
  /// Admin's on-the-spot approval ([approver], from
  /// `UserService.authorizeApprover`). The editor recorded is the one who had
  /// the authority. Cancelled entries cannot be edited.
  Future<EntryWithPhotos> update(
    User actor,
    String entryId,
    EntryDraft draft, {
    User? approver,
  }) async {
    final editor = await _authority(actor, approver, Permission.editEntry);
    final existing = await _entry(entryId);
    if (existing.status == EntryStatus.cancelled) {
      throw EntryActionException(EntryActionProblem.alreadyCancelled);
    }
    if (existing.type != draft.type) {
      throw ArgumentError('An entry cannot change between income and expense.');
    }
    final errors = await validate(
      draft,
      existingApprover: existing.approverName,
    );
    if (errors.isNotEmpty) throw EntryValidationException(errors);

    final current = await photosOf(entryId);
    final byId = {for (final p in current) p.id: p};
    final newFiles = <int, String>{};
    try {
      for (var i = 0; i < draft.photos.length; i++) {
        final ph = draft.photos[i];
        if (ph.existingId == null) {
          newFiles[i] = await _photos.save(entryId, ph.bytes!);
        } else if (!byId.containsKey(ph.existingId)) {
          throw ArgumentError('Unknown photo ${ph.existingId}');
        }
      }
      await _db.transaction(() async {
        await (_db.update(
          _db.entries,
        )..where((e) => e.id.equals(entryId))).write(
          EntriesCompanion(
            receiptNo: Value(draft.receiptNo!),
            entryDate: Value(dayKey(draft.date!)),
            name: Value(draft.name.trim()),
            purpose: Value(
              _nullIfEmpty(
                draft.type == EntryType.expense ? draft.purpose : '',
              ),
            ),
            approverName: Value(
              _nullIfEmpty(
                draft.type == EntryType.expense ? draft.approverName : '',
              ),
            ),
            amount: Value(draft.amount!),
            address: Value(_nullIfEmpty(draft.address)),
            editedBy: Value(editor.id),
            editedAt: Value(now()),
          ),
        );
        // Removing a photo only removes its row; the file stays on disk.
        final keep = {
          for (final p in draft.photos)
            if (p.existingId != null) p.existingId!,
        };
        for (final p in current) {
          if (!keep.contains(p.id)) {
            await (_db.delete(
              _db.photos,
            )..where((x) => x.id.equals(p.id))).go();
          }
        }
        for (var i = 0; i < draft.photos.length; i++) {
          final ph = draft.photos[i];
          if (ph.existingId != null) {
            await (_db.update(
              _db.photos,
            )..where((x) => x.id.equals(ph.existingId!))).write(
              PhotosCompanion(
                label: Value(ph.label.trim()),
                position: Value(i),
              ),
            );
          } else {
            await _db
                .into(_db.photos)
                .insert(
                  PhotosCompanion.insert(
                    id: _uuid.v4(),
                    entryId: entryId,
                    fileName: newFiles[i]!,
                    label: ph.label.trim(),
                    position: i,
                  ),
                );
          }
        }
      });
    } catch (_) {
      for (final name in newFiles.values) {
        final f = _photos.fileFor(entryId, name);
        if (f.existsSync()) f.deleteSync();
      }
      rethrow;
    }
    return (await getWithPhotos(entryId))!;
  }

  // ------------------------------------------------------------------ cancel

  /// EDT-3: only an Admin or the Super Admin (or a User with an Admin's
  /// approval) cancels, and a reason is required. Nothing is deleted. A
  /// cancelled entry stays in the records and is left out of every total
  /// (EDT-4).
  Future<Entry> cancel(
    User actor,
    String entryId,
    String reason, {
    User? approver,
  }) async {
    final who = await _authority(actor, approver, Permission.cancelEntry);
    final clean = reason.trim();
    if (clean.isEmpty) {
      throw EntryActionException(EntryActionProblem.reasonRequired);
    }
    final existing = await _entry(entryId);
    if (existing.status == EntryStatus.cancelled) {
      throw EntryActionException(EntryActionProblem.alreadyCancelled);
    }
    await (_db.update(_db.entries)..where((e) => e.id.equals(entryId))).write(
      EntriesCompanion(
        status: Value(EntryStatus.cancelled),
        cancelReason: Value(clean),
        cancelledBy: Value(who.id),
        cancelledAt: Value(now()),
      ),
    );
    return _entry(entryId);
  }

  /// SYN-8: an Admin clears the "duplicate receipt number" mark after
  /// checking the entry.
  Future<void> clearDuplicateFlag(User actor, String entryId) async {
    final live = await _liveActor(actor);
    requirePermission(live.role, Permission.editEntry);
    await (_db.update(_db.entries)..where((e) => e.id.equals(entryId))).write(
      const EntriesCompanion(isDuplicate: Value(false)),
    );
  }

  // ------------------------------------------------------------------- read

  Future<Entry?> getById(String id) => (_db.select(
    _db.entries,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<Photo>> photosOf(String entryId) =>
      (_db.select(_db.photos)
            ..where((p) => p.entryId.equals(entryId))
            ..orderBy([(p) => OrderingTerm.asc(p.position)]))
          .get();

  Future<EntryWithPhotos?> getWithPhotos(String id) async {
    final e = await getById(id);
    if (e == null) return null;
    return EntryWithPhotos(e, await photosOf(id));
  }

  /// FND-2 / FND-3 / FND-4 / FND-5 / FND-7. Newest first.
  Future<EntryPage> list(EntryQuery q, {int limit = 50, int offset = 0}) async {
    final e = _db.entries;
    final cond = _condition(q);

    final rowsQ = _db.select(e)
      ..where((_) => cond)
      ..orderBy([
        (t) => OrderingTerm.desc(t.entryDate),
        (t) => OrderingTerm.desc(t.receiptNo),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit, offset: offset);
    final rows = await rowsQ.get();

    final cnt = e.id.count();
    final sum = e.amount.sum();
    final activeSum = _db.selectOnly(e)
      ..addColumns([cnt, sum])
      ..where(cond & e.status.equalsValue(EntryStatus.active));
    final active = await activeSum.getSingle();
    final cancelledQ = _db.selectOnly(e)
      ..addColumns([cnt])
      ..where(cond & e.status.equalsValue(EntryStatus.cancelled));
    final cancelled = (await cancelledQ.getSingle()).read(cnt) ?? 0;

    final photoCounts = <String, int>{};
    if (rows.isNotEmpty) {
      final pc = _db.photos.id.count();
      final pq = _db.selectOnly(_db.photos)
        ..addColumns([_db.photos.entryId, pc])
        ..where(_db.photos.entryId.isIn(rows.map((r) => r.id)))
        ..groupBy([_db.photos.entryId]);
      for (final r in await pq.get()) {
        photoCounts[r.read(_db.photos.entryId)!] = r.read(pc)!;
      }
    }

    final activeCount = active.read(cnt) ?? 0;
    return EntryPage(
      rows: rows,
      count: activeCount + cancelled,
      total: active.read(sum) ?? 0,
      cancelledCount: cancelled,
      photoCounts: photoCounts,
    );
  }

  Expression<bool> _condition(EntryQuery q) {
    final e = _db.entries;
    Expression<bool> cond = e.type.equalsValue(q.type);
    final p = q.period;
    if (p != null) {
      cond =
          cond &
          e.entryDate.isBiggerOrEqualValue(dayKey(p.from)) &
          e.entryDate.isSmallerOrEqualValue(dayKey(p.to));
    }
    if (q.onlyDuplicates) cond = cond & e.isDuplicate.equals(true);
    final text = q.text.trim();
    if (text.isNotEmpty) {
      final asNumber = int.tryParse(toEnglishDigits(text));
      final byName = e.name.like('%${_escapeLike(text)}%', escapeChar: r'\');
      cond =
          cond &
          (asNumber == null ? byName : (byName | e.receiptNo.equals(asNumber)));
    }
    return cond;
  }

  /// The newest entries of both types, for the dashboard.
  Future<List<Entry>> recent({int limit = 5}) {
    final q = _db.select(_db.entries)
      ..orderBy([
        (e) => OrderingTerm.desc(e.entryDate),
        (e) => OrderingTerm.desc(e.createdAt),
      ])
      ..limit(limit);
    return q.get();
  }

  /// All entries (any status) inside a period, both types; used by reports
  /// and Excel. Oldest first.
  Future<List<Entry>> inPeriod(Period period, {EntryType? type}) {
    final q = _db.select(_db.entries)
      ..where(
        (e) =>
            e.entryDate.isBiggerOrEqualValue(dayKey(period.from)) &
            e.entryDate.isSmallerOrEqualValue(dayKey(period.to)) &
            (type == null ? const Constant(true) : e.type.equalsValue(type)),
      )
      ..orderBy([
        (e) => OrderingTerm.asc(e.entryDate),
        (e) => OrderingTerm.asc(e.receiptNo),
        (e) => OrderingTerm.asc(e.createdAt),
      ]);
    return q.get();
  }

  // ---------------------------------------------------------------- helpers

  Future<Entry> _entry(String id) async {
    final e = await getById(id);
    if (e == null) throw EntryActionException(EntryActionProblem.notFound);
    return e;
  }

  /// The actor as stored now: a role change or disabling applies at once.
  Future<User> _liveActor(User actor) async {
    final live = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(actor.id))).getSingleOrNull();
    if (live == null) throw UserException(UserProblem.notFound);
    if (!live.isActive) throw UserException(UserProblem.accountDisabled);
    return live;
  }

  /// Who has the authority for [permission]: the actor, or else an approver
  /// (EDT-2).
  Future<User> _authority(
    User actor,
    User? approver,
    Permission permission,
  ) async {
    final live = await _liveActor(actor);
    if (can(live.role, permission)) return live;
    if (approver != null) {
      final a = await _liveActor(approver);
      if (can(a.role, permission)) return a;
    }
    throw PermissionDeniedException(permission);
  }

  /// Makes `%` and `_` in what the user typed match themselves.
  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static String? _nullIfEmpty(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}

/// INC-10: a photo left without a label is named after the entry's
/// description and its number, e.g. "সিলেট বালু ২ ট্রলি ১". [unknownName] is
/// used when an income has no name.
String defaultPhotoLabel(
  String description,
  int number,
  Fmt fmt, {
  required String unknownName,
}) {
  final d = description.trim().isEmpty ? unknownName : description.trim();
  return '$d ${fmt.integer(number)}';
}

/// Fills in blank photo labels by INC-10, numbering by position.
List<PhotoDraft> withDefaultLabels(
  EntryDraft draft,
  Fmt fmt, {
  required String unknownName,
}) {
  return [
    for (var i = 0; i < draft.photos.length; i++)
      draft.photos[i].label.trim().isEmpty
          ? draft.photos[i].withLabel(
              defaultPhotoLabel(
                draft.description,
                i + 1,
                fmt,
                unknownName: unknownName,
              ),
            )
          : draft.photos[i],
  ];
}
