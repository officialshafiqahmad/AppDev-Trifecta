import 'package:get/get.dart';
import '../../../services/fixtures/fixtures_service.dart';
import '../../../services/standings/standings_service.dart';
import '../controller/standings_controller.dart';

/// GetX binding for Standings feature.
class StandingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StandingsController>(
      () => StandingsController(
        standingsService: Get.find<StandingsService>(),
        fixturesService: Get.find<FixturesService>(),
      ),
    );
  }
}
