import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/theme_ext.dart';
import 'pressable_scale.dart';

/// Secondary action button adhering strictly to design tokens.
/// Standard height: 48px (buttonSecondary), radius: 12px (radiusMd).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.labelKey,
    required this.onPressed,
    this.icon,
    this.height,
    this.isFullWidth = true,
  });

  final String labelKey;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? height;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isDisabled = onPressed == null;
    final buttonHeight = height ?? sizes.buttonSecondary;

    return PressableScale(
      enabled: !isDisabled,
      child: SizedBox(
        height: buttonHeight,
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            disabledForegroundColor: colors.textTertiary,
            side: BorderSide(
              color: isDisabled ? colors.surfaceVariant : colors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizes.radiusMd),
            ),
            padding: EdgeInsets.symmetric(horizontal: sizes.lg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: sizes.iconSm,
                  color: isDisabled ? colors.textTertiary : colors.primary,
                ),
                SizedBox(width: sizes.sm),
              ],
              Text(
                labelKey.tr,
                style: textStyles.labelLg.copyWith(
                  color: isDisabled ? colors.textTertiary : colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
