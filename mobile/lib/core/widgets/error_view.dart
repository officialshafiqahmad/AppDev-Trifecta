import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../strings/app_strings.dart';
import '../theme/theme_ext.dart';
import 'primary_button.dart';

/// Full-screen error state: error icon + messageKey + single recovery action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.messageKey,
    this.onRetry,
    this.actionLabelKey = AppStrings.commonRetry,
  });

  final String messageKey;
  final VoidCallback? onRetry;
  final String actionLabelKey;

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
                color: colors.errorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: sizes.iconLg,
                color: colors.error,
              ),
            ),
            SizedBox(height: sizes.lg),
            Text(
              messageKey.tr,
              style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: sizes.xl),
              PrimaryButton(
                labelKey: actionLabelKey,
                onPressed: onRetry,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
