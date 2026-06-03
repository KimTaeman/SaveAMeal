import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.brand,
    required this.brandLight,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color brand;
  final Color brandLight;

  static const light = AppColors(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF57F17),
    onWarning: Color(0xFF000000),
    danger: Color(0xFFC62828),
    onDanger: Color(0xFFFFFFFF),
    brand: Color(0xFF006E2F),
    brandLight: Color(0xFF22C55E),
  );

  static const dark = AppColors(
    success: Color(0xFF66BB6A),
    onSuccess: Color(0xFF000000),
    warning: Color(0xFFFFCA28),
    onWarning: Color(0xFF000000),
    danger: Color(0xFFEF9A9A),
    onDanger: Color(0xFF000000),
    brand: Color(0xFF006E2F),
    brandLight: Color(0xFF22C55E),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? brand,
    Color? brandLight,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    brand: brand ?? this.brand,
    brandLight: brandLight ?? this.brandLight,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandLight: Color.lerp(brandLight, other.brandLight, t)!,
    );
  }
}
