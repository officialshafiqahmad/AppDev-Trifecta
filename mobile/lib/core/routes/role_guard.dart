import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth/auth_service.dart';
import '../strings/app_strings.dart';
import '../widgets/app_snackbar.dart';
import 'app_routes.dart';

/// Route guard preventing unauthorized role access to sensitive operational views.
class RoleGuardMiddleware extends GetMiddleware {
  RoleGuardMiddleware({required this.allowedRoles, int? priority}) : super(priority: priority ?? 1);

  final List<UserRole> allowedRoles;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthService>()) return null;
    final auth = Get.find<AuthService>();
    final user = auth.currentUser;

    if (user == null || !allowedRoles.contains(user.role)) {
      AppSnackbar.error(AppStrings.errForbidden);
      return const RouteSettings(name: AppRoutes.main);
    }
    return null;
  }
}
