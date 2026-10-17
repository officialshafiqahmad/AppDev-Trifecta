import '../../core/utils/result.dart';

/// Match summary model according to API_MODELS.md §2.
class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.leagueId,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.status, // upcoming | in_progress | completed | postponed | abandoned | cancelled
    required this.startsAt,
    required this.sport,
    this.homeScore,
    this.awayScore,
    this.venueName = 'A-01 Main Arena',
  });

  final String matchId;
  final String leagueId;
  final String homeTeamId;
  final String homeTeamName;
  final String awayTeamId;
  final String awayTeamName;
  final String status;
  final DateTime startsAt;
  final String sport;
  final int? homeScore;
  final int? awayScore;
  final String venueName;

  bool get isLive => status == 'in_progress';
  bool get isUpcoming => status == 'upcoming';
  bool get isCompleted => status == 'completed';

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: (json['match_id'] ?? json['matchId']) as String,
      leagueId: (json['league_id'] ?? json['leagueId']) as String,
      homeTeamId: (json['home_team_id'] ?? json['homeTeamId']) as String,
      homeTeamName: (json['home_team_name'] ?? json['homeTeamName']) as String? ?? 'Home Team',
      awayTeamId: (json['away_team_id'] ?? json['awayTeamId']) as String,
      awayTeamName: (json['away_team_name'] ?? json['awayTeamName']) as String? ?? 'Away Team',
      status: (json['status']) as String,
      startsAt: DateTime.tryParse((json['starts_at'] ?? json['startsAt']) as String? ?? '') ?? DateTime.now(),
      sport: (json['sport']) as String? ?? 'Football',
      homeScore: (json['home_score'] ?? json['homeScore']) as int?,
      awayScore: (json['away_score'] ?? json['awayScore']) as int?,
      venueName: (json['venue_name'] ?? json['venueName']) as String? ?? 'A-01 Main Arena',
    );
  }

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'league_id': leagueId,
        'home_team_id': homeTeamId,
        'home_team_name': homeTeamName,
        'away_team_id': awayTeamId,
        'away_team_name': awayTeamName,
        'status': status,
        'starts_at': startsAt.toIso8601String(),
        'sport': sport,
        'home_score': homeScore,
        'away_score': awayScore,
        'venue_name': venueName,
      };
}

/// Fixtures service contract.
abstract class FixturesService {
  Future<Result<List<MatchSummary>>> getFixtures({String? leagueId});
  Future<Result<MatchSummary>> getMatchSummary(String matchId);
}
