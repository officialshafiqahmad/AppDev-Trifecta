import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/pressable_scale.dart';

/// Quick selector pill chip for demo accounts.
class AccountChip extends StatelessWidget {
  const AccountChip({
    super.key,
    required this.labelKey,
    required this.email,
    required this.isSelected,
    required this.onTap,
  });

  final String labelKey;
  final String email;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.md,
            vertical: sizes.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(sizes.radiusPill),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: sizes.iconSm,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              SizedBox(width: sizes.xs),
              Text(
                labelKey.tr,
                style: textStyles.labelMd.copyWith(
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
