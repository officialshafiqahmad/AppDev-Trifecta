import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/match_detail_controller.dart';
import '../widgets/event_timeline_tile.dart';
import '../widgets/pinned_merch_card.dart';

/// Dumb layout view for Match Detail screen adhering to rules C4, C12, C13, C14, and C15.
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

        final (String statusLabel, AppStatusTone tone, bool dot) = switch (proj.status) {
          'in_progress' => ('LIVE', AppStatusTone.danger, true),
          'completed' => ('FULL TIME', AppStatusTone.neutral, false),
          _ => ('UPCOMING', AppStatusTone.info, false),
        };

        return RefreshIndicator(
          onRefresh: controller.loadProjection,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: sizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Live Score Card (Rule C12 & C13)
                AppCard(
                  padding: EdgeInsets.all(sizes.cardPadding),
                  child: Column(
                    children: [
                      // Sport & Status Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            proj.sportId.toUpperCase(),
                            style: textStyles.overline.copyWith(color: colors.textSecondary),
                          ),
                          AppStatusChip(
                            label: statusLabel,
                            tone: tone,
                            showDot: dot,
                          ),
                        ],
                      ),
                      SizedBox(height: sizes.lg),

                      // Teams & Score Row
                      Row(
                        children: [
                          // Home Team
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: sizes.iconMd,
                                  backgroundColor: colors.primaryContainer,
                                  child: Text(
                                    proj.home.teamName.isNotEmpty ? proj.home.teamName[0] : 'H',
                                    style: textStyles.titleMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: sizes.xs),
                                Text(
                                  proj.home.teamName,
                                  style: textStyles.titleMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Score in Center (Largest text: headlineLg)
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(
                                proj.isLive || proj.status == 'completed'
                                    ? '${proj.home.score} - ${proj.away.score}'
                                    : 'vs',
                                style: textStyles.headlineLg.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: proj.isLive ? colors.primary : colors.textPrimary,
                                ),
                              ),
                            ),
                          ),

                          // Away Team
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: sizes.iconMd,
                                  backgroundColor: colors.surfaceVariant,
                                  child: Text(
                                    proj.away.teamName.isNotEmpty ? proj.away.teamName[0] : 'A',
                                    style: textStyles.titleMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: sizes.xs),
                                Text(
                                  proj.away.teamName,
                                  style: textStyles.titleMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: sizes.lg),
                      Divider(height: 1, color: colors.border),
                      SizedBox(height: sizes.sm),

                      // Venue & Fair Play row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: sizes.iconSm - 4,
                                color: colors.textTertiary,
                              ),
                              SizedBox(width: sizes.xs),
                              Text(
                                'A-01 Main Arena',
                                style: textStyles.caption.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            'Fair Play: ${proj.home.fairPlay} - ${proj.away.fairPlay}',
                            style: textStyles.caption.copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.lg),

                // 2. Role-Gated Action: Enter Score Event (Organizer ONLY & Match is Live)
                if (controller.canEnterScores.value) ...[
                  PrimaryButton(
                    labelKey: AppStrings.matchEnterScoreAction,
                    onPressed: controller.openScoringEntry,
                    icon: Icons.edit_note_outlined,
                  ),
                  SizedBox(height: sizes.lg),
                ],

                // 3. Event Timeline in a SINGLE AppCard (Rule C4 & C15)
                SectionHeader(
                  titleKey: AppStrings.matchEventsTitle,
                  actionLabelKey: AppStrings.commonRefresh,
                  onAction: controller.loadProjection,
                ),
                SizedBox(height: sizes.xs),

                if (proj.events.isEmpty)
                  const EmptyView(
                    messageKey: AppStrings.matchEventsEmpty,
                    icon: Icons.timeline_outlined,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < proj.events.length; i++) ...[
                          EventTimelineTile(event: proj.events.reversed.toList()[i]),
                          if (i < proj.events.length - 1)
                            Divider(height: 1, color: colors.border),
                        ],
                      ],
                    ),
                  ),

                SizedBox(height: sizes.lg),

                // 4. Rule C14: Pinned Merchandise Showcase BELOW event timeline
                PinnedMerchCard(
                  onViewStore: controller.openStoreMerchandise,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
