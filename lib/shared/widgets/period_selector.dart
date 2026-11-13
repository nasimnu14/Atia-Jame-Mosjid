import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../context_ext.dart';
import '../formatters.dart';
import '../period.dart';
import '../period_choice.dart';
import 'basics.dart';
import 'date_form_field.dart';

/// "Today / this week / this month / this year / a chosen day, week, month or
/// year / a date range" (FND-4, FND-5, PDF-1, XLS-3).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.today,
    this.showSpecific = true,
  });

  final PeriodChoice value;
  final ValueChanged<PeriodChoice> onChanged;
  final DateTime today;
  final bool showSpecific;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final modes = [
      (PeriodMode.today, l.periodToday),
      (PeriodMode.week, l.periodWeek),
      (PeriodMode.month, l.periodMonth),
      (PeriodMode.year, l.periodYear),
      if (showSpecific) (PeriodMode.specific, l.periodSpecific),
      (PeriodMode.range, l.periodRange),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        container: true,
        label: l.periodLabel,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (mode, label) in modes)
            _Chip(
              label: label,
              on: value.mode == mode,
              onTap: () => onChanged(_select(mode)),
            ),
        ]),
      ),
      if (value.mode == PeriodMode.specific) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: 220,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.periodSpecific,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<SpecificUnit>(
                initialValue: value.unit,
                items: [
                  DropdownMenuItem(value: SpecificUnit.day, child: Text(l.unitDay)),
                  DropdownMenuItem(value: SpecificUnit.week, child: Text(l.unitWeek)),
                  DropdownMenuItem(value: SpecificUnit.month, child: Text(l.unitMonth)),
                  DropdownMenuItem(value: SpecificUnit.year, child: Text(l.unitYear)),
                ],
                onChanged: (u) => onChanged(value.copyWith(unit: u)),
              ),
            ]),
          ),
          SizedBox(
            width: 240,
            child: DateFormField(
              label: l.pickAnyDate,
              compact: true,
              value: value.anchor,
              onChanged: (d) => onChanged(d == null
                  ? value.copyWith(clearAnchor: true)
                  : value.copyWith(anchor: d)),
            ),
          ),
        ]),
      ],
      if (value.mode == PeriodMode.range) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: 240,
            child: DateFormField(
              label: l.dateFrom,
              compact: true,
              value: value.from,
              onChanged: (d) => onChanged(
                  d == null ? value.copyWith(clearFrom: true) : value.copyWith(from: d)),
            ),
          ),
          SizedBox(
            width: 240,
            child: DateFormField(
              label: l.dateTo,
              compact: true,
              value: value.to,
              onChanged: (d) => onChanged(
                  d == null ? value.copyWith(clearTo: true) : value.copyWith(to: d)),
            ),
          ),
        ]),
        if (value.rangeReversed) ...[
          const SizedBox(height: 8),
          MessageBanner(l.rangeInvalid, kind: BannerKind.error),
        ],
      ],
    ]);
  }

  /// Switching mode keeps sensible dates: a chosen day starts at today, a range
  /// starts as the current month.
  PeriodChoice _select(PeriodMode mode) {
    var next = value.copyWith(mode: mode);
    if (mode == PeriodMode.specific && next.anchor == null) {
      next = next.copyWith(anchor: today);
    }
    if (mode == PeriodMode.range && (next.from == null || next.to == null)) {
      final m = Period.monthOf(today);
      next = next.copyWith(from: m.from, to: m.to);
    }
    return next;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? AppColors.primary : Colors.white,
          shape: StadiumBorder(
              side: BorderSide(color: on ? AppColors.primary : AppColors.inputBorder)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 38),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 14, color: on ? Colors.white : AppColors.text)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// A readable name for a choice: "মাস: নভেম্বর ২০২৬", "০১/১১/২০২৬ – ৩০/১১/২০২৬".
String periodChoiceName(
    AppLocalizations l, Fmt fmt, PeriodChoice c, DateTime today) {
  final p = c.resolve(today);
  if (p == null) return '';
  switch (c.mode) {
    case PeriodMode.today:
      return l.periodDayName(fmt.date(p.from));
    case PeriodMode.week:
      return l.periodWeekName(fmt.date(p.from), fmt.date(p.to));
    case PeriodMode.month:
      return l.periodMonthName(fmt.monthYear(p.from));
    case PeriodMode.year:
      return l.periodYearName(fmt.integer(p.from.year));
    case PeriodMode.specific:
      return switch (c.unit) {
        SpecificUnit.day => l.periodDayName(fmt.date(p.from)),
        SpecificUnit.week => l.periodWeekName(fmt.date(p.from), fmt.date(p.to)),
        SpecificUnit.month => l.periodMonthName(fmt.monthYear(p.from)),
        SpecificUnit.year => l.periodYearName(fmt.integer(p.from.year)),
      };
    case PeriodMode.range:
      return l.periodRangeName(fmt.date(p.from), fmt.date(p.to));
  }
}
