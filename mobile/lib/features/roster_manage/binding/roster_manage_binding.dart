import 'package:get/get.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/club/club_service.dart';
import '../../../services/roster/roster_service.dart';
import '../../../services/sync/sync_service.dart';
import '../controller/roster_manage_controller.dart';

/// GetX binding for Roster Management feature.
class RosterManageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RosterManageController>(
      () => RosterManageController(
        rosterService: Get.find<RosterService>(),
        clubService: Get.find<ClubService>(),
        authService: Get.find<AuthService>(),
        syncService: Get.find<SyncService>(),
      ),
    );
  }
}
