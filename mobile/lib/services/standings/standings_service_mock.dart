import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import 'standings_service.dart';

/// Mock StandingsService with local persistent cache.
class StandingsServiceMock implements StandingsService {
  StandingsServiceMock({required this.cacheService});

  final CacheService cacheService;

  static const StandingsResult _mockStandings = StandingsResult(
    leagueId: 'league-alpha-1',
    leagueName: 'Premier Championship',
    sportId: 'football',
    qualificationSpots: 2,
    rows: [
      StandingRow(
        rank: 1,
        teamId: 'club-alpha-1',
        teamName: 'Alpha FC',
        played: 10,
        won: 8,
        drawn: 1,
        lost: 1,
        scored: 24,
        conceded: 7,
        diff: 17,
        points: 25,
        fairPlay: 9,
        status: 'clinched',
        resolvedBy: 'Goal Difference',
      ),
      StandingRow(
        rank: 2,
        teamId: 'club-alpha-2',
        teamName: 'Alpha United',
        played: 10,
        won: 6,
        drawn: 2,
        lost: 2,
        scored: 18,
        conceded: 11,
        diff: 7,
        points: 20,
        fairPlay: 8,
        status: 'still_possible',
      ),
      StandingRow(
        rank: 3,
        teamId: 'club-beta-1',
        teamName: 'Beta Titans',
        played: 10,
        won: 3,
        drawn: 1,
        lost: 6,
        scored: 12,
        conceded: 19,
        diff: -7,
        points: 10,
        fairPlay: 7,
        status: 'eliminated',
      ),
      StandingRow(
        rank: 4,
        teamId: 'club-beta-2',
        teamName: 'Beta Athletic',
        played: 10,
        won: 1,
        drawn: 0,
        lost: 9,
        scored: 6,
        conceded: 23,
        diff: -17,
        points: 3,
        fairPlay: 8,
        status: 'eliminated',
      ),
    ],
  );

  @override
  Future<Result<StandingsResult>> getStandings(String leagueId) async {
    final cacheKey = 'cache_standings_$leagueId';

    // 1. Try cache
    try {
      final cachedRes = await cacheService.get(cacheKey);
      final cached = cachedRes.dataOrNull;
      if (cached != null) {
        return Success(StandingsResult.fromJson(cached));
      }
    } catch (_) {}

    // 2. Cache default mock and return
    await cacheService.put(cacheKey, _mockStandings.toJson());
    return const Success(_mockStandings);
  }
}
