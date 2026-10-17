import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../strings/app_strings.dart';
import '../theme/theme_ext.dart';
import '../../services/sync/sync_service.dart';
import '../../services/sync/sync_service_mock.dart';
import 'pressable_scale.dart';

/// Always-visible sync indicator in the app bar.
/// Displays Online / Offline / Syncing state and pending queued action count.
/// Tapping it opens the Sync Status details screen.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    SyncServiceMock syncService;
    try {
      syncService = Get.find<SyncService>() as SyncServiceMock;
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final isOnline = syncService.isOnlineRx.value;
      final isSyncing = syncService.isSyncingRx.value;
      final pendingCount = syncService.rxActions.where((a) => a.isPending).length;

      Color badgeBg;
      Color badgeFg;
      String label;
      IconData icon;

      if (isSyncing) {
        badgeBg = colors.primaryContainer;
        badgeFg = colors.primary;
        label = AppStrings.syncSyncing.tr;
        icon = Icons.sync_outlined;
      } else if (!isOnline) {
        badgeBg = colors.warningBg;
        badgeFg = colors.warning;
        label = AppStrings.syncOffline.tr;
        icon = Icons.cloud_off_outlined;
      } else {
        badgeBg = colors.successBg;
        badgeFg = colors.success;
        label = AppStrings.syncOnline.tr;
        icon = Icons.cloud_done_outlined;
      }

      return PressableScale(
        child: GestureDetector(
          onTap: () {
            if (Get.currentRoute != AppRoutes.syncStatus) {
              Get.toNamed(AppRoutes.syncStatus);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: sizes.sm,
              vertical: sizes.sm,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: sizes.sm,
              vertical: sizes.xs,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(sizes.radiusPill),
              border: Border.all(color: badgeFg.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: sizes.iconSm,
                  color: badgeFg,
                ),
                SizedBox(width: sizes.xs),
                Text(
                  label,
                  style: textStyles.labelMd.copyWith(color: badgeFg),
                ),
                if (pendingCount > 0) ...[
                  SizedBox(width: sizes.xs),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sizes.xs,
                      vertical: sizes.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(sizes.radiusPill),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: textStyles.labelMd.copyWith(color: colors.onPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
