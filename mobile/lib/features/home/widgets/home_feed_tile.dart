import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../model/home_feed_item.dart';

/// Feature widget displaying a recent operational feed item.
class HomeFeedTile extends StatelessWidget {
  const HomeFeedTile({
    super.key,
    required this.item,
  });

  final HomeFeedItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return AppCard(
      padding: EdgeInsets.all(sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.sm,
                  vertical: sizes.xxs,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(sizes.radiusSm),
                ),
                child: Text(
                  item.category,
                  style: textStyles.labelMd.copyWith(color: colors.primary),
                ),
              ),
              Text(
                Formatters.shortDate(item.timestamp),
                style: textStyles.caption,
              ),
            ],
          ),
          SizedBox(height: sizes.sm),
          Text(
            item.title,
            style: textStyles.titleMd,
          ),
          SizedBox(height: sizes.xs),
          Text(
            item.subtitle,
            style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
