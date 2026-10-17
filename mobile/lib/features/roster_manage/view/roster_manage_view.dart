import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/club/club_service.dart';
import '../controller/roster_manage_controller.dart';

/// Dumb layout view for Roster Management screen adhering to rules A2, C4, C27, C28, C29, and C30.
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
              // Rule A2: Segmented control between Operations & Add Player
              AppSegmentedControl<int>(
                items: [
                  SegmentedItem(value: 0, label: 'Roster Operations', icon: Icons.swap_horiz_outlined),
                  SegmentedItem(value: 1, label: AppStrings.rosterAddPlayer.tr, icon: Icons.person_add_outlined),
                ],
                selectedValue: controller.activeSubTab.value,
                onChanged: controller.setSubTab,
              ),
              SizedBox(height: sizes.lg),

              if (controller.activeSubTab.value == 1) ...[
                // --- SUB-TAB 1: ADD PLAYER FORM (Rule A2) ---
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.rosterAddPlayer.tr,
                        style: textStyles.titleLg,
                      ),
                      SizedBox(height: sizes.xs),
                      Text(
                        'Register a new player into Lahore FC squads',
                        style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                      ),
                      SizedBox(height: sizes.md),

                      AppTextField(
                        controller: controller.newPlayerNameController,
                        label: AppStrings.rosterPlayerName.tr,
                        hintText: 'e.g. Harry Kane',
                        prefixIcon: Icon(Icons.person_outline, size: sizes.iconSm, color: colors.textTertiary),
                      ),
                      SizedBox(height: sizes.md),

                      AppTextField(
                        controller: controller.newPlayerJerseyController,
                        label: AppStrings.rosterJerseyNumber.tr,
                        hintText: 'e.g. 7',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icon(Icons.tag_outlined, size: sizes.iconSm, color: colors.textTertiary),
                      ),
                      SizedBox(height: sizes.md),

                      Text(AppStrings.rosterPosition.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.xs),
                      AppSegmentedControl<String>(
                        items: const [
                          SegmentedItem(value: 'Forward / Striker', label: 'Forward'),
                          SegmentedItem(value: 'Midfielder', label: 'Midfield'),
                          SegmentedItem(value: 'Defender', label: 'Defender'),
                          SegmentedItem(value: 'Goalkeeper', label: 'Keeper'),
                        ],
                        selectedValue: controller.newPlayerPosition.value,
                        onChanged: (val) => controller.newPlayerPosition.value = val,
                      ),
                      SizedBox(height: sizes.md),

                      Text(AppStrings.rosterTargetSquad.tr, style: textStyles.labelLg),
                      SizedBox(height: sizes.xs),
                      AppSegmentedControl<String>(
                        items: const [
                          SegmentedItem(value: 'squad-alpha-1', label: 'First Team'),
                          SegmentedItem(value: 'squad-reserves', label: 'Reserves'),
                          SegmentedItem(value: 'squad-academy', label: 'Academy'),
                        ],
                        selectedValue: controller.newPlayerSquad.value,
                        onChanged: (val) => controller.newPlayerSquad.value = val,
                      ),
                      SizedBox(height: sizes.xl),

                      PrimaryButton(
                        labelKey: AppStrings.rosterAddPlayerSubmit,
                        onPressed: controller.submitAddPlayer,
                        isLoading: controller.isSubmitting.value,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // --- SUB-TAB 0: ROSTER MUTATION OPERATIONS ---

                // Rule C27: Player Selector displaying name, jersey, position, and squad
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
                          child: Row(
                            children: [
                              Text(
                                '#${p.jerseyNumber}',
                                style: textStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                              SizedBox(width: sizes.sm),
                              Text(p.name, style: textStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                              SizedBox(width: sizes.xs),
                              Text('(${p.position})', style: textStyles.caption),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) controller.selectPlayer(p);
                      },
                    ),
                  ),
                ),
                SizedBox(height: sizes.md),

                // Action Type Selector (Transfer, Loan, Release)
                AppSegmentedControl<String>(
                  items: [
                    SegmentedItem(value: 'transfer', label: AppStrings.rosterActionTransfer.tr),
                    SegmentedItem(value: 'loan', label: AppStrings.rosterActionLoan.tr),
                    SegmentedItem(value: 'release', label: AppStrings.rosterActionRelease.tr),
                  ],
                  selectedValue: controller.actionType.value,
                  onChanged: controller.setActionType,
                ),
                SizedBox(height: sizes.md),

                // Operation Details Card
                AppCard(
                  padding: EdgeInsets.all(sizes.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Target Squad Selector (Rule C28)
                      if (controller.actionType.value != 'release') ...[
                        Text(AppStrings.rosterTargetSquad.tr, style: textStyles.labelLg),
                        SizedBox(height: sizes.xs),
                        AppSegmentedControl<String>(
                          items: const [
                            SegmentedItem(value: 'squad-reserves', label: 'Reserves'),
                            SegmentedItem(value: 'squad-academy', label: 'Academy'),
                            SegmentedItem(value: 'squad-beta-loan', label: 'Loan Club'),
                          ],
                          selectedValue: controller.targetSquadId.value,
                          onChanged: (val) => controller.targetSquadId.value = val,
                        ),
                        SizedBox(height: sizes.md),
                      ],

                      // Rule C29 & G8: Native Date Pickers
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.rosterEffectiveDate.tr, style: textStyles.labelMd),
                                SizedBox(height: sizes.xs),
                                OutlinedButton.icon(
                                  onPressed: () => controller.pickEffectiveDate(context),
                                  icon: Icon(Icons.calendar_today_outlined, size: sizes.iconSm),
                                  label: Text(DateFormat('yyyy-MM-dd').format(controller.effectiveDate.value)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(sizes.radiusMd),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (controller.actionType.value == 'loan') ...[
                            SizedBox(width: sizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppStrings.rosterLoanEndDate.tr, style: textStyles.labelMd),
                                  SizedBox(height: sizes.xs),
                                  OutlinedButton.icon(
                                    onPressed: () => controller.pickLoanEndDate(context),
                                    icon: Icon(Icons.event_available_outlined, size: sizes.iconSm),
                                    label: Text(DateFormat('yyyy-MM-dd').format(controller.loanEndDate.value)),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(sizes.radiusMd),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: sizes.md),

                      // Reason input (Rule D4)
                      AppTextField(
                        controller: controller.reasonController,
                        label: AppStrings.rosterReasonLabel.tr,
                        hintText: 'Formal operational reason for audit record',
                        prefixIcon: Icon(Icons.description_outlined, size: sizes.iconSm, color: colors.textTertiary),
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
              ],

              SizedBox(height: sizes.lg),

              // Player Audit Trail Section in a SINGLE AppCard (Rule C4 & C30)
              const SectionHeader(titleKey: AppStrings.rosterHistoryTitle),
              SizedBox(height: sizes.xs),

              if (controller.playerHistory.isEmpty)
                const EmptyView(
                  messageKey: AppStrings.rosterHistoryEmpty,
                  icon: Icons.history_edu_outlined,
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < controller.playerHistory.length; i++) ...[
                        Padding(
                          padding: EdgeInsets.all(sizes.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AppStatusChip(
                                    label: controller.playerHistory[i].action.toUpperCase(),
                                    tone: controller.playerHistory[i].action == 'release'
                                        ? AppStatusTone.danger
                                        : controller.playerHistory[i].action == 'loan'
                                            ? AppStatusTone.warning
                                            : AppStatusTone.info,
                                  ),
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm').format(controller.playerHistory[i].when),
                                    style: textStyles.caption.copyWith(color: colors.textSecondary),
                                  ),
                                ],
                              ),
                              SizedBox(height: sizes.xs),
                              Text(
                                '${controller.playerHistory[i].fromSquadId} → ${controller.playerHistory[i].toSquadId ?? "Free Agent"}',
                                style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: sizes.xxs),
                              Text(
                                'Reason: ${controller.playerHistory[i].why}',
                                style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                              ),
                              Text(
                                'By: ${controller.playerHistory[i].who}',
                                style: textStyles.caption.copyWith(color: colors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        if (i < controller.playerHistory.length - 1)
                          Divider(height: 1, color: colors.border),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
