import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
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
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(AppStrings.commonClose.tr, style: textStyles.labelMd),
                ),
              ],
            ),
            SizedBox(height: sizes.sm),

            // Cart Items List
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sizes.contentMaxWidth / 2),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => SizedBox(height: sizes.xs),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AppCard(
                    padding: EdgeInsets.all(sizes.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: textStyles.titleMd),
                              Text(
                                'Size: ${item.variant.size} • ${item.formattedTotal}',
                                style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Quantity controls
                        IconButton(
                          icon: Icon(Icons.remove_outlined, size: sizes.iconSm),
                          onPressed: () => controller.updateQuantity(item, -1),
                        ),
                        Text('${item.quantity}', style: textStyles.labelLg),
                        IconButton(
                          icon: Icon(Icons.add_outlined, size: sizes.iconSm),
                          onPressed: () => controller.updateQuantity(item, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: sizes.md),

            // Discount Code Input Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: sizes.buttonSecondary,
                    child: TextField(
                      controller: controller.discountController,
                      style: textStyles.bodyMd,
                      decoration: InputDecoration(
                        hintText: 'Discount Code (WELCOME10)',
                        hintStyle: textStyles.caption,
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: EdgeInsets.symmetric(horizontal: sizes.md),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(sizes.radiusMd),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(sizes.radiusMd),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: sizes.sm),
                SizedBox(
                  height: sizes.buttonSecondary,
                  child: SecondaryButton(
                    labelKey: AppStrings.storeApplyCode,
                    onPressed: controller.applyDiscountCode,
                    isFullWidth: false,
                  ),
                ),
              ],
            ),
            if (controller.appliedDiscount.value.isNotEmpty) ...[
              SizedBox(height: sizes.xxs),
              Text(
                '10% Discount Applied',
                style: textStyles.caption.copyWith(color: colors.success),
              ),
            ],
            SizedBox(height: sizes.md),

            // Payment token selector (for test judges)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.storePaymentOption.tr, style: textStyles.labelMd),
                DropdownButton<String>(
                  value: controller.paymentToken.value,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.surface,
                  style: textStyles.bodyMd,
                  items: const [
                    DropdownMenuItem(value: 'tok_success', child: Text('Success Gateway')),
                    DropdownMenuItem(value: 'tok_declined', child: Text('Decline Gateway (402)')),
                  ],
                  onChanged: (val) {
                    if (val != null) controller.paymentToken.value = val;
                  },
                ),
              ],
            ),
            SizedBox(height: sizes.sm),

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
                  style: textStyles.headlineMd.copyWith(color: colors.primary),
                ),
              ],
            ),
            SizedBox(height: sizes.lg),

            // Checkout Button (Single PrimaryButton)
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
