import 'bangla.dart';

const _bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', //
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];
const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];
// Index = DateTime.weekday - 1 (Monday = 0).
const _bnWeekdays = [
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];
const _enWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The one place that decides how numbers, money and dates look.
/// In Bangla mode everything uses Bangla digits (GEN-4); amounts are always
/// Taka (GEN-5).
class Fmt {
  const Fmt({required this.bangla});
  const Fmt.bn() : bangla = true;
  const Fmt.en() : bangla = false;

  final bool bangla;

  /// Applies the language's digits to text that already holds digits.
  String digits(String s) => bangla ? toBanglaDigits(s) : s;

  String integer(int n) => digits(n.toString());

  /// Bangladeshi grouping: 487250 → 4,87,250.
  String number(int n) {
    final neg = n < 0;
    final s = n.abs().toString();
    String out;
    if (s.length <= 3) {
      out = s;
    } else {
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final parts = <String>[];
      var h = head;
      while (h.length > 2) {
        parts.insert(0, h.substring(h.length - 2));
        h = h.substring(0, h.length - 2);
      }
      if (h.isNotEmpty) parts.insert(0, h);
      out = '${parts.join(',')},$tail';
    }
    return digits(neg ? '-$out' : out);
  }

  /// "৳ ৫,০০০"
  String money(int taka) =>
      taka < 0 ? '−৳ ${number(-taka)}' : '৳ ${number(taka)}';

  /// Signed money for income − expense: "+ ৳ ৫০০" / "− ৳ ৫০০".
  String signedMoney(int taka) => taka < 0
      ? '− ৳ ${number(-taka)}'
      : taka == 0
      ? '৳ ${number(0)}'
      : '+ ৳ ${number(taka)}';

  /// DD/MM/YYYY (GEN-7).
  String date(DateTime d) => digits(
    '${_two(d.day)}/${_two(d.month)}/${d.year.toString().padLeft(4, '0')}',
  );

  String time(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final pm = d.hour >= 12;
    final mm = _two(d.minute);
    if (bangla) {
      final part = d.hour < 4
          ? 'রাত'
          : d.hour < 6
          ? 'ভোর'
          : d.hour < 12
          ? 'সকাল'
          : d.hour < 15
          ? 'দুপুর'
          : d.hour < 18
          ? 'বিকাল'
          : d.hour < 20
          ? 'সন্ধ্যা'
          : 'রাত';
      return '$part ${digits('$h12:$mm')}';
    }
    return '$h12:$mm ${pm ? 'PM' : 'AM'}';
  }

  String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  String monthName(int month) => (bangla ? _bnMonths : _enMonths)[month - 1];

  String monthYear(DateTime d) =>
      '${monthName(d.month)} ${digits('${d.year}')}';

  String weekday(DateTime d) =>
      (bangla ? _bnWeekdays : _enWeekdays)[d.weekday - 1];

  /// "শুক্রবার, ১৩ নভেম্বর ২০২৬"
  String longDate(DateTime d) =>
      '${weekday(d)}, ${digits('${d.day}')} ${monthName(d.month)} ${digits('${d.year}')}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// `yyyy-MM-dd` key stored in the database (compares correctly as text).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Calendar day without a time, in local time.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
