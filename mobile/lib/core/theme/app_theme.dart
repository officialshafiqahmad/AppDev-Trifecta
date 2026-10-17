import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text.dart';

/// ThemeData built solely from design tokens.
abstract final class AppTheme {
  static const AppSizes _sizes = AppSizes();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final styles = AppTextStyles(palette);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.textPrimary,
      secondary: palette.secondary,
      onSecondary: palette.onPrimary,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceVariant,
      onSurfaceVariant: palette.textSecondary,
      error: palette.error,
      onError: palette.onPrimary,
      outline: palette.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Inter',
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: TextTheme(
        displayMedium: styles.display,
        headlineLarge: styles.headlineLg,
        headlineMedium: styles.headlineMd,
        titleLarge: styles.titleLg,
        titleMedium: styles.titleMd,
        bodyLarge: styles.bodyLg,
        bodyMedium: styles.bodyMd,
        bodySmall: styles.bodySm,
        labelLarge: styles.labelLg,
        labelMedium: styles.labelMd,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        toolbarHeight: _sizes.appBar,
        titleTextStyle: styles.titleLg,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _sizes.lg,
          vertical: _sizes.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_sizes.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_sizes.radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_sizes.radiusMd),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_sizes.radiusMd),
          borderSide: BorderSide(color: palette.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_sizes.radiusMd),
          borderSide: BorderSide(color: palette.error, width: 1.5),
        ),
        hintStyle: styles.bodyMd.copyWith(color: palette.textTertiary),
        errorStyle: styles.caption.copyWith(color: palette.error),
      ),
    );
  }
}
