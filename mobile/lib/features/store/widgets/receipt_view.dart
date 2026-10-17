import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../services/store/store_service.dart';

/// Modal view displaying final paid receipt and PDF download action.
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sizes.lg, vertical: sizes.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.storeReceiptTitle.tr, style: textStyles.titleLg),
              IconButton(
                icon: Icon(Icons.close_outlined, size: sizes.iconSm),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          SizedBox(height: sizes.md),

          // Receipt details card
          AppCard(
            padding: EdgeInsets.all(sizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID', style: textStyles.labelMd),
                    Text(receipt.orderId, style: textStyles.bodyMd),
                  ],
                ),
                SizedBox(height: sizes.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date', style: textStyles.labelMd),
                    Text(Formatters.dateTime(receipt.timestamp), style: textStyles.bodyMd),
                  ],
                ),
                SizedBox(height: sizes.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Auth ID', style: textStyles.labelMd),
                    Text(receipt.paymentAuthId, style: textStyles.bodySm.copyWith(color: colors.textSecondary)),
                  ],
                ),
                Divider(height: sizes.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.storeSubtotal.tr, style: textStyles.bodyMd),
                    Text(receipt.formattedSubtotal, style: textStyles.bodyMd),
                  ],
                ),
                if (receipt.discountMinor > 0) ...[
                  SizedBox(height: sizes.xxs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.storeDiscount.tr, style: textStyles.bodyMd.copyWith(color: colors.success)),
                      Text('- ${receipt.formattedDiscount}', style: textStyles.bodyMd.copyWith(color: colors.success)),
                    ],
                  ),
                ],
                SizedBox(height: sizes.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.storeTotal.tr, style: textStyles.titleLg),
                    Text(
                      receipt.formattedTotal,
                      style: textStyles.headlineMd.copyWith(color: colors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: sizes.lg),

          // Download Receipt PDF Primary Action
          PrimaryButton(
            labelKey: AppStrings.storeDownloadReceipt,
            onPressed: () {
              Get.back();
              Get.snackbar(
                '',
                AppStrings.storeReceiptDownloaded.tr,
                titleText: const SizedBox.shrink(),
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: colors.surfaceVariant,
              );
            },
            icon: Icons.download_outlined,
          ),
          SizedBox(height: sizes.sm),
          SecondaryButton(
            labelKey: AppStrings.commonClose,
            onPressed: () => Get.back(),
          ),
          SizedBox(height: sizes.sm),
        ],
      ),
    );
  }
}
