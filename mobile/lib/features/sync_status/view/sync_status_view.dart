import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/sync_status_controller.dart';

/// Dumb layout view for Sync Status & Offline Queue screen.
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
              // Connectivity Status & Simulator Toggle Card
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
                          Text(
                            isOnline ? 'Connected to Trifecta servers' : 'Simulating offline / airplane mode',
                            style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: !isOnline,
                      onChanged: (_) => controller.toggleOnline(),
                      activeThumbColor: colors.warning,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.xl),

              // Trigger Sync Button (Single PrimaryButton on screen)
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
                actionLabelKey: actions.any((a) => !a.isPending) ? 'Clear Completed' : null,
                onAction: controller.clearCompletedActions,
              ),
              SizedBox(height: sizes.md),

              if (actions.isEmpty)
                const EmptyView(
                  messageKey: AppStrings.syncQueueEmpty,
                  icon: Icons.cloud_done_outlined,
                )
              else
                for (final action in actions.reversed) ...[
                  _buildActionCard(context, action),
                  SizedBox(height: sizes.sm),
                ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionCard(BuildContext context, dynamic action) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    Color statusBg;
    Color statusFg;
    String statusLabel;

    if (action.status == 'pending') {
      statusBg = colors.primaryContainer;
      statusFg = colors.primary;
      statusLabel = AppStrings.commonPending.tr;
    } else if (action.status == 'applied') {
      statusBg = colors.successBg;
      statusFg = colors.success;
      statusLabel = 'Applied (${action.resolution})';
    } else {
      statusBg = colors.errorBg;
      statusFg = colors.error;
      statusLabel = 'Rejected';
    }

    return AppCard(
      padding: EdgeInsets.all(sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                action.type.toString().replaceAll('_', ' ').toUpperCase(),
                style: textStyles.titleMd,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(sizes.radiusPill),
                ),
                child: Text(
                  statusLabel,
                  style: textStyles.labelMd.copyWith(color: statusFg),
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.xs),
          Text(
            'Action ID: ${action.actionId} • Base v${action.baseVersion}',
            style: textStyles.caption,
          ),
          Text(
            'Queued: ${Formatters.dateTime(action.queuedAt)}',
            style: textStyles.caption,
          ),
          if (action.userMessage != null) ...[
            SizedBox(height: sizes.xs),
            Container(
              padding: EdgeInsets.all(sizes.sm),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
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
}
