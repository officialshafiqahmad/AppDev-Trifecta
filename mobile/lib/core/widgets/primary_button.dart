import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/theme_ext.dart';
import 'pressable_scale.dart';

/// Primary action button adhering strictly to design system tokens.
/// Standard height: 52px (buttonPrimary), radius: 16px (radiusLg).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.labelKey,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabelKey,
    this.icon,
    this.height,
    this.isFullWidth = true,
  });

  final String labelKey;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabelKey;
  final IconData? icon;
  final double? height;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isDisabled = isLoading || onPressed == null;
    final buttonHeight = height ?? sizes.buttonPrimary;

    Widget content;
    if (isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: sizes.iconSm,
            height: sizes.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: sizes.xxs,
              valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
            ),
          ),
          if (loadingLabelKey != null) ...[
            SizedBox(width: sizes.sm),
            Text(
              loadingLabelKey!.tr,
              style: textStyles.labelLg.copyWith(color: colors.onPrimary),
            ),
          ],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: sizes.iconSm,
              color: isDisabled ? colors.textTertiary : colors.onPrimary,
            ),
            SizedBox(width: sizes.sm),
          ],
          Text(
            labelKey.tr,
            style: textStyles.labelLg.copyWith(
              color: isDisabled ? colors.textTertiary : colors.onPrimary,
            ),
          ),
        ],
      );
    }

    return PressableScale(
      enabled: !isDisabled,
      child: SizedBox(
        height: buttonHeight,
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            disabledBackgroundColor: colors.surfaceVariant,
            disabledForegroundColor: colors.textTertiary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizes.radiusLg),
            ),
            padding: EdgeInsets.symmetric(horizontal: sizes.lg),
          ),
          child: content,
        ),
      ),
    );
  }
}
