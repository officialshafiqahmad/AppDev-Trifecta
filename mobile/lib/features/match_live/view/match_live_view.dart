import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/match_live_controller.dart';

/// Native Match Live stream screen (Phase II additive screen).
/// Opened directly via nascon://entity/match-m1 without stopping at login.
class MatchLiveView extends GetView<MatchLiveController> {
  const MatchLiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      showSyncIndicator: false,
      titleKey: null,
      titleWidget: Text(
        'Match Live',
        key: const ValueKey('match_live_header'),
        style: textStyles.titleLg,
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_outlined, size: sizes.iconMd),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.main);
          }
        },
      ),
      body: SingleChildScrollView(
        key: const ValueKey('match_live_screen'),
        padding: EdgeInsets.symmetric(vertical: sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live Score Banner (data-testid / Key: live-score-banner)
            Obx(() => AppCard(
                  key: const ValueKey('live-score-banner'),
                  padding: EdgeInsets.all(sizes.cardPadding),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppStatusChip(
                            label: 'LIVE',
                            tone: AppStatusTone.danger,
                            showDot: true,
                          ),
                          SizedBox(width: sizes.sm),
                          Text(
                            controller.matchId.value,
                            style: textStyles.caption.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                      SizedBox(height: sizes.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Text(
                              controller.homeTeamName.value,
                              textAlign: TextAlign.center,
                              style: textStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${controller.homeScore.value} - ${controller.awayScore.value}',
                            style: textStyles.headlineLg.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              controller.awayTeamName.value,
                              textAlign: TextAlign.center,
                              style: textStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(height: sizes.md),

            // 2. Video Player Container (Key: guest-video-player)
            Container(
              key: const ValueKey('guest-video-player'),
              height: 220,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(sizes.radiusLg),
                border: Border.all(color: colors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.live_tv_outlined,
                        size: sizes.giant,
                        color: colors.primary,
                      ),
                      SizedBox(height: sizes.sm),
                      Obx(() => Text(
                        controller.streamStatusMessage.value,
                        style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                      )),
                      SizedBox(height: sizes.xxs),
                      Obx(() => Padding(
                            padding: EdgeInsets.symmetric(horizontal: sizes.md),
                            child: Text(
                              controller.playbackUrl.value,
                              style: textStyles.caption.copyWith(color: colors.textSecondary),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                  ),
                  Positioned(
                    top: sizes.sm,
                    right: sizes.sm,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(sizes.radiusSm),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: sizes.xs),
                          Text(
                            'HLS 1080p',
                            style: textStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes.md),

            // 3. Pinned Merch Card (Key: pinned-merch-card)
            AppCard(
              key: const ValueKey('pinned-merch-card'),
              padding: EdgeInsets.all(sizes.cardPadding),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(sizes.radiusMd),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: sizes.iconMd,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(width: sizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alpha FC Official Home Jersey',
                          style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: sizes.xxs),
                        Text(
                          'PKR 4500.00',
                          style: textStyles.bodyMd.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SecondaryButton(
                    labelKey: 'View',
                    isFullWidth: false,
                    onPressed: () => Get.toNamed(AppRoutes.main),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
