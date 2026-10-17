import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/scoring_entry_controller.dart';

/// Refactored Scoring Entry view adhering to C31, C32, D2, D4, G9, G11, G13.
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
                    Expanded(
                      child: Text(
                        proj.home.teamName,
                        style: textStyles.titleMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sizes.md),
                      child: Text(
                        '${proj.home.score} - ${proj.away.score}',
                        style: textStyles.headlineMd.copyWith(color: colors.primary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        proj.away.teamName,
                        style: textStyles.titleMd,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Segmented Action Tabs: Score Event / Compensate
              AppSegmentedControl<int>(
                selectedValue: activeTab,
                onValueChanged: controller.setActiveTab,
                segments: const [
                  SegmentItem(value: 0, label: 'Append Score'),
                  SegmentItem(value: 1, label: 'Compensate (Undo)'),
                ],
              ),
              SizedBox(height: sizes.lg),

              // Tab 0: Append Score Event (C31, G11)
              if (activeTab == 0)
                AppCard(
                  padding: EdgeInsets.all(sizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Team selector (SegmentedControl showing team names)
                      Text(AppStrings.scoringSelectTeam.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.sm),
                      AppSegmentedControl<String>(
                        selectedValue: controller.selectedTeamId.value,
                        onValueChanged: (val) => controller.selectedTeamId.value = val,
                        segments: [
                          SegmentItem(value: proj.home.teamId, label: proj.home.teamName),
                          SegmentItem(value: proj.away.teamId, label: proj.away.teamName),
                        ],
                      ),
                      SizedBox(height: sizes.lg),

                      // Event type: 2x2 grid of tap cards
                      Text('Event Type', style: textStyles.labelLg),
                      SizedBox(height: sizes.sm),
                      _buildEventTypeGrid(context),
                      SizedBox(height: sizes.lg),

                      // Minute stepper
                      Text('Match Minute', style: textStyles.labelLg),
                      SizedBox(height: sizes.sm),
                      _buildMinuteStepper(context),
                      SizedBox(height: sizes.lg),

                      // Player selector / text input
                      Text(AppStrings.scoringPlayerOrDetail.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.sm),
                      if (controller.rosterPlayers.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: controller.selectedPlayer.value.isNotEmpty ? controller.selectedPlayer.value : null,
                          isExpanded: true,
                          dropdownColor: colors.surface,
                          style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Select Player from Roster',
                            contentPadding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
                          ),
                          items: controller.rosterPlayers.map((name) {
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.selectedPlayer.value = val;
                          },
                        ),
                        SizedBox(height: sizes.sm),
                        Text('Or enter custom player name:', style: textStyles.caption),
                        SizedBox(height: sizes.xs),
                      ],
                      AppTextField(
                        controller: controller.playerController,
                        hintText: 'e.g. Marcus Rashford',
                        onChanged: (val) {
                          if (val.trim().isNotEmpty) {
                            controller.selectedPlayer.value = '';
                          }
                        },
                      ),
                      SizedBox(height: sizes.xl),

                      PrimaryButton(
                        labelKey: AppStrings.scoringSubmitScore,
                        onPressed: controller.isSubmitting.value ? null : controller.appendScoreEvent,
                        isLoading: controller.isSubmitting.value,
                        icon: Icons.sports_soccer_outlined,
                      ),
                    ],
                  ),
                ),

              // Tab 1: Append Compensation Event (Undo) (C32, D2)
              if (activeTab == 1) ...[
                Builder(
                  builder: (context) {
                    final events = proj.events.where((e) => e.type != 'match_init').toList().reversed.toList();

                    if (events.isEmpty) {
                      return const EmptyView(
                        messageKey: 'No events available to compensate.',
                        icon: Icons.check_circle_outline,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Reason Input Card
                        AppCard(
                          padding: EdgeInsets.all(sizes.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(AppStrings.scoringCompensateReason.tr, style: textStyles.labelLg),
                              SizedBox(height: sizes.sm),
                              AppTextField(
                                controller: controller.reasonController,
                                hintText: 'Reason for correction (required)',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sizes.md),

                        Text('Select Event to Compensate', style: textStyles.titleSm),
                        SizedBox(height: sizes.sm),

                        // Single Card containing event list with dividers (C4, C32)
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length,
                            separatorBuilder: (context, _) => Divider(
                              height: 1,
                              thickness: 1,
                              color: colors.border,
                            ),
                            itemBuilder: (context, index) {
                              final evt = events[index];
                              final isSelected = controller.selectedCompensateEvent.value?.eventId == evt.eventId;
                              final minuteVal = evt.payload['minute'] ?? 14;
                              final playerVal = evt.payload['player'] ?? 'Unknown';
                              final eventTypeLabel = evt.type.toUpperCase();

                              return Padding(
                                padding: EdgeInsets.all(sizes.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Format: Goal (14') — Marcus Rashford (C32)
                                              Text(
                                                '$eventTypeLabel ($minuteVal\') — $playerVal',
                                                style: textStyles.titleSm,
                                              ),
                                              SizedBox(height: sizes.xxs),
                                              Text(
                                                'Seq #${evt.sequence} • Match ID: ${proj.matchId}',
                                                style: textStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        AppStatusChip(
                                          label: evt.compensated ? 'Compensated' : 'Reversible',
                                          tone: evt.compensated ? AppChipTone.danger : AppChipTone.warning,
                                          hasDot: true,
                                        ),
                                      ],
                                    ),
                                    if (!evt.compensated) ...[
                                      SizedBox(height: sizes.md),
                                      SecondaryButton(
                                        labelKey: isSelected ? 'Compensate Selected Event' : 'Select for Compensation',
                                        icon: Icons.undo_outlined,
                                        isLoading: controller.isSubmitting.value && isSelected,
                                        onPressed: () {
                                          controller.selectedCompensateEvent.value = evt;
                                          controller.submitCompensation();
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildEventTypeGrid(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final types = [
      {'id': 'goal', 'label': 'Goal', 'icon': Icons.sports_soccer_outlined},
      {'id': 'yellow_card', 'label': 'Yellow Card', 'icon': Icons.style_outlined},
      {'id': 'red_card', 'label': 'Red Card', 'icon': Icons.warning_amber_outlined},
      {'id': 'sub', 'label': 'Substitution', 'icon': Icons.swap_horiz_outlined},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: sizes.sm,
        crossAxisSpacing: sizes.sm,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final t = types[index];
        final id = t['id'] as String;
        final label = t['label'] as String;
        final icon = t['icon'] as IconData;
        final isSelected = controller.selectedEventType.value == id;

        return PressableScale(
          child: GestureDetector(
            onTap: () => controller.selectedEventType.value = id,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xs),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryContainer : colors.surface,
                borderRadius: BorderRadius.circular(sizes.radiusMd),
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: sizes.iconSm,
                    color: isSelected ? colors.primary : colors.textSecondary,
                  ),
                  SizedBox(width: sizes.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: textStyles.labelMd.copyWith(
                        color: isSelected ? colors.primary : colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinuteStepper(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: controller.decrementMinute,
            icon: Icon(Icons.remove_outlined, color: colors.textPrimary, size: sizes.iconMd),
          ),
          Obx(
            () => Text(
              '${controller.minute.value}\'',
              style: textStyles.titleLg.copyWith(color: colors.primary),
            ),
          ),
          IconButton(
            onPressed: controller.incrementMinute,
            icon: Icon(Icons.add_outlined, color: colors.textPrimary, size: sizes.iconMd),
          ),
        ],
      ),
    );
  }
}
