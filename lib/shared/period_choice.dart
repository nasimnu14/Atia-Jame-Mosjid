import 'formatters.dart';
import 'period.dart';

enum PeriodMode { today, week, month, year, specific, range }

enum SpecificUnit { day, week, month, year }

/// What the user picked in a period selector (FND-4, FND-5): a quick period
/// for today, any chosen day / week / month / year, or a date range.
class PeriodChoice {
  const PeriodChoice({
    this.mode = PeriodMode.month,
    this.unit = SpecificUnit.month,
    this.anchor,
    this.from,
    this.to,
  });

  /// The default for entry lists: the current month (FND-6).
  const PeriodChoice.currentMonth() : this();

  final PeriodMode mode;

  /// For [PeriodMode.specific]: which unit, and any date inside it.
  final SpecificUnit unit;
  final DateTime? anchor;

  /// For [PeriodMode.range].
  final DateTime? from;
  final DateTime? to;

  PeriodChoice copyWith({
    PeriodMode? mode,
    SpecificUnit? unit,
    DateTime? anchor,
    bool clearAnchor = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) =>
      PeriodChoice(
        mode: mode ?? this.mode,
        unit: unit ?? this.unit,
        anchor: clearAnchor ? null : (anchor ?? this.anchor),
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );

  /// The dates this choice stands for, or null while it is incomplete or
  /// wrong (a range with a missing end, or an end before the start).
  Period? resolve(DateTime today) {
    final t = dateOnly(today);
    switch (mode) {
      case PeriodMode.today:
        return Period.day(t);
      case PeriodMode.week:
        return Period.weekOf(t);
      case PeriodMode.month:
        return Period.monthOf(t);
      case PeriodMode.year:
        return Period.yearOf(t);
      case PeriodMode.specific:
        final a = anchor;
        if (a == null) return null;
        return switch (unit) {
          SpecificUnit.day => Period.day(a),
          SpecificUnit.week => Period.weekOf(a),
          SpecificUnit.month => Period.monthOf(a),
          SpecificUnit.year => Period.yearOf(a),
        };
      case PeriodMode.range:
        final f = from, e = to;
        if (f == null || e == null || e.isBefore(f)) return null;
        return Period(dateOnly(f), dateOnly(e));
    }
  }

  /// True when both ends of a range are filled in but the wrong way round.
  bool get rangeReversed =>
      mode == PeriodMode.range &&
      from != null &&
      to != null &&
      to!.isBefore(from!);
}
