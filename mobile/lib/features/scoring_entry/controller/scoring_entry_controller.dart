import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/club/club_service.dart';
import '../../../services/match/match_service.dart';
import '../../../services/sync/sync_service.dart';

/// Controller managing score event appending and compensation events (undo).
class ScoringEntryController extends GetxController {
  ScoringEntryController({
    required this.matchService,
    required this.syncService,
    required this.clubService,
  });

  final MatchService matchService;
  final SyncService syncService;
  final ClubService clubService;

  late final String matchId;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final Rx<ScoreProjection?> projection = Rx<ScoreProjection?>(null);
  final RxInt activeTab = 0.obs; // 0: Append Score, 1: Compensate

  // Score Event Form (C31, G11)
  final RxString selectedTeamId = ''.obs;
  final RxString selectedEventType = 'goal'.obs;
  final RxInt minute = 54.obs;
  final RxString selectedPlayer = ''.obs;
  final RxList<String> rosterPlayers = <String>[].obs;
  final TextEditingController playerController = TextEditingController();

  // Compensation Form (C32)
  final Rx<MatchEvent?> selectedCompensateEvent = Rx<MatchEvent?>(null);
  final TextEditingController reasonController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    matchId = (args is String && args.isNotEmpty) ? args : 'm-alpha-1';
    loadMatch();
    loadRoster();
  }

  @override
  void onClose() {
    playerController.dispose();
    reasonController.dispose();
    super.onClose();
  }

  Future<void> loadRoster() async {
    final res = await clubService.getClubProfile('club-alpha-1');
    if (res.isSuccess && res.dataOrNull != null) {
      rosterPlayers.assignAll(res.dataOrNull!.roster.map((p) => p.name).toList());
      if (rosterPlayers.isNotEmpty && selectedPlayer.value.isEmpty) {
        selectedPlayer.value = rosterPlayers.first;
      }
    }
  }

  Future<void> loadMatch() async {
    isLoading.value = true;
    hasError.value = false;

    final res = await matchService.getScoreProjection(matchId);

    isLoading.value = false;

    if (res.isSuccess && res.dataOrNull != null) {
      final proj = res.dataOrNull!;
      projection.value = proj;
      selectedTeamId.value = proj.home.teamId;

      // Rule G13: Entering scoring on completed or scheduled match gives errMatchNotInProgress
      if (proj.status != 'in_progress') {
        hasError.value = true;
        errorMessageKey.value = AppStrings.errMatchNotInProgress;
        return;
      }

      final compensatable = proj.events.where((e) => !e.compensated && e.type != 'match_init').toList();
      if (compensatable.isNotEmpty) {
        selectedCompensateEvent.value = compensatable.last;
      }
    } else {
      hasError.value = true;
      errorMessageKey.value = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void setActiveTab(int tab) {
    activeTab.value = tab;
  }

  void incrementMinute() {
    if (minute.value < 120) minute.value++;
  }

  void decrementMinute() {
    if (minute.value > 1) minute.value--;
  }

  Future<void> appendScoreEvent() async {
    // Rule G9: double-tap guard
    if (isSubmitting.value) return;

    // Rule G13 guard
    if (projection.value == null || projection.value!.status != 'in_progress') {
      AppSnackbar.error(AppStrings.errMatchNotInProgress);
      return;
    }

    final player = selectedPlayer.value.isNotEmpty ? selectedPlayer.value : playerController.text.trim();
    if (player.isEmpty) {
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

    isSubmitting.value = true;

    // Rule G11: payload sends integer minute
    final payload = {
      'team_id': selectedTeamId.value,
      'event_type': selectedEventType.value,
      'minute': minute.value, // integer per Rule G11
      'player': player,
    };

    final res = await matchService.postEvent(
      matchId: matchId,
      type: 'score',
      payload: payload,
    );

    isSubmitting.value = false;

    if (res.isSuccess) {
      playerController.clear();
      await loadMatch();

      if (!syncService.isOnline) {
        AppSnackbar.info('Score event queued offline in pending queue');
      } else {
        AppSnackbar.success(AppStrings.successSaved);
      }
    } else {
      final msgKey = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
      AppSnackbar.error(msgKey);
    }
  }

  Future<void> submitCompensation() async {
    // Rule G9: double-tap guard
    if (isSubmitting.value) return;

    if (selectedCompensateEvent.value == null) return;

    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

    final confirmed = await AppDialog.confirm(
      titleKey: AppStrings.scoringCompensateConfirm,
      bodyKey: AppStrings.scoringCompensateConfirmBody,
      confirmLabelKey: AppStrings.commonConfirm,
    );

    if (!confirmed) return;

    isSubmitting.value = true;

    final res = await matchService.compensateEvent(
      matchId: matchId,
      targetEventId: selectedCompensateEvent.value!.eventId,
      reason: reason,
    );

    isSubmitting.value = false;

    if (res.isSuccess) {
      reasonController.clear();
      await loadMatch();

      if (!syncService.isOnline) {
        AppSnackbar.info('Compensation event queued offline in pending queue');
      } else {
        AppSnackbar.success(AppStrings.successSaved);
      }
    } else {
      final msgKey = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
      AppSnackbar.error(msgKey);
    }
  }
}
