import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../strings/app_strings.dart';
import '../theme/theme_ext.dart';

/// Standard progress / loading indicator.
/// Supports staged (indeterminate) and determinate (progress 0.0 - 1.0) variants.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay.staged({
    super.key,
    this.labelKey = AppStrings.commonLoading,
  }) : progress = null;

  const LoadingOverlay.determinate({
    super.key,
    required double this.progress,
    this.labelKey = AppStrings.commonLoading,
  });

  final String labelKey;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final progressValue = progress;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(sizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: sizes.contentMaxWidth / 3,
              child: LinearProgressIndicator(
                value: progressValue,
                color: colors.primary,
                backgroundColor: colors.surfaceVariant,
                minHeight: sizes.xs,
                borderRadius: BorderRadius.circular(sizes.radiusPill),
              ),
            ),
            SizedBox(height: sizes.lg),
            Text(
              progressValue == null
                  ? labelKey.tr
                  : '${labelKey.tr} ${(progressValue * 100).round()}%',
              style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
