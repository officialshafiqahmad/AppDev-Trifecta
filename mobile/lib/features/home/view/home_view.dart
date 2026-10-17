import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/home_controller.dart';
import '../widgets/home_feed_tile.dart';
import '../widgets/home_stat_card.dart';

/// Dumb view for Home screen: layout and Obx observation only.
/// Absolutely no logic, no state mutations, and no Get.put in build().
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;

    return AppScaffold(
      titleKey: AppStrings.homeTitle,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        if (controller.hasError.value) {
          return ErrorView(
            messageKey: controller.errorMessageKey.value,
            onRetry: controller.loadDashboardData,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: sizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Overview stats
                const SectionHeader(
                  titleKey: AppStrings.homeSectionOverview,
                ),
                SizedBox(height: sizes.md),
                Row(
                  children: [
                    for (int i = 0; i < controller.stats.length; i++) ...[
                      if (i > 0) SizedBox(width: sizes.sm),
                      HomeStatCard(stat: controller.stats[i]),
                    ],
                  ],
                ),
                SizedBox(height: sizes.xxl),

                // Section 2: Shared kit demo buttons (Dialog & Sheet)
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        labelKey: AppStrings.homeShowDialogAction,
                        onPressed: controller.onShowDialogDemo,
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ),
                    SizedBox(width: sizes.md),
                    Expanded(
                      child: PrimaryButton(
                        labelKey: AppStrings.homeShowSheetAction,
                        onPressed: controller.onShowSheetDemo,
                        icon: Icons.layers_outlined,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sizes.xxl),

                // Section 3: Recent Activity Feed
                SectionHeader(
                  titleKey: AppStrings.homeSectionRecent,
                  actionLabelKey: AppStrings.homeRefreshAction,
                  onAction: controller.loadDashboardData,
                ),
                SizedBox(height: sizes.md),
                if (controller.feedItems.isEmpty)
                  const EmptyView(
                    messageKey: AppStrings.homeEmptyFeed,
                  )
                else
                  for (final item in controller.feedItems) ...[
                    HomeFeedTile(item: item),
                    SizedBox(height: sizes.sm),
                  ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
