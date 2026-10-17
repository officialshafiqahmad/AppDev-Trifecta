import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import 'fixtures_service.dart';

/// Mock fixtures service backed by local CacheService and canonical world.
class FixturesServiceMock implements FixturesService {
  FixturesServiceMock({required this.cacheService});

  final CacheService cacheService;
  static const String _cacheKeyFixtures = 'cache_fixtures_list_canonical';

  static final List<MatchSummary> _mockMatches = [
    MatchSummary(
      matchId: 'match-alpha-1',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-1',
      homeTeamName: 'Lahore FC',
      awayTeamId: 'club-alpha-2',
      awayTeamName: 'Karachi City',
      status: 'completed',
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      sport: 'Football',
      homeScore: 2,
      awayScore: 1,
      venueName: 'A-01 Main Arena',
    ),
    MatchSummary(
      matchId: 'match-alpha-2',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-3',
      homeTeamName: 'Islamabad United',
      awayTeamId: 'club-alpha-4',
      awayTeamName: 'Peshawar Stars',
      status: 'in_progress',
      startsAt: DateTime.now().subtract(const Duration(minutes: 35)),
      sport: 'Football',
      homeScore: 1,
      awayScore: 0,
      venueName: 'A-02 Pitch West',
    ),
    MatchSummary(
      matchId: 'match-alpha-3',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-1',
      homeTeamName: 'Lahore FC',
      awayTeamId: 'club-alpha-3',
      awayTeamName: 'Islamabad United',
      status: 'upcoming',
      startsAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      sport: 'Football',
      homeScore: null,
      awayScore: null,
      venueName: 'A-01 Main Arena',
    ),
    MatchSummary(
      matchId: 'match-alpha-4',
      leagueId: 'league-alpha-1',
      homeTeamId: 'club-alpha-2',
      homeTeamName: 'Karachi City',
      awayTeamId: 'club-alpha-4',
      awayTeamName: 'Peshawar Stars',
      status: 'upcoming',
      startsAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
      sport: 'Football',
      homeScore: null,
      awayScore: null,
      venueName: 'A-03 National Stadium',
    ),
  ];

  @override
  Future<Result<List<MatchSummary>>> getFixtures({String? leagueId}) async {
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

    await cacheService.put(_cacheKeyFixtures, {
      'matches': _mockMatches.map((m) => m.toJson()).toList(),
    });

    if (leagueId != null) {
      return Success(_mockMatches.where((m) => m.leagueId == leagueId).toList());
    }
    return Success(List.unmodifiable(_mockMatches));
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
