import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/store/store_service.dart';
import '../controller/store_controller.dart';

/// Modal view displaying final paid receipt and real PDF download action.
/// Strictly follows Rule C25 (success header with check_circle_outlined in successBg,
/// no Auth ID row, no bottom Close SecondaryButton, real download PrimaryButton).
class ReceiptView extends StatelessWidget {
  const ReceiptView({
    super.key,
    required this.receipt,
  });

  final CheckoutResult receipt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;
    final controller = Get.find<StoreController>();

    final dateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(receipt.timestamp);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: sizes.lg,
        right: sizes.lg,
        top: sizes.sm,
        bottom: sizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Title and Close X icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.storeReceiptTitle.tr,
                style: textStyles.titleLg.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.close_outlined, size: sizes.iconSm),
                tooltip: AppStrings.commonClose.tr,
                onPressed: () => Get.back(),
              ),
            ],
          ),
          SizedBox(height: sizes.md),

          // Rule C25: Success header (check_circle_outlined in a successBg circle + "Payment successful" in titleLg)
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outlined,
                    size: sizes.iconLg,
                    color: colors.success,
                  ),
                ),
                SizedBox(height: sizes.sm),
                Text(
                  AppStrings.storePaymentSuccessful.tr,
                  style: textStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: sizes.xxs),
                Text(
                  AppStrings.storePaymentSuccessDesc.tr,
                  style: textStyles.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: sizes.lg),

          // Receipt details card (Rule C25: Auth ID removed)
          AppCard(
            padding: EdgeInsets.all(sizes.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID', style: textStyles.labelMd.copyWith(color: colors.textSecondary)),
                    Text(receipt.orderId, style: textStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: sizes.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date', style: textStyles.labelMd.copyWith(color: colors.textSecondary)),
                    Text(dateFormatted, style: textStyles.bodyMd),
                  ],
                ),
                Divider(height: sizes.lg, thickness: 1, color: colors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.storeSubtotal.tr, style: textStyles.bodyMd),
                    Text(receipt.formattedSubtotal, style: textStyles.bodyMd),
                  ],
                ),
                if (receipt.discountMinor > 0) ...[
                  SizedBox(height: sizes.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.storeDiscount.tr, style: textStyles.bodyMd.copyWith(color: colors.success)),
                      Text(
                        '- ${receipt.formattedDiscount}',
                        style: textStyles.bodyMd.copyWith(
                          color: colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                Divider(height: sizes.lg, thickness: 1, color: colors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.storeTotal.tr, style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      receipt.formattedTotal,
                      style: textStyles.headlineMd.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: sizes.lg),

          // Rule A3 & C25: Real PDF Download button is the single PrimaryButton
          PrimaryButton(
            labelKey: AppStrings.storeDownloadReceipt,
            onPressed: () => controller.downloadReceipt(receipt),
            icon: Icons.download_outlined,
          ),
          SizedBox(height: sizes.sm),
        ],
      ),
    );
  }
}
