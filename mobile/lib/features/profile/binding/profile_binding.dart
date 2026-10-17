import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';
import '../controller/profile_controller.dart';

/// GetX binding for Profile feature.
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        authService: Get.find<AuthService>(),
        clubService: Get.find<ClubService>(),
      ),
    );
  }
}
