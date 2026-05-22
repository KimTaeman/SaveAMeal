import 'package:flutter/material.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF1565C0);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
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
