import 'package:get/get.dart';

import '../../../services/deeplink/deeplink_service.dart';
import '../../../services/match/match_service.dart';

/// Controller for Match Live stream screen (Phase II additive feature).
class MatchLiveController extends GetxController {
  MatchLiveController({this.matchService});

  final MatchService? matchService;

  final RxString matchId = 'match-m1'.obs;
  final RxString homeTeamName = 'Alpha FC'.obs;
  final RxString awayTeamName = 'Beta Titans'.obs;
  final RxInt homeScore = 1.obs;
  final RxInt awayScore = 0.obs;
  final RxString status = 'in_progress'.obs;
  final RxString playbackUrl = 'http://localhost:8888/live/sk_live_m1/index.m3u8'.obs;

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
    _loadScore();
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
