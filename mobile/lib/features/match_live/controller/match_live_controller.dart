import 'package:get/get.dart';

import '../../../services/deeplink/deeplink_service.dart';
import '../../../services/match/match_service.dart';
import '../../../services/streaming/streaming_service.dart';

/// Controller for Match Live stream screen (Phase II additive feature).
class MatchLiveController extends GetxController {
  MatchLiveController({this.matchService, this.streamingService});

  final MatchService? matchService;
  final StreamingService? streamingService;

  final RxString matchId = 'match-m1'.obs;
  final RxString homeTeamName = 'Alpha FC'.obs;
  final RxString awayTeamName = 'Beta Titans'.obs;
  final RxInt homeScore = 1.obs;
  final RxInt awayScore = 0.obs;
  final RxString status = 'in_progress'.obs;
  final RxString playbackUrl = 'http://localhost:8888/live/sk_live_m1/index.m3u8'.obs;
  final RxBool isLiveStreamActive = false.obs;
  final RxString streamStatusMessage = 'Waiting for stream signal'.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) {
      matchId.value = args;
    } else if (args is Map && args['match_id'] != null) {
      matchId.value = args['match_id'] as String;
    } else if (Get.isRegistered<DeepLinkService>()) {
      final initialId = Get.find<DeepLinkService>().lastMatchId;
      if (initialId != null && initialId.isNotEmpty) {
        matchId.value = initialId;
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    _loadScore();
    _loadStream();
  }

  Future<void> _loadStream() async {
    if (streamingService != null) {
      final res = await streamingService!.getStreamKey(
        playerId: 'player-alpha-1',
        label: matchId.value,
      );
      if (res.isSuccess && res.dataOrNull != null) {
        final data = res.dataOrNull!;
        if (data['playback_url'] != null) {
          playbackUrl.value = data['playback_url'] as String;
        }
        if (data['status'] == 'active') {
          // If media endpoints are defined, stream key is active
          streamStatusMessage.value = 'Stream online (HLS)';
        }
      }
    }
  }

  Future<void> _loadScore() async {
    if (matchService != null) {
      final res = await matchService!.getScoreProjection(matchId.value);
      if (res.isSuccess && res.dataOrNull != null) {
        final proj = res.dataOrNull!;
        homeScore.value = proj.home.score;
        awayScore.value = proj.away.score;
        status.value = proj.status;
      }
    }
  }
}
