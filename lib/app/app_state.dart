import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/repositories/settings_repository.dart';
import '../shared/formatters.dart';
import 'app_services.dart';

/// App-wide state: language (GEN-3) and the signed-in user (USR-1).
class AppState extends ChangeNotifier {
  AppState(this.services);
  final AppServices services;

  bool ready = false;

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
    ready = true;
    notifyListeners();
  }

  /// GEN-3: the choice is remembered.
  Future<void> setLanguage(bool toBangla) async {
    bangla = toBangla;
    notifyListeners();
    await services.settingsRepo
        .set(SettingKey.language, toBangla ? 'bn' : 'en');
  }

  /// First launch: create the Super Admin and sign in as them.
  Future<void> createSuperAdmin(
      {required String name,
      required String username,
      required String password}) async {
    final u = await services.users.createSuperAdmin(
        name: name, username: username, password: password);
    hasUsers = true;
    user = await services.users.signIn(u.username, password);
    notifyListeners();
  }

  Future<void> signIn(String username, String password) async {
    user = await services.users.signIn(username, password);
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
