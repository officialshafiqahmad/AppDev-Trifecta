import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../strings/app_strings.dart';
import '../theme/theme_ext.dart';

/// Standard dialog shell. Features never call Get.dialog ad-hoc.
abstract final class AppDialog {
  /// Confirmation dialog; returns true when confirmed, false when dismissed.
  static Future<bool> confirm({
    required String titleKey,
    required String bodyKey,
    String confirmLabelKey = AppStrings.commonConfirm,
    String cancelLabelKey = AppStrings.commonCancel,
    bool isDestructive = false,
  }) async {
    final context = Get.context;
    if (context == null) return false;

    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusLg),
          side: BorderSide(color: colors.border),
        ),
        title: Text(titleKey.tr, style: textStyles.titleLg),
        content: Text(bodyKey.tr, style: textStyles.bodyMd),
        actionsPadding: EdgeInsets.all(sizes.lg),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              cancelLabelKey.tr,
              style: textStyles.labelLg.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? colors.error : colors.primary,
            ),
            child: Text(
              confirmLabelKey.tr,
              style: textStyles.labelLg.copyWith(
                color: isDestructive ? colors.error : colors.primary,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Informational alert dialog.
  static Future<void> info({
    required String titleKey,
    required String bodyKey,
    String actionLabelKey = AppStrings.commonOk,
  }) async {
    final context = Get.context;
    if (context == null) return;

    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusLg),
          side: BorderSide(color: colors.border),
        ),
        title: Text(titleKey.tr, style: textStyles.titleLg),
        content: Text(bodyKey.tr, style: textStyles.bodyMd),
        actionsPadding: EdgeInsets.all(sizes.lg),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              actionLabelKey.tr,
              style: textStyles.labelLg.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
