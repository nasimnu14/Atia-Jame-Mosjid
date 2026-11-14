import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/repositories/settings_repository.dart';
import '../shared/formatters.dart';
import '../features/users/user_service.dart';
import 'app_services.dart';
import 'built_in_admin.dart';

/// App-wide state: language (GEN-3) and the signed-in user (USR-1).
class AppState extends ChangeNotifier {
  AppState(this.services, {this.seedBuiltInAdmin = false});
  final AppServices services;

  /// Create the built-in Super Admin when this is a computer with no accounts.
  final bool seedBuiltInAdmin;

  bool ready = false;

  /// A message to show once on the sign-in screen (for example after a restore).
  String? notice;

  /// Whether any account exists yet. False on the very first launch (USR-3).
  bool hasUsers = false;
  User? user;

  /// Bangla is the default (GEN-3).
  bool bangla = true;

  Fmt get fmt => Fmt(bangla: bangla);
  Locale get locale => Locale(bangla ? 'bn' : 'en');

  Future<void> load() async {
    final lang = await services.settingsRepo.get(SettingKey.language);
    bangla = lang != 'en';
    hasUsers = await services.users.hasAnyUser();
    if (!hasUsers && seedBuiltInAdmin && !services.isPhone) {
      // A phone never does this: its accounts come from the computer (MOB-5).
      try {
        await services.users.createSuperAdmin(
          name: builtInAdminName,
          username: builtInAdminUsername,
          password: builtInAdminPassword,
        );
      } on UserException {
        // Created a moment ago by another load(): nothing to do.
      }
      hasUsers = await services.users.hasAnyUser();
    }
    ready = true;
    notifyListeners();
  }

  /// GEN-3: the choice is remembered.
  Future<void> setLanguage(bool toBangla) async {
    bangla = toBangla;
    notifyListeners();
    await services.settingsRepo.set(
      SettingKey.language,
      toBangla ? 'bn' : 'en',
    );
  }

  /// First launch: create the Super Admin and sign in as them.
  Future<void> createSuperAdmin({
    required String name,
    required String username,
    required String password,
  }) async {
    final u = await services.users.createSuperAdmin(
      name: name,
      username: username,
      password: password,
    );
    hasUsers = true;
    user = await services.users.signIn(u.username, password);
    notifyListeners();
  }

  Future<void> signIn(String username, String password) async {
    user = await services.users.signIn(username, password);
    notice = null;
    notifyListeners();
  }

  void signOut() {
    user = null;
    notifyListeners();
  }

  /// Re-read the signed-in user (e.g. after their own password change).
  Future<void> refreshUser() async {
    final u = user;
    if (u == null) return;
    user = await services.users.byId(u.id);
    notifyListeners();
  }

  /// After restoring a backup the whole database has been replaced.
  Future<void> reloadAfterRestore() async {
    user = null;
    await load();
  }
}
