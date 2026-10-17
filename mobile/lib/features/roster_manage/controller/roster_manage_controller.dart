import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';
import '../../../services/roster/roster_service.dart';
import '../../../services/sync/sync_service.dart';

/// Controller managing roster operations (transfer, loan, release, add player) and audit trails.
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

  // Sub-tab: 0 = Operations (Transfer/Loan/Release), 1 = Add Player
  final RxInt activeSubTab = 0.obs;

  final RxList<Player> availablePlayers = <Player>[].obs;
  final Rx<Player?> selectedPlayer = Rx<Player?>(null);

  final RxString actionType = 'transfer'.obs; // transfer | loan | release
  final RxString targetSquadId = 'squad-reserves'.obs;
  final TextEditingController reasonController = TextEditingController();

  // Rule C29 & G8: Native Date Pickers
  final Rx<DateTime> effectiveDate = DateTime.now().obs;
  final Rx<DateTime> loanEndDate = DateTime.now().add(const Duration(days: 30)).obs;

  // Rule A2: Add Player form fields
  final TextEditingController newPlayerNameController = TextEditingController();
  final TextEditingController newPlayerJerseyController = TextEditingController();
  final RxString newPlayerPosition = 'Forward / Striker'.obs;
  final RxString newPlayerSquad = 'squad-alpha-1'.obs;

  final RxList<AuditEntry> playerHistory = <AuditEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Rule B8: Role guard verification on entry
    final user = authService.currentUser;
    if (user == null ||
        (user.role != UserRole.superAdmin &&
            user.role != UserRole.organizer &&
            user.role != UserRole.clubManager)) {
      AppSnackbar.error(AppStrings.errForbidden);
      Get.back();
      return;
    }
    loadClubPlayers();
  }

  @override
  void onClose() {
    reasonController.dispose();
    newPlayerNameController.dispose();
    newPlayerJerseyController.dispose();
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
      if (roster.isNotEmpty && (selectedPlayer.value == null || !roster.contains(selectedPlayer.value))) {
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

  void setSubTab(int index) {
    activeSubTab.value = index;
  }

  // Rule C29 & G8: Pick effective date
  Future<void> pickEffectiveDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      effectiveDate.value = picked;
      if (loanEndDate.value.isBefore(picked.add(const Duration(days: 1)))) {
        loanEndDate.value = picked.add(const Duration(days: 30));
      }
    }
  }

  // Rule C29 & G8: Pick loan end date with validation
  Future<void> pickLoanEndDate(BuildContext context) async {
    final minDate = effectiveDate.value.add(const Duration(days: 1));
    final initial = loanEndDate.value.isAfter(minDate) ? loanEndDate.value : minDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: effectiveDate.value.add(const Duration(days: 730)),
    );
    if (picked != null) {
      loanEndDate.value = picked;
    }
  }

  /// Rule A2: Register a new player into squad
  Future<void> submitAddPlayer() async {
    if (isSubmitting.value) return;

    final name = newPlayerNameController.text.trim();
    final jerseyText = newPlayerJerseyController.text.trim();

    if (name.isEmpty || jerseyText.isEmpty) {
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

    final jerseyNumber = int.tryParse(jerseyText) ?? 10;

    isSubmitting.value = true;

    final res = await rosterService.addPlayer(
      clubId: 'club-alpha-1',
      squadId: newPlayerSquad.value,
      name: name,
      position: newPlayerPosition.value,
      jerseyNumber: jerseyNumber,
    );

    isSubmitting.value = false;

    if (res.isSuccess) {
      newPlayerNameController.clear();
      newPlayerJerseyController.clear();
      AppSnackbar.success(AppStrings.rosterAddPlayerSuccess);
      await loadClubPlayers();
      activeSubTab.value = 0; // Return to roster operations
    } else {
      AppSnackbar.error(res.failureOrNull?.userMessageKey ?? AppStrings.errDefault);
    }
  }

  /// Rule G9 & A5: Submit transfer with double-tap guard and per-player base version
  Future<void> submitRosterAction() async {
    // Rule G9: Guard double taps
    if (isSubmitting.value) return;
    if (selectedPlayer.value == null) return;

    final player = selectedPlayer.value!;
    final reason = reasonController.text.trim();

    if (reason.isEmpty) {
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

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

    // Rule A5: Read player's individual base version
    final versionRes = await rosterService.getPlayerBaseVersion(player.playerId);
    final baseVersion = versionRes.dataOrNull ?? 1;

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
      effectiveDate: DateFormat('yyyy-MM-dd').format(effectiveDate.value),
      loanEndDate: actionType.value == 'loan'
          ? DateFormat('yyyy-MM-dd').format(loanEndDate.value)
          : null,
      reason: reason,
      requestedBy: requestedBy,
      baseVersion: baseVersion,
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
