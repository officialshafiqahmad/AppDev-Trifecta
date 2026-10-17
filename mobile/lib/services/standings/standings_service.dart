import '../../core/utils/result.dart';

/// Standing table row representation.
class StandingRow {
  const StandingRow({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.scored,
    required this.conceded,
    required this.diff,
    required this.points,
    required this.fairPlay,
    required this.status, // clinched | eliminated | still_possible
    this.resolvedBy,
  });

  final int rank;
  final String teamId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int scored;
  final int conceded;
  final num diff;
  final int points;
  final int fairPlay;
  final String status;
  final String? resolvedBy;

  bool get isClinched => status == 'clinched';
  bool get isEliminated => status == 'eliminated';
  bool get isPossible => status == 'still_possible';

  factory StandingRow.fromJson(Map<String, dynamic> json) {
    return StandingRow(
      rank: (json['rank']) as int,
      teamId: (json['team_id'] ?? json['teamId']) as String,
      teamName: (json['team_name'] ?? json['teamName']) as String? ?? 'Team',
      played: (json['played']) as int,
      won: (json['won']) as int,
      drawn: (json['drawn']) as int,
      lost: (json['lost']) as int,
      scored: (json['scored']) as int,
      conceded: (json['conceded']) as int,
      diff: (json['diff']) as num,
      points: (json['points']) as int,
      fairPlay: (json['fair_play'] ?? json['fairPlay']) as int? ?? 10,
      status: (json['status']) as String? ?? 'still_possible',
      resolvedBy: (json['resolved_by'] ?? json['resolvedBy']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'team_id': teamId,
        'team_name': teamName,
        'played': played,
        'won': won,
        'drawn': drawn,
        'lost': lost,
        'scored': scored,
        'conceded': conceded,
        'diff': diff,
        'points': points,
        'fair_play': fairPlay,
        'status': status,
        'resolved_by': resolvedBy,
      };
}

/// Standings result with qualification spots and optional h2h tie-breaker data.
class StandingsResult {
  const StandingsResult({
    required this.leagueId,
    required this.leagueName,
    required this.sportId,
    required this.qualificationSpots,
    required this.rows,
    this.h2h,
  });

  final String leagueId;
  final String leagueName;
  final String sportId;
  final int qualificationSpots;
  final List<StandingRow> rows;
  final Map<String, dynamic>? h2h;

  factory StandingsResult.fromJson(Map<String, dynamic> json) {
    final rawTable = json['table'] ?? json['rows'];
    return StandingsResult(
      leagueId: (json['league_id'] ?? json['leagueId']) as String,
      leagueName: (json['league_name'] ?? json['leagueName']) as String? ?? 'League',
      sportId: (json['sport_id'] ?? json['sportId']) as String,
      qualificationSpots: (json['qualification_spots'] ?? json['qualificationSpots']) as int? ?? 2,
      rows: (rawTable as List<dynamic>? ?? [])
          .map((r) => StandingRow.fromJson(r as Map<String, dynamic>))
          .toList(),
      h2h: json['h2h'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'league_id': leagueId,
        'league_name': leagueName,
        'sport_id': sportId,
        'qualification_spots': qualificationSpots,
        'table': rows.map((r) => r.toJson()).toList(),
        if (h2h != null) 'h2h': h2h,
      };
}

/// Standings service contract.
abstract class StandingsService {
  Future<Result<StandingsResult>> getStandings(String leagueId);
}
