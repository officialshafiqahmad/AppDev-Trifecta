import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';
import '../../../services/fixtures/fixtures_service.dart';
import '../../../services/standings/standings_service.dart';
import '../../../services/store/store_service.dart';
import '../../../services/sync/sync_service.dart';
import '../../fixtures/controller/fixtures_controller.dart';
import '../../profile/controller/profile_controller.dart';
import '../../standings/controller/standings_controller.dart';
import '../../store/controller/store_controller.dart';
import '../controller/main_nav_controller.dart';

/// Binds MainNavController and the 4 bottom-nav tab controllers.
class MainNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavController>(
      () => MainNavController(
        authService: Get.find<AuthService>(),
      ),
    );

    Get.lazyPut<FixturesController>(
      () => FixturesController(
        fixturesService: Get.find<FixturesService>(),
      ),
    );

    Get.lazyPut<StandingsController>(
      () => StandingsController(
        standingsService: Get.find<StandingsService>(),
        fixturesService: Get.find<FixturesService>(),
      ),
    );

    Get.lazyPut<StoreController>(
      () => StoreController(
        storeService: Get.find<StoreService>(),
        authService: Get.find<AuthService>(),
        syncService: Get.find<SyncService>(),
      ),
    );

    Get.lazyPut<ProfileController>(
      () => ProfileController(
        authService: Get.find<AuthService>(),
        clubService: Get.find<ClubService>(),
      ),
    );
  }
}
