import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import '../sync/sync_service.dart';
import 'match_service.dart';

/// Mock MatchService with offline-sync queueing and live score simulation.
class MatchServiceMock implements MatchService {
  MatchServiceMock({
    required this.cacheService,
    required this.syncService,
  });

  final CacheService cacheService;
  final SyncService syncService;

  static final Map<String, ScoreProjection> _liveStore = {
    'm-alpha-1': ScoreProjection(
      matchId: 'm-alpha-1',
      sportId: 'football',
      leagueId: 'league-alpha-1',
      status: 'in_progress',
      outcome: 'pending',
      home: const TeamScore(
        teamId: 'club-alpha-1',
        teamName: 'Alpha FC',
        score: 2,
      ),
      away: const TeamScore(
        teamId: 'club-alpha-2',
        teamName: 'Alpha United',
        score: 1,
      ),
      version: 4,
      events: [
        MatchEvent(
          sequence: 1,
          eventId: 'evt-init-1',
          type: 'match_init',
          payload: {'period': 'first_half'},
          signature: 'sig-mock-1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
        ),
        MatchEvent(
          sequence: 2,
          eventId: 'evt-score-1',
          type: 'score',
          payload: {'team_id': 'club-alpha-1', 'event_type': 'goal', 'player': 'Tariq Al-Mansoor (24\')'},
          signature: 'sig-mock-2',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        MatchEvent(
          sequence: 3,
          eventId: 'evt-score-2',
          type: 'score',
          payload: {'team_id': 'club-alpha-2', 'event_type': 'goal', 'player': 'Kareem Vance (38\')'},
          signature: 'sig-mock-3',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        MatchEvent(
          sequence: 4,
          eventId: 'evt-score-3',
          type: 'score',
          payload: {'team_id': 'club-alpha-1', 'event_type': 'goal', 'player': 'Tariq Al-Mansoor (41\')'},
          signature: 'sig-mock-4',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ],
    ),
  };

  @override
  Future<Result<ScoreProjection>> getScoreProjection(String matchId) async {
    final cacheKey = 'cache_match_projection_$matchId';

    // Try cache if exists
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
          home: const TeamScore(teamId: 'club-alpha-1', teamName: 'Alpha FC', score: 0),
          away: const TeamScore(teamId: 'club-beta-1', teamName: 'Beta Titans', score: 0),
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
    final newVersion = proj.version + 1;
    final eventId = 'evt-${DateTime.now().millisecondsSinceEpoch}';

    final event = MatchEvent(
      sequence: newVersion,
      eventId: eventId,
      type: type,
      payload: payload,
      signature: 'sig-$eventId',
      timestamp: DateTime.now(),
    );

    // If offline, queue in sync service!
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

    // Update in-memory state
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
    await cacheService.put('cache_match_projection_$matchId', updatedProj.toJson());

    return Success(event);
  }

  @override
  Future<Result<MatchEvent>> compensateEvent({
    required String matchId,
    required String targetEventId,
    required String reason,
  }) async {
    final proj = _liveStore[matchId] ?? (await getScoreProjection(matchId)).dataOrNull!;
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
      timestamp: DateTime.now(),
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

    // Offset score if it was a score event
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

    // Mark original compensated
    final updatedEvents = List<MatchEvent>.from(proj.events);
    updatedEvents[targetIndex] = MatchEvent(
      sequence: target.sequence,
      eventId: target.eventId,
      type: target.type,
      payload: target.payload,
      signature: target.signature,
      compensated: true,
      compensatedBy: compensationId,
      timestamp: target.timestamp,
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
    await cacheService.put('cache_match_projection_$matchId', updatedProj.toJson());

    return Success(compEvent);
  }
}
