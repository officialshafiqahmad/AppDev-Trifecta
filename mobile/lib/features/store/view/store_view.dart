import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../controller/store_controller.dart';
import '../widgets/product_card.dart';

/// Dumb layout view for Store catalogue screen.
class StoreView extends GetView<StoreController> {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;

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

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: controller.loadProducts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: sizes.lg,
                bottom: sizes.giant * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    titleKey: AppStrings.storeTitle,
                    actionLabelKey: controller.cartItems.isNotEmpty
                        ? '${controller.cartItems.length} items'
                        : null,
                    onAction: controller.openCart,
                  ),
                  SizedBox(height: sizes.md),

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

          // Floating Cart Bar (when cart has items)
          if (controller.cartItems.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: sizes.lg,
              child: PrimaryButton(
                labelKey: AppStrings.storeCartTitle,
                onPressed: controller.openCart,
                icon: Icons.shopping_bag_outlined,
              ),
            ),
        ],
      );
    });
  }
}
