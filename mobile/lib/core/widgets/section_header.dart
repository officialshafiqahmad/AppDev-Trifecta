import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/theme_ext.dart';

/// Section title with an optional trailing action button.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.titleKey,
    this.title,
    this.actionLabelKey,
    this.onAction,
  }) : assert(titleKey != null || title != null, 'Either title or titleKey must be provided');

  final String? titleKey;
  final String? title;
  final String? actionLabelKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title ?? titleKey!.tr,
            style: textStyles.titleMd,
          ),
        ),
        if (actionLabelKey != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: colors.secondary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabelKey!.tr,
              style: textStyles.labelMd.copyWith(color: colors.secondary),
            ),
          ),
      ],
    );
  }
}
