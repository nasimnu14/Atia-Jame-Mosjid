import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../data/tables.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/period.dart';
import '../../shared/widgets/basics.dart';
import '../entries/entry_details_screen.dart';
import '../entries/entry_form_screen.dart';
import '../entries/entry_text.dart';
import '../sync/sync_scan_screen.dart';

/// The phone's home: balance of THIS PHONE's entries only, with a clear note
/// that it is not the mosque's balance (MOB-3), the sync status, and the two
/// "new" buttons.
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _income = 0, _expense = 0, _pending = 0;
  DateTime? _lastSync;
  List<Entry> _recent = const [];
  StreamSubscription<void>? _sub;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null) {
      _sub = context.services.entries.changes.listen((_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final s = context.services;
    final sum = await s.balance.summary(Period(DateTime(2000), DateTime(2200)));
    final pending = await s.syncClient.pendingCount();
    final last = await s.syncClient.lastSync();
    final recent = await s.entries.recent(limit: 6);
    if (!mounted) {
      return;
    }
    setState(() {
      _income = sum.incomeTotal;
      _expense = sum.expenseTotal;
      _pending = pending;
      _lastSync = last;
      _recent = recent;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    if (!_loaded) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MessageBanner(l.phoneOnlyNote, kind: BannerKind.warn),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.phoneBalance,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onPrimaryMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fmt.money(_income - _expense),
                key: const Key('phone-balance'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                l.phoneIncomeExpense(fmt.money(_income), fmt.money(_expense)),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onPrimaryMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(14),
          radius: 14,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.syncPending(fmt.integer(_pending)),
                      key: const Key('sync-pending'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.lastSyncLine(
                        _lastSync == null ? l.never : fmt.dateTime(_lastSync!),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SyncScanScreen()),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                child: Text(l.syncNowBtn),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _bigButton(
                l.newIncome,
                AppColors.incomeSoft,
                AppColors.income,
                () => _open(const EntryFormScreen(type: EntryType.income)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigButton(
                l.newExpense,
                AppColors.expenseSoft,
                AppColors.expense,
                () => _open(const EntryFormScreen(type: EntryType.expense)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l.recentEntries,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final e in _recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _open(EntryDetailsScreen(entryId: e.id)),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                radius: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.type == EntryType.expense &&
                                    (e.purpose ?? '').isNotEmpty
                                ? '${displayName(l, e)} · ${e.purpose}'
                                : displayName(l, e),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${e.type == EntryType.income ? l.typeIncome : l.typeExpense} · ${receiptNoLabel(l, e.type)} ${fmt.integer(e.receiptNo)} · ${fmt.date(parseDayKey(e.entryDate))}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${e.type == EntryType.income ? '+' : '−'} ${fmt.money(e.amount)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: e.type == EntryType.income
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        e.synced
                            ? StatusPill(l.syncedPill)
                            : StatusPill.warn(l.pendingPill),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_recent.isEmpty)
          Text(l.noEntries, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Widget _bigButton(String label, Color bg, Color fg, VoidCallback onTap) =>
      Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      );
}
