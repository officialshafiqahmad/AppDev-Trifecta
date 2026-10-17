import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/sync/sync_service.dart';
import '../controller/sync_status_controller.dart';

/// Refactored Sync Status view adhering to C4, C33, C34, C35, A6.
class SyncStatusView extends GetView<SyncStatusController> {
  const SyncStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: AppStrings.syncTitle,
      body: Obx(() {
        final isOnline = controller.isOnline;
        final isSyncing = controller.isSyncing;
        final actions = controller.actions;
        final pendingActions = actions.where((a) => a.isPending).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connectivity Status Card (C33: NO SIMULATION SWITCH HERE)
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Row(
                  children: [
                    Container(
                      width: sizes.listRowMin,
                      height: sizes.listRowMin,
                      decoration: BoxDecoration(
                        color: isOnline ? colors.successBg : colors.warningBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                        size: sizes.iconMd,
                        color: isOnline ? colors.success : colors.warning,
                      ),
                    ),
                    SizedBox(width: sizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? AppStrings.syncOnline.tr : AppStrings.syncOffline.tr,
                            style: textStyles.titleLg,
                          ),
                          SizedBox(height: sizes.xxs),
                          Text(
                            isOnline
                                ? 'Connected to Trifecta servers • Real-time sync active'
                                : '${pendingActions.length} change(s) queued locally in persistent storage',
                            style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AppStatusChip(
                      label: isOnline ? 'Live' : 'Offline',
                      tone: isOnline ? AppChipTone.success : AppChipTone.warning,
                      hasDot: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Trigger Sync Button
              PrimaryButton(
                labelKey: AppStrings.syncNowAction,
                onPressed: isOnline && pendingActions.isNotEmpty ? controller.triggerSync : null,
                isLoading: isSyncing,
                icon: Icons.sync_outlined,
              ),
              SizedBox(height: sizes.xl),

              // Queued Offline Actions Section
              SectionHeader(
                titleKey: AppStrings.syncQueueTitle,
                actionLabelKey: actions.any((a) => !a.isPending) ? 'Clear History' : null,
                onAction: controller.clearCompletedActions,
              ),
              SizedBox(height: sizes.md),

              if (actions.isEmpty)
                const EmptyView(
                  messageKey: AppStrings.syncQueueEmpty,
                  icon: Icons.cloud_done_outlined,
                )
              else
                // Single Card for repeating list items with dividers (C4)
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: actions.length,
                    separatorBuilder: (context, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.border,
                    ),
                    itemBuilder: (context, index) {
                      final action = actions.reversed.toList()[index];
                      return _buildActionRow(context, action);
                    },
                  ),
                ),
              SizedBox(height: sizes.xxl),

              // Developer / Testing section at the bottom (C33)
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build_outlined, size: sizes.iconSm, color: colors.textSecondary),
                        SizedBox(width: sizes.xs),
                        Text('Developer & Network Simulation', style: textStyles.labelLg),
                      ],
                    ),
                    SizedBox(height: sizes.xs),
                    Text(
                      'Simulate network drops to test offline persistence and deterministic replay.',
                      style: textStyles.caption,
                    ),
                    SizedBox(height: sizes.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Simulate Offline Mode', style: textStyles.bodyMd),
                        Switch(
                          value: !isOnline,
                          onChanged: (_) => controller.toggleOnline(),
                          activeThumbColor: colors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionRow(BuildContext context, QueuedAction action) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final title = _formatActionTitle(action);
    final tone = _getStatusTone(action.status);
    final statusLabel = _getStatusLabel(action);

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
                    Text(
                      title,
                      style: textStyles.titleSm,
                    ),
                    SizedBox(height: sizes.xxs),
                    Text(
                      'Action #${action.actionId.substring(0, action.actionId.length > 8 ? 8 : action.actionId.length)} • Base v${action.baseVersion}',
                      style: textStyles.caption,
                    ),
                  ],
                ),
              ),
              AppStatusChip(
                label: statusLabel,
                tone: tone,
                hasDot: true,
              ),
            ],
          ),
          SizedBox(height: sizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Queued: ${Formatters.dateTime(action.queuedAt)}',
                style: textStyles.caption,
              ),
              if (action.resolution != null)
                Text(
                  'Resolution: ${action.resolution}',
                  style: textStyles.caption.copyWith(color: colors.primary),
                ),
            ],
          ),
          if (action.userMessage != null && action.userMessage!.isNotEmpty) ...[
            SizedBox(height: sizes.xs),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xs),
              decoration: BoxDecoration(
                color: action.status == 'rejected' ? colors.errorBg : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(sizes.radiusSm),
              ),
              child: Text(
                action.userMessage!,
                style: textStyles.bodySm.copyWith(
                  color: action.status == 'rejected' ? colors.error : colors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatActionTitle(QueuedAction action) {
    final payload = action.payload;
    switch (action.type) {
      case 'score':
        final eventType = (payload['event_type'] as String?)?.capitalizeFirst ?? 'Score';
        final min = payload['minute'];
        final player = payload['player'] as String?;
        final minStr = min != null ? " ($min')" : "";
        final playerStr = player != null && player.isNotEmpty ? " — $player" : "";
        return 'Score: $eventType$minStr$playerStr';
      case 'roster_transfer':
        final name = payload['player_name'] ?? payload['player_id'] ?? 'Player';
        return 'Transfer: $name';
      case 'player_registration':
        final name = payload['name'] ?? 'Player';
        return 'Registration: $name';
      case 'store_order':
        final prod = payload['item_name'] ?? 'Merchandise';
        return 'Store Order: $prod';
      default:
        return action.type.replaceAll('_', ' ').capitalizeFirst ?? action.type;
    }
  }

  AppChipTone _getStatusTone(String status) {
    switch (status) {
      case 'applied':
        return AppChipTone.success;
      case 'rejected':
        return AppChipTone.danger;
      case 'pending':
      default:
        return AppChipTone.warning;
    }
  }

  String _getStatusLabel(QueuedAction action) {
    switch (action.status) {
      case 'applied':
        return 'Applied';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending Sync';
    }
  }
}
