import '../data/tables.dart';
import '../l10n/app_localizations.dart';

String roleName(AppLocalizations l, Role r) => switch (r) {
      Role.superAdmin => l.roleSuperAdmin,
      Role.admin => l.roleAdmin,
      Role.user => l.roleUser,
    };

String roleCan(AppLocalizations l, Role r) => switch (r) {
      Role.superAdmin => l.roleSuperAdminCan,
      Role.admin => l.roleAdminCan,
      Role.user => l.roleUserCan,
    };
