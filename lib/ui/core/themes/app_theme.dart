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
      navigationBarTheme: NavigationBarThemeData(
        height: 50, // Chiều cao mong muốn (56 - 60)
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primaryBrand, size: 24);
          }
          return IconThemeData(color: colors.textSecondary, size: 24);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgSurface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actionsIconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),

        shape: Border(
          bottom: BorderSide(
            color: colors.borderDefault.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      extensions: [colors],
    );
  }
}
