import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/settings_controller.dart';

/// Refactored Settings view adhering to C36, C37, D4, A4.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: AppStrings.settingsTitle,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Server Configuration Card (C36, C37, D4)
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: AppStrings.settingsServerAddress.tr,
                      controller: controller.hostController,
                      hintText: '10.0.2.2',
                      helperText: 'Default: 10.0.2.2:8080 (Android emulator host)',
                      suffixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: sizes.md),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ':8080',
                              style: textStyles.titleSm.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.lg),
                    PrimaryButton(
                      labelKey: AppStrings.commonSave,
                      onPressed: controller.saveServerHost,
                      icon: Icons.save_outlined,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Device Identity Card
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.settingsDeviceId.tr, style: textStyles.labelMd),
                    Text(
                      controller.deviceId.value,
                      style: textStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Local Cache Management Card (A4)
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppStrings.settingsCacheTitle.tr, style: textStyles.titleMd),
                    SizedBox(height: sizes.xxs),
                    Text(
                      'Clears offline cache files while preserving persistent app settings and queued sync actions.',
                      style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                    ),
                    SizedBox(height: sizes.md),
                    SecondaryButton(
                      labelKey: AppStrings.settingsClearCache,
                      onPressed: controller.clearCache,
                      icon: Icons.delete_outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
