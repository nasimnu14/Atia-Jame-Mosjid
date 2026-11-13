import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/shared/bangla.dart';
import 'package:atia_masjid_accounts/shared/formatters.dart';
import 'package:atia_masjid_accounts/shared/money_parse.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:atia_masjid_accounts/shared/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bangla digits both ways (GEN-4)', () {
    expect(toBanglaDigits('13/11/2026'), '১৩/১১/২০২৬');
    expect(toEnglishDigits('১৩/১১/২০২৬ abc'), '13/11/2026 abc');
    expect(toEnglishDigits(toBanglaDigits('0123456789')), '0123456789');
  });

  group('formatting', () {
    test('money uses Taka and Bangladeshi grouping (GEN-4, GEN-5)', () {
      expect(const Fmt.bn().money(5000), '৳ ৫,০০০');
      expect(const Fmt.bn().money(487250), '৳ ৪,৮৭,২৫০');
      expect(const Fmt.en().money(487250), '৳ 4,87,250');
      expect(const Fmt.en().money(12), '৳ 12');
      expect(const Fmt.en().money(1234567), '৳ 12,34,567');
      expect(const Fmt.bn().money(0), '৳ ০');
    });
    test('dates', () {
      expect(const Fmt.bn().date(DateTime(2026, 11, 13)), '১৩/১১/২০২৬');
      expect(const Fmt.en().date(DateTime(2026, 1, 5)), '05/01/2026');
      expect(const Fmt.bn().longDate(DateTime(2026, 11, 13)),
          'শুক্রবার, ১৩ নভেম্বর ২০২৬');
    });
    test('day keys sort as text', () {
      expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
      expect(parseDayKey('2026-03-05'), DateTime(2026, 3, 5));
    });
  });

  group('amounts (INC-2, EXP-2, plan rule 3)', () {
    test('accepts Bangla/English digits, commas and the Taka sign', () {
      expect(parseAmount('৳ ২,০০০').taka, 2000);
      expect(parseAmount('2000').taka, 2000);
      expect(parseAmount(' 1,00,000 ').taka, 100000);
    });
    test('refuses zero, negative, decimals, text, empty', () {
      expect(parseAmount('0').problem, AmountProblem.notPositive);
      expect(parseAmount('-5').problem, AmountProblem.notWholeNumber);
      expect(parseAmount('12.5').problem, AmountProblem.notWholeNumber);
      expect(parseAmount('abc').problem, AmountProblem.notWholeNumber);
      expect(parseAmount('').problem, AmountProblem.empty);
      expect(parseAmount('9999999999999').problem, AmountProblem.tooLarge);
    });
  });

  group('periods (FND-4); the week starts on Saturday', () {
    test('Friday 13 Nov 2026 falls in the week Sat 7 to Fri 13', () {
      final w = Period.weekOf(DateTime(2026, 11, 13));
      expect(w.from, DateTime(2026, 11, 7));
      expect(w.to, DateTime(2026, 11, 13));
    });
    test('Saturday starts a new week; Sunday is day 2', () {
      expect(Period.weekOf(DateTime(2026, 11, 14)).from, DateTime(2026, 11, 14));
      expect(Period.weekOf(DateTime(2026, 11, 15)).from, DateTime(2026, 11, 14));
      expect(Period.weekOf(DateTime(2026, 11, 14)).to, DateTime(2026, 11, 20));
    });
    test('week across a month end', () {
      final w = Period.weekOf(DateTime(2026, 12, 2));
      expect(w.from, DateTime(2026, 11, 28));
      expect(w.to, DateTime(2026, 12, 4));
    });
    test('month and year, including February of a leap year', () {
      expect(Period.monthOf(DateTime(2024, 2, 10)).to, DateTime(2024, 2, 29));
      expect(Period.monthOf(DateTime(2026, 12, 10)).to, DateTime(2026, 12, 31));
      expect(Period.yearOf(DateTime(2026, 6, 1)).from, DateTime(2026, 1, 1));
    });
    test('contains is inclusive and ignores time of day', () {
      final p = Period.monthOf(DateTime(2026, 11, 1));
      expect(p.contains(DateTime(2026, 11, 30, 23, 59)), isTrue);
      expect(p.contains(DateTime(2026, 12, 1)), isFalse);
    });
  });

  group('role permissions (USR-2 table)', () {
    const user = {
      Permission.addEntry, Permission.viewEntries, Permission.syncPhone,
      Permission.changeOwnPassword,
    };
    const adminExtra = {
      Permission.editEntry, Permission.cancelEntry, Permission.setOpeningBalance,
      Permission.manageApprovers, Permission.manageBackupAndSettings,
    };
    const superOnly = {Permission.restoreBackup, Permission.manageUsers};

    test('User', () {
      for (final p in Permission.values) {
        expect(can(Role.user, p), user.contains(p), reason: p.name);
      }
    });
    test('Admin', () {
      for (final p in Permission.values) {
        expect(can(Role.admin, p), user.contains(p) || adminExtra.contains(p),
            reason: p.name);
      }
    });
    test('Super Admin can do everything', () {
      for (final p in Permission.values) {
        expect(can(Role.superAdmin, p), isTrue, reason: p.name);
      }
      expect(superOnly.every((p) => !can(Role.admin, p)), isTrue);
    });
    test('requirePermission throws', () {
      expect(() => requirePermission(Role.user, Permission.editEntry),
          throwsA(isA<PermissionDeniedException>()));
    });
  });
}
