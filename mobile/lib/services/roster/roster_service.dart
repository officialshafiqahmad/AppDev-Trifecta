import '../../core/utils/result.dart';

/// Transfer request model according to API_MODELS.md §2.3.
class TransferRequest {
  const TransferRequest({
    required this.requestId,
    required this.leagueId,
    required this.playerId,
    required this.type, // transfer | loan | release
    required this.fromSquadId,
    this.toSquadId,
    required this.effectiveDate,
    this.loanEndDate,
    required this.reason,
    required this.requestedBy,
    this.baseVersion = 1,
  });

  final String requestId;
  final String leagueId;
  final String playerId;
  final String type;
  final String fromSquadId;
  final String? toSquadId;
  final String effectiveDate;
  final String? loanEndDate;
  final String reason;
  final String requestedBy;
  final int baseVersion;

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'league_id': leagueId,
        'player_id': playerId,
        'type': type,
        'from_squad_id': fromSquadId,
        'to_squad_id': toSquadId,
        'effective_date': effectiveDate,
        'loan_end_date': loanEndDate,
        'reason': reason,
        'requested_by': requestedBy,
        'base_version': baseVersion,
      };

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    return TransferRequest(
      requestId: (json['request_id'] ?? json['requestId']) as String,
      leagueId: (json['league_id'] ?? json['leagueId']) as String,
      playerId: (json['player_id'] ?? json['playerId']) as String,
      type: (json['type']) as String,
      fromSquadId: (json['from_squad_id'] ?? json['fromSquadId']) as String,
      toSquadId: (json['to_squad_id'] ?? json['toSquadId']) as String?,
      effectiveDate: (json['effective_date'] ?? json['effectiveDate']) as String,
      loanEndDate: (json['loan_end_date'] ?? json['loanEndDate']) as String?,
      reason: (json['reason']) as String,
      requestedBy: (json['requested_by'] ?? json['requestedBy']) as String,
      baseVersion: (json['base_version'] ?? json['baseVersion']) as int? ?? 1,
    );
  }
}

/// Audit trail history entry.
class AuditEntry {
  const AuditEntry({
    required this.auditId,
    required this.action,
    required this.playerId,
    required this.leagueId,
    required this.fromSquadId,
    this.toSquadId,
    required this.state,
    required this.who,
    required this.when,
    required this.effectiveDate,
    required this.why,
  });

  final String auditId;
  final String action;
  final String playerId;
  final String leagueId;
  final String fromSquadId;
  final String? toSquadId;
  final String state;
  final String who;
  final DateTime when;
  final String effectiveDate;
  final String why;

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      auditId: (json['audit_id'] ?? json['auditId']) as String,
      action: (json['action']) as String,
      playerId: (json['player_id'] ?? json['playerId']) as String,
      leagueId: (json['league_id'] ?? json['leagueId']) as String,
      fromSquadId: (json['from_squad_id'] ?? json['fromSquadId']) as String,
      toSquadId: (json['to_squad_id'] ?? json['toSquadId']) as String?,
      state: (json['state']) as String? ?? 'active',
      who: (json['who']) as String,
      when: DateTime.tryParse((json['when']) as String? ?? '') ?? DateTime.now(),
      effectiveDate: (json['effective_date'] ?? json['effectiveDate']) as String,
      why: (json['why']) as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'audit_id': auditId,
        'action': action,
        'player_id': playerId,
        'league_id': leagueId,
        'from_squad_id': fromSquadId,
        'to_squad_id': toSquadId,
        'state': state,
        'who': who,
        'when': when.toIso8601String(),
        'effective_date': effectiveDate,
        'why': why,
      };
}

/// Transfer result outcome according to API_MODELS.md §2.
class TransferResult {
  const TransferResult({
    required this.requestId,
    required this.status,
    required this.state,
    this.blockingMatchId,
    required this.registration,
    required this.auditEntry,
  });

  final String requestId;
  final String status;
  final String state;
  final String? blockingMatchId;
  final Map<String, dynamic> registration; // registration_id, player_id, squad_id, state, base_version
  final AuditEntry auditEntry;

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      requestId: (json['request_id'] ?? json['requestId']) as String,
      status: (json['status']) as String,
      state: (json['state']) as String,
      blockingMatchId: (json['blocking_match_id'] ?? json['blockingMatchId']) as String?,
      registration: (json['registration'] as Map<String, dynamic>?) ?? {},
      auditEntry: AuditEntry.fromJson(json['audit_entry'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'status': status,
        'state': state,
        'blocking_match_id': blockingMatchId,
        'registration': registration,
        'audit_entry': auditEntry.toJson(),
      };
}

/// Roster service contract.
abstract class RosterService {
  Future<Result<TransferResult>> submitTransfer(TransferRequest request);
  Future<Result<List<AuditEntry>>> getPlayerHistory(String playerId);
  Future<Result<int>> getPlayerBaseVersion(String playerId);
  Future<Result<void>> addPlayer({
    required String clubId,
    required String squadId,
    required String name,
    required String position,
    required int jerseyNumber,
  });
}
