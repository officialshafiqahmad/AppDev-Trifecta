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
      };

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    return TransferRequest(
      requestId: json['request_id'] as String,
      leagueId: json['league_id'] as String,
      playerId: json['player_id'] as String,
      type: json['type'] as String,
      fromSquadId: json['from_squad_id'] as String,
      toSquadId: json['to_squad_id'] as String?,
      effectiveDate: json['effective_date'] as String,
      loanEndDate: json['loan_end_date'] as String?,
      reason: json['reason'] as String,
      requestedBy: json['requested_by'] as String,
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
      auditId: json['audit_id'] as String,
      action: json['action'] as String,
      playerId: json['player_id'] as String,
      leagueId: json['league_id'] as String,
      fromSquadId: json['from_squad_id'] as String,
      toSquadId: json['to_squad_id'] as String?,
      state: json['state'] as String? ?? 'active',
      who: json['who'] as String,
      when: DateTime.tryParse(json['when'] as String? ?? '') ?? DateTime.now(),
      effectiveDate: json['effective_date'] as String,
      why: json['why'] as String,
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

/// Transfer result outcome.
class TransferResult {
  const TransferResult({
    required this.requestId,
    required this.status,
    required this.state,
    this.blockingMatchId,
    required this.auditEntry,
  });

  final String requestId;
  final String status;
  final String state;
  final String? blockingMatchId;
  final AuditEntry auditEntry;
}

/// Roster service contract.
abstract class RosterService {
  Future<Result<TransferResult>> submitTransfer(TransferRequest request);
  Future<Result<List<AuditEntry>>> getPlayerHistory(String playerId);
}
