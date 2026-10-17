import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import 'standings_service.dart';

/// Mock StandingsService supporting multi-league canonical data and persistent caching.
class StandingsServiceMock implements StandingsService {
  StandingsServiceMock({required this.cacheService});

  final CacheService cacheService;

  static const StandingsResult _premierDivision = StandingsResult(
    leagueId: 'league-alpha-1',
    leagueName: 'Premier Division',
    sportId: 'football',
    qualificationSpots: 2,
    rows: [
      StandingRow(
        rank: 1,
        teamId: 'club-alpha-1',
        teamName: 'Lahore FC',
        played: 1,
        won: 1,
        drawn: 0,
        lost: 0,
        scored: 2,
        conceded: 1,
        diff: 1,
        points: 3,
        fairPlay: 9,
        status: 'clinched',
        resolvedBy: 'Points',
      ),
      StandingRow(
        rank: 2,
        teamId: 'club-alpha-3',
        teamName: 'Islamabad United',
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        scored: 0,
        conceded: 0,
        diff: 0,
        points: 0,
        fairPlay: 10,
        status: 'still_possible',
      ),
      StandingRow(
        rank: 3,
        teamId: 'club-alpha-4',
        teamName: 'Peshawar Stars',
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        scored: 0,
        conceded: 0,
        diff: 0,
        points: 0,
        fairPlay: 10,
        status: 'still_possible',
      ),
      StandingRow(
        rank: 4,
        teamId: 'club-alpha-2',
        teamName: 'Karachi City',
        played: 1,
        won: 0,
        drawn: 0,
        lost: 1,
        scored: 1,
        conceded: 2,
        diff: -1,
        points: 0,
        fairPlay: 8,
        status: 'still_possible',
      ),
    ],
  );

  static const StandingsResult _divisionOne = StandingsResult(
    leagueId: 'league-beta-1',
    leagueName: 'Division One',
    sportId: 'football',
    qualificationSpots: 1,
    rows: [
      StandingRow(
        rank: 1,
        teamId: 'club-beta-1',
        teamName: 'Rawalpindi Royals',
        played: 2,
        won: 2,
        drawn: 0,
        lost: 0,
        scored: 4,
        conceded: 1,
        diff: 3,
        points: 6,
        fairPlay: 10,
        status: 'clinched',
      ),
      StandingRow(
        rank: 2,
        teamId: 'club-beta-2',
        teamName: 'Quetta Gladiators',
        played: 2,
        won: 1,
        drawn: 0,
        lost: 1,
        scored: 3,
        conceded: 2,
        diff: 1,
        points: 3,
        fairPlay: 8,
        status: 'still_possible',
      ),
      StandingRow(
        rank: 3,
        teamId: 'club-beta-3',
        teamName: 'Multan Sultans',
        played: 2,
        won: 0,
        drawn: 0,
        lost: 2,
        scored: 1,
        conceded: 5,
        diff: -4,
        points: 0,
        fairPlay: 7,
        status: 'eliminated',
      ),
    ],
  );

  @override
  Future<Result<StandingsResult>> getStandings(String leagueId) async {
    final cacheKey = 'cache_standings_canonical_$leagueId';

    try {
      final cachedRes = await cacheService.get(cacheKey);
      final cached = cachedRes.dataOrNull;
      if (cached != null) {
        return Success(StandingsResult.fromJson(cached));
      }
    } catch (_) {}

    final result = leagueId == 'league-beta-1' ? _divisionOne : _premierDivision;
    await cacheService.put(cacheKey, result.toJson());
    return Success(result);
  }
}
