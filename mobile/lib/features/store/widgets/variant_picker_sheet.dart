import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable_scale.dart';
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
          Text(
            product.name,
            style: textStyles.titleLg,
          ),
          SizedBox(height: sizes.xxs),
          Text(
            product.formattedPrice,
            style: textStyles.headlineMd.copyWith(color: colors.primary),
          ),
          SizedBox(height: sizes.md),
          Text(
            AppStrings.storeSelectVariant.tr,
            style: textStyles.labelLg,
          ),
          SizedBox(height: sizes.sm),
          for (final variant in product.variants) ...[
            PressableScale(
              child: GestureDetector(
                onTap: () => onSelectVariant(variant),
                behavior: HitTestBehavior.opaque,
                child: AppCard(
                  padding: EdgeInsets.all(sizes.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Size: ${variant.size}', style: textStyles.titleMd),
                          Text('Color: ${variant.color}', style: textStyles.bodySm.copyWith(color: colors.textSecondary)),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(sizes.radiusPill),
                        ),
                        child: Text(
                          '${variant.stock} left',
                          style: textStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: sizes.xs),
          ],
          SizedBox(height: sizes.lg),
        ],
      ),
    );
  }
}
