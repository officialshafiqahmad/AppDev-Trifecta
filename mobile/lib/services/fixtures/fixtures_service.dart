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
      matchId: json['matchId'] as String,
      leagueId: json['leagueId'] as String,
      homeTeamId: json['homeTeamId'] as String,
      homeTeamName: json['homeTeamName'] as String,
      awayTeamId: json['awayTeamId'] as String,
      awayTeamName: json['awayTeamName'] as String,
      status: json['status'] as String,
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
      sport: json['sport'] as String? ?? 'Football',
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      venueName: json['venueName'] as String? ?? 'A-01 Main Arena',
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'leagueId': leagueId,
        'homeTeamId': homeTeamId,
        'homeTeamName': homeTeamName,
        'awayTeamId': awayTeamId,
        'awayTeamName': awayTeamName,
        'status': status,
        'startsAt': startsAt.toIso8601String(),
        'sport': sport,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'venueName': venueName,
      };
}

/// Fixtures service contract.
abstract class FixturesService {
  Future<Result<List<MatchSummary>>> getFixtures({String? leagueId});
  Future<Result<MatchSummary>> getMatchSummary(String matchId);
}
