import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale — the ONLY place font sizes, weights, and line heights are defined.
/// Uses the bundled 'Inter' asset font. Styles are parameterized by the active
/// [AppPalette].
class AppTextStyles {
  const AppTextStyles(this.palette);

  final AppPalette palette;

  static const String _family = 'Inter';

  TextStyle _base({
    required double size,
    required FontWeight weight,
    required double lineHeight,
    Color? color,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight,
      letterSpacing: letterSpacing,
      color: color ?? palette.textPrimary,
    );
  }

  /// display 32/700/1.20
  TextStyle get display =>
      _base(size: 32, weight: FontWeight.w700, lineHeight: 1.20);

  /// headlineLg 24/700/1.25
  TextStyle get headlineLg =>
      _base(size: 24, weight: FontWeight.w700, lineHeight: 1.25);

  /// headlineMd 20/600/1.30
  TextStyle get headlineMd =>
      _base(size: 20, weight: FontWeight.w600, lineHeight: 1.30);

  /// titleLg 18/600/1.35
  TextStyle get titleLg =>
      _base(size: 18, weight: FontWeight.w600, lineHeight: 1.35);

  /// titleMd 16/600/1.40
  TextStyle get titleMd =>
      _base(size: 16, weight: FontWeight.w600, lineHeight: 1.40);

  /// titleSm 14/600/1.40
  TextStyle get titleSm =>
      _base(size: 14, weight: FontWeight.w600, lineHeight: 1.40);

  /// bodyLg 16/400/1.50
  TextStyle get bodyLg =>
      _base(size: 16, weight: FontWeight.w400, lineHeight: 1.50);

  /// bodyMd 14/400/1.50
  TextStyle get bodyMd =>
      _base(size: 14, weight: FontWeight.w400, lineHeight: 1.50);

  /// bodySm 13/400/1.45
  TextStyle get bodySm =>
      _base(size: 13, weight: FontWeight.w400, lineHeight: 1.45);

  /// labelLg 14/600/1.40
  TextStyle get labelLg =>
      _base(size: 14, weight: FontWeight.w600, lineHeight: 1.40);

  /// labelMd 12/600/1.35
  TextStyle get labelMd =>
      _base(size: 12, weight: FontWeight.w600, lineHeight: 1.35);

  /// caption 12/400 in textSecondary
  TextStyle get caption => _base(
    size: 12,
    weight: FontWeight.w400,
    lineHeight: 1.40,
    color: palette.textSecondary,
  );

  /// overline 11/600 letter-spacing 0.8 in textSecondary
  TextStyle get overline => _base(
    size: 11,
    weight: FontWeight.w600,
    lineHeight: 1.30,
    letterSpacing: 0.8,
    color: palette.textSecondary,
  );
}
