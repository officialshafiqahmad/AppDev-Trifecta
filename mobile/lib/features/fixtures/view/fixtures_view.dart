import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/fixtures/fixtures_service.dart';
import '../controller/fixtures_controller.dart';
import '../widgets/match_card.dart';

/// Dumb layout view for Fixtures screen adhering to UX rules C5, C10, and C11.
class FixturesView extends GetView<FixturesController> {
  const FixturesView({super.key});

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE, d MMMM').format(date);
  }

  Map<String, List<MatchSummary>> _groupMatches(List<MatchSummary> matches) {
    final Map<String, List<MatchSummary>> groups = {};
    for (final match in matches) {
      final key = _formatDateHeader(match.startsAt);
      groups.putIfAbsent(key, () => []).add(match);
    }
    return groups;
  }

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
      final grouped = _groupMatches(matches);

      return RefreshIndicator(
        onRefresh: controller.loadFixtures,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rule C5: Shared AppSegmentedControl for filters
              AppSegmentedControl<String>(
                items: [
                  SegmentedItem(value: 'all', label: AppStrings.fixturesFilterAll.tr),
                  SegmentedItem(value: 'live', label: AppStrings.fixturesFilterLive.tr),
                  SegmentedItem(value: 'upcoming', label: AppStrings.fixturesFilterUpcoming.tr),
                  SegmentedItem(value: 'completed', label: AppStrings.fixturesFilterCompleted.tr),
                ],
                selectedValue: controller.activeFilter.value,
                onChanged: controller.setFilter,
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
                // Rule C11: Date-grouped match sections
                for (final entry in grouped.entries) ...[
                  SectionHeader(title: entry.key),
                  SizedBox(height: sizes.xs),
                  for (final match in entry.value) ...[
                    MatchCard(
                      match: match,
                      onTap: () => controller.openMatchDetail(match),
                    ),
                    SizedBox(height: sizes.sm),
                  ],
                  SizedBox(height: sizes.sm),
                ],
            ],
          ),
        ),
      );
    });
  }
}
