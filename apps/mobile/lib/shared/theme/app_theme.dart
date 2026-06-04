import 'package:flutter/material.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

abstract final class AppTheme {
  // Darkened from 0xFF3DBE6C to meet WCAG AA contrast (≥4.5:1) with white text.
  static const _seed = Color(0xFF1A7A3A);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed).copyWith(
      primary: _seed,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6F5E5),
      surface: const Color(0xFFF2FAF4),
    ),
    extensions: const [AppColors.light],
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    extensions: const [AppColors.dark],
  );
}
