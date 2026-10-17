import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text.dart';

/// Context extensions to access design tokens cleanly from anywhere without magic numbers.
extension ThemeExt on BuildContext {
  /// Active semantic colour palette
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// Palette alias
  AppPalette get palette => colors;

  /// Active typographic styles
  AppTextStyles get text => AppTextStyles(colors);

  /// Text styles alias
  AppTextStyles get textStyles => text;

  /// Layout tokens and sizing constants
  AppSizes get sizes => const AppSizes();
}
