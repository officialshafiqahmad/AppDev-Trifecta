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
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String? ?? 'Team',
      score: json['score'] as int? ?? 0,
      wickets: json['wickets'] as int?,
      balls: json['balls'] as int?,
      overs: json['overs'] as String?,
      fairPlay: json['fairPlay'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'score': score,
        'wickets': wickets,
        'balls': balls,
        'overs': overs,
        'fairPlay': fairPlay,
      };
}

/// Match event representation.
class MatchEvent {
  const MatchEvent({
    required this.sequence,
    required this.eventId,
    required this.type, // match_init|match_start|score|discipline|tiebreak_winner|match_end|compensation
    required this.payload,
    required this.signature,
    this.compensated = false,
    this.compensatedBy,
    required this.timestamp,
  });

  final int sequence;
  final String eventId;
  final String type;
  final Map<String, dynamic> payload;
  final String signature;
  final bool compensated;
  final String? compensatedBy;
  final DateTime timestamp;

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      sequence: json['sequence'] as int? ?? 1,
      eventId: json['eventId'] as String,
      type: json['type'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      signature: json['signature'] as String? ?? 'sig-mock',
      compensated: json['compensated'] as bool? ?? false,
      compensatedBy: json['compensatedBy'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'eventId': eventId,
        'type': type,
        'payload': payload,
        'signature': signature,
        'compensated': compensated,
        'compensatedBy': compensatedBy,
        'timestamp': timestamp.toIso8601String(),
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
      matchId: json['matchId'] as String,
      sportId: json['sportId'] as String,
      leagueId: json['leagueId'] as String?,
      status: json['status'] as String,
      outcome: json['outcome'] as String? ?? 'pending',
      winnerTeamId: json['winnerTeamId'] as String?,
      tiebreakWinnerTeamId: json['tiebreakWinnerTeamId'] as String?,
      home: TeamScore.fromJson(json['home'] as Map<String, dynamic>),
      away: TeamScore.fromJson(json['away'] as Map<String, dynamic>),
      version: json['version'] as int? ?? 1,
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'sportId': sportId,
        'leagueId': leagueId,
        'status': status,
        'outcome': outcome,
        'winnerTeamId': winnerTeamId,
        'tiebreakWinnerTeamId': tiebreakWinnerTeamId,
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
