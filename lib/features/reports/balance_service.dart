import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../../data/tables.dart';
import '../../features/settings/settings_service.dart';
import '../../shared/formatters.dart';
import '../../shared/period.dart';

class PeriodSummary {
  const PeriodSummary({
    required this.incomeTotal,
    required this.incomeCount,
    required this.expenseTotal,
    required this.expenseCount,
    required this.cancelledCount,
  });

  /// Cancelled entries are left out of totals and counts (EDT-4).
  final int incomeTotal;
  final int incomeCount;
  final int expenseTotal;
  final int expenseCount;
  final int cancelledCount;

  /// Income − expense (BAL-4).
  int get net => incomeTotal - expenseTotal;
}

/// One row of a breakdown: a day, a week or a month, with its totals.
class BreakdownRow {
  const BreakdownRow(this.period, this.summary);
  final Period period;
  final PeriodSummary summary;
}

enum BreakdownUnit { day, week, month }

/// Splits a period into the pieces a summary table shows: days for a week or
/// less, weeks (Saturday to Friday, cut at the period's ends) for up to about
/// two months, otherwise months.
(BreakdownUnit, List<Period>) breakdownBuckets(Period p) {
  final days = p.to.difference(p.from).inDays + 1;
  final out = <Period>[];
  if (days <= 7) {
    for (
      var d = p.from;
      !d.isAfter(p.to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      out.add(Period.day(d));
    }
    return (BreakdownUnit.day, out);
  }
  if (days <= 62) {
    var start = p.from;
    while (!start.isAfter(p.to)) {
      final weekEnd = Period.weekOf(start).to;
      final end = weekEnd.isAfter(p.to) ? p.to : weekEnd;
      out.add(Period(start, end));
      start = DateTime(end.year, end.month, end.day + 1);
    }
    return (BreakdownUnit.week, out);
  }
  var start = p.from;
  while (!start.isAfter(p.to)) {
    final monthEnd = Period.monthOf(start).to;
    final end = monthEnd.isAfter(p.to) ? p.to : monthEnd;
    out.add(Period(start, end));
    start = DateTime(end.year, end.month, end.day + 1);
  }
  return (BreakdownUnit.month, out);
}

/// Current balance and period summaries (BAL-3, BAL-4).
class BalanceService {
  BalanceService(this._db, this._settings);
  final AppDatabase _db;
  final SettingsService _settings;

  /// Current balance = opening balance + all income − all expense. Cancelled
  /// entries are not counted.
  Future<int> currentBalance() async {
    final opening = (await _settings.openingBalance())?.amount ?? 0;
    final all = await _sums(null);
    return opening + all.income - all.expense;
  }

  Future<PeriodSummary> summary(Period period) async {
    final r = await _sums(period);
    final e = _db.entries;
    final cnt = e.id.count();
    final cq = _db.selectOnly(e)
      ..addColumns([cnt])
      ..where(
        e.status.equalsValue(EntryStatus.cancelled) &
            e.entryDate.isBiggerOrEqualValue(dayKey(period.from)) &
            e.entryDate.isSmallerOrEqualValue(dayKey(period.to)),
      );
    final cancelled = (await cq.getSingle()).read(cnt) ?? 0;
    return PeriodSummary(
      incomeTotal: r.income,
      incomeCount: r.incomeCount,
      expenseTotal: r.expense,
      expenseCount: r.expenseCount,
      cancelledCount: cancelled,
    );
  }

  /// The summary table under a period: one row per day, week or month.
  Future<(BreakdownUnit, List<BreakdownRow>)> breakdown(Period period) async {
    final (unit, buckets) = breakdownBuckets(period);
    return (unit, [for (final b in buckets) BreakdownRow(b, await summary(b))]);
  }

  Future<({int income, int incomeCount, int expense, int expenseCount})> _sums(
    Period? period,
  ) async {
    final e = _db.entries;
    final sum = e.amount.sum();
    final cnt = e.id.count();
    final q = _db.selectOnly(e)
      ..addColumns([e.type, sum, cnt])
      ..where(
        e.status.equalsValue(EntryStatus.active) &
            (period == null
                ? const Constant(true)
                : e.entryDate.isBiggerOrEqualValue(dayKey(period.from)) &
                      e.entryDate.isSmallerOrEqualValue(dayKey(period.to))),
      )
      ..groupBy([e.type]);
    var income = 0, expense = 0, ic = 0, ec = 0;
    for (final row in await q.get()) {
      final type = row.read(e.type);
      if (type == EntryType.income.name) {
        income = row.read(sum) ?? 0;
        ic = row.read(cnt) ?? 0;
      } else {
        expense = row.read(sum) ?? 0;
        ec = row.read(cnt) ?? 0;
      }
    }
    return (
      income: income,
      incomeCount: ic,
      expense: expense,
      expenseCount: ec,
    );
  }
}
