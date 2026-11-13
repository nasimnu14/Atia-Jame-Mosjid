import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/formatters.dart';
import '../../shared/permissions.dart';

class OpeningBalance {
  const OpeningBalance(this.amount, this.date);
  final int amount;
  final DateTime date;
}

enum SettingsProblem { nameRequired, nameTaken, notFound, negativeAmount }

class SettingsException implements Exception {
  SettingsException(this.problem);
  final SettingsProblem problem;
  @override
  String toString() => 'SettingsException(${problem.name})';
}

/// Opening balance (BAL-1, BAL-2) and the approver list (EXP-6, EXP-7).
class SettingsService {
  SettingsService(this._db, this.repo);
  final AppDatabase _db;
  final SettingsRepository repo;
  static const _uuid = Uuid();

  Future<OpeningBalance?> openingBalance() async {
    final amount = await repo.getInt(SettingKey.openingBalance);
    final date = await repo.get(SettingKey.openingBalanceDate);
    if (amount == null || date == null) return null;
    return OpeningBalance(amount, parseDayKey(date));
  }

  /// BAL-1 / BAL-2: Admin or Super Admin only. Whole Taka, not negative
  /// (cash in hand).
  Future<void> setOpeningBalance(User actor, int amount, DateTime date) async {
    await _require(actor, Permission.setOpeningBalance);
    if (amount < 0) throw SettingsException(SettingsProblem.negativeAmount);
    await _db.transaction(() async {
      await repo.set(SettingKey.openingBalance, amount.toString());
      await repo.set(SettingKey.openingBalanceDate, dayKey(date));
    });
  }

  Future<List<Approver>> approvers({bool activeOnly = true}) {
    final q = _db.select(_db.approvers)
      ..orderBy([(a) => OrderingTerm.asc(a.name)]);
    if (activeOnly) q.where((a) => a.isActive.equals(true));
    return q.get();
  }

  Stream<List<Approver>> watchApprovers() => (_db.select(
    _db.approvers,
  )..orderBy([(a) => OrderingTerm.asc(a.name)])).watch();

  /// EXP-7: only an Admin or the Super Admin.
  Future<Approver> addApprover(User actor, String name) async {
    await _require(actor, Permission.manageApprovers);
    final clean = await _cleanName(name);
    final a = ApproversCompanion.insert(id: _uuid.v4(), name: clean);
    await _db.into(_db.approvers).insert(a);
    return (await (_db.select(
      _db.approvers,
    )..where((x) => x.id.equals(a.id.value))).getSingle());
  }

  /// Renaming does not touch old expenses: each expense stores the name text
  /// it was saved with (EXP-8).
  Future<void> renameApprover(User actor, String id, String name) async {
    await _require(actor, Permission.manageApprovers);
    final clean = await _cleanName(name, exceptId: id);
    final n = await (_db.update(_db.approvers)..where((a) => a.id.equals(id)))
        .write(ApproversCompanion(name: Value(clean)));
    if (n == 0) throw SettingsException(SettingsProblem.notFound);
  }

  /// Approvers are switched off, not deleted.
  Future<void> setApproverActive(User actor, String id, bool active) async {
    await _require(actor, Permission.manageApprovers);
    final n = await (_db.update(_db.approvers)..where((a) => a.id.equals(id)))
        .write(ApproversCompanion(isActive: Value(active)));
    if (n == 0) throw SettingsException(SettingsProblem.notFound);
  }

  /// Checks the role stored now, not the one the screen remembers.
  Future<void> _require(User actor, Permission permission) async {
    final live = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(actor.id))).getSingleOrNull();
    if (live == null || !live.isActive) {
      throw PermissionDeniedException(permission);
    }
    requirePermission(live.role, permission);
  }

  Future<String> _cleanName(String name, {String? exceptId}) async {
    final clean = name.trim();
    if (clean.isEmpty) throw SettingsException(SettingsProblem.nameRequired);
    final clash = await (_db.select(
      _db.approvers,
    )..where((a) => a.name.equals(clean))).get();
    if (clash.any((a) => a.id != exceptId)) {
      throw SettingsException(SettingsProblem.nameTaken);
    }
    return clean;
  }
}
