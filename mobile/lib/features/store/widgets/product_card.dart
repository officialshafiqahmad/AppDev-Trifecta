import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/store/store_service.dart';

/// Product catalogue display card strictly adhering to Rule C21 card budget:
/// icon tile, name, price, ONE compact action. Whole card tap opens variant picker.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    // Determine variant summary
    final variantCount = product.variants.length;
    final totalStock = product.variants.fold<int>(0, (sum, v) => sum + v.stock);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(sizes.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon tile (Rule C21)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(sizes.radiusMd),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: sizes.iconMd,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(width: sizes.md),

          // 2. Name & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sizes.xxs),
                Text(
                  product.formattedPrice,
                  style: textStyles.titleLg.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: sizes.xxs),
                Text(
                  totalStock <= 0
                      ? 'Sold Out'
                      : '$variantCount ${variantCount == 1 ? "option" : "options"}',
                  style: textStyles.caption.copyWith(
                    color: totalStock <= 0 ? colors.error : colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: sizes.sm),

          // 3. Compact trailing "Add" action (Rule C21)
          Material(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(sizes.radiusMd),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(sizes.radiusMd),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.md,
                  vertical: sizes.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_outlined,
                      size: sizes.iconSm,
                      color: colors.primary,
                    ),
                    SizedBox(width: sizes.xxs),
                    Text(
                      'Add',
                      style: textStyles.labelMd.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
