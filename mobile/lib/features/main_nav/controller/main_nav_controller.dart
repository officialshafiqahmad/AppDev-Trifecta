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
    if (res.isSuccess) {
      currentUser.value = res.dataOrNull;
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
