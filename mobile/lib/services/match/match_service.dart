import '../../core/utils/result.dart';

/// Team score representation inside a match score projection.
class TeamScore {
  const TeamScore({
    required this.teamId,
    required this.teamName,
    required this.score,
    this.wickets,
    this.balls,
    this.overs,
    this.fairPlay = 10,
  });

  final String teamId;
  final String teamName;
  final int score;
  final int? wickets;
  final int? balls;
  final String? overs;
  final int fairPlay;

  factory TeamScore.fromJson(Map<String, dynamic> json) {
    return TeamScore(
      teamId: (json['team_id'] ?? json['teamId']) as String,
      teamName: (json['team_name'] ?? json['teamName']) as String? ?? 'Team',
      score: (json['score']) as int? ?? 0,
      wickets: (json['wickets']) as int?,
      balls: (json['balls']) as int?,
      overs: (json['overs']) as String?,
      fairPlay: (json['fair_play'] ?? json['fairPlay']) as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'team_name': teamName,
        'score': score,
        'wickets': wickets,
        'balls': balls,
        'overs': overs,
        'fair_play': fairPlay,
      };
}

/// Match event representation strictly adhering to API_MODELS.md §2.
/// Hard law: Must NOT contain a timestamp field.
class MatchEvent {
  const MatchEvent({
    required this.sequence,
    required this.eventId,
    required this.type, // match_init|match_start|score|discipline|tiebreak_winner|match_end|compensation
    required this.payload,
    required this.signature,
    this.compensated = false,
    this.compensatedBy,
  });

  final int sequence;
  final String eventId;
  final String type;
  final Map<String, dynamic> payload;
  final String signature;
  final bool compensated;
  final String? compensatedBy;

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      sequence: (json['sequence']) as int? ?? 1,
      eventId: (json['event_id'] ?? json['eventId']) as String,
      type: (json['type']) as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      signature: (json['signature']) as String? ?? 'sig-mock',
      compensated: (json['compensated']) as bool? ?? false,
      compensatedBy: (json['compensated_by'] ?? json['compensatedBy']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'event_id': eventId,
        'type': type,
        'payload': payload,
        'signature': signature,
        'compensated': compensated,
        'compensated_by': compensatedBy,
      };
}

/// Complete score projection representation.
class ScoreProjection {
  const ScoreProjection({
    required this.matchId,
    required this.sportId,
    this.leagueId,
    required this.status, // upcoming | in_progress | completed
    required this.outcome, // pending | home_win | away_win | draw | undecided
    this.winnerTeamId,
    this.tiebreakWinnerTeamId,
    required this.home,
    required this.away,
    required this.version,
    required this.events,
  });

  final String matchId;
  final String sportId;
  final String? leagueId;
  final String status;
  final String outcome;
  final String? winnerTeamId;
  final String? tiebreakWinnerTeamId;
  final TeamScore home;
  final TeamScore away;
  final int version;
  final List<MatchEvent> events;

  bool get isLive => status == 'in_progress';

  ScoreProjection copyWith({
    String? status,
    String? outcome,
    TeamScore? home,
    TeamScore? away,
    int? version,
    List<MatchEvent>? events,
  }) {
    return ScoreProjection(
      matchId: matchId,
      sportId: sportId,
      leagueId: leagueId,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      winnerTeamId: winnerTeamId,
      tiebreakWinnerTeamId: tiebreakWinnerTeamId,
      home: home ?? this.home,
      away: away ?? this.away,
      version: version ?? this.version,
      events: events ?? this.events,
    );
  }

  factory ScoreProjection.fromJson(Map<String, dynamic> json) {
    return ScoreProjection(
      matchId: (json['match_id'] ?? json['matchId']) as String,
      sportId: (json['sport_id'] ?? json['sportId']) as String,
      leagueId: (json['league_id'] ?? json['leagueId']) as String?,
      status: (json['status']) as String,
      outcome: (json['outcome']) as String? ?? 'pending',
      winnerTeamId: (json['winner_team_id'] ?? json['winnerTeamId']) as String?,
      tiebreakWinnerTeamId: (json['tiebreak_winner_team_id'] ?? json['tiebreakWinnerTeamId']) as String?,
      home: TeamScore.fromJson(json['home'] as Map<String, dynamic>),
      away: TeamScore.fromJson(json['away'] as Map<String, dynamic>),
      version: (json['version']) as int? ?? 1,
      events: ((json['events']) as List<dynamic>? ?? [])
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'sport_id': sportId,
        'league_id': leagueId,
        'status': status,
        'outcome': outcome,
        'winner_team_id': winnerTeamId,
        'tiebreak_winner_team_id': tiebreakWinnerTeamId,
        'home': home.toJson(),
        'away': away.toJson(),
        'version': version,
        'events': events.map((e) => e.toJson()).toList(),
      };
}

/// Match service contract.
abstract class MatchService {
  Future<Result<ScoreProjection>> getScoreProjection(String matchId);

  Future<Result<MatchEvent>> postEvent({
    required String matchId,
    required String type,
    required Map<String, dynamic> payload,
  });

  Future<Result<MatchEvent>> compensateEvent({
    required String matchId,
    required String targetEventId,
    required String reason,
  });
}
