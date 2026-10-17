import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../services/auth/auth_service.dart';

/// Configuration for demo roles and accounts.
class DemoRoleConfig {
  const DemoRoleConfig({
    required this.roleKey,
    required this.title,
    required this.email,
    required this.password,
    required this.tenantTag,
    required this.description,
    required this.icon,
    required this.tone,
  });

  final String roleKey;
  final String title;
  final String email;
  final String password;
  final String tenantTag;
  final String description;
  final IconData icon;
  final AppStatusTone tone;
}

/// Controller for role selection, login flow, and credential management.
class AuthController extends GetxController {
  AuthController({required this.authService});

  final AuthService authService;

  static const List<DemoRoleConfig> demoRoles = [
    DemoRoleConfig(
      roleKey: AppStrings.roleOrganizer,
      title: 'League Organizer',
      email: 'organizer@nascon.test',
      password: 'Nascon@26',
      tenantTag: 'LEAGUE-ALPHA-1',
      description: 'Match scheduling, score event entry & timeline compensation',
      icon: Icons.emoji_events_outlined,
      tone: AppStatusTone.info,
    ),
    DemoRoleConfig(
      roleKey: AppStrings.roleManager,
      title: 'Club Manager',
      email: 'manager@nascon.test',
      password: 'Nascon@26',
      tenantTag: 'CLUB-ALPHA-1',
      description: 'Squad roster management, player transfers, loans & registration',
      icon: Icons.groups_outlined,
      tone: AppStatusTone.success,
    ),
    DemoRoleConfig(
      roleKey: AppStrings.roleAdmin,
      title: 'Platform Super-Admin',
      email: 'admin@nascon.test',
      password: 'Nascon@26',
      tenantTag: 'CROSS-TENANT',
      description: 'System-wide league operations & administrative controls',
      icon: Icons.admin_panel_settings_outlined,
      tone: AppStatusTone.danger,
    ),
    DemoRoleConfig(
      roleKey: AppStrings.rolePlayer,
      title: 'Player',
      email: 'player@nascon.test',
      password: 'Nascon@26',
      tenantTag: 'PLAYER-ALPHA-1',
      description: 'Squad member profile, match schedule & personal stats',
      icon: Icons.person_outline_rounded,
      tone: AppStatusTone.neutral,
    ),
    DemoRoleConfig(
      roleKey: AppStrings.roleViewer,
      title: 'General Viewer',
      email: 'viewer@nascon.test',
      password: 'Nascon@26',
      tenantTag: 'TENANT-ALPHA',
      description: 'Public match fixtures, points table & club profiles',
      icon: Icons.visibility_outlined,
      tone: AppStatusTone.warning,
    ),
  ];

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = ''.obs;
  final RxBool obscurePassword = true.obs;
  final Rx<DemoRoleConfig?> selectedRole = Rx<DemoRoleConfig?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is DemoRoleConfig) {
      selectedRole.value = args;
      emailController.text = args.email;
      passwordController.text = args.password;
    } else {
      selectedRole.value = null;
      emailController.clear();
      passwordController.clear();
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void selectRole(DemoRoleConfig role) {
    selectedRole.value = role;
    emailController.text = role.email;
    passwordController.text = role.password;
    Get.toNamed(AppRoutes.login, arguments: role);
  }

  void navigateToCustomLogin() {
    selectedRole.value = null;
    emailController.clear();
    passwordController.clear();
    Get.toNamed(AppRoutes.login);
  }

  void changeRole() {
    Get.back();
  }

  Future<void> submitLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      hasError.value = true;
      errorMessageKey.value = AppStrings.errValidation;
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    final result = await authService.login(email: email, password: password);

    isLoading.value = false;

    if (result.isSuccess) {
      Get.offAllNamed(AppRoutes.main);
    } else {
      hasError.value = true;
      errorMessageKey.value = result.failureOrNull?.userMessageKey ?? AppStrings.loginInvalidCreds;
      AppSnackbar.error(errorMessageKey.value);
    }
  }
}
