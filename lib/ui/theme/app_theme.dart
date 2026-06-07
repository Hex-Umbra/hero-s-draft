import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkNeonTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonBlue,
        secondary: AppColors.neonPurple,
        surface: AppColors.darkSurface,
        error: AppColors.danger,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.containerDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get lightParchmentTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.parchmentBg,
      cardColor: AppColors.parchmentSurface,
      dividerColor: AppColors.parchmentBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.borderParchment,
        secondary: AppColors.neonGold,
        surface: AppColors.parchmentSurface,
        onSurface: AppColors.parchmentText,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.parchmentText, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.parchmentInk, fontSize: 14),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.parchmentSurface,
        titleTextStyle: TextStyle(
          color: AppColors.parchmentText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: AppColors.parchmentInk, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  // Aliases for compatibility
  static ThemeData get dark => darkNeonTheme;
  static ThemeData get light => lightParchmentTheme;
}
