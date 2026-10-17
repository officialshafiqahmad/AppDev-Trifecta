import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/primary_button.dart';

/// Sheet content component for the Home quick action sheet.
/// Uses design tokens exclusively.
class HomeSheetContent extends StatelessWidget {
  const HomeSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final textStyles = context.text;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: sizes.screenPadding,
        vertical: sizes.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.homeSheetTitle.tr,
            style: textStyles.titleLg,
          ),
          SizedBox(height: sizes.sm),
          Text(
            AppStrings.homeSheetDescription.tr,
            style: textStyles.bodyMd,
          ),
          SizedBox(height: sizes.lg),
          PrimaryButton(
            labelKey: AppStrings.commonClose,
            onPressed: () => Get.back(),
          ),
          SizedBox(height: sizes.sm),
        ],
      ),
    );
  }
}
