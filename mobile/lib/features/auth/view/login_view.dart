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

/// Screen 2 of Authentication: Focused credential entry and authentication.
/// Opened after selecting a role or choosing custom credentials.
class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Obx(() {
      final selectedRole = controller.selectedRole.value;

      return AppScaffold(
        showSyncIndicator: false,
        titleKey: AppStrings.loginTitle,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_outlined,
            size: sizes.iconMd,
            color: colors.textPrimary,
          ),
          onPressed: controller.changeRole,
        ),
        body: controller.isLoading.value
            ? const LoadingOverlay.staged(labelKey: AppStrings.commonLoading)
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: sizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Role context: one slim line, no card (if entered from role selection)
                    if (selectedRole != null) ...[
                      Row(
                        children: [
                          Icon(
                            selectedRole.icon,
                            size: sizes.iconMd,
                            color: colors.textSecondary,
                          ),
                          SizedBox(width: sizes.sm),
                          Expanded(
                            child: Text(
                              selectedRole.title,
                              style: textStyles.titleMd,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: controller.changeRole,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: sizes.sm,
                              ),
                              foregroundColor: colors.primary,
                            ),
                            child: Text(
                              AppStrings.roleChange.tr,
                              style: textStyles.labelMd.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizes.lg),
                    ],

                    // Credentials Input Card
                    AppCard(
                      padding: EdgeInsets.all(sizes.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Account Credentials',
                            style: textStyles.titleMd,
                          ),
                          SizedBox(height: sizes.xxs),
                          Text(
                            selectedRole != null
                                ? 'Demo credentials are filled in — just sign in:'
                                : 'Enter your registered credentials to sign in:',
                            style: textStyles.caption,
                          ),
                          SizedBox(height: sizes.lg),

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

                          Obx(
                            () => AppTextField(
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
                            ),
                          ),
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
                      SizedBox(height: sizes.lg),
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
    });
  }
}
