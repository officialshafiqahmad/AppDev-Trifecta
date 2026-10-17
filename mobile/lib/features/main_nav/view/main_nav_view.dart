import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../fixtures/view/fixtures_view.dart';
import '../../profile/view/profile_view.dart';
import '../../standings/view/standings_view.dart';
import '../../store/view/store_view.dart';
import '../controller/main_nav_controller.dart';

/// Main navigation shell hosting bottom navigation and the 4 tab views.
class MainNavView extends GetView<MainNavController> {
  const MainNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;

    return Obx(() {
      final tabIndex = controller.currentIndex.value;

      String titleKey;
      switch (tabIndex) {
        case 0:
          titleKey = AppStrings.navFixtures;
          break;
        case 1:
          titleKey = AppStrings.navStandings;
          break;
        case 2:
          titleKey = AppStrings.navStore;
          break;
        case 3:
          titleKey = AppStrings.navProfile;
          break;
        default:
          titleKey = AppStrings.appName;
      }

      return AppScaffold(
        titleKey: titleKey,
        showSyncIndicator: true,
        body: IndexedStack(
          index: tabIndex,
          children: const [
            FixturesView(),
            StandingsView(),
            StoreView(),
            ProfileView(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: NavigationBar(
            selectedIndex: tabIndex,
            onDestinationSelected: controller.changeTab,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: colors.primaryContainer,
            height: sizes.buttonPrimary + sizes.md,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.sports_soccer_outlined, size: sizes.iconMd, color: colors.textSecondary),
                selectedIcon: Icon(Icons.sports_soccer_outlined, size: sizes.iconMd, color: colors.primary),
                label: AppStrings.navFixtures.tr,
              ),
              NavigationDestination(
                icon: Icon(Icons.table_chart_outlined, size: sizes.iconMd, color: colors.textSecondary),
                selectedIcon: Icon(Icons.table_chart_outlined, size: sizes.iconMd, color: colors.primary),
                label: AppStrings.navStandings.tr,
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined, size: sizes.iconMd, color: colors.textSecondary),
                selectedIcon: Icon(Icons.storefront_outlined, size: sizes.iconMd, color: colors.primary),
                label: AppStrings.navStore.tr,
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: sizes.iconMd, color: colors.textSecondary),
                selectedIcon: Icon(Icons.person_outline_rounded, size: sizes.iconMd, color: colors.primary),
                label: AppStrings.navProfile.tr,
              ),
            ],
          ),
        ),
      );
    });
  }
}
