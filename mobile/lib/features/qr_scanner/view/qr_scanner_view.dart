import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../controller/qr_scanner_controller.dart';

/// QR scanner & resolver screen (Phase II additive screen).
class QrScannerView extends GetView<QrScannerController> {
  const QrScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppScaffold(
      showSyncIndicator: false,
      titleKey: null,
      titleWidget: Text(
        'Scan QR Code',
        key: const ValueKey('qr_scanner_header'),
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
        key: const ValueKey('qr_scanner_screen'),
        padding: EdgeInsets.symmetric(vertical: sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Viewfinder Simulation Frame
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(sizes.radiusLg),
                border: Border.all(color: colors.primary, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_outlined,
                        size: sizes.giant,
                        color: colors.primary,
                      ),
                      SizedBox(height: sizes.sm),
                      Text(
                        'Align QR Code within frame',
                        style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                  // Reticle corners
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.primary, width: 3),
                          left: BorderSide(color: colors.primary, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.primary, width: 3),
                          right: BorderSide(color: colors.primary, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.primary, width: 3),
                          left: BorderSide(color: colors.primary, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.primary, width: 3),
                          right: BorderSide(color: colors.primary, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes.lg),

            // Manual Code Entry / Simulated Input
            AppCard(
              padding: EdgeInsets.all(sizes.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Resolve QR Payload / Short URL',
                    style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: sizes.sm),
                  TextField(
                    key: const ValueKey('qr-code-input'),
                    controller: controller.inputController,
                    decoration: InputDecoration(
                      hintText: 'e.g. m1-live or nascon://entity/match-m1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(sizes.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.qr_code),
                    ),
                  ),
                  SizedBox(height: sizes.sm),
                  Obx(() {
                    if (controller.errorMessage.value.isNotEmpty) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: sizes.sm),
                        child: Text(
                          controller.errorMessage.value,
                          style: textStyles.caption.copyWith(color: colors.error),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  PrimaryButton(
                    key: const ValueKey('qr-resolve-btn'),
                    labelKey: 'Resolve & Open',
                    onPressed: () => controller.resolveCode(),
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes.md),

            // Fast Test Actions
            Text(
              'Quick Scan Shortcuts',
              style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: sizes.xs),
            Wrap(
              spacing: sizes.sm,
              runSpacing: sizes.xs,
              children: [
                ActionChip(
                  label: const Text('m1-live (Match Live)'),
                  onPressed: () => controller.resolveCode('m1-live'),
                ),
                ActionChip(
                  label: const Text('cs-session-101 (Co-Stream)'),
                  onPressed: () => controller.resolveCode('cs-session-101'),
                ),
                ActionChip(
                  label: const Text('nascon://entity/match-m1'),
                  onPressed: () => controller.resolveCode('nascon://entity/match-m1'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
