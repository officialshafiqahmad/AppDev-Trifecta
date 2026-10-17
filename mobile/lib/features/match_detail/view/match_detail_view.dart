import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/match_detail_controller.dart';
import '../widgets/event_timeline_tile.dart';
import '../widgets/pinned_merch_card.dart';

/// Dumb layout view for Match Detail screen.
class MatchDetailView extends GetView<MatchDetailController> {
  const MatchDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: AppStrings.matchDetailTitle,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        if (controller.hasError.value || controller.projection.value == null) {
          return ErrorView(
            messageKey: controller.errorMessageKey.value,
            onRetry: controller.loadProjection,
          );
        }

        final proj = controller.projection.value!;

        return RefreshIndicator(
          onRefresh: controller.loadProjection,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: sizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live Score Block (Score is the largest text: headlineLg)
                AppCard(
                  padding: EdgeInsets.all(sizes.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            proj.sportId.toUpperCase(),
                            style: textStyles.overline,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: sizes.sm,
                              vertical: sizes.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: proj.isLive ? colors.errorBg : colors.primaryContainer,
                              borderRadius: BorderRadius.circular(sizes.radiusPill),
                            ),
                            child: Text(
                              proj.status.toUpperCase(),
                              style: textStyles.labelMd.copyWith(
                                color: proj.isLive ? colors.error : colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sizes.lg),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proj.home.teamName,
                                  style: textStyles.headlineMd,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  'Fair Play: ${proj.home.fairPlay}/10',
                                  style: textStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: sizes.lg),
                            child: Text(
                              '${proj.home.score} - ${proj.away.score}',
                              style: textStyles.headlineLg.copyWith(
                                fontWeight: FontWeight.w700,
                                color: proj.isLive ? colors.primary : colors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  proj.away.teamName,
                                  style: textStyles.headlineMd,
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  'Fair Play: ${proj.away.fairPlay}/10',
                                  style: textStyles.caption,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.xl),

                // Role-Gated Action: Enter Score Event (Organizer ONLY)
                if (controller.canEnterScores.value) ...[
                  PrimaryButton(
                    labelKey: AppStrings.matchEnterScoreAction,
                    onPressed: controller.openScoringEntry,
                    icon: Icons.edit_note_outlined,
                  ),
                  SizedBox(height: sizes.xl),
                ],

                // Pinned Merchandise Showcase
                PinnedMerchCard(
                  onViewStore: controller.openStoreMerchandise,
                ),
                SizedBox(height: sizes.xl),

                // Event Timeline
                SectionHeader(
                  titleKey: AppStrings.matchEventsTitle,
                  actionLabelKey: AppStrings.commonRefresh,
                  onAction: controller.loadProjection,
                ),
                SizedBox(height: sizes.md),

                if (proj.events.isEmpty)
                  const EmptyView(
                    messageKey: AppStrings.matchEventsEmpty,
                    icon: Icons.timeline_outlined,
                  )
                else
                  for (final evt in proj.events.reversed) ...[
                    EventTimelineTile(event: evt),
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
