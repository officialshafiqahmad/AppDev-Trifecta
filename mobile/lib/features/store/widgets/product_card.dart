import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../services/store/store_service.dart';

/// Product catalogue display card strictly adhering to Rule C21 card budget.
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

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed aspect ratio clean outlined placeholder icon (Rule C21)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: sizes.iconLg,
                  color: colors.primary,
                ),
              ),
              SizedBox(width: sizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.sm),
          Text(
            product.description,
            style: textStyles.bodySm.copyWith(color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: sizes.md),
          SecondaryButton(
            labelKey: AppStrings.storeAddToCart,
            onPressed: onTap,
            icon: Icons.add_shopping_cart_outlined,
          ),
        ],
      ),
    );
  }
}
