import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';

/// Controller managing bottom navigation state and active user session.
class MainNavController extends GetxController {
  MainNavController({required this.authService});

  final AuthService authService;

  final RxInt currentIndex = 0.obs;
  final Rx<SessionUser?> currentUser = Rx<SessionUser?>(null);

  @override
  void onInit() {
    super.onInit();
    loadSession();
  }

  Future<void> loadSession() async {
    final res = await authService.getCurrentUser();
    if (res.isSuccess && res.dataOrNull != null) {
      final user = res.dataOrNull!;
      currentUser.value = user;

      // Rule B10: Role-aware initial tab
      if (user.role == UserRole.player || user.role == UserRole.clubManager) {
        currentIndex.value = 3; // Profile
      } else {
        currentIndex.value = 0; // Fixtures
      }
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  /// Rule G10: Switch tabs without stacking duplicate navigation shells
  void switchTab(int index) {
    currentIndex.value = index;
  }
}
