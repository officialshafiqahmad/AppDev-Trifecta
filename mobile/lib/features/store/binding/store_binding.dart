import 'package:get/get.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/store/store_service.dart';
import '../../../services/sync/sync_service.dart';
import '../controller/store_controller.dart';

/// GetX binding for Store feature.
class StoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreController>(
      () => StoreController(
        storeService: Get.find<StoreService>(),
        authService: Get.find<AuthService>(),
        syncService: Get.find<SyncService>(),
      ),
    );
  }
}
