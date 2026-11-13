import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../data/tables.dart';
import '../../shared/password_hasher.dart';
import '../../shared/permissions.dart';

enum UserProblem {
  nameRequired,
  usernameRequired,
  usernameInvalid,
  usernameTaken,
  passwordTooShort,
  passwordTooLong,
  wrongCurrentPassword,
  superAdminExists,
  cannotChangeSuperAdmin,
  invalidCredentials,
  accountDisabled,
  notFound,
  invalidRole,
  notAnApprover,
}

class UserException implements Exception {
  UserException(this.problem);
  final UserProblem problem;
  @override
  String toString() => 'UserException(${problem.name})';
}

/// Accounts, sign-in and the Super Admin rules (USR-1 to USR-7, USR-9).
/// Role checks are enforced here, not only in the screens.
class UserService {
  UserService(this._db,
      {this.hasher = const PasswordHasher(), this.now = DateTime.now});

  final AppDatabase _db;
  final PasswordHasher hasher;
  final DateTime Function() now;
  String? _dummyHash;
  static const _uuid = Uuid();

  static String normaliseUsername(String u) => u.trim().toLowerCase();

  Future<bool> hasAnyUser() async =>
      (await (_db.select(_db.users)..limit(1)).get()).isNotEmpty;

  Future<List<User>> all() =>
      (_db.select(_db.users)..orderBy([(u) => OrderingTerm.asc(u.createdAt)]))
          .get();

  Stream<List<User>> watchAll() =>
      (_db.select(_db.users)..orderBy([(u) => OrderingTerm.asc(u.createdAt)]))
          .watch();

  Future<User?> byId(String id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();

  /// First launch (USR-3). There is only one Super Admin.
  Future<User> createSuperAdmin(
      {required String name,
      required String username,
      required String password}) async {
    final existing = await (_db.select(_db.users)
          ..where((u) => u.role.equals(Role.superAdmin.name)))
        .get();
    if (existing.isNotEmpty) {
      throw UserException(UserProblem.superAdminExists);
    }
    return _insert(
        name: name, username: username, password: password, role: Role.superAdmin);
  }

  /// Only the Super Admin can add users (USR-4), as Admin or User.
  Future<User> addUser(User actor,
      {required String name,
      required String username,
      required String password,
      required Role role}) async {
    await _requireLiveActor(actor, Permission.manageUsers);
    if (role == Role.superAdmin) throw UserException(UserProblem.invalidRole);
    return _insert(name: name, username: username, password: password, role: role);
  }

  Future<User> _insert(
      {required String name,
      required String username,
      required String password,
      required Role role}) async {
    final cleanName = name.trim();
    final cleanUser = normaliseUsername(username);
    if (cleanName.isEmpty) throw UserException(UserProblem.nameRequired);
    if (cleanUser.isEmpty) throw UserException(UserProblem.usernameRequired);
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(cleanUser)) {
      throw UserException(UserProblem.usernameInvalid);
    }
    _checkPassword(password);
    final clash = await (_db.select(_db.users)
          ..where((u) => u.username.equals(cleanUser)))
        .getSingleOrNull();
    if (clash != null) throw UserException(UserProblem.usernameTaken);
    final user = UsersCompanion.insert(
      id: _uuid.v4(),
      name: cleanName,
      username: cleanUser,
      passwordHash: await hasher.hash(password),
      role: role,
      createdAt: now(),
    );
    await _db.into(_db.users).insert(user);
    return (await (_db.select(_db.users)
              ..where((u) => u.username.equals(cleanUser)))
            .getSingle());
  }

  void _checkPassword(String password) {
    if (PasswordHasher.isTooShort(password)) {
      throw UserException(UserProblem.passwordTooShort);
    }
    if (PasswordHasher.isTooLong(password)) {
      throw UserException(UserProblem.passwordTooLong);
    }
  }

  /// Sign in with username and password (USR-1). A disabled user cannot
  /// sign in (USR-6).
  Future<User> signIn(String username, String password) async {
    final user = await (_db.select(_db.users)
          ..where((u) => u.username.equals(normaliseUsername(username))))
        .getSingleOrNull();
    if (user == null) {
      // Same work as a real check, so timing does not reveal valid usernames.
      _dummyHash ??= await hasher.hash('timing-only');
      await hasher.verify(password, _dummyHash!);
      throw UserException(UserProblem.invalidCredentials);
    }
    if (!await hasher.verify(password, user.passwordHash)) {
      throw UserException(UserProblem.invalidCredentials);
    }
    if (!user.isActive) throw UserException(UserProblem.accountDisabled);
    final at = now();
    await (_db.update(_db.users)..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(lastSignInAt: Value(at)));
    return user.copyWith(lastSignInAt: Value(at));
  }

  /// An Admin or Super Admin approves an edit or cancel on the spot with their
  /// own username and password (EDT-2). Returns that approver.
  Future<User> authorizeApprover(String username, String password) async {
    final user = await signIn(username, password);
    if (!can(user.role, Permission.editEntry)) {
      throw UserException(UserProblem.notAnApprover);
    }
    return user;
  }

  /// USR-5: only the Super Admin changes roles. The Super Admin's own role
  /// can never change, and nobody can become Super Admin.
  Future<void> changeRole(User actor, String userId, Role role) async {
    await _requireLiveActor(actor, Permission.manageUsers);
    if (role == Role.superAdmin) throw UserException(UserProblem.invalidRole);
    final target = await _target(userId);
    if (target.role == Role.superAdmin) {
      throw UserException(UserProblem.cannotChangeSuperAdmin);
    }
    await (_db.update(_db.users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(role: Value(role)));
  }

  /// Disable or re-enable (USR-5, USR-6). Users are never deleted.
  Future<void> setActive(User actor, String userId, bool active) async {
    await _requireLiveActor(actor, Permission.manageUsers);
    final target = await _target(userId);
    if (target.role == Role.superAdmin) {
      throw UserException(UserProblem.cannotChangeSuperAdmin);
    }
    await (_db.update(_db.users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(isActive: Value(active)));
  }

  /// USR-5: the Super Admin's own password cannot be reset by anyone.
  Future<void> resetPassword(
      User actor, String userId, String newPassword) async {
    await _requireLiveActor(actor, Permission.manageUsers);
    final target = await _target(userId);
    if (target.role == Role.superAdmin) {
      throw UserException(UserProblem.cannotChangeSuperAdmin);
    }
    _checkPassword(newPassword);
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(passwordHash: Value(await hasher.hash(newPassword))));
  }

  /// USR-7: every user changes their own password with the current one.
  Future<void> changeOwnPassword(
      User actor, String currentPassword, String newPassword) async {
    final live = await _target(actor.id);
    if (!live.isActive) throw UserException(UserProblem.accountDisabled);
    if (!await hasher.verify(currentPassword, live.passwordHash)) {
      throw UserException(UserProblem.wrongCurrentPassword);
    }
    _checkPassword(newPassword);
    await (_db.update(_db.users)..where((u) => u.id.equals(live.id))).write(
        UsersCompanion(passwordHash: Value(await hasher.hash(newPassword))));
  }

  Future<User> _target(String id) async {
    final u = await byId(id);
    if (u == null) throw UserException(UserProblem.notFound);
    return u;
  }

  /// Checks the actor against the database, not the object the screen holds:
  /// a role change or disabling takes effect immediately.
  Future<void> _requireLiveActor(User actor, Permission permission) async {
    final live = await _target(actor.id);
    if (!live.isActive) throw UserException(UserProblem.accountDisabled);
    requirePermission(live.role, permission);
  }
}
