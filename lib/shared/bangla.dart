const _bnDigits = '০১২৩৪৫৬৭৮৯';

/// "123" → "১২৩". Leaves every other character alone.
String toBanglaDigits(String s) =>
    s.replaceAllMapped(RegExp('[0-9]'), (m) => _bnDigits[int.parse(m[0]!)]);

/// "১২৩" → "123" (GEN-8: typed dates and amounts may use Bangla digits).
String toEnglishDigits(String s) => s.replaceAllMapped(
  RegExp('[০-৯]'),
  (m) => _bnDigits.indexOf(m[0]!).toString(),
);
