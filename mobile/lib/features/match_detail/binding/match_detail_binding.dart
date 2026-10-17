import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/match/match_service.dart';
import '../controller/match_detail_controller.dart';

/// GetX binding for Match Detail feature.
class MatchDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchDetailController>(
      () => MatchDetailController(
        matchService: Get.find<MatchService>(),
        authService: Get.find<AuthService>(),
      ),
    );
  }
}
