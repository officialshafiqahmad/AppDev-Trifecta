import 'dart:async';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/match/match_service.dart';
import '../../main_nav/controller/main_nav_controller.dart';

/// Controller managing single match score projection, events, polling timer, and role gating.
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

  Timer? _liveScoreTimer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    matchId = (args is String && args.isNotEmpty) ? args : 'match-alpha-1';
    loadProjection();
  }

  @override
  void onClose() {
    _liveScoreTimer?.cancel();
    super.onClose();
  }

  void _startLiveTimerIfNeeded() {
    _liveScoreTimer?.cancel();
    if (projection.value?.isLive == true) {
      // Rule B9: 15-second polling timer for live matches
      _liveScoreTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _pollLiveScore();
      });
    }
  }

  Future<void> _pollLiveScore() async {
    final result = await matchService.getScoreProjection(matchId);
    if (result.isSuccess && result.dataOrNull != null) {
      projection.value = result.dataOrNull;
      _updatePermission();
    }
  }

  void _updatePermission() {
    final user = authService.currentUser;
    // Rule G13: Entering scores is only allowed for organizers when match is in_progress
    final isLive = projection.value?.status == 'in_progress';
    canEnterScores.value = (user?.isOrganizer ?? false) && isLive;
  }

  Future<void> loadProjection() async {
    isLoading.value = true;
    hasError.value = false;

    final result = await matchService.getScoreProjection(matchId);

    isLoading.value = false;

    if (result.isSuccess) {
      projection.value = result.dataOrNull;
      _updatePermission();
      _startLiveTimerIfNeeded();
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

  /// Rule G10: Switch to Store tab without creating stacked navigation shells
  void openStoreMerchandise() {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().switchTab(2);
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.main);
    }
  }
}
