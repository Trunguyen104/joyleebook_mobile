import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceSubtle,
    required this.primaryBrand,
    required this.primaryBrandDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textOnBrand,
    required this.borderDefault,
    required this.borderFocus,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceSubtle;
  final Color primaryBrand;
  final Color primaryBrandDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textOnBrand;
  final Color borderDefault;
  final Color borderFocus;
  final Color success;
  final Color warning;
  final Color danger;

  // Cấu hình bảng màu Light (Đồng bộ PaletteLight Web Blazor)
  static const light = AppColors(
    bgCanvas: Color(0xFFFFFCF7),
    bgSurface: Color(0xFFFFFFFF),
    bgSurfaceSubtle: Color(0xFFFBF5EC),
    primaryBrand: Color(0xFF773B8E),
    primaryBrandDark: Color(0xFF5F2E72),
    accent: Color(0xFFD58522),
    textPrimary: Color(0xFF1D1917),
    textSecondary: Color(0xFF574A43),
    textDisabled: Color(0xFF8A7A70),
    textOnBrand: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFE2D9D2),
    borderFocus: Color(0xFF914FA7),
    success: Color(0xFF2D7B57),
    warning: Color(0xFF8F4E13),
    danger: Color(0xFFB74B43),
  );

  // Cấu hình bảng màu Dark (Đồng bộ PaletteDark Web Blazor)
  static const dark = AppColors(
    bgCanvas: Color(0xFF1D1917),
    bgSurface: Color(0xFF2A2421),
    bgSurfaceSubtle: Color(0xFF3A312D),
    primaryBrand: Color(0xFF914FA7),
    primaryBrandDark: Color(0xFF773B8E),
    accent: Color(0xFFF0BD5A),
    textPrimary: Color(0xFFFFFCF7),
    textSecondary: Color(0xFFC9BDB3),
    textDisabled: Color(0xFF8A7A70),
    textOnBrand: Color(0xFFFFFFFF),
    borderDefault: Color(0xFF574A43),
    borderFocus: Color(0xFFF0BD5A),
    success: Color(0xFF82C9A6),
    warning: Color(0xFFF8D88F),
    danger: Color(0xFFF0A49D),
  );

  @override
  AppColors copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceSubtle,
    Color? primaryBrand,
    Color? primaryBrandDark,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textOnBrand,
    Color? borderDefault,
    Color? borderFocus,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppColors(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceSubtle: bgSurfaceSubtle ?? this.bgSurfaceSubtle,
      primaryBrand: primaryBrand ?? this.primaryBrand,
      primaryBrandDark: primaryBrandDark ?? this.primaryBrandDark,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFocus: borderFocus ?? this.borderFocus,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceSubtle: Color.lerp(bgSurfaceSubtle, other.bgSurfaceSubtle, t)!,
      primaryBrand: Color.lerp(primaryBrand, other.primaryBrand, t)!,
      primaryBrandDark: Color.lerp(primaryBrandDark, other.primaryBrandDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

// Extension helper để gọi trực tiếp context.colors
extension AppColorsBuildContextX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
