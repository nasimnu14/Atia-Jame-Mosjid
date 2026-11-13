import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GEN-2: every screen and message exists in both Bangla and English.
void main() {
  final en =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final bn =
      jsonDecode(File('lib/l10n/app_bn.arb').readAsStringSync())
          as Map<String, dynamic>;
  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();
  Set<String> placeholders(String s) =>
      RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

  test('both languages have exactly the same keys', () {
    expect(keys(bn).difference(keys(en)), isEmpty, reason: 'only in Bangla');
    expect(keys(en).difference(keys(bn)), isEmpty, reason: 'only in English');
  });

  test('no empty text, and the same placeholders in both', () {
    for (final k in keys(en)) {
      expect((en[k] as String).trim(), isNotEmpty, reason: 'en $k');
      expect((bn[k] as String).trim(), isNotEmpty, reason: 'bn $k');
      expect(
        placeholders(bn[k] as String),
        placeholders(en[k] as String),
        reason: k,
      );
    }
  });

  test(
    'Bangla text is really Bangla, not copied English (except brand words)',
    () {
      const sameOk = {
        'langEnglish',
        'langBangla',
        'switchLanguage',
        'periodRangeName',
      };
      final bangla = RegExp('[ঀ-৿]');
      for (final k in keys(bn)) {
        if (sameOk.contains(k)) continue;
        expect(
          bangla.hasMatch(bn[k] as String),
          isTrue,
          reason: 'bn $k = ${bn[k]}',
        );
      }
    },
  );
}
