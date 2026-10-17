import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';
import '../controller/auth_controller.dart';

/// GetX binding for Authentication feature.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        authService: Get.find<AuthService>(),
      ),
    );
  }
}
