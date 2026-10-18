import 'package:get/get.dart';

import '../../../services/match/match_service.dart';
import '../../../services/streaming/streaming_service.dart';
import '../controller/match_live_controller.dart';

class MatchLiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchLiveController>(
      () => MatchLiveController(
        matchService: Get.isRegistered<MatchService>() ? Get.find<MatchService>() : null,
        streamingService: Get.isRegistered<StreamingService>() ? Get.find<StreamingService>() : null,
      ),
    );
  }
}
