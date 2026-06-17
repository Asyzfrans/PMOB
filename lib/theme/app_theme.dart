import 'package:flutter/material.dart';

// DonateID Brand Colors — biru/putih
class AppColors {
  // Brand (blue)
  static const brand50  = Color(0xFFEFF6FF);
  static const brand100 = Color(0xFFDBEAFE);
  static const brand200 = Color(0xFFBFDBFE);
  static const brand300 = Color(0xFF93C5FD);
  static const brand400 = Color(0xFF60A5FA);
  static const brand500 = Color(0xFF3B82F6);
  static const brand600 = Color(0xFF2563EB);
  static const brand700 = Color(0xFF1D4ED8);
  static const brand800 = Color(0xFF1E40AF);
  static const brand900 = Color(0xFF1E3A8A);

  // Ink (slate/gray) — tidak berubah
  static const ink50  = Color(0xFFF8FAFC);
  static const ink100 = Color(0xFFF1F5F9);
  static const ink200 = Color(0xFFE2E8F0);
  static const ink500 = Color(0xFF64748B);
  static const ink600 = Color(0xFF475569);
  static const ink700 = Color(0xFF334155);
  static const ink900 = Color(0xFF0F172A);

  // Status
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const error   = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand700,
      primary: AppColors.brand700,
      onPrimary: Colors.white,
      secondary: AppColors.brand500,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink900,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink900,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink900,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand700,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand700,
        side: const BorderSide(color: AppColors.brand700),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ink50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.ink200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.ink200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand700, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.ink600, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.ink500, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.ink200),
      ),
      color: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.ink100,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.ink200,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.ink900, letterSpacing: -1.5),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink900, letterSpacing: -1),
      displaySmall:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink900, letterSpacing: -0.5),
      headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink900),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink900),
      headlineSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink900),
      titleLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink900),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink700),
      titleSmall:  TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink600),
      bodyLarge:   TextStyle(fontSize: 15, color: AppColors.ink700, height: 1.6),
      bodyMedium:  TextStyle(fontSize: 14, color: AppColors.ink600, height: 1.5),
      bodySmall:   TextStyle(fontSize: 12, color: AppColors.ink500),
      labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink900),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );
}
