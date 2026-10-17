import 'package:get/get.dart';

import '../../../services/match/match_service.dart';
import '../../../services/sync/sync_service.dart';
import '../controller/scoring_entry_controller.dart';

/// GetX binding for Scoring Entry feature.
class ScoringEntryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScoringEntryController>(
      () => ScoringEntryController(
        matchService: Get.find<MatchService>(),
        syncService: Get.find<SyncService>(),
      ),
    );
  }
}
