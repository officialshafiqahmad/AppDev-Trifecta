import 'package:flutter/material.dart';

/// Layout tokens — the ONLY place layout numbers and durations live.
/// Fixed logical pixels only; no screenutil or percentage sizing.
class AppSizes {
  const AppSizes();

  // Spacing scale: 2, 4, 8, 12, 16, 20, 24, 32, 40, 48
  final double xxs = 2;
  final double xs = 4;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 20;
  final double xxl = 24;
  final double xxxl = 32;
  final double huge = 40;
  final double giant = 48;

  // Screen & container paddings
  final double screenPadding = 16;
  final double screenPaddingWide = 20;
  final double cardPadding = 16;

  // Corner radii: 8, 12, 16, 20, sheet 28, pill 999
  final double radiusSm = 8;
  final double radiusMd = 12;
  final double radiusLg = 16;
  final double radiusXl = 20;
  final double radiusSheet = 28;
  final double radiusPill = 999;

  // Control heights
  final double buttonPrimary = 52;
  final double buttonSecondary = 48;
  final double buttonCompact = 40;
  final double input = 52;
  final double listRowMin = 56;
  final double appBar = 56;

  // Icon sizes
  final double iconSm = 20;
  final double iconMd = 24;
  final double iconLg = 28;

  // Minimum touch target everywhere
  final double minTouchTarget = 48;

  // Content max width and breakpoints: 600 / 840
  final double contentMaxWidth = 640;
  final double breakpointMedium = 600;
  final double breakpointExpanded = 840;

  // Motion durations: 120 / 200 / 320 ms
  final Duration motionFast = const Duration(milliseconds: 120);
  final Duration motionNormal = const Duration(milliseconds: 200);
  final Duration motionSlow = const Duration(milliseconds: 320);

  // Common motion curves
  final Curve curveDefault = Curves.easeInOutCubic;
  final Curve curveEnter = Curves.easeOutCubic;
  final Curve curveExit = Curves.easeInCubic;

  /// Returns responsive screen padding based on window width.
  double paddingFor(double width) =>
      width >= breakpointMedium ? screenPaddingWide : screenPadding;
}
