import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../services/store/store_service.dart';

/// Product catalogue display card.
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
        children: [
          Row(
            children: [
              Container(
                width: sizes.listRowMin,
                height: sizes.listRowMin,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(sizes.radiusSm),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: sizes.iconMd,
                  color: colors.primary,
                ),
              ),
              SizedBox(width: sizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: textStyles.titleMd),
                    SizedBox(height: sizes.xxs),
                    Text(
                      product.formattedPrice,
                      style: textStyles.headlineMd.copyWith(color: colors.primary),
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
            labelKey: 'store_add_to_cart',
            onPressed: onTap,
            icon: Icons.add_shopping_cart_outlined,
          ),
        ],
      ),
    );
  }
}
