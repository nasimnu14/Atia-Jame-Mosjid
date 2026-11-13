import 'bangla.dart';

enum AmountProblem { empty, notWholeNumber, notPositive, tooLarge }

class AmountParseResult {
  const AmountParseResult.ok(int this.taka) : problem = null;
  const AmountParseResult.error(AmountProblem this.problem) : taka = null;
  final int? taka;
  final AmountProblem? problem;
  bool get isOk => taka != null;
}

const maxAmountTaka = 999999999999;

/// Reads a typed amount: Bangla or English digits, optional ৳ and commas.
/// Whole Taka only (plan rule 3); must be more than 0 (INC-2, EXP-2).
AmountParseResult parseAmount(String input) {
  var t = toEnglishDigits(input).replaceAll('৳', '').replaceAll(',', '');
  t = t.replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return const AmountParseResult.error(AmountProblem.empty);
  if (!RegExp(r'^\d+$').hasMatch(t)) {
    return const AmountParseResult.error(AmountProblem.notWholeNumber);
  }
  if (t.length > 12) return const AmountParseResult.error(AmountProblem.tooLarge);
  final n = int.parse(t);
  if (n <= 0) return const AmountParseResult.error(AmountProblem.notPositive);
  return AmountParseResult.ok(n);
}
