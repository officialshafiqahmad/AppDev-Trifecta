import 'package:flutter/material.dart';

import '../theme/theme_ext.dart';
import 'pressable_scale.dart';

/// Standard card container adhering to the design system.
/// Uses colors.surface background, colors.border outline, and sizes.radiusLg (16).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;

    final card = Container(
      padding: padding ?? EdgeInsets.all(sizes.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(sizes.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );

    if (onTap != null) {
      return PressableScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }

    return card;
  }
}
