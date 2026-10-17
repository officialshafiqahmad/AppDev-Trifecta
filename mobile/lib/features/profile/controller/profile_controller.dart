import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';

/// Controller managing user session overview and profile settings navigation.
class ProfileController extends GetxController {
  ProfileController({
    required this.authService,
    required this.clubService,
  });

  final AuthService authService;
  final ClubService clubService;

  final RxBool isLoading = true.obs;
  final Rx<SessionUser?> user = Rx<SessionUser?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    final res = await authService.getCurrentUser();
    isLoading.value = false;
    if (res.isSuccess) {
      user.value = res.dataOrNull;
    }
  }

  void openSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  void openSyncStatus() {
    Get.toNamed(AppRoutes.syncStatus);
  }

  void openRosterManagement() {
    Get.toNamed(AppRoutes.rosterManage);
  }

  Future<void> logout() async {
    await authService.logout();
    Get.offAllNamed(AppRoutes.roleSelect);
  }
}
