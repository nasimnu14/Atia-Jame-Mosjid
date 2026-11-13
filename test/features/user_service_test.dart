import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/users/user_service.dart';
import 'package:atia_masjid_accounts/shared/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

Matcher problem(UserProblem p) =>
    throwsA(isA<UserException>().having((e) => e.problem, 'problem', p));

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());

  test('USR-9: passwords are stored hashed, never plain', () async {
    final all = await env.users.all();
    for (final u in all) {
      expect(u.passwordHash, isNot(contains('secret')));
      expect(u.passwordHash, startsWith(r'$2'));
    }
  });

  group('sign in (USR-1, USR-6)', () {
    test('right password signs in; username is case-insensitive', () async {
      expect((await env.users.signIn(' ADMIN ', 'secret2')).id, env.admin.id);
    });
    test('wrong password and unknown user are refused alike', () async {
      await expectLater(env.users.signIn('admin', 'nope!!'),
          problem(UserProblem.invalidCredentials));
      await expectLater(env.users.signIn('ghost', 'secret2'),
          problem(UserProblem.invalidCredentials));
    });
    test('a disabled user cannot sign in, and is not deleted', () async {
      await env.users.setActive(env.superAdmin, env.user.id, false);
      await expectLater(
          env.users.signIn('user', 'secret3'), problem(UserProblem.accountDisabled));
      expect((await env.users.all()).any((u) => u.id == env.user.id), isTrue);
      await env.users.setActive(env.superAdmin, env.user.id, true);
      expect((await env.users.signIn('user', 'secret3')).id, env.user.id);
    });
  });

  group('first launch (USR-3)', () {
    test('there is only one Super Admin', () async {
      await expectLater(
          env.users.createSuperAdmin(name: 'X', username: 'x', password: 'secret9'),
          problem(UserProblem.superAdminExists));
    });
  });

  group('managing users (USR-4, USR-5)', () {
    test('only the Super Admin adds users, as Admin or User', () async {
      await expectLater(
          env.users.addUser(env.admin,
              name: 'N', username: 'n1', password: 'secret9', role: Role.user),
          throwsA(isA<PermissionDeniedException>()));
      await expectLater(
          env.users.addUser(env.user,
              name: 'N', username: 'n1', password: 'secret9', role: Role.user),
          throwsA(isA<PermissionDeniedException>()));
      await expectLater(
          env.users.addUser(env.superAdmin,
              name: 'N', username: 'n1', password: 'secret9', role: Role.superAdmin),
          problem(UserProblem.invalidRole));
    });
    test('username must be unique, valid; password long enough', () async {
      Future<void> add(String u, String p) => env.users
          .addUser(env.superAdmin, name: 'N', username: u, password: p, role: Role.user);
      await expectLater(add('ADMIN', 'secret9'), problem(UserProblem.usernameTaken));
      await expectLater(add('a b', 'secret9'), problem(UserProblem.usernameInvalid));
      await expectLater(add('ok1', '123'), problem(UserProblem.passwordTooShort));
      await expectLater(add('ok1', 'ক' * 30), problem(UserProblem.passwordTooLong));
    });
    test('only the Super Admin changes roles, disables, resets passwords', () async {
      await expectLater(env.users.changeRole(env.admin, env.user.id, Role.admin),
          throwsA(isA<PermissionDeniedException>()));
      await expectLater(env.users.setActive(env.admin, env.user.id, false),
          throwsA(isA<PermissionDeniedException>()));
      await expectLater(env.users.resetPassword(env.admin, env.user.id, 'newpass1'),
          throwsA(isA<PermissionDeniedException>()));
      await env.users.changeRole(env.superAdmin, env.user.id, Role.admin);
      expect((await env.users.byId(env.user.id))!.role, Role.admin);
      await env.users.resetPassword(env.superAdmin, env.user.id, 'newpass1');
      expect((await env.users.signIn('user', 'newpass1')).id, env.user.id);
    });
    test("nobody can reset the Super Admin's password or change their role", () async {
      await expectLater(
          env.users.resetPassword(env.superAdmin, env.superAdmin.id, 'hacked1'),
          problem(UserProblem.cannotChangeSuperAdmin));
      await expectLater(env.users.changeRole(env.superAdmin, env.superAdmin.id, Role.user),
          problem(UserProblem.cannotChangeSuperAdmin));
      await expectLater(env.users.setActive(env.superAdmin, env.superAdmin.id, false),
          problem(UserProblem.cannotChangeSuperAdmin));
      await expectLater(env.users.changeRole(env.superAdmin, env.user.id, Role.superAdmin),
          problem(UserProblem.invalidRole));
    });
    test('a demoted or disabled actor loses power at once (stale object)', () async {
      await env.users.changeRole(env.superAdmin, env.admin.id, Role.user);
      // env.admin still holds role admin in memory.
      // env.admin still says "admin" in memory, but the database says "user".
      await expectLater(env.settings.setOpeningBalance(env.admin, 5, DateTime(2026)),
          throwsA(isA<PermissionDeniedException>()));
      await expectLater(env.settings.addApprover(env.admin, 'কেউ'),
          throwsA(isA<PermissionDeniedException>()));
      await env.users.setActive(env.superAdmin, env.user.id, false);
      await expectLater(env.settings.setOpeningBalance(env.user, 5, DateTime(2026)),
          throwsA(isA<PermissionDeniedException>()));
    });
  });

  group('change own password (USR-7)', () {
    test('needs the current password', () async {
      await expectLater(env.users.changeOwnPassword(env.user, 'bad', 'newpass1'),
          problem(UserProblem.wrongCurrentPassword));
      await env.users.changeOwnPassword(env.user, 'secret3', 'newpass1');
      expect((await env.users.signIn('user', 'newpass1')).id, env.user.id);
      await expectLater(env.users.signIn('user', 'secret3'),
          problem(UserProblem.invalidCredentials));
    });
    test('the Super Admin can change their own', () async {
      await env.users.changeOwnPassword(env.superAdmin, 'secret1', 'newpass1');
      expect((await env.users.signIn('super', 'newpass1')).role, Role.superAdmin);
    });
  });

  group('on-the-spot approval (EDT-2)', () {
    test('an Admin or Super Admin approves; a User cannot', () async {
      expect((await env.users.authorizeApprover('admin', 'secret2')).id, env.admin.id);
      expect((await env.users.authorizeApprover('super', 'secret1')).id,
          env.superAdmin.id);
      await expectLater(env.users.authorizeApprover('user', 'secret3'),
          problem(UserProblem.notAnApprover));
      await expectLater(env.users.authorizeApprover('admin', 'wrong!!'),
          problem(UserProblem.invalidCredentials));
    });
  });
}
