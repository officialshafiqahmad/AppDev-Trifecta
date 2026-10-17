import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/secondary_button.dart';

/// Pinned merchandise showcase card inside match detail.
class PinnedMerchCard extends StatelessWidget {
  const PinnedMerchCard({
    super.key,
    required this.onViewStore,
  });

  final VoidCallback onViewStore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppCard(
      padding: EdgeInsets.all(sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: sizes.huge,
                height: sizes.huge,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(sizes.radiusSm),
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
                  children: [
                    Text(
                      AppStrings.matchPinnedProductTitle.tr,
                      style: textStyles.labelMd.copyWith(color: colors.textSecondary),
                    ),
                    Text(
                      'Alpha FC Official Home Jersey',
                      style: textStyles.titleMd,
                    ),
                    Text(
                      'PKR 4500.00',
                      style: textStyles.bodyMd.copyWith(color: colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.md),
          SecondaryButton(
            labelKey: AppStrings.matchViewStore,
            onPressed: onViewStore,
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
    );
  }
}
