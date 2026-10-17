import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controller/store_controller.dart';
import '../widgets/product_card.dart';

/// Dumb layout view for Store catalogue screen adhering to rules C21 and C22.
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
                top: sizes.lg,
                bottom: hasCart ? sizes.giant * 2 : sizes.xl,
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

          // Rule C22: Floating Cart Bar with slide-in animation
          AnimatedPositioned(
            duration: sizes.motionNormal,
            curve: sizes.curveDefault,
            left: 0,
            right: 0,
            bottom: hasCart ? sizes.lg : -100,
            child: hasCart
                ? Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(sizes.radiusLg),
                      border: Border.all(color: colors.primary, width: 1.5),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: sizes.cardPadding,
                      vertical: sizes.sm + 2,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(sizes.sm),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
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
                                '${controller.cartItems.length} items in cart',
                                style: textStyles.labelMd.copyWith(color: colors.textSecondary),
                              ),
                              Text(
                                controller.formattedTotal,
                                style: textStyles.titleLg.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: controller.openCart,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sizes.radiusMd),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: sizes.lg,
                              vertical: sizes.sm,
                            ),
                          ),
                          child: Text(
                            'View Cart',
                            style: textStyles.labelLg.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}
