import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../controller/store_controller.dart';

/// Modal bottom sheet displaying active shopping cart and checkout controls.
/// Follows Rules C4, C23, C24, and C26 (scroll view, 3 radio payment outcomes, plain discount).
class CartSheet extends GetView<StoreController> {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Obx(() {
      final items = controller.cartItems;

      if (items.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(sizes.xl),
          child: EmptyView(
            messageKey: AppStrings.storeEmpty,
            icon: Icons.remove_shopping_cart_outlined,
            actionLabelKey: AppStrings.commonClose,
            onAction: () => Get.back(),
          ),
        );
      }

      // Rule C26: Wrap the whole sheet content in a scroll view to prevent overflow at 640dp
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.storeCartTitle.tr,
                  style: textStyles.titleLg.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.close_outlined, size: sizes.iconSm),
                  tooltip: AppStrings.commonClose.tr,
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: sizes.sm),

            // Rule C4 & C26: Cart Items in a SINGLE AppCard with dividers
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes.cardPadding,
                        vertical: sizes.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items[i].product.name,
                                  style: textStyles.titleMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: sizes.xxs),
                                // Rule C26: Variant rows: title "M — White", no "Size:" / "Color:" prefixes
                                Text(
                                  '${items[i].variant.size} — ${items[i].variant.color}',
                                  style: textStyles.bodySm.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  items[i].formattedTotal,
                                  style: textStyles.titleMd.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: sizes.sm),
                          // Quantity Steppers
                          Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_outlined, size: sizes.iconSm),
                                  tooltip: 'Decrease quantity',
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  onPressed: () => controller.updateQuantity(items[i], -1),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: sizes.xs),
                                  child: Text(
                                    '${items[i].quantity}',
                                    style: textStyles.labelLg.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_outlined, size: sizes.iconSm),
                                  tooltip: 'Increase quantity',
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  onPressed: items[i].quantity < items[i].variant.stock
                                      ? () => controller.updateQuantity(items[i], 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(height: 1, thickness: 1, color: colors.border),
                  ],
                ],
              ),
            ),
            SizedBox(height: sizes.lg),

            // Rule C24: Discount Code Row
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller.discountController,
                    hintText: AppStrings.storeDiscountCodeHint.tr,
                  ),
                ),
                SizedBox(width: sizes.sm),
                SecondaryButton(
                  labelKey: AppStrings.storeApplyCode,
                  onPressed: controller.applyDiscountCode,
                  isFullWidth: false,
                ),
              ],
            ),
            if (controller.appliedDiscount.value.isNotEmpty) ...[
              SizedBox(height: sizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.storeDiscountApplied.tr,
                    style: textStyles.caption.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: controller.clearDiscount,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sizes.xs, vertical: sizes.xxs),
                      child: Text(
                        'Remove',
                        style: textStyles.caption.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: sizes.lg),

            // Rule C23: 3 Selectable Radio-Style Rows with Outlined Icons
            Text(
              AppStrings.storePaymentOption.tr,
              style: textStyles.labelLg.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: sizes.xs),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PaymentRadioTile(
                    title: AppStrings.storePaymentSucceeds.tr,
                    subtitle: AppStrings.storePaymentSucceedsDesc.tr,
                    icon: Icons.credit_card_outlined,
                    value: 'tok_success',
                    groupValue: controller.paymentToken.value,
                    onSelected: (v) => controller.paymentToken.value = v,
                  ),
                  Divider(height: 1, thickness: 1, color: colors.border),
                  _PaymentRadioTile(
                    title: AppStrings.storePaymentDeclined.tr,
                    subtitle: AppStrings.storePaymentDeclinedDesc.tr,
                    icon: Icons.credit_card_off_outlined,
                    value: 'tok_declined',
                    groupValue: controller.paymentToken.value,
                    onSelected: (v) => controller.paymentToken.value = v,
                  ),
                  Divider(height: 1, thickness: 1, color: colors.border),
                  _PaymentRadioTile(
                    title: AppStrings.storePaymentCaptureFail.tr,
                    subtitle: AppStrings.storePaymentCaptureFailDesc.tr,
                    icon: Icons.error_outline,
                    value: 'tok_capture_fail',
                    groupValue: controller.paymentToken.value,
                    onSelected: (v) => controller.paymentToken.value = v,
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes.lg),

            // Price Breakdown Card
            AppCard(
              padding: EdgeInsets.all(sizes.cardPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.storeSubtotal.tr,
                        style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
                      ),
                      Text(controller.formattedSubtotal, style: textStyles.bodyMd),
                    ],
                  ),
                  if (controller.discountMinor > 0) ...[
                    SizedBox(height: sizes.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.storeDiscount.tr,
                          style: textStyles.bodyMd.copyWith(color: colors.success),
                        ),
                        Text(
                          '- ${controller.formattedDiscount}',
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
                      Text(
                        AppStrings.storeTotal.tr,
                        style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        controller.formattedTotal,
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

            // Rule 36: Exactly ONE PrimaryButton on screen
            PrimaryButton(
              labelKey: AppStrings.storeCheckout,
              onPressed: controller.confirmAndCheckout,
              isLoading: controller.isCheckingOut.value,
              icon: Icons.check_circle_outline,
            ),
            SizedBox(height: sizes.sm),
          ],
        ),
      );
    });
  }
}

class _PaymentRadioTile extends StatelessWidget {
  const _PaymentRadioTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onSelected(value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sizes.cardPadding,
          vertical: sizes.md,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_outlined
                  : Icons.radio_button_unchecked_outlined,
              size: sizes.iconSm,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: sizes.md),
            Icon(
              icon,
              size: sizes.iconMd,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: sizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textStyles.titleMd.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: sizes.xxs),
                  Text(
                    subtitle,
                    style: textStyles.caption.copyWith(color: colors.textSecondary),
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
