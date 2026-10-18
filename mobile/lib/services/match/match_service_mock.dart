import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import '../sync/sync_service.dart';
import 'match_service.dart';

/// Mock MatchService with offline-sync queueing, canonical world, and live score updates.
class MatchServiceMock implements MatchService {
  MatchServiceMock({
    required this.cacheService,
    required this.syncService,
  });

  final CacheService cacheService;
  final SyncService syncService;

  static final Map<String, ScoreProjection> _liveStore = {
    // Completed match: Lahore FC 2 - 1 Karachi City (Rule G14)
    'match-alpha-1': const ScoreProjection(
      matchId: 'match-alpha-1',
      sportId: 'football',
      leagueId: 'league-alpha-1',
      status: 'completed',
      outcome: 'home_win',
      winnerTeamId: 'club-alpha-1',
      home: TeamScore(
        teamId: 'club-alpha-1',
        teamName: 'Lahore FC',
        score: 2,
      ),
      away: TeamScore(
        teamId: 'club-alpha-2',
        teamName: 'Karachi City',
        score: 1,
      ),
      version: 4,
      events: [
        MatchEvent(
          sequence: 1,
          eventId: 'evt-alpha-1-1',
          type: 'match_start',
          payload: {'period': 'first_half'},
          signature: 'sig-mock-1',
        ),
        MatchEvent(
          sequence: 2,
          eventId: 'evt-alpha-1-2',
          type: 'score',
          payload: {
            'team_id': 'club-alpha-1',
            'team_name': 'Lahore FC',
            'event_type': 'goal',
            'minute': 14,
            'player': 'Marcus Rashford',
          },
          signature: 'sig-mock-2',
        ),
        MatchEvent(
          sequence: 3,
          eventId: 'evt-alpha-1-3',
          type: 'score',
          payload: {
            'team_id': 'club-alpha-2',
            'team_name': 'Karachi City',
            'event_type': 'goal',
            'minute': 38,
            'player': 'Bruno Fernandes',
          },
          signature: 'sig-mock-3',
        ),
        MatchEvent(
          sequence: 4,
          eventId: 'evt-alpha-1-4',
          type: 'score',
          payload: {
            'team_id': 'club-alpha-1',
            'team_name': 'Lahore FC',
            'event_type': 'goal',
            'minute': 72,
            'player': 'Rasmus Hojlund',
          },
          signature: 'sig-mock-4',
        ),
      ],
    ),
    // Live match: Islamabad United 1 - 0 Peshawar Stars (Rule G14)
    'match-alpha-2': const ScoreProjection(
      matchId: 'match-alpha-2',
      sportId: 'football',
      leagueId: 'league-alpha-1',
      status: 'in_progress',
      outcome: 'pending',
      home: TeamScore(
        teamId: 'club-alpha-3',
        teamName: 'Islamabad United',
        score: 1,
      ),
      away: TeamScore(
        teamId: 'club-alpha-4',
        teamName: 'Peshawar Stars',
        score: 0,
      ),
      version: 2,
      events: [
        MatchEvent(
          sequence: 1,
          eventId: 'evt-alpha-2-1',
          type: 'match_start',
          payload: {'period': 'first_half'},
          signature: 'sig-live-1',
        ),
        MatchEvent(
          sequence: 2,
          eventId: 'evt-alpha-2-2',
          type: 'score',
          payload: {
            'team_id': 'club-alpha-3',
            'team_name': 'Islamabad United',
            'event_type': 'goal',
            'minute': 23,
            'player': 'Alejandro Garnacho',
          },
          signature: 'sig-live-2',
        ),
      ],
    ),
    // Upcoming match 1 (Rule G14: empty events, null scores)
    'match-alpha-3': const ScoreProjection(
      matchId: 'match-alpha-3',
      sportId: 'football',
      leagueId: 'league-alpha-1',
      status: 'upcoming',
      outcome: 'pending',
      home: TeamScore(
        teamId: 'club-alpha-1',
        teamName: 'Lahore FC',
        score: 0,
      ),
      away: TeamScore(
        teamId: 'club-alpha-3',
        teamName: 'Islamabad United',
        score: 0,
      ),
      version: 1,
      events: [],
    ),
    // Upcoming match 2 (Rule G14: empty events, null scores)
    'match-alpha-4': const ScoreProjection(
      matchId: 'match-alpha-4',
      sportId: 'football',
      leagueId: 'league-alpha-1',
      status: 'upcoming',
      outcome: 'pending',
      home: TeamScore(
        teamId: 'club-alpha-2',
        teamName: 'Karachi City',
        score: 0,
      ),
      away: TeamScore(
        teamId: 'club-alpha-4',
        teamName: 'Peshawar Stars',
        score: 0,
      ),
      version: 1,
      events: [],
    ),
    // Added real data for match-m1 seeded score 1-0 (in_progress)
    'match-m1': const ScoreProjection(
      matchId: 'match-m1',
      sportId: 'football',
      status: 'in_progress',
      outcome: 'pending',
      home: TeamScore(teamId: 'club-alpha-1', teamName: 'Alpha FC', score: 1),
      away: TeamScore(teamId: 'club-alpha-2', teamName: 'Beta Titans', score: 0),
      version: 1,
      events: const [],
    ),
  };

  @override
  Future<Result<ScoreProjection>> getScoreProjection(String matchId) async {
    final cacheKey = 'cache_match_projection_v2_$matchId';

    final cachedRes = await cacheService.get(cacheKey);
    final cached = cachedRes.dataOrNull;
    if (cached != null) {
      try {
        return Success(ScoreProjection.fromJson(cached));
      } catch (_) {}
    }

    final projection = _liveStore[matchId] ??
        ScoreProjection(
          matchId: matchId,
          sportId: 'football',
          status: 'upcoming',
          outcome: 'pending',
          home: const TeamScore(teamId: 'club-alpha-1', teamName: 'Lahore FC', score: 0),
          away: const TeamScore(teamId: 'club-alpha-2', teamName: 'Karachi City', score: 0),
          version: 1,
          events: const [],
        );

    await cacheService.put(cacheKey, projection.toJson());
    return Success(projection);
  }

  @override
  Future<Result<MatchEvent>> postEvent({
    required String matchId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final proj = _liveStore[matchId] ?? (await getScoreProjection(matchId)).dataOrNull!;

    // Rule G13: refuse score on match that is not in progress
    if (proj.status != 'in_progress') {
      return const Failure(
        AppFailure(
          code: 'MATCH_NOT_IN_PROGRESS',
          userMessageKey: AppStrings.errMatchNotInProgress,
        ),
      );
    }

    final newVersion = proj.version + 1;
    final eventId = 'evt-${DateTime.now().millisecondsSinceEpoch}';

    final event = MatchEvent(
      sequence: newVersion,
      eventId: eventId,
      type: type,
      payload: payload,
      signature: 'sig-$eventId',
    );

    if (!syncService.isOnline) {
      await syncService.queueAction(
        type: 'score_event',
        baseVersion: proj.version,
        payload: {
          'event_id': eventId,
          'match_id': matchId,
          'type': type,
          'payload': payload,
        },
      );
    }

    int homeDelta = 0;
    int awayDelta = 0;
    if (type == 'score') {
      final teamId = payload['team_id'];
      if (teamId == proj.home.teamId) {
        homeDelta = 1;
      } else {
        awayDelta = 1;
      }
    }

    final updatedProj = proj.copyWith(
      version: newVersion,
      home: TeamScore(
        teamId: proj.home.teamId,
        teamName: proj.home.teamName,
        score: proj.home.score + homeDelta,
      ),
      away: TeamScore(
        teamId: proj.away.teamId,
        teamName: proj.away.teamName,
        score: proj.away.score + awayDelta,
      ),
      events: [...proj.events, event],
    );

    _liveStore[matchId] = updatedProj;
    await cacheService.put('cache_match_projection_v2_$matchId', updatedProj.toJson());

    return Success(event);
  }

  @override
  Future<Result<MatchEvent>> compensateEvent({
    required String matchId,
    required String targetEventId,
    required String reason,
  }) async {
    final proj = _liveStore[matchId] ?? (await getScoreProjection(matchId)).dataOrNull!;

    if (proj.status != 'in_progress') {
      return const Failure(
        AppFailure(
          code: 'MATCH_NOT_IN_PROGRESS',
          userMessageKey: AppStrings.errMatchNotInProgress,
        ),
      );
    }

    final targetIndex = proj.events.indexWhere((e) => e.eventId == targetEventId);

    if (targetIndex == -1) {
      return const Failure(
        AppFailure(code: 'EVENT_NOT_FOUND', userMessageKey: AppStrings.errNotFound),
      );
    }

    final target = proj.events[targetIndex];
    if (target.compensated) {
      return const Failure(
        AppFailure(code: 'INVALID_COMPENSATION', userMessageKey: AppStrings.errInvalidCompensation),
      );
    }

    final newVersion = proj.version + 1;
    final compensationId = 'comp-${DateTime.now().millisecondsSinceEpoch}';

    final compEvent = MatchEvent(
      sequence: newVersion,
      eventId: compensationId,
      type: 'compensation',
      payload: {
        'compensates': targetEventId,
        'reason': reason,
      },
      signature: 'sig-$compensationId',
    );

    if (!syncService.isOnline) {
      await syncService.queueAction(
        type: 'score_event',
        baseVersion: proj.version,
        payload: {
          'event_id': compensationId,
          'match_id': matchId,
          'type': 'compensation',
          'payload': compEvent.payload,
        },
      );
    }

    int homeDelta = 0;
    int awayDelta = 0;
    if (target.type == 'score') {
      final teamId = target.payload['team_id'];
      if (teamId == proj.home.teamId) {
        homeDelta = -1;
      } else {
        awayDelta = -1;
      }
    }

    final updatedEvents = List<MatchEvent>.from(proj.events);
    updatedEvents[targetIndex] = MatchEvent(
      sequence: target.sequence,
      eventId: target.eventId,
      type: target.type,
      payload: target.payload,
      signature: target.signature,
      compensated: true,
      compensatedBy: compensationId,
    );
    updatedEvents.add(compEvent);

    final updatedProj = proj.copyWith(
      version: newVersion,
      home: TeamScore(
        teamId: proj.home.teamId,
        teamName: proj.home.teamName,
        score: (proj.home.score + homeDelta).clamp(0, 999),
      ),
      away: TeamScore(
        teamId: proj.away.teamId,
        teamName: proj.away.teamName,
        score: (proj.away.score + awayDelta).clamp(0, 999),
      ),
      events: updatedEvents,
    );

    _liveStore[matchId] = updatedProj;
    await cacheService.put('cache_match_projection_v2_$matchId', updatedProj.toJson());

    return Success(compEvent);
  }
}
