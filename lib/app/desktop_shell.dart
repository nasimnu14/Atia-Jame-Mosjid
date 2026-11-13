import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/tables.dart';
import '../features/entries/entry_list_screen.dart';
import '../features/google_drive/backup_screen.dart';
import '../features/google_drive/excel_upload_screen.dart';
import '../features/reports/dashboard_screen.dart';
import '../features/reports/pdf_report_screen.dart';
import '../features/reports/summary_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/users/users_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/context_ext.dart';
import '../shared/permissions.dart';
import '../shared/role_text.dart';
import '../features/sign_in/language_switch.dart';
import 'section_placeholder.dart';
import 'shell_controller.dart';
import 'theme.dart';

enum Section {
  dashboard,
  income,
  expense,
  summary,
  pdf,
  excel,
  sync,
  users,
  backup,
  settings,
}

String sectionLabel(AppLocalizations l, Section s) => switch (s) {
  Section.dashboard => l.navDashboard,
  Section.income => l.navIncome,
  Section.expense => l.navExpense,
  Section.summary => l.navSummary,
  Section.pdf => l.navPdf,
  Section.excel => l.navExcel,
  Section.sync => l.navSync,
  Section.users => l.navUsers,
  Section.backup => l.navBackup,
  Section.settings => l.navSettings,
};

/// Which menu items each role sees (matches the designs: Users for the Super
/// Admin only; Backup for Admin and Super Admin).
bool sectionVisible(Role role, Section s) => switch (s) {
  Section.users => can(role, Permission.manageUsers),
  Section.backup => can(role, Permission.manageBackupAndSettings),
  _ => true,
};

/// The desktop layout: dark menu on the side, content on the right. Content
/// screens (details, forms) open inside the content area so the menu stays.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  final _navKey = GlobalKey<NavigatorState>();
  Section _section = Section.dashboard;

  Widget _page(Section s) => switch (s) {
    Section.dashboard => const DashboardScreen(),
    Section.summary => const SummaryScreen(),
    Section.pdf => const PdfReportScreen(),
    Section.excel => const ExcelUploadScreen(),
    Section.backup => const BackupScreen(),
    Section.income => const EntryListScreen(type: EntryType.income),
    Section.expense => const EntryListScreen(type: EntryType.expense),
    Section.users => const UsersScreen(),
    Section.settings => const SettingsScreen(),
    _ => SectionPlaceholder(section: s),
  };

  void _go(Section s) {
    if (s == _section) {
      _navKey.currentState!.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _section = s);
    _navKey.currentState!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => _page(s),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.appWatch.user!.role;
    return Provider<ShellController>.value(
      value: ShellController(_go),
      child: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 240,
              child: _SideMenu(active: _section, onSelect: _go, role: role),
            ),
            Expanded(
              child: Navigator(
                key: _navKey,
                onGenerateRoute: (_) => PageRouteBuilder(
                  pageBuilder: (_, _, _) => _page(_section),
                  transitionDuration: Duration.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.active,
    required this.onSelect,
    required this.role,
  });
  final Section active;
  final ValueChanged<Section> onSelect;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.appWatch.user!;
    return Semantics(
      container: true,
      label: l.mainMenu,
      child: Container(
        color: AppColors.primaryDark,
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 6),
                const LogoMark(size: 36, light: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.appName,
                        style: const TextStyle(
                          color: Color(0xFFE6F0EB),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        l.mosquePlace,
                        style: const TextStyle(
                          color: AppColors.navMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  for (final s in Section.values.where(
                    (s) => sectionVisible(role, s),
                  ))
                    _NavItem(
                      label: sectionLabel(l, s),
                      active: s == active,
                      onTap: () => onSelect(s),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDarker,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Color(0xFFE6F0EB),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    roleName(l, user.role),
                    style: const TextStyle(
                      color: AppColors.navMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: context.app.signOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        l.signOut,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Material(
      color: active ? AppColors.incomeSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: active,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primaryDark : const Color(0xFFE6F0EB),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
