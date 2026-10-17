import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_sizes.dart';
import '../theme/theme_ext.dart';

/// Sanctioned notification snackbar.
/// Used for completed asynchronous facts, never for errors requiring decisions.
abstract final class AppSnackbar {
  static const AppSizes _sizes = AppSizes();

  static void success(String messageKey) => _show(messageKey, isError: false);
  static void info(String messageKey) => _show(messageKey, isError: false);
  static void error(String messageKey) => _show(messageKey, isError: true);

  static void _show(String messageKey, {required bool isError}) {
    final context = Get.context;
    if (context == null) return;

    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    Get.snackbar(
      '',
      messageKey.tr,
      titleText: const SizedBox.shrink(),
      messageText: Text(
        messageKey.tr,
        style: textStyles.bodyMd.copyWith(
          color: isError ? colors.error : colors.textPrimary,
        ),
      ),
      backgroundColor: isError ? colors.errorBg : colors.surfaceVariant,
      colorText: colors.textPrimary,
      borderRadius: sizes.radiusMd,
      margin: EdgeInsets.all(sizes.screenPadding),
      borderColor: isError ? colors.error : colors.border,
      borderWidth: 1,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      animationDuration: _sizes.motionFast,
    );
  }
}
