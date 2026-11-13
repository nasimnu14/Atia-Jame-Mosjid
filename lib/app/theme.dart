import 'package:flutter/material.dart';

/// Colours from the screen designs.
abstract final class AppColors {
  static const primary = Color(0xFF0F5C46);
  static const primaryDark = Color(0xFF0F3D30);
  static const primaryDarker = Color(0xFF164B3B);
  static const income = Color(0xFF0B5D4B);
  static const incomeSoft = Color(0xFFE3F0EA);
  static const expense = Color(0xFF9A3709);
  static const expenseSoft = Color(0xFFFBEBDD);
  static const expenseBorder = Color(0xFFE8B898);
  static const background = Color(0xFFF4F6F3);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE3DF);
  static const inputBorder = Color(0xFFC9D3CE);
  static const divider = Color(0xFFEEF2F0);
  static const text = Color(0xFF1C2B26);
  static const muted = Color(0xFF5B6B65);
  static const mutedStrong = Color(0xFF3D4C46);
  static const warnBg = Color(0xFFFFF1CC);
  static const warnText = Color(0xFF6B4700);
  static const warnBorder = Color(0xFFC98A00);
  static const cancelledBg = Color(0xFFFBE4E4);
  static const cancelledText = Color(0xFF8E1F24);
  static const neutralPill = Color(0xFFE6ECE9);
  static const onPrimaryMuted = Color(0xFFD3E8DE);
  static const navMuted = Color(0xFFB8CEC4);
}

const kFontFamily = 'HindSiliguri';

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.expense,
    surface: AppColors.card,
    onSurface: AppColors.text,
    error: AppColors.cancelledText,
    outline: AppColors.inputBorder,
    outlineVariant: AppColors.border,
  );
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: AppColors.inputBorder),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.divider,
    textTheme: ThemeData.light().textTheme.apply(
          fontFamily: kFontFamily,
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.cancelledText)),
      focusedErrorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.cancelledText, width: 2)),
      errorMaxLines: 3,
      helperMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
            fontFamily: kFontFamily, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: kFontFamily, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontFamily: kFontFamily, fontSize: 14),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
