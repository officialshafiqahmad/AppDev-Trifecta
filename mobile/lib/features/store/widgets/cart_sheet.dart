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

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: sizes.lg, vertical: sizes.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.storeCartTitle.tr, style: textStyles.titleLg),
                IconButton(
                  icon: Icon(Icons.close_outlined, size: sizes.iconSm),
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
                                  style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  'Size: ${items[i].variant.size} · Color: ${items[i].variant.color}',
                                  style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                                ),
                                SizedBox(height: sizes.xxs),
                                Text(
                                  items[i].formattedTotal,
                                  style: textStyles.bodyMd.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Steppers
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_outlined, size: sizes.iconSm),
                                onPressed: () => controller.updateQuantity(items[i], -1),
                              ),
                              Text('${items[i].quantity}', style: textStyles.labelLg),
                              IconButton(
                                icon: Icon(Icons.add_outlined, size: sizes.iconSm),
                                onPressed: () => controller.updateQuantity(items[i], 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(height: 1, color: colors.border),
                  ],
                ],
              ),
            ),
            SizedBox(height: sizes.md),

            // Discount Code Row (Rule D4)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller.discountController,
                    hintText: 'Discount Code (WELCOME10)',
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
              Text(
                '10% Discount Applied (WELCOME10)',
                style: textStyles.caption.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: sizes.md),

            // Rule C23 & A7: 3 Radio payment methods in clean single card
            Text(AppStrings.storePaymentOption.tr, style: textStyles.labelLg),
            SizedBox(height: sizes.xs),
            AppCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: controller.paymentToken.value,
                onChanged: (v) {
                  if (v != null) controller.paymentToken.value = v;
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(AppStrings.storePaymentCash.tr, style: textStyles.bodyMd),
                      subtitle: Text('Pay physical cash at the ground counter', style: textStyles.caption),
                      value: 'tok_cash',
                    ),
                    Divider(height: 1, color: colors.border),
                    RadioListTile<String>(
                      title: Text(AppStrings.storePaymentCard.tr, style: textStyles.bodyMd),
                      subtitle: Text('Instant debit/credit card gateway authorization', style: textStyles.caption),
                      value: 'tok_success',
                    ),
                    Divider(height: 1, color: colors.border),
                    RadioListTile<String>(
                      title: Text(AppStrings.storePaymentClubCredit.tr, style: textStyles.bodyMd),
                      subtitle: Text('Deduct from club membership credit wallet', style: textStyles.caption),
                      value: 'tok_club_credit',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: sizes.md),

            // Price Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.storeSubtotal.tr, style: textStyles.bodyMd),
                Text(controller.formattedSubtotal, style: textStyles.bodyMd),
              ],
            ),
            if (controller.discountMinor > 0) ...[
              SizedBox(height: sizes.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.storeDiscount.tr, style: textStyles.bodyMd.copyWith(color: colors.success)),
                  Text('- ${controller.formattedDiscount}', style: textStyles.bodyMd.copyWith(color: colors.success)),
                ],
              ),
            ],
            SizedBox(height: sizes.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.storeTotal.tr, style: textStyles.titleLg),
                Text(
                  controller.formattedTotal,
                  style: textStyles.headlineMd.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: sizes.lg),

            // Checkout Button
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
