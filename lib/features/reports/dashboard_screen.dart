import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/desktop_shell.dart';
import '../../app/shell_controller.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/period.dart';
import '../../shared/permissions.dart';
import '../../shared/widgets/basics.dart';
import '../entries/entry_details_screen.dart';
import '../entries/entry_form_screen.dart';
import '../entries/entry_text.dart';
import 'balance_service.dart';

class _DashData {
  _DashData({
    required this.balance,
    required this.opening,
    required this.openingDate,
    required this.today,
    required this.month,
    required this.recent,
    required this.backupAt,
    required this.backupError,
    required this.excelAt,
    required this.excelError,
    required this.syncAt,
  });
  final int balance;
  final int? opening;
  final DateTime? openingDate;
  final PeriodSummary today;
  final PeriodSummary month;
  final List<Entry> recent;
  final DateTime? backupAt;
  final String? backupError;
  final DateTime? excelAt;
  final String? excelError;
  final DateTime? syncAt;
}

/// The main screen: the current balance (BAL-3), today and this month at a
/// glance, backup / Excel / sync status, and the newest entries.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashData? _data;
  StreamSubscription<void>? _sub;
  StreamSubscription<void>? _settingsSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null) {
      final s = context.services;
      _sub = s.entries.changes.listen((_) => _load());
      _settingsSub = s.db
          .tableUpdates(TableUpdateQuery.onTable(s.db.settings))
          .listen((_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = context.services;
    final today = dateOnly(s.now());
    final ob = await s.settings.openingBalance();
    final data = _DashData(
      balance: await s.balance.currentBalance(),
      opening: ob?.amount,
      openingDate: ob?.date,
      today: await s.balance.summary(Period.day(today)),
      month: await s.balance.summary(Period.monthOf(today)),
      recent: await s.entries.recent(limit: 5),
      backupAt: await s.settingsRepo.getDateTime(SettingKey.lastBackupAt),
      backupError: await s.settingsRepo.get(SettingKey.lastBackupError),
      excelAt: await s.settingsRepo.getDateTime(SettingKey.lastExcelUploadAt),
      excelError: await s.settingsRepo.get(SettingKey.lastExcelError),
      syncAt: await s.settingsRepo.getDateTime(SettingKey.lastSyncAt),
    );
    if (mounted) setState(() => _data = data);
  }

  String _status(AppLocalizations l, Fmt fmt, DateTime? at, String? error) {
    if (error != null && error.isNotEmpty) {
      return l.statusFailedAt(at == null ? l.statusNotYet : fmt.dateTime(at));
    }
    return at == null ? l.statusNotYet : l.statusOkAt(fmt.dateTime(at));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final d = _data;
    final today = dateOnly(context.services.now());
    final shell = context.read<ShellController>();
    final role = context.appWatch.user!.role;
    if (d == null) {
      return PageScaffold(
        title: l.navDashboard,
        child: const SizedBox.shrink(),
      );
    }

    Widget stat(String label, int value, int count, {required bool income}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                fmt.money(value),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: income ? AppColors.income : AppColors.expense,
                ),
              ),
              Text(
                l.entriesCount(fmt.integer(count)),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        );

    Widget statusCard(String label, String value, Section? goTo) => InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: goTo == null ? null : () => shell.goTo(goTo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.income,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return PageScaffold(
      title: l.navDashboard,
      subtitle: fmt.longDate(today),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EntryFormScreen(type: EntryType.income),
            ),
          ),
          child: Text(l.newIncome),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EntryFormScreen(type: EntryType.expense),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.expense,
            side: const BorderSide(color: AppColors.expenseBorder),
          ),
          child: Text(l.newExpense),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.currentBalance,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.onPrimaryMuted,
                        ),
                      ),
                      Text(
                        fmt.money(d.balance),
                        key: const Key('current-balance'),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.opening == null
                            ? l.balanceNoOpening
                            : l.balanceFormulaLine(
                                fmt.money(d.opening!),
                                fmt.date(d.openingDate!),
                              ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onPrimaryMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => shell.goTo(Section.summary),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(l.viewSummary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = (c.maxWidth / 200).floor().clamp(1, 4);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: w,
                    child: stat(
                      l.incomeToday,
                      d.today.incomeTotal,
                      d.today.incomeCount,
                      income: true,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: stat(
                      l.expenseToday,
                      d.today.expenseTotal,
                      d.today.expenseCount,
                      income: false,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: stat(
                      l.incomeThisMonth,
                      d.month.incomeTotal,
                      d.month.incomeCount,
                      income: true,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: stat(
                      l.expenseThisMonth,
                      d.month.expenseTotal,
                      d.month.expenseCount,
                      income: false,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = (c.maxWidth / 260).floor().clamp(1, 3);
              final w = (c.maxWidth - (cols - 1) * 14) / cols;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: w,
                    child: statusCard(
                      l.statusBackup,
                      _status(l, fmt, d.backupAt, d.backupError),
                      can(role, Permission.manageBackupAndSettings)
                          ? Section.backup
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: statusCard(
                      l.statusExcel,
                      _status(l, fmt, d.excelAt, d.excelError),
                      Section.excel,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: statusCard(
                      l.statusSync,
                      d.syncAt == null
                          ? l.statusNotYet
                          : fmt.dateTime(d.syncAt!),
                      Section.sync,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.recentEntries,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => shell.goTo(Section.income),
                          child: Text(l.seeAll),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(l.colType, style: _head),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(l.colReceiptNo, style: _head),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(l.colDate, style: _head),
                        ),
                        Expanded(child: Text(l.colNameOrPurpose, style: _head)),
                        SizedBox(
                          width: 130,
                          child: Text(
                            l.colAmount,
                            textAlign: TextAlign.right,
                            style: _head,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final e in d.recent)
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EntryDetailsScreen(entryId: e.id),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: e.type == EntryType.income
                                    ? StatusPill(l.typeIncome)
                                    : StatusPill.expense(l.typeExpense),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Text(
                                fmt.integer(e.receiptNo),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Text(
                                fmt.date(parseDayKey(e.entryDate)),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.type == EntryType.expense &&
                                        (e.purpose ?? '').isNotEmpty
                                    ? '${displayName(l, e)} · ${e.purpose}'
                                    : displayName(l, e),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(
                              width: 130,
                              child: Text(
                                fmt.money(e.amount),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: e.status == EntryStatus.cancelled
                                      ? AppColors.muted
                                      : AppColors.text,
                                  decoration: e.status == EntryStatus.cancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (d.recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.noEntries,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _head = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
}
