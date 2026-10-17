import 'package:get/get.dart';

import '../../features/home/binding/home_binding.dart';
import '../../features/home/view/home_view.dart';
import '../constants/app_sizes.dart';
import 'app_routes.dart';

/// Central registry of all application pages and transitions.
/// ALL navigation must be routed through these definitions.
abstract final class AppPages {
  static const AppSizes _sizes = AppSizes();

  static const String initial = AppRoutes.home;

  static final List<GetPage<dynamic>> pages = [
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _sizes.motionNormal,
    ),
  ];
}
