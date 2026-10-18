import '../../core/utils/result.dart';
import '../api/api_service.dart';

/// Contract for Day 2 streaming, co-stream session management, and QR resolution.
abstract class StreamingService {
  Future<Result<Map<String, dynamic>>> getStreamKey({
    required String playerId,
    String action = 'generate',
    String label = 'default',
  });

  Future<Result<Map<String, dynamic>>> getCoStreamSession({
    required String sessionId,
    String hostPlayerId = 'player-alpha-1',
    List<String> participants = const [
      'player-alpha-1',
      'player-alpha-2',
      'player-beta-1',
      'player-beta-2',
    ],
    String layout = 'grid_4',
    bool simulateHostDrop = false,
  });

  Future<Result<Map<String, dynamic>>> resolveQr(String entityId, {bool inspect = true});
}

/// Real HTTP implementation of StreamingService calling Shafiq's /audit/v1/* backend.
class StreamingServiceImpl implements StreamingService {
  const StreamingServiceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<Result<Map<String, dynamic>>> getStreamKey({
    required String playerId,
    String action = 'generate',
    String label = 'default',
  }) async {
    final res = await apiService.post(
      '/audit/v1/stream-key',
      data: {
        'action': action,
        'player_id': playerId,
        'label': label,
      },
    );
    if (res.isSuccess && res.dataOrNull is Map<String, dynamic>) {
      return Success(res.dataOrNull as Map<String, dynamic>);
    }
    return Failure(res.failureOrNull ?? const AppFailure(code: 'STREAM_KEY_FAILED', userMessageKey: 'err_stream_key_failed'));
  }

  @override
  Future<Result<Map<String, dynamic>>> getCoStreamSession({
    required String sessionId,
    String hostPlayerId = 'player-alpha-1',
    List<String> participants = const [
      'player-alpha-1',
      'player-alpha-2',
      'player-beta-1',
      'player-beta-2',
    ],
    String layout = 'grid_4',
    bool simulateHostDrop = false,
  }) async {
    final res = await apiService.post(
      '/audit/v1/costream/session',
      data: {
        'session_id': sessionId,
        'host_player_id': hostPlayerId,
        'participants': participants,
        'layout': layout,
        'simulate_host_drop': simulateHostDrop,
      },
    );
    if (res.isSuccess && res.dataOrNull is Map<String, dynamic>) {
      return Success(res.dataOrNull as Map<String, dynamic>);
    }
    return Failure(res.failureOrNull ?? const AppFailure(code: 'COSTREAM_SESSION_FAILED', userMessageKey: 'err_costream_failed'));
  }

  @override
  Future<Result<Map<String, dynamic>>> resolveQr(String entityId, {bool inspect = true}) async {
    final res = await apiService.get(
      '/audit/v1/qr/$entityId',
      queryParameters: {'inspect': inspect.toString()},
    );
    if (res.isSuccess && res.dataOrNull is Map<String, dynamic>) {
      return Success(res.dataOrNull as Map<String, dynamic>);
    }
    return Failure(res.failureOrNull ?? const AppFailure(code: 'QR_RESOLUTION_FAILED', userMessageKey: 'err_qr_failed'));
  }
}

/// Hermetic Mock fallback implementation for StreamingService.
class StreamingServiceMock implements StreamingService {
  @override
  Future<Result<Map<String, dynamic>>> getStreamKey({
    required String playerId,
    String action = 'generate',
    String label = 'default',
  }) async {
    if (label == 'match-m1') {
      return Success({
        'player_id': playerId,
        'label': label,
        'stream_key': 'sk_live_m1',
        'status': 'active',
        'ingest_endpoints': {
          'rtmp': 'rtmp://172.15.57.248:1935/live/sk_live_m1',
          'webrtc': 'http://172.15.57.248:8889/live/sk_live_m1/whip',
        },
        'playback_url': 'http://172.15.57.248:8080/live/sk_live_m1/index.m3u8',
      });
    }
    // Default mock fallback
    return Success({
      'player_id': playerId,
      'label': label,
      'stream_key': 'sk_live_m1_mock',
      'status': 'active',
      'ingest_endpoints': {
        'rtmp': 'rtmp://localhost:1935/live/sk_live_m1_mock',
        'webrtc': 'http://localhost:8889/live/sk_live_m1_mock/whip',
      },
      'playback_url': 'http://localhost:8888/live/sk_live_m1_mock/index.m3u8',
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> getCoStreamSession({
    required String sessionId,
    String hostPlayerId = 'player-alpha-1',
    List<String> participants = const [
      'player-alpha-1',
      'player-alpha-2',
      'player-beta-1',
      'player-beta-2',
    ],
    String layout = 'grid_4',
    bool simulateHostDrop = false,
  }) async {
    return Success({
      'session_id': sessionId,
      'active_host': hostPlayerId,
      'handoff_occurred': false,
      'participant_count': participants.length,
      'active_participants': participants,
      'status': 'active',
      'layout': layout,
      'common_chat_room_id': 'chat-$sessionId',
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> resolveQr(String entityId, {bool inspect = true}) async {
    return Success({
      'entity_id': entityId,
      'target_route': entityId.startsWith('cs-')
          ? '/web/costream/$entityId'
          : '/web/matches/$entityId/live',
      'short_url': 'http://localhost:8080/q/$entityId',
      'scan_count': 1,
    });
  }
}
