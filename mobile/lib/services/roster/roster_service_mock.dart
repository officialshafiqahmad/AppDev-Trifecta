import 'package:get/get.dart';
import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../club/club_service.dart';
import '../club/club_service_mock.dart';
import '../sync/sync_service.dart';
import 'roster_service.dart';

/// Mock RosterService with per-player base versioning and offline queue integration.
class RosterServiceMock implements RosterService {
  RosterServiceMock({required this.syncService});

  final SyncService syncService;

  // Rule A5: Per-player base versions map
  static final Map<String, int> _playerBaseVersions = {
    'player-alpha-1': 1,
    'player-alpha-2': 1,
    'player-alpha-3': 1,
    'player-alpha-4': 1,
    'player-alpha-5': 1,
  };

  static final List<AuditEntry> _historyStore = [
    AuditEntry(
      auditId: 'aud-init-1',
      action: 'registration',
      playerId: 'player-alpha-1',
      leagueId: 'league-alpha-1',
      fromSquadId: 'squad-alpha-youth',
      toSquadId: 'squad-alpha-1',
      state: 'active',
      who: 'manager@nascon.test',
      when: DateTime.now().subtract(const Duration(days: 45)),
      effectiveDate: '2026-09-01',
      why: 'Initial season registration',
    ),
    AuditEntry(
      auditId: 'aud-loan-1',
      action: 'loan',
      playerId: 'player-alpha-1',
      leagueId: 'league-alpha-1',
      fromSquadId: 'squad-alpha-1',
      toSquadId: 'squad-beta-1',
      state: 'completed',
      who: 'manager@nascon.test',
      when: DateTime.now().subtract(const Duration(days: 20)),
      effectiveDate: '2026-09-27',
      why: 'Short-term development loan',
    ),
  ];

  @override
  Future<Result<int>> getPlayerBaseVersion(String playerId) async {
    return Success(_playerBaseVersions[playerId] ?? 1);
  }

  @override
  Future<Result<TransferResult>> submitTransfer(TransferRequest request) async {
    // 1. Validation check
    if (request.reason.trim().isEmpty) {
      return const Failure(
        AppFailure(
          code: 'VALIDATION_ERROR',
          userMessageKey: AppStrings.errValidation,
        ),
      );
    }

    // 2. Rule A5: Per-player base version validation
    final currentVersion = _playerBaseVersions[request.playerId] ?? 1;
    if (request.baseVersion != currentVersion) {
      return const Failure(
        AppFailure(
          code: 'INVALID_BASE_VERSION',
          userMessageKey: AppStrings.errInvalidBaseVersion,
        ),
      );
    }

    final auditId = 'aud-${DateTime.now().millisecondsSinceEpoch}';
    final entry = AuditEntry(
      auditId: auditId,
      action: request.type,
      playerId: request.playerId,
      leagueId: request.leagueId,
      fromSquadId: request.fromSquadId,
      toSquadId: request.toSquadId,
      state: 'active',
      who: request.requestedBy,
      when: DateTime.now(),
      effectiveDate: request.effectiveDate,
      why: request.reason,
    );

    // 3. Queue offline if disconnected
    if (!syncService.isOnline) {
      await syncService.queueAction(
        type: 'roster_transfer',
        baseVersion: currentVersion,
        payload: request.toJson(),
      );
    }

    // Increment player base version on mutation
    final newVersion = currentVersion + 1;
    _playerBaseVersions[request.playerId] = newVersion;
    _historyStore.insert(0, entry);

    return Success(
      TransferResult(
        requestId: request.requestId,
        status: 'accepted',
        state: 'active',
        registration: {
          'registration_id': 'reg-${DateTime.now().millisecondsSinceEpoch}',
          'player_id': request.playerId,
          'squad_id': request.toSquadId ?? request.fromSquadId,
          'state': 'active',
          'base_version': newVersion,
        },
        auditEntry: entry,
      ),
    );
  }

  @override
  Future<Result<void>> addPlayer({
    required String clubId,
    required String squadId,
    required String name,
    required String position,
    required int jerseyNumber,
  }) async {
    if (name.trim().isEmpty || position.trim().isEmpty) {
      return const Failure(
        AppFailure(
          code: 'VALIDATION_ERROR',
          userMessageKey: AppStrings.errValidation,
        ),
      );
    }

    final playerId = 'player-${DateTime.now().millisecondsSinceEpoch}';
    _playerBaseVersions[playerId] = 1;

    final player = Player(
      playerId: playerId,
      name: name.trim(),
      position: position.trim(),
      role: 'Player',
      jerseyNumber: jerseyNumber,
      squadId: squadId,
    );

    // If ClubService is available in GetX, update local club profile
    if (Get.isRegistered<ClubService>()) {
      final clubService = Get.find<ClubService>();
      if (clubService is ClubServiceMock) {
        clubService.addPlayerLocally(player);
      }
    }

    final auditId = 'aud-${DateTime.now().millisecondsSinceEpoch}';
    _historyStore.insert(
      0,
      AuditEntry(
        auditId: auditId,
        action: 'registration',
        playerId: playerId,
        leagueId: 'league-alpha-1',
        fromSquadId: 'external',
        toSquadId: squadId,
        state: 'active',
        who: 'manager@nascon.test',
        when: DateTime.now(),
        effectiveDate: DateTime.now().toIso8601String().split('T').first,
        why: 'New squad registration',
      ),
    );

    if (!syncService.isOnline) {
      await syncService.queueAction(
        type: 'roster_transfer',
        baseVersion: 1,
        payload: {
          'action': 'add_player',
          'player_id': playerId,
          'name': name,
          'position': position,
          'jersey_number': jerseyNumber,
          'squad_id': squadId,
        },
      );
    }

    return const Success(null);
  }

  @override
  Future<Result<List<AuditEntry>>> getPlayerHistory(String playerId) async {
    final list = _historyStore.where((e) => e.playerId == playerId).toList();
    if (list.isEmpty) {
      return Success(List.unmodifiable(_historyStore));
    }
    return Success(List.unmodifiable(list));
  }
}
