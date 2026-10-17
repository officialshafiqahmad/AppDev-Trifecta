import 'package:get/get.dart';

import '../../../services/fixtures/fixtures_service.dart';
import '../controller/fixtures_controller.dart';

/// GetX binding for Fixtures feature.
class FixturesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FixturesController>(
      () => FixturesController(
        fixturesService: Get.find<FixturesService>(),
      ),
    );
  }
}
