import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/tables.dart';
import '../features/entries/entry_list_screen.dart';
import '../features/mobile/more_screen.dart';
import '../features/mobile/mobile_home_screen.dart';
import '../features/reports/pdf_report_screen.dart';
import '../features/reports/summary_screen.dart';
import '../shared/context_ext.dart';
import 'desktop_shell.dart';
import 'shell_controller.dart';
import 'theme.dart';

enum MobileTab { home, income, expense, summary, more }

/// The Android layout: a top bar and a bottom bar with Home, Income, Expense,
/// Summary and More (MOB-1).
class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  final _navKey = GlobalKey<NavigatorState>();
  MobileTab _tab = MobileTab.home;

  Widget _page(MobileTab t) => switch (t) {
    MobileTab.home => const MobileHomeScreen(),
    MobileTab.income => const EntryListScreen(type: EntryType.income),
    MobileTab.expense => const EntryListScreen(type: EntryType.expense),
    MobileTab.summary => const SummaryScreen(),
    MobileTab.more => const MoreScreen(),
  };

  void _select(MobileTab t) {
    if (t == _tab) {
      _navKey.currentState!.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _tab = t);
    _navKey.currentState!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => _page(t),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  /// Other screens ask the shell to switch section; on the phone only a few
  /// make sense.
  void _goTo(Section s) {
    switch (s) {
      case Section.income:
        _select(MobileTab.income);
      case Section.expense:
        _select(MobileTab.expense);
      case Section.summary:
        _select(MobileTab.summary);
      case Section.pdf:
        _navKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const PdfReportScreen()),
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = {
      MobileTab.home: (l.navHome, Icons.home_outlined),
      MobileTab.income: (l.navIncome, Icons.south_rounded),
      MobileTab.expense: (l.navExpense, Icons.north_rounded),
      MobileTab.summary: (l.navSummary, Icons.bar_chart_rounded),
      MobileTab.more: (l.navMore, Icons.more_horiz),
    };
    return Provider<ShellController>.value(
      value: ShellController(_goTo),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.appName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        body: NavigatorPopHandler(
          onPopWithResult: (_) => _navKey.currentState!.maybePop(),
          child: Navigator(
            key: _navKey,
            onGenerateRoute: (_) => PageRouteBuilder(
              pageBuilder: (_, _, _) => _page(_tab),
              transitionDuration: Duration.zero,
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (final t in MobileTab.values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: t == _tab,
                        child: InkWell(
                          onTap: () => _select(t),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t == _tab
                                      ? AppColors.incomeSoft
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Icon(
                                  labels[t]!.$2,
                                  size: 22,
                                  color: t == _tab
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                labels[t]!.$1,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: t == _tab
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: t == _tab
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
