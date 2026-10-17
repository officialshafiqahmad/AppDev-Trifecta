import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';

/// Controller managing club details, staff, and roster views.
class ClubProfileController extends GetxController {
  ClubProfileController({
    required this.clubService,
    required this.authService,
  });

  final ClubService clubService;
  final AuthService authService;

  late final String clubId;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final Rx<ClubProfile?> profile = Rx<ClubProfile?>(null);
  final RxBool canManageRoster = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    clubId = (args is String && args.isNotEmpty) ? args : 'club-alpha-1';
    checkRole();
    loadProfile();
  }

  Future<void> checkRole() async {
    final userRes = await authService.getCurrentUser();
    if (userRes.isSuccess && userRes.dataOrNull != null) {
      canManageRoster.value = userRes.dataOrNull!.isClubManager;
    }
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    hasError.value = false;

    final res = await clubService.getClubProfile(clubId);

    isLoading.value = false;

    if (res.isSuccess) {
      profile.value = res.dataOrNull;
    } else {
      hasError.value = true;
      errorMessageKey.value = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void openRosterManagement() {
    Get.toNamed(AppRoutes.rosterManage)?.then((_) => loadProfile());
  }
}
