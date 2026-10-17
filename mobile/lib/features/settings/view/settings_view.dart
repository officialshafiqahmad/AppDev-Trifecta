import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/settings_controller.dart';

/// Dumb layout view for Settings screen.
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
              // Server Configuration Card
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.settingsServerAddress.tr,
                      style: textStyles.labelLg,
                    ),
                    SizedBox(height: sizes.xs),
                    SizedBox(
                      height: sizes.input,
                      child: TextField(
                        controller: controller.hostController,
                        style: textStyles.bodyMd,
                        decoration: InputDecoration(
                          hintText: '10.0.2.2 or LAN IP',
                          suffixText: ':8080',
                          suffixStyle: textStyles.bodyMd.copyWith(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: EdgeInsets.symmetric(horizontal: sizes.md),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(sizes.radiusMd),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(sizes.radiusMd),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.xs),
                    Text(
                      'Port 8080 is fixed per competition specification.',
                      style: textStyles.caption,
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
                      style: textStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Local DB Cache Management Card
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppStrings.settingsCacheTitle.tr, style: textStyles.titleMd),
                    SizedBox(height: sizes.xxs),
                    Text(
                      'Stores offline fixtures, standings, and club profiles locally.',
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
