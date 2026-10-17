import 'package:get/get.dart';

import '../../../services/cache/cache_service.dart';
import '../../../services/settings/settings_service.dart';
import '../controller/settings_controller.dart';

/// GetX binding for Settings feature.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        settingsService: Get.find<SettingsService>(),
        cacheService: Get.find<CacheService>(),
      ),
    );
  }
}
