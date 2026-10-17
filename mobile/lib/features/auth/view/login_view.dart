import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../controller/auth_controller.dart';

/// Dumb layout view for Login screen adhering to UX rules C7, C8, and C9.
class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  static const _demoAccounts = [
    (roleKey: AppStrings.roleOrganizer, email: 'organizer@nascon.test', desc: 'League operations & scoring control'),
    (roleKey: AppStrings.roleManager, email: 'manager@nascon.test', desc: 'Club & player roster management'),
    (roleKey: AppStrings.roleAdmin, email: 'admin@nascon.test', desc: 'Platform super-admin access'),
    (roleKey: AppStrings.rolePlayer, email: 'player@nascon.test', desc: 'Player profile & squad viewer'),
    (roleKey: AppStrings.roleViewer, email: 'viewer@nascon.test', desc: 'Spectator & public match fan'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      showSyncIndicator: false,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: sizes.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Block
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
                  AppStrings.loginTitle.tr,
                  style: textStyles.headlineLg,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sizes.xs),
                Text(
                  AppStrings.loginSubtitle.tr,
                  style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sizes.xl),

                // Rule C8: Quick Demo Accounts (Tap to Sign In Immediately)
                Text(
                  AppStrings.loginQuickAccounts.tr,
                  style: textStyles.titleMd,
                ),
                SizedBox(height: sizes.xs),
                Text(
                  AppStrings.loginDemoSection.tr,
                  style: textStyles.caption.copyWith(color: colors.textSecondary),
                ),
                SizedBox(height: sizes.md),

                // Demo Accounts in a single card with dividers (Rule C4)
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < _demoAccounts.length; i++) ...[
                        InkWell(
                          onTap: () => controller.signInWithDemo(
                            _demoAccounts[i].email,
                            'Nascon@26',
                          ),
                          borderRadius: i == 0
                              ? BorderRadius.vertical(top: Radius.circular(sizes.radiusLg))
                              : i == _demoAccounts.length - 1
                                  ? BorderRadius.vertical(bottom: Radius.circular(sizes.radiusLg))
                                  : BorderRadius.zero,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: sizes.cardPadding,
                              vertical: sizes.md,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(sizes.radiusSm),
                                  ),
                                  child: Icon(
                                    Icons.badge_outlined,
                                    size: sizes.iconSm,
                                    color: colors.primary,
                                  ),
                                ),
                                SizedBox(width: sizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _demoAccounts[i].roleKey.tr,
                                        style: textStyles.labelLg.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _demoAccounts[i].email,
                                        style: textStyles.bodySm.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_outlined,
                                  size: sizes.iconSm,
                                  color: colors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (i < _demoAccounts.length - 1)
                          Divider(height: 1, color: colors.border),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: sizes.xl),

                // Rule C8: Subtle divider
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

                SizedBox(height: sizes.xl),

                // Form Container with AppTextField (Rule D4)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: controller.emailController,
                        label: AppStrings.loginEmailLabel.tr,
                        hintText: 'name@nascon.test',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          size: sizes.iconSm,
                          color: colors.textTertiary,
                        ),
                      ),
                      SizedBox(height: sizes.md),
                      Obx(() => AppTextField(
                            controller: controller.passwordController,
                            label: AppStrings.loginPasswordLabel.tr,
                            hintText: '••••••••',
                            obscureText: controller.obscurePassword.value,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              size: sizes.iconSm,
                              color: colors.textTertiary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscurePassword.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: sizes.iconSm,
                                color: colors.textSecondary,
                              ),
                              onPressed: controller.toggleObscurePassword,
                            ),
                          )),
                      SizedBox(height: sizes.xl),
                      PrimaryButton(
                        labelKey: AppStrings.loginButton,
                        onPressed: controller.submitLogin,
                        icon: Icons.login_outlined,
                      ),
                    ],
                  ),
                ),

                if (controller.hasError.value) ...[
                  SizedBox(height: sizes.xl),
                  ErrorView(
                    messageKey: controller.errorMessageKey.value,
                    actionLabelKey: AppStrings.commonRetry,
                    onRetry: controller.submitLogin,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
