import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/match/match_service.dart';
import '../controller/scoring_entry_controller.dart';

/// Dumb layout view for Scoring Entry screen.
class ScoringEntryView extends GetView<ScoringEntryController> {
  const ScoringEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: AppStrings.scoringTitle,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        if (controller.hasError.value || controller.projection.value == null) {
          return ErrorView(
            messageKey: controller.errorMessageKey.value,
            onRetry: controller.loadMatch,
          );
        }

        final proj = controller.projection.value!;
        final activeTab = controller.activeTab.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Match Summary Header
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(proj.home.teamName, style: textStyles.titleMd),
                    Text(
                      '${proj.home.score} - ${proj.away.score}',
                      style: textStyles.headlineMd.copyWith(color: colors.primary),
                    ),
                    Text(proj.away.teamName, style: textStyles.titleMd),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Segmented Action Tabs: Score Event / Compensate
              Row(
                children: [
                  Expanded(
                    child: _buildTab(context, 0, AppStrings.scoringAppendScore, Icons.add_circle_outline),
                  ),
                  SizedBox(width: sizes.sm),
                  Expanded(
                    child: _buildTab(context, 1, AppStrings.scoringCompensate, Icons.undo_outlined),
                  ),
                ],
              ),
              SizedBox(height: sizes.lg),

              // Tab 0: Append Score Event
              if (activeTab == 0)
                AppCard(
                  padding: EdgeInsets.all(sizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(AppStrings.scoringSelectTeam.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTeamChoice(context, proj.home.teamId, proj.home.teamName),
                          ),
                          SizedBox(width: sizes.sm),
                          Expanded(
                            child: _buildTeamChoice(context, proj.away.teamId, proj.away.teamName),
                          ),
                        ],
                      ),
                      SizedBox(height: sizes.lg),

                      Text(AppStrings.scoringPlayerOrDetail.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.xs),
                      SizedBox(
                        height: sizes.input,
                        child: TextField(
                          controller: controller.playerController,
                          style: textStyles.bodyMd,
                          decoration: InputDecoration(
                            hintText: 'Player Name / Event notation',
                            hintStyle: textStyles.caption,
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: EdgeInsets.symmetric(horizontal: sizes.md),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sizes.xl),

                      PrimaryButton(
                        labelKey: AppStrings.scoringSubmitScore,
                        onPressed: controller.appendScoreEvent,
                        isLoading: controller.isSubmitting.value,
                        icon: Icons.sports_soccer_outlined,
                      ),
                    ],
                  ),
                ),

              // Tab 1: Append Compensation Event (Undo)
              if (activeTab == 1) ...[
                Builder(
                  builder: (context) {
                    final compensatableEvents = proj.events
                        .where((e) => !e.compensated && e.type != 'match_init')
                        .toList();

                    if (compensatableEvents.isEmpty) {
                      return const EmptyView(
                        messageKey: 'No events available to compensate.',
                        icon: Icons.check_circle_outline,
                      );
                    }

                    return AppCard(
                      padding: EdgeInsets.all(sizes.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(AppStrings.scoringCompensateSelect.tr, style: textStyles.labelLg),
                          SizedBox(height: sizes.xs),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<MatchEvent>(
                              value: controller.selectedCompensateEvent.value,
                              isExpanded: true,
                              dropdownColor: colors.surface,
                              style: textStyles.bodyMd,
                              items: compensatableEvents.map((evt) {
                                final label = evt.payload['player'] as String? ?? evt.type;
                                return DropdownMenuItem<MatchEvent>(
                                  value: evt,
                                  child: Text('Seq #${evt.sequence}: $label'),
                                );
                              }).toList(),
                              onChanged: (evt) {
                                if (evt != null) controller.selectedCompensateEvent.value = evt;
                              },
                            ),
                          ),
                          SizedBox(height: sizes.lg),

                          Text(AppStrings.scoringCompensateReason.tr, style: textStyles.labelLg),
                          SizedBox(height: sizes.xs),
                          SizedBox(
                            height: sizes.input,
                            child: TextField(
                              controller: controller.reasonController,
                              style: textStyles.bodyMd,
                              decoration: InputDecoration(
                                hintText: 'Audit reason for compensation',
                                hintStyle: textStyles.caption,
                                filled: true,
                                fillColor: colors.surface,
                                contentPadding: EdgeInsets.symmetric(horizontal: sizes.md),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: sizes.xl),

                          PrimaryButton(
                            labelKey: AppStrings.scoringSubmitUndo,
                            onPressed: controller.submitCompensation,
                            isLoading: controller.isSubmitting.value,
                            icon: Icons.undo_outlined,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTab(BuildContext context, int tabIndex, String labelKey, IconData icon) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isSelected = controller.activeTab.value == tabIndex;

    return PressableScale(
      child: GestureDetector(
        onTap: () => controller.setActiveTab(tabIndex),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sizes.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(sizes.radiusMd),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: sizes.iconSm,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              SizedBox(width: sizes.xs),
              Text(
                labelKey.tr,
                style: textStyles.labelMd.copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamChoice(BuildContext context, String teamId, String teamName) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isSelected = controller.selectedTeamId.value == teamId;

    return PressableScale(
      child: GestureDetector(
        onTap: () => controller.selectedTeamId.value = teamId,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sizes.md, horizontal: sizes.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(sizes.radiusMd),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            teamName,
            style: textStyles.bodyMd.copyWith(
              color: isSelected ? colors.primary : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
