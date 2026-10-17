import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../services/store/store_service.dart';

/// Bottom sheet to select variant (size/colour) before adding to cart.
class VariantPickerSheet extends StatelessWidget {
  const VariantPickerSheet({
    super.key,
    required this.product,
    required this.onSelectVariant,
  });

  final Product product;
  final ValueChanged<ProductVariant> onSelectVariant;

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
              Expanded(
                child: Text(
                  product.name,
                  style: textStyles.titleLg,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_outlined, size: sizes.iconSm),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          SizedBox(height: sizes.xxs),
          Text(
            product.formattedPrice,
            style: textStyles.headlineMd.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: sizes.md),
          Text(
            AppStrings.storeSelectVariant.tr,
            style: textStyles.labelLg,
          ),
          SizedBox(height: sizes.sm),

          // Variants in a SINGLE AppCard with dividers (Rule C4)
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < product.variants.length; i++) ...[
                  InkWell(
                    onTap: product.variants[i].stock > 0
                        ? () => onSelectVariant(product.variants[i])
                        : null,
                    borderRadius: BorderRadius.circular(sizes.radiusSm),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes.cardPadding,
                        vertical: sizes.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Size: ${product.variants[i].size}',
                                style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: sizes.xxs),
                              Text(
                                'Color: ${product.variants[i].color}',
                                style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                          if (product.variants[i].stock <= 0)
                            const AppStatusChip(
                              label: 'Sold Out',
                              tone: AppStatusTone.danger,
                            )
                          else if (product.variants[i].stock == 1)
                            const AppStatusChip(
                              label: 'Only 1 left!',
                              tone: AppStatusTone.warning,
                              showDot: true,
                            )
                          else
                            AppStatusChip(
                              label: '${product.variants[i].stock} in stock',
                              tone: AppStatusTone.neutral,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (i < product.variants.length - 1)
                    Divider(height: 1, color: colors.border),
                ],
              ],
            ),
          ),
          SizedBox(height: sizes.lg),
        ],
      ),
    );
  }
}
