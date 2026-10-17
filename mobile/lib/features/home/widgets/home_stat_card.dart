import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../model/home_feed_item.dart';

/// Feature widget displaying an operational metric summary.
class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    super.key,
    required this.stat,
  });

  final HomeStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Expanded(
      child: AppCard(
        padding: EdgeInsets.all(sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  IconData(stat.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: sizes.iconSm,
                  color: colors.primary,
                ),
                Text(
                  Formatters.count(stat.count),
                  style: textStyles.headlineMd.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
            SizedBox(height: sizes.sm),
            Text(
              stat.titleKey.tr,
              style: textStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
