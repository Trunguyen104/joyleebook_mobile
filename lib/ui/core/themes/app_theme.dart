import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

abstract final class AppTheme {
  static ThemeData get light => _createTheme(AppColors.light, Brightness.light);
  static ThemeData get dark => _createTheme(AppColors.dark, Brightness.dark);

  static ThemeData _createTheme(AppColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bgCanvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primaryBrand,
        onPrimary: colors.textOnBrand,
        secondary: colors.accent,
        onSecondary: colors.textPrimary,
        error: colors.danger,
        onError: colors.textOnBrand,
        surface: colors.bgSurface,
        onSurface: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: colors.borderDefault, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgCanvas,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      extensions: [colors],
    );
  }
}
