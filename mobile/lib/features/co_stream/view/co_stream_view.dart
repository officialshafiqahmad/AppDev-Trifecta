import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../controller/co_stream_controller.dart';

/// Native 4-Way Co-Stream screen (Phase II additive screen).
/// Opened directly via nascon://stream/cs-session-101 without stopping at login.
class CoStreamView extends GetView<CoStreamController> {
  const CoStreamView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      titleKey: null,
      titleWidget: Text(
        'Co-Stream Session',
        key: const ValueKey('costream_header'),
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
        key: const ValueKey('costream_screen'),
        padding: EdgeInsets.symmetric(vertical: sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Info Banner
            Obx(() => AppCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizes.cardPadding,
                    vertical: sizes.sm,
                  ),
                  child: Row(
                    children: [
                      const AppStatusChip(
                        label: '4-WAY CO-STREAM',
                        tone: AppStatusTone.warning,
                        showDot: true,
                      ),
                      SizedBox(width: sizes.sm),
                      Expanded(
                        child: Text(
                          controller.sessionId.value,
                          style: textStyles.caption.copyWith(color: colors.textSecondary),
                        ),
                      ),
                      Text(
                        'Host: ${controller.activeHost.value}',
                        style: textStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: sizes.md),

            // 4-Way Split Video Grid (grid_4)
            Container(
              key: const ValueKey('costream_grid_container'),
              height: 280,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(sizes.radiusLg),
                border: Border.all(color: colors.border),
              ),
              padding: EdgeInsets.all(sizes.xs),
              child: Obx(() => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: controller.participants.length,
                    itemBuilder: (context, index) {
                      final p = controller.participants[index];
                      final isHost = p == controller.activeHost.value;

                      return Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(sizes.radiusMd),
                          border: Border.all(
                            color: isHost ? colors.primary : colors.border,
                            width: isHost ? 1.5 : 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: sizes.iconLg,
                                  color: isHost ? colors.primary : colors.textSecondary,
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  p,
                                  style: textStyles.caption.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (isHost)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'HOST',
                                    style: textStyles.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )),
            ),
            SizedBox(height: sizes.md),

            // Unified Audience Chat Room
            Text(
              'Audience Live Chat',
              style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: sizes.xs),
            AppCard(
              padding: EdgeInsets.all(sizes.cardPadding),
              child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final msg in controller.chatMessages) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: sizes.xxs),
                          child: RichText(
                            text: TextSpan(
                              style: textStyles.bodySm.copyWith(color: colors.textPrimary),
                              children: [
                                TextSpan(
                                  text: '${msg['sender']}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                                TextSpan(text: msg['text']),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
