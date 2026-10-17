import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controller/store_controller.dart';
import '../widgets/product_card.dart';

/// Catalogue view for Store screen adhering strictly to DESIGN_RULES.md and Rule C22.
class StoreView extends GetView<StoreController> {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Obx(() {
      if (controller.isLoading.value) {
        return const LoadingOverlay.staged(
          labelKey: AppStrings.commonLoading,
        );
      }

      if (controller.hasError.value) {
        return ErrorView(
          messageKey: controller.errorMessageKey.value,
          onRetry: controller.loadProducts,
        );
      }

      final items = controller.products;
      final hasCart = controller.cartItems.isNotEmpty;

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: controller.loadProducts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: sizes.md,
                bottom: hasCart ? 96 : sizes.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (items.isEmpty)
                    const EmptyView(
                      messageKey: AppStrings.storeEmpty,
                      icon: Icons.storefront_outlined,
                    )
                  else
                    for (final product in items) ...[
                      ProductCard(
                        product: product,
                        onTap: () => controller.openVariantPicker(product),
                      ),
                      SizedBox(height: sizes.md),
                    ],
                ],
              ),
            ),
          ),

          // Rule C22: Floating Cart Bar with bag icon, "View cart", and the cart total price on the right
          AnimatedPositioned(
            duration: sizes.motionNormal,
            curve: sizes.curveDefault,
            left: 0,
            right: 0,
            bottom: hasCart ? sizes.md : -100,
            child: hasCart
                ? Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(sizes.radiusLg),
                    child: InkWell(
                      onTap: controller.openCart,
                      borderRadius: BorderRadius.circular(sizes.radiusLg),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(sizes.radiusLg),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes.cardPadding,
                          vertical: sizes.sm + 4,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(sizes.radiusMd),
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: sizes.iconSm,
                                color: colors.primary,
                              ),
                            ),
                            SizedBox(width: sizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.storeViewCart.tr,
                                    style: textStyles.titleMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: sizes.xxs),
                                  Text(
                                    '${controller.cartItems.length} ${controller.cartItems.length == 1 ? "item" : "items"} in cart',
                                    style: textStyles.caption.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.formattedTotal,
                                  style: textStyles.titleLg.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: sizes.xs),
                            Icon(
                              Icons.chevron_right_outlined,
                              size: sizes.iconSm,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}
