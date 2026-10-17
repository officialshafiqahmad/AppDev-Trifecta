import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../controller/fixtures_controller.dart';
import '../widgets/match_card.dart';

/// Dumb layout view for Fixtures screen.
class FixturesView extends GetView<FixturesController> {
  const FixturesView({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;

    return Obx(() {
      if (controller.isLoading.value) {
        return const LoadingOverlay.staged(
          labelKey: AppStrings.commonLoading,
        );
      }

      if (controller.hasError.value) {
        return ErrorView(
          messageKey: controller.errorMessageKey.value,
          onRetry: controller.loadFixtures,
        );
      }

      final matches = controller.filteredMatches;

      return RefreshIndicator(
        onRefresh: controller.loadFixtures,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filters Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'all', AppStrings.fixturesFilterAll),
                    SizedBox(width: sizes.sm),
                    _buildFilterChip(context, 'live', AppStrings.fixturesFilterLive),
                    SizedBox(width: sizes.sm),
                    _buildFilterChip(context, 'upcoming', AppStrings.fixturesFilterUpcoming),
                    SizedBox(width: sizes.sm),
                    _buildFilterChip(context, 'completed', AppStrings.fixturesFilterCompleted),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Match List or Empty View
              if (matches.isEmpty)
                EmptyView(
                  messageKey: AppStrings.fixturesEmpty,
                  icon: Icons.sports_soccer_outlined,
                  actionLabelKey: AppStrings.commonRefresh,
                  onAction: controller.loadFixtures,
                )
              else
                for (final match in matches) ...[
                  MatchCard(
                    match: match,
                    onTap: () => controller.openMatchDetail(match),
                  ),
                  SizedBox(height: sizes.sm),
                ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterChip(BuildContext context, String filterKey, String labelKey) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isSelected = controller.activeFilter.value == filterKey;

    return PressableScale(
      child: GestureDetector(
        onTap: () => controller.setFilter(filterKey),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.md,
            vertical: sizes.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(sizes.radiusPill),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            labelKey.tr,
            style: textStyles.labelMd.copyWith(
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
