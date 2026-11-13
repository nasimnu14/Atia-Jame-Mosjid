import '../data/tables.dart';

/// Every action that depends on the role (USR-2 table).
enum Permission {
  addEntry,
  viewEntries, // search, list, details, PDF, Excel upload
  syncPhone,
  changeOwnPassword,
  editEntry,
  cancelEntry,
  setOpeningBalance,
  manageApprovers,
  manageBackupAndSettings,
  restoreBackup,
  manageUsers, // add users, change roles, disable, reset passwords
}

const _userPerms = {
  Permission.addEntry,
  Permission.viewEntries,
  Permission.syncPhone,
  Permission.changeOwnPassword,
};

const _adminPerms = {
  ..._userPerms,
  Permission.editEntry,
  Permission.cancelEntry,
  Permission.setOpeningBalance,
  Permission.manageApprovers,
  Permission.manageBackupAndSettings,
};

const _superPerms = {
  ..._adminPerms,
  Permission.restoreBackup,
  Permission.manageUsers,
};

bool can(Role role, Permission permission) => switch (role) {
      Role.user => _userPerms,
      Role.admin => _adminPerms,
      Role.superAdmin => _superPerms,
    }
        .contains(permission);

class PermissionDeniedException implements Exception {
  PermissionDeniedException(this.permission);
  final Permission permission;
  @override
  String toString() => 'Permission denied: ${permission.name}';
}

/// Throws unless [role] may do [permission].
void requirePermission(Role role, Permission permission) {
  if (!can(role, permission)) throw PermissionDeniedException(permission);
}
