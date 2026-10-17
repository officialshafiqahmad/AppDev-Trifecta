import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../sync/sync_service.dart';
import 'roster_service.dart';

/// Mock RosterService with offline queue integration.
class RosterServiceMock implements RosterService {
  RosterServiceMock({required this.syncService});

  final SyncService syncService;

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

    // 2. If offline, queue in SyncService!
    if (!syncService.isOnline) {
      await syncService.queueAction(
        type: 'roster_transfer',
        baseVersion: _historyStore.length,
        payload: request.toJson(),
      );
    }

    _historyStore.insert(0, entry);

    return Success(
      TransferResult(
        requestId: request.requestId,
        status: 'accepted',
        state: 'active',
        auditEntry: entry,
      ),
    );
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
