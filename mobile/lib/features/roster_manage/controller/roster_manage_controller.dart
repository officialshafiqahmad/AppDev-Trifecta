import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';
import '../../../services/roster/roster_service.dart';
import '../../../services/sync/sync_service.dart';

/// Controller managing roster mutations (transfer, loan, release) and player audit trails.
class RosterManageController extends GetxController {
  RosterManageController({
    required this.rosterService,
    required this.clubService,
    required this.authService,
    required this.syncService,
  });

  final RosterService rosterService;
  final ClubService clubService;
  final AuthService authService;
  final SyncService syncService;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final RxList<Player> availablePlayers = <Player>[].obs;
  final Rx<Player?> selectedPlayer = Rx<Player?>(null);

  final RxString actionType = 'transfer'.obs; // transfer | loan | release
  final RxString targetSquadId = 'squad-beta-1'.obs;
  final TextEditingController reasonController = TextEditingController();

  final RxList<AuditEntry> playerHistory = <AuditEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadClubPlayers();
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }

  Future<void> loadClubPlayers() async {
    isLoading.value = true;
    hasError.value = false;

    final clubRes = await clubService.getClubProfile('club-alpha-1');
    isLoading.value = false;

    if (clubRes.isSuccess && clubRes.dataOrNull != null) {
      final roster = clubRes.dataOrNull!.roster;
      availablePlayers.assignAll(roster);
      if (roster.isNotEmpty) {
        selectPlayer(roster.first);
      }
    } else {
      hasError.value = true;
      errorMessageKey.value = clubRes.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void selectPlayer(Player player) {
    selectedPlayer.value = player;
    loadHistory(player.playerId);
  }

  Future<void> loadHistory(String playerId) async {
    final histRes = await rosterService.getPlayerHistory(playerId);
    if (histRes.isSuccess) {
      playerHistory.assignAll(histRes.dataOrNull ?? []);
    }
  }

  void setActionType(String type) {
    actionType.value = type;
  }

  Future<void> submitRosterAction() async {
    if (selectedPlayer.value == null) return;

    final player = selectedPlayer.value!;
    final reason = reasonController.text.trim();

    if (reason.isEmpty) {
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

    // Confirmation dialog before risky release action
    if (actionType.value == 'release') {
      final confirmed = await AppDialog.confirm(
        titleKey: AppStrings.rosterReleaseConfirm,
        bodyKey: AppStrings.rosterReleaseBody,
        confirmLabelKey: AppStrings.rosterActionRelease,
        isDestructive: true,
      );
      if (!confirmed) return;
    }

    isSubmitting.value = true;

    final userRes = await authService.getCurrentUser();
    final requestedBy = userRes.dataOrNull?.email ?? 'manager@nascon.test';
    final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';

    final request = TransferRequest(
      requestId: requestId,
      leagueId: 'league-alpha-1',
      playerId: player.playerId,
      type: actionType.value,
      fromSquadId: player.squadId,
      toSquadId: actionType.value == 'release' ? null : targetSquadId.value,
      effectiveDate: '2026-10-17',
      loanEndDate: actionType.value == 'loan' ? '2026-12-31' : null,
      reason: reason,
      requestedBy: requestedBy,
    );

    final res = await rosterService.submitTransfer(request);

    isSubmitting.value = false;

    if (res.isSuccess) {
      reasonController.clear();
      await loadHistory(player.playerId);

      if (!syncService.isOnline) {
        AppSnackbar.info('Roster change saved offline in pending queue');
      } else {
        AppSnackbar.success(AppStrings.successSaved);
      }
    } else {
      final msgKey = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
      AppSnackbar.error(msgKey);
    }
  }
}
