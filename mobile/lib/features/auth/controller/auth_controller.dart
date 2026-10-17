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
  final RxBool obscurePassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Rule C7: Clean start without pre-filled inputs
    emailController.clear();
    passwordController.clear();
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

  /// Rule C8: Immediate sign-in on demo account tap
  Future<void> signInWithDemo(String email, String password) async {
    emailController.text = email;
    passwordController.text = password;
    await submitLogin();
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
