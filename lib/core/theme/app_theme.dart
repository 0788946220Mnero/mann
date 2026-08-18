import 'package:flutter/material.dart';

/// هوية ديار الأنباط: أحمر عنّابي + ذهبي على خلفية داكنة أنيقة.
class AppColors {
  static const gold = Color(0xFFC9A84C);
  static const red = Color(0xFFB91C2C);
  static const dark = Color(0xFF17110F);
  static const surface = Color(0xFF221A17);
  static const surfaceAlt = Color(0xFF2C221E);
  static const border = Color(0x22C9A84C);
  static const textMain = Color(0xFFF3ECE0);
  static const textMuted = Color(0xFFB3A79A);

  // ألوان حالات الطلب
  static const statusNew = Color(0xFFE05A5A);
  static const statusPreparing = Color(0xFFD9A03A);
  static const statusReady = Color(0xFF3FBF72);
  static const statusDone = Color(0xFF4A90D9);
  static const statusCancelled = Color(0xFF8A8A8A);
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.dark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.gold,
        secondary: AppColors.red,
        surface: AppColors.surface,
        error: AppColors.statusNew,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain, fontFamily: 'Tajawal',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.gold.withOpacity(.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, color: AppColors.textMain),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}
