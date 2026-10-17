import 'package:get/get.dart';

import '../../../services/sync/sync_service.dart';
import '../controller/sync_status_controller.dart';

/// GetX binding for Sync Status feature.
class SyncStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SyncStatusController>(
      () => SyncStatusController(
        syncService: Get.find<SyncService>(),
      ),
    );
  }
}
