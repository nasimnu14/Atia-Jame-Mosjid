import 'bangla.dart';

enum DateParseProblem {
  /// Nothing typed.
  empty,

  /// Not three numbers like DD/MM/YYYY.
  format,

  /// Month is not 1 to 12.
  month,

  /// The day does not exist in that month (e.g. 31/02/2026).
  dayNotInMonth,

  /// Year outside 1900..2200.
  year,
}

class DateParseResult {
  const DateParseResult.ok(DateTime this.date)
      : problem = null,
        maxDay = null,
        month = null,
        year = null;
  const DateParseResult.error(DateParseProblem this.problem,
      {this.maxDay, this.month, this.year})
      : date = null;

  final DateTime? date;
  final DateParseProblem? problem;

  /// For [DateParseProblem.dayNotInMonth]: how many days that month has, so the
  /// message can say why the date was refused (GEN-8).
  final int? maxDay;
  final int? month;
  final int? year;

  bool get isOk => date != null;
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Reads a typed date (GEN-7, GEN-8): DD/MM/YYYY, with `/`, `-`, `.` or spaces
/// as separators, Bangla or English digits. A date that does not exist is
/// refused with the reason.
DateParseResult parseTypedDate(String input) {
  final text = toEnglishDigits(input.trim());
  if (text.isEmpty) return const DateParseResult.error(DateParseProblem.empty);
  final m = RegExp(r'^(\d{1,2})\s*[/\-.\s]\s*(\d{1,2})\s*[/\-.\s]\s*(\d{4})$')
      .firstMatch(text);
  if (m == null) return const DateParseResult.error(DateParseProblem.format);
  final d = int.parse(m[1]!);
  final mo = int.parse(m[2]!);
  final y = int.parse(m[3]!);
  if (y < 1900 || y > 2200) {
    return DateParseResult.error(DateParseProblem.year, year: y);
  }
  if (mo < 1 || mo > 12) {
    return DateParseResult.error(DateParseProblem.month, month: mo);
  }
  final max = daysInMonth(y, mo);
  if (d < 1 || d > max) {
    return DateParseResult.error(DateParseProblem.dayNotInMonth,
        maxDay: max, month: mo, year: y);
  }
  return DateParseResult.ok(DateTime(y, mo, d));
}
