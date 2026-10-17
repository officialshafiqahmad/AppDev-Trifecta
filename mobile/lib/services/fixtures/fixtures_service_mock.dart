import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import 'fixtures_service.dart';

/// Mock fixtures service backed by local CacheService.
class FixturesServiceMock implements FixturesService {
  FixturesServiceMock({required this.cacheService});

  final CacheService cacheService;
  static const String _cacheKeyFixtures = 'cache_fixtures_list';

  static final List<MatchSummary> _mockMatches = [
    MatchSummary(
      matchId: 'm-alpha-1',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-1',
      homeTeamName: 'Alpha FC',
      awayTeamId: 'club-alpha-2',
      awayTeamName: 'Alpha United',
      status: 'in_progress',
      startsAt: DateTime.now().subtract(const Duration(minutes: 42)),
      sport: 'Football',
      homeScore: 2,
      awayScore: 1,
      venueName: 'A-01 Main Arena',
    ),
    MatchSummary(
      matchId: 'm-alpha-2',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-2',
      homeTeamName: 'Alpha United',
      awayTeamId: 'club-beta-1',
      awayTeamName: 'Beta Titans',
      status: 'upcoming',
      startsAt: DateTime.now().add(const Duration(hours: 3)),
      sport: 'Football',
      venueName: 'A-02 Pitch West',
    ),
    MatchSummary(
      matchId: 'm-alpha-3',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-1',
      homeTeamName: 'Alpha FC',
      awayTeamId: 'club-beta-1',
      awayTeamName: 'Beta Titans',
      status: 'completed',
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      sport: 'Football',
      homeScore: 3,
      awayScore: 0,
      venueName: 'A-101 Field',
    ),
    MatchSummary(
      matchId: 'm-alpha-4',
      leagueId: 'league-alpha-2',
      homeTeamId: 'club-alpha-1',
      homeTeamName: 'Alpha Kings',
      awayTeamId: 'club-beta-1',
      awayTeamName: 'Beta Wolves',
      status: 'in_progress',
      startsAt: DateTime.now().subtract(const Duration(minutes: 25)),
      sport: 'Basketball',
      homeScore: 54,
      awayScore: 48,
      venueName: 'A-102 Indoor Court',
    ),
  ];

  @override
  Future<Result<List<MatchSummary>>> getFixtures({String? leagueId}) async {
    // 1. Try cache first for true offline capability
    try {
      final cachedRes = await cacheService.get(_cacheKeyFixtures);
      final cached = cachedRes.dataOrNull;
      if (cached != null && cached.containsKey('matches')) {
        final list = (cached['matches'] as List<dynamic>)
            .map((item) => MatchSummary.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          if (leagueId != null) {
            return Success(list.where((m) => m.leagueId == leagueId).toList());
          }
          return Success(list);
        }
      }
    } catch (_) {}

    // 2. Fallback to mock data and store to cache
    await cacheService.put(_cacheKeyFixtures, {
      'matches': _mockMatches.map((m) => m.toJson()).toList(),
    });

    if (leagueId != null) {
      return Success(_mockMatches.where((m) => m.leagueId == leagueId).toList());
    }
    return Success(_mockMatches);
  }

  @override
  Future<Result<MatchSummary>> getMatchSummary(String matchId) async {
    final listRes = await getFixtures();
    if (listRes.isFailure) return Failure(listRes.failureOrNull!);

    final matches = listRes.dataOrNull!;
    final match = matches.firstWhere(
      (m) => m.matchId == matchId,
      orElse: () => _mockMatches.first,
    );
    return Success(match);
  }
}
