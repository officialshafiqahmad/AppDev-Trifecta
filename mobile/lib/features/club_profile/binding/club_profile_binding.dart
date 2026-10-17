import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';
import '../controller/club_profile_controller.dart';

/// GetX binding for Club Profile feature.
class ClubProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClubProfileController>(
      () => ClubProfileController(
        clubService: Get.find<ClubService>(),
        authService: Get.find<AuthService>(),
      ),
    );
  }
}
