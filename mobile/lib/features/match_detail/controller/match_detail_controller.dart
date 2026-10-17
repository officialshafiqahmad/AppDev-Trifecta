import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/match/match_service.dart';

/// Controller managing single match score projection, events, and role gating.
class MatchDetailController extends GetxController {
  MatchDetailController({
    required this.matchService,
    required this.authService,
  });

  final MatchService matchService;
  final AuthService authService;

  late final String matchId;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final Rx<ScoreProjection?> projection = Rx<ScoreProjection?>(null);
  final RxBool canEnterScores = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    matchId = (args is String && args.isNotEmpty) ? args : 'm-alpha-1';
    checkRolePermissions();
    loadProjection();
  }

  Future<void> checkRolePermissions() async {
    final userRes = await authService.getCurrentUser();
    if (userRes.isSuccess && userRes.dataOrNull != null) {
      canEnterScores.value = userRes.dataOrNull!.isOrganizer;
    }
  }

  Future<void> loadProjection() async {
    isLoading.value = true;
    hasError.value = false;

    final result = await matchService.getScoreProjection(matchId);

    isLoading.value = false;

    if (result.isSuccess) {
      projection.value = result.dataOrNull;
    } else {
      hasError.value = true;
      errorMessageKey.value = result.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void openScoringEntry() {
    Get.toNamed(
      AppRoutes.scoringEntry,
      arguments: matchId,
    )?.then((_) => loadProjection());
  }

  void openStoreMerchandise() {
    Get.toNamed(AppRoutes.main);
  }
}
