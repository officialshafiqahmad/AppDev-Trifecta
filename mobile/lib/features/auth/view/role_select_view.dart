import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/auth_controller.dart';

/// Screen 1 of Authentication: Dedicated role selection screen.
/// Adheres strictly to DESIGN_RULES.md (no gradients, drop shadows, glassmorphism, or emojis; outlined icons only).
class RoleSelectView extends GetView<AuthController> {
  const RoleSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      showSyncIndicator: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: sizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Branding Header
            Center(
              child: Container(
                width: sizes.listRowMin,
                height: sizes.listRowMin,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_soccer_outlined,
                  size: sizes.iconLg,
                  color: colors.primary,
                ),
              ),
            ),
            SizedBox(height: sizes.md),
            Text(
              AppStrings.roleSelectTitle.tr,
              style: textStyles.headlineLg,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sizes.xs),
            Text(
              AppStrings.roleSelectSubtitle.tr,
              style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sizes.xl),

            // Section Label
            Text(
              'Available Operational Roles',
              style: textStyles.titleMd,
            ),
            SizedBox(height: sizes.xs),
            Text(
              'Select any role to proceed with verified demo credentials:',
              style: textStyles.caption,
            ),
            SizedBox(height: sizes.md),

            // Single AppCard with dividers for all roles (Rule C4)
            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AuthController.demoRoles.length,
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border,
                ),
                itemBuilder: (context, index) {
                  final role = AuthController.demoRoles[index];
                  return InkWell(
                    onTap: () => controller.selectRole(role),
                    borderRadius: index == 0
                        ? BorderRadius.vertical(top: Radius.circular(sizes.radiusLg))
                        : index == AuthController.demoRoles.length - 1
                            ? BorderRadius.vertical(bottom: Radius.circular(sizes.radiusLg))
                            : BorderRadius.zero,
                    child: Padding(
                      padding: EdgeInsets.all(sizes.cardPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(sizes.radiusSm),
                            ),
                            child: Icon(
                              role.icon,
                              size: sizes.iconMd,
                              color: colors.primary,
                            ),
                          ),
                          SizedBox(width: sizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        role.title,
                                        style: textStyles.labelLg.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    AppStatusChip(
                                      label: role.tenantTag,
                                      tone: role.tone,
                                    ),
                                  ],
                                ),
                                SizedBox(height: sizes.xs),
                                Text(
                                  role.description,
                                  style: textStyles.bodySm.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  role.email,
                                  style: textStyles.caption.copyWith(
                                    color: colors.textTertiary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: sizes.sm),
                          Padding(
                            padding: EdgeInsets.only(top: sizes.xs),
                            child: Icon(
                              Icons.arrow_forward_outlined,
                              size: sizes.iconSm,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: sizes.xl),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: colors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.md),
                  child: Text(
                    AppStrings.loginOrCredentials.tr,
                    style: textStyles.caption.copyWith(color: colors.textTertiary),
                  ),
                ),
                Expanded(child: Divider(color: colors.border)),
              ],
            ),
            SizedBox(height: sizes.lg),

            // Custom Credentials Option
            SecondaryButton(
              labelKey: AppStrings.roleSelectCustom,
              icon: Icons.edit_outlined,
              onPressed: controller.navigateToCustomLogin,
            ),
          ],
        ),
      ),
    );
  }
}
