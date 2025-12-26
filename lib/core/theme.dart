import 'package:flutter/material.dart';
import 'package:sptm/core/constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: const Color(AppColors.primary),
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(AppColors.primary),
      onPrimary: const Color(AppColors.textMain),
      secondary: const Color(AppColors.secondaryIndigo),
      onSecondary: const Color(AppColors.textMain),
      error: const Color(AppColors.danger),
      onError: const Color(AppColors.textMain),
      background: const Color(AppColors.background),
      onBackground: const Color(AppColors.textMain),
      surface: const Color(AppColors.surface),
      onSurface: const Color(AppColors.textMain),
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(AppColors.background),
    inputDecorationTheme: InputDecorationTheme(
      //filled: true,
      fillColor: const Color(AppColors.surfaceBase),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
