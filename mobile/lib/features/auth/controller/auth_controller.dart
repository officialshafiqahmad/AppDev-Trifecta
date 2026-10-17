import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/auth/auth_service.dart';

/// Controller for login flow and credential management.
class AuthController extends GetxController {
  AuthController({required this.authService});

  final AuthService authService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Default pre-fill for fast testing
    selectQuickAccount('organizer@nascon.test', 'Nascon@26');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void selectQuickAccount(String email, String password) {
    emailController.text = email;
    passwordController.text = password;
    hasError.value = false;
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
