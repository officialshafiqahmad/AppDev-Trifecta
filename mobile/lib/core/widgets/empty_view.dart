import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/theme_ext.dart';
import 'primary_button.dart';

/// Standard empty state: icon + messageKey + optional recovery action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.messageKey,
    this.actionLabelKey,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String messageKey;
  final String? actionLabelKey;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(sizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: sizes.listRowMin,
              height: sizes.listRowMin,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: sizes.iconLg,
                color: colors.primary,
              ),
            ),
            SizedBox(height: sizes.lg),
            Text(
              messageKey.tr,
              style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabelKey != null && onAction != null) ...[
              SizedBox(height: sizes.xl),
              PrimaryButton(
                labelKey: actionLabelKey!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
