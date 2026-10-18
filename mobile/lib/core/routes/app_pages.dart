import 'package:get/get.dart';

import '../../features/auth/binding/auth_binding.dart';
import '../../features/auth/view/login_view.dart';
import '../../features/auth/view/role_select_view.dart';
import '../../features/club_profile/binding/club_profile_binding.dart';
import '../../features/club_profile/view/club_profile_view.dart';
import '../../features/main_nav/binding/main_nav_binding.dart';
import '../../features/main_nav/view/main_nav_view.dart';
import '../../features/match_detail/binding/match_detail_binding.dart';
import '../../features/match_detail/view/match_detail_view.dart';
import '../../features/match_live/binding/match_live_binding.dart';
import '../../features/match_live/view/match_live_view.dart';
import '../../features/co_stream/binding/co_stream_binding.dart';
import '../../features/co_stream/view/co_stream_view.dart';
import '../../features/qr_scanner/binding/qr_scanner_binding.dart';
import '../../features/qr_scanner/view/qr_scanner_view.dart';
import '../../features/roster_manage/binding/roster_manage_binding.dart';
import '../../features/roster_manage/view/roster_manage_view.dart';
import '../../features/scoring_entry/binding/scoring_entry_binding.dart';
import '../../features/scoring_entry/view/scoring_entry_view.dart';
import '../../features/settings/binding/settings_binding.dart';
import '../../features/settings/view/settings_view.dart';
import '../../features/sync_status/binding/sync_status_binding.dart';
import '../../features/sync_status/view/sync_status_view.dart';
import '../constants/app_sizes.dart';
import 'app_routes.dart';

import '../../services/auth/auth_service.dart';
import 'role_guard.dart';

/// Central page registry linking all routes to their views and bindings.
abstract final class AppPages {
  static const AppSizes _sizes = AppSizes();

  static const String initial = AppRoutes.roleSelect;

  static final List<GetPage<dynamic>> pages = [
    GetPage<dynamic>(
      name: AppRoutes.roleSelect,
      page: () => const RoleSelectView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionFast,
    ),
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: _sizes.motionFast,
    ),
    GetPage<dynamic>(
      name: AppRoutes.main,
      page: () => const MainNavView(),
      binding: MainNavBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.matchDetail,
      page: () => const MatchDetailView(),
      binding: MatchDetailBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.clubProfile,
      page: () => const ClubProfileView(),
      binding: ClubProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.rosterManage,
      page: () => const RosterManageView(),
      binding: RosterManageBinding(),
      middlewares: [
        RoleGuardMiddleware(
          allowedRoles: const [
            UserRole.superAdmin,
            UserRole.organizer,
            UserRole.clubManager,
          ],
        ),
      ],
      transition: Transition.rightToLeft,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.scoringEntry,
      page: () => const ScoringEntryView(),
      binding: ScoringEntryBinding(),
      middlewares: [
        RoleGuardMiddleware(
          allowedRoles: const [
            UserRole.superAdmin,
            UserRole.organizer,
          ],
        ),
      ],
      transition: Transition.rightToLeft,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.syncStatus,
      page: () => const SyncStatusView(),
      binding: SyncStatusBinding(),
      transition: Transition.downToUp,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: AppRoutes.matchLive,
      page: () => const MatchLiveView(),
      binding: MatchLiveBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionFast,
    ),
    GetPage<dynamic>(
      name: AppRoutes.coStream,
      page: () => const CoStreamView(),
      binding: CoStreamBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionFast,
    ),
    GetPage<dynamic>(
      name: AppRoutes.qrScanner,
      page: () => const QrScannerView(),
      binding: QrScannerBinding(),
      transition: Transition.downToUp,
      transitionDuration: _sizes.motionNormal,
    ),
    GetPage<dynamic>(
      name: 'nascon://entity/match-m1',
      page: () => const MatchLiveView(),
      binding: MatchLiveBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionFast,
    ),
    GetPage<dynamic>(
      name: 'nascon://stream/cs-session-101',
      page: () => const CoStreamView(),
      binding: CoStreamBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionFast,
    ),
  ];
}
