import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/club/club_service.dart';
import '../controller/roster_manage_controller.dart';

/// Dumb layout view for Roster Management screen.
class RosterManageView extends GetView<RosterManageController> {
  const RosterManageView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: AppStrings.rosterManageTitle,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingOverlay.staged(
            labelKey: AppStrings.commonLoading,
          );
        }

        if (controller.hasError.value) {
          return ErrorView(
            messageKey: controller.errorMessageKey.value,
            onRetry: controller.loadClubPlayers,
          );
        }

        final players = controller.availablePlayers;
        final selected = controller.selectedPlayer.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Player Selector
              Text(AppStrings.rosterSelectPlayer.tr, style: textStyles.labelLg),
              SizedBox(height: sizes.xs),
              AppCard(
                padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.xs),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Player>(
                    value: selected,
                    isExpanded: true,
                    dropdownColor: colors.surface,
                    style: textStyles.bodyMd,
                    items: players.map((p) {
                      return DropdownMenuItem<Player>(
                        value: p,
                        child: Text('${p.name} (#${p.jerseyNumber} - ${p.position})'),
                      );
                    }).toList(),
                    onChanged: (p) {
                      if (p != null) controller.selectPlayer(p);
                    },
                  ),
                ),
              ),
              SizedBox(height: sizes.lg),

              // Action Type Tabs
              Row(
                children: [
                  Expanded(child: _buildActionTab(context, 'transfer', AppStrings.rosterActionTransfer)),
                  SizedBox(width: sizes.sm),
                  Expanded(child: _buildActionTab(context, 'loan', AppStrings.rosterActionLoan)),
                  SizedBox(width: sizes.sm),
                  Expanded(child: _buildActionTab(context, 'release', AppStrings.rosterActionRelease)),
                ],
              ),
              SizedBox(height: sizes.lg),

              // Target Squad & Details Card
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller.actionType.value != 'release') ...[
                      Text(AppStrings.rosterTargetSquad.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.xs),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(sizes.radiusMd),
                        ),
                        child: Text('Beta Titans (squad-beta-1)', style: textStyles.bodyMd),
                      ),
                      SizedBox(height: sizes.md),
                    ],

                    Text(AppStrings.rosterReasonLabel.tr, style: textStyles.labelLg),
                    SizedBox(height: sizes.xs),
                    SizedBox(
                      height: sizes.input,
                      child: TextField(
                        controller: controller.reasonController,
                        style: textStyles.bodyMd,
                        decoration: InputDecoration(
                          hintText: 'Enter formal reason for audit record',
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
                    SizedBox(height: sizes.lg),

                    // Submit Primary Button
                    PrimaryButton(
                      labelKey: AppStrings.rosterSubmitAction,
                      onPressed: controller.submitRosterAction,
                      isLoading: controller.isSubmitting.value,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.xxl),

              // Player Audit Trail Section
              const SectionHeader(titleKey: AppStrings.rosterHistoryTitle),
              SizedBox(height: sizes.md),

              if (controller.playerHistory.isEmpty)
                const EmptyView(
                  messageKey: AppStrings.rosterHistoryEmpty,
                  icon: Icons.history_edu_outlined,
                )
              else
                for (final audit in controller.playerHistory) ...[
                  AppCard(
                    padding: EdgeInsets.all(sizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(sizes.radiusPill),
                              ),
                              child: Text(
                                audit.action.toUpperCase(),
                                style: textStyles.labelMd.copyWith(color: colors.primary),
                              ),
                            ),
                            Text(Formatters.date(audit.when), style: textStyles.caption),
                          ],
                        ),
                        SizedBox(height: sizes.xs),
                        Text(
                          '${audit.fromSquadId} → ${audit.toSquadId ?? 'Free Agent'}',
                          style: textStyles.titleMd,
                        ),
                        SizedBox(height: sizes.xxs),
                        Text(
                          'Reason: ${audit.why}',
                          style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sizes.xs),
                ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionTab(BuildContext context, String type, String labelKey) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isSelected = controller.actionType.value == type;

    return PressableScale(
      child: GestureDetector(
        onTap: () => controller.setActionType(type),
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
          child: Text(
            labelKey.tr,
            style: textStyles.labelMd.copyWith(
              color: isSelected ? colors.primary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
