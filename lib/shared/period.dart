import 'formatters.dart';

enum PeriodKind {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  day,
  week,
  month,
  year,
  range,
}

/// A date range, both ends included (FND-4, FND-5).
class Period {
  const Period(this.from, this.to);
  final DateTime from;
  final DateTime to;

  bool contains(DateTime d) {
    final x = dateOnly(d);
    return !x.isBefore(from) && !x.isAfter(to);
  }

  @override
  bool operator ==(Object other) =>
      other is Period && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
  @override
  String toString() => 'Period(${dayKey(from)}..${dayKey(to)})';

  static Period day(DateTime d) => Period(dateOnly(d), dateOnly(d));

  /// The week starts on Saturday (Constraints & Assumptions).
  static Period weekOf(DateTime d) {
    final x = dateOnly(d);
    // DateTime.weekday: Mon=1 .. Sat=6, Sun=7. Days since Saturday:
    final sinceSat = (x.weekday + 1) % 7;
    final start = DateTime(x.year, x.month, x.day - sinceSat);
    return Period(start, DateTime(start.year, start.month, start.day + 6));
  }

  static Period monthOf(DateTime d) =>
      Period(DateTime(d.year, d.month, 1), DateTime(d.year, d.month + 1, 0));

  static Period yearOf(DateTime d) =>
      Period(DateTime(d.year, 1, 1), DateTime(d.year, 12, 31));

  /// Resolves a quick period for "today" (FND-4).
  static Period forKind(PeriodKind kind, DateTime anchor) => switch (kind) {
    PeriodKind.today || PeriodKind.day => day(anchor),
    PeriodKind.thisWeek || PeriodKind.week => weekOf(anchor),
    PeriodKind.thisMonth || PeriodKind.month => monthOf(anchor),
    PeriodKind.thisYear || PeriodKind.year => yearOf(anchor),
    PeriodKind.range => day(anchor),
  };
}
