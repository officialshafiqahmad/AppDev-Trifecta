import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/profile_controller.dart';

/// Dumb layout view for User Profile & settings entry point.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Obx(() {
      if (controller.isLoading.value) {
        return const LoadingOverlay.staged(
          labelKey: AppStrings.commonLoading,
        );
      }

      final u = controller.user.value;

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User identity card
            AppCard(
              padding: EdgeInsets.all(sizes.lg),
              child: Row(
                children: [
                  Container(
                    width: sizes.listRowMin,
                    height: sizes.listRowMin,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: sizes.iconLg,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(width: sizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u?.name ?? 'User', style: textStyles.titleLg),
                        SizedBox(height: sizes.xxs),
                        Text(
                          u?.email ?? '',
                          style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                        ),
                        SizedBox(height: sizes.xs),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(sizes.radiusPill),
                          ),
                          child: Text(
                            u?.role.name.toUpperCase() ?? '',
                            style: textStyles.labelMd.copyWith(color: colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes.lg),

            // Tenant Info
            AppCard(
              padding: EdgeInsets.all(sizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.profileCurrentTenant.tr, style: textStyles.labelMd),
                  Text(u?.tenantId ?? 'tenant-alpha', style: textStyles.bodyMd),
                ],
              ),
            ),
            SizedBox(height: sizes.xl),

            // Role Shortcut: Manage Roster (if Manager)
            if (u?.isClubManager ?? false) ...[
              PrimaryButton(
                labelKey: AppStrings.clubManageRosterAction,
                onPressed: controller.openRosterManagement,
                icon: Icons.group_add_outlined,
              ),
              SizedBox(height: sizes.md),
            ],

            // Secondary Navigation Buttons
            SecondaryButton(
              labelKey: AppStrings.syncTitle,
              onPressed: controller.openSyncStatus,
              icon: Icons.sync_outlined,
            ),
            SizedBox(height: sizes.sm),

            SecondaryButton(
              labelKey: AppStrings.settingsTitle,
              onPressed: controller.openSettings,
              icon: Icons.settings_outlined,
            ),
            SizedBox(height: sizes.xl),

            // Sign out
            SecondaryButton(
              labelKey: AppStrings.logoutButton,
              onPressed: controller.logout,
              icon: Icons.logout_outlined,
            ),
          ],
        ),
      );
    });
  }
}
