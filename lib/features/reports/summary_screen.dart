import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/desktop_shell.dart';
import '../../app/shell_controller.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/period_choice.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/period_selector.dart';
import 'balance_service.dart';

/// Total income, total expense and income − expense for any period (BAL-4),
/// with a table by day, week or month.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  PeriodChoice _choice = const PeriodChoice.currentMonth();
  PeriodSummary? _summary;
  BreakdownUnit? _unit;
  List<BreakdownRow> _rows = const [];
  int _balance = 0;
  StreamSubscription<void>? _sub;
  int _generation = 0;

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
    final services = context.services;
    final period = _choice.resolve(dateOnly(services.now()));
    final gen = ++_generation;
    final balance = await services.balance.currentBalance();
    PeriodSummary? summary;
    BreakdownUnit? unit;
    var rows = <BreakdownRow>[];
    if (period != null) {
      summary = await services.balance.summary(period);
      final b = await services.balance.breakdown(period);
      unit = b.$1;
      rows = b.$2;
    }
    if (!mounted || gen != _generation) return;
    setState(() {
      _summary = summary;
      _unit = unit;
      _rows = rows;
      _balance = balance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final today = dateOnly(context.services.now());
    final s = _summary;
    final shell = context.read<ShellController>();
    final periodName = periodChoiceName(l, fmt, _choice, today);

    Widget card(
      String title,
      String value,
      String note, {
      Color? color,
      bool strong = false,
    }) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: strong ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: strong ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: strong ? AppColors.onPrimaryMuted : AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: strong ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              color: strong ? AppColors.onPrimaryMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );

    return PageScaffold(
      title: l.navSummary,
      actions: [
        FilledButton(
          onPressed: () => shell.goTo(Section.pdf),
          child: Text(l.makePdf),
        ),
        // The phone does not upload Excel files (the desktop holds all the records).
        if (!context.services.isPhone)
          OutlinedButton(
            onPressed: () => shell.goTo(Section.excel),
            child: Text(l.excelUploadBtn),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: PeriodSelector(
              value: _choice,
              today: today,
              onChanged: (c) {
                setState(() => _choice = c);
                _load();
              },
            ),
          ),
          const SizedBox(height: 18),
          // MOB-3: on the phone these figures are only for this phone's entries.
          if (context.services.isPhone) ...[
            MessageBanner(l.phoneOnlyNote, kind: BannerKind.warn),
            const SizedBox(height: 14),
          ],
          if (s == null)
            MessageBanner(l.completePeriod, kind: BannerKind.info)
          else ...[
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 720 ? 3 : 1;
                final w = (c.maxWidth - (cols - 1) * 14) / cols;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: w,
                      child: card(
                        l.totalIncome,
                        fmt.money(s.incomeTotal),
                        l.entriesCount(fmt.integer(s.incomeCount)),
                        color: AppColors.income,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: card(
                        l.totalExpense,
                        fmt.money(s.expenseTotal),
                        l.entriesCount(fmt.integer(s.expenseCount)),
                        color: AppColors.expense,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: card(
                        l.incomeMinusExpense,
                        fmt.signedMoney(s.net),
                        s.net >= 0 ? l.surplusNote : l.deficitNote,
                        strong: true,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              l.summaryNote(fmt.money(_balance)),
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            _breakdown(l, fmt, periodName, s),
          ],
        ],
      ),
    );
  }

  Widget _breakdown(
    AppLocalizations l,
    Fmt fmt,
    String periodName,
    PeriodSummary total,
  ) {
    final title = switch (_unit!) {
      BreakdownUnit.day => l.breakdownDays(periodName),
      BreakdownUnit.week => l.breakdownWeeks(periodName),
      BreakdownUnit.month => l.breakdownMonths(periodName),
    };
    final firstCol = switch (_unit!) {
      BreakdownUnit.day => l.unitDay,
      BreakdownUnit.week => l.unitWeek,
      BreakdownUnit.month => l.unitMonth,
    };
    String label(BreakdownRow r) {
      final p = r.period;
      return switch (_unit!) {
        BreakdownUnit.day => fmt.date(p.from),
        BreakdownUnit.week => '${fmt.date(p.from)} – ${fmt.date(p.to)}',
        BreakdownUnit.month => fmt.monthYear(p.from),
      };
    }

    Widget cells(
      List<Widget> c, {
      bool header = false,
      bool strongTop = false,
    }) => Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: header ? 10 : 12),
      decoration: BoxDecoration(
        color: header ? AppColors.background : null,
        border: header
            ? null
            : Border(
                top: BorderSide(
                  color: strongTop ? AppColors.border : AppColors.divider,
                  width: strongTop ? 2 : 1,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(child: c[0]),
          for (final x in c.skip(1)) SizedBox(width: 150, child: x),
        ],
      ),
    );
    TextStyle head() => const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.muted,
    );
    Text right(String t, {TextStyle? style}) =>
        Text(t, textAlign: TextAlign.right, style: style);
    Color netColor(int n) => n < 0 ? AppColors.expense : AppColors.income;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Scrolls sideways on a narrow screen (a phone).
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: c.maxWidth < 640 ? 640 : c.maxWidth,
                  child: Column(
                    children: [
                      cells([
                        Text(firstCol, style: head()),
                        right(l.navIncome, style: head()),
                        right(l.navExpense, style: head()),
                        right(l.incomeMinusExpense, style: head()),
                      ], header: true),
                      for (final r in _rows)
                        cells([
                          Text(label(r), style: const TextStyle(fontSize: 14)),
                          right(fmt.money(r.summary.incomeTotal)),
                          right(fmt.money(r.summary.expenseTotal)),
                          right(
                            fmt.signedMoney(r.summary.net),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: netColor(r.summary.net),
                            ),
                          ),
                        ]),
                      cells([
                        Text(
                          l.rowTotal,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        right(
                          fmt.money(total.incomeTotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        right(
                          fmt.money(total.expenseTotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        right(
                          fmt.signedMoney(total.net),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: netColor(total.net),
                          ),
                        ),
                      ], strongTop: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
