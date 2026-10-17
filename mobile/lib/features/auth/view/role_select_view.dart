import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/auth_controller.dart';

/// Screen 1 of Authentication: role selection.
/// One headline, one card, five clean rows — role name + demo email, nothing else.
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
            Text(AppStrings.roleSelectTitle.tr, style: textStyles.headlineLg),
            SizedBox(height: sizes.xs),
            Text(
              AppStrings.roleSelectSubtitle.tr,
              style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: sizes.xl),

            // One card, five rows. Each row: icon, role name, demo email, chevron.
            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AuthController.demoRoles.length,
                separatorBuilder: (context, _) =>
                    Divider(height: 1, thickness: 1, color: colors.border),
                itemBuilder: (context, index) {
                  final role = AuthController.demoRoles[index];
                  return InkWell(
                    onTap: () => controller.selectRole(role),
                    borderRadius: index == 0
                        ? BorderRadius.vertical(
                            top: Radius.circular(sizes.radiusLg),
                          )
                        : index == AuthController.demoRoles.length - 1
                        ? BorderRadius.vertical(
                            bottom: Radius.circular(sizes.radiusLg),
                          )
                        : BorderRadius.zero,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes.cardPadding,
                        vertical: sizes.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            role.icon,
                            size: sizes.iconMd,
                            color: colors.textSecondary,
                          ),
                          SizedBox(width: sizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role.title, style: textStyles.titleMd),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  role.email,
                                  style: textStyles.bodySm.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_outlined,
                            size: sizes.iconSm,
                            color: colors.textTertiary,
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
                    style: textStyles.caption.copyWith(
                      color: colors.textTertiary,
                    ),
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
