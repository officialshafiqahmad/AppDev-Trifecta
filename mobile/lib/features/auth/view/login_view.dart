import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../controller/auth_controller.dart';
import '../widgets/account_chip.dart';

/// Dumb layout view for Login screen.
class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

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
            padding: EdgeInsets.symmetric(vertical: sizes.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Block
                Container(
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
                SizedBox(height: sizes.lg),
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
                SizedBox(height: sizes.xxl),

                // Form Container
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      Text(
                        AppStrings.loginEmailLabel.tr,
                        style: textStyles.labelLg,
                      ),
                      SizedBox(height: sizes.xs),
                      SizedBox(
                        height: sizes.input,
                        child: TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: textStyles.bodyMd,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: EdgeInsets.symmetric(horizontal: sizes.lg),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sizes.lg),

                      // Password Field
                      Text(
                        AppStrings.loginPasswordLabel.tr,
                        style: textStyles.labelLg,
                      ),
                      SizedBox(height: sizes.xs),
                      SizedBox(
                        height: sizes.input,
                        child: TextField(
                          controller: controller.passwordController,
                          obscureText: true,
                          style: textStyles.bodyMd,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: EdgeInsets.symmetric(horizontal: sizes.lg),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sizes.xl),

                      // Submit Primary Button
                      PrimaryButton(
                        labelKey: AppStrings.loginButton,
                        onPressed: controller.submitLogin,
                        icon: Icons.login_outlined,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.xl),

                // Quick Demo Accounts Chips
                Text(
                  AppStrings.loginQuickAccounts.tr,
                  style: textStyles.titleMd,
                ),
                SizedBox(height: sizes.md),
                Wrap(
                  spacing: sizes.sm,
                  runSpacing: sizes.sm,
                  children: [
                    AccountChip(
                      labelKey: AppStrings.roleOrganizer,
                      email: 'organizer@nascon.test',
                      isSelected: controller.emailController.text == 'organizer@nascon.test',
                      onTap: () => controller.selectQuickAccount('organizer@nascon.test', 'Nascon@26'),
                    ),
                    AccountChip(
                      labelKey: AppStrings.roleManager,
                      email: 'manager@nascon.test',
                      isSelected: controller.emailController.text == 'manager@nascon.test',
                      onTap: () => controller.selectQuickAccount('manager@nascon.test', 'Nascon@26'),
                    ),
                    AccountChip(
                      labelKey: AppStrings.roleAdmin,
                      email: 'admin@nascon.test',
                      isSelected: controller.emailController.text == 'admin@nascon.test',
                      onTap: () => controller.selectQuickAccount('admin@nascon.test', 'Nascon@26'),
                    ),
                    AccountChip(
                      labelKey: AppStrings.rolePlayer,
                      email: 'player@nascon.test',
                      isSelected: controller.emailController.text == 'player@nascon.test',
                      onTap: () => controller.selectQuickAccount('player@nascon.test', 'Nascon@26'),
                    ),
                    AccountChip(
                      labelKey: AppStrings.roleViewer,
                      email: 'viewer@nascon.test',
                      isSelected: controller.emailController.text == 'viewer@nascon.test',
                      onTap: () => controller.selectQuickAccount('viewer@nascon.test', 'Nascon@26'),
                    ),
                  ],
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
