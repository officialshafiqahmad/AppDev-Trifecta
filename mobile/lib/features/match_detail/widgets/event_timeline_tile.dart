import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/match/match_service.dart';

/// Event timeline row representing a match event.
class EventTimelineTile extends StatelessWidget {
  const EventTimelineTile({
    super.key,
    required this.event,
  });

  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final isCompensated = event.compensated;
    final isScore = event.type == 'score';
    final isCompensation = event.type == 'compensation';

    IconData icon;
    Color iconColor;

    if (isCompensation) {
      icon = Icons.undo_outlined;
      iconColor = colors.warning;
    } else if (isScore) {
      icon = Icons.sports_soccer_outlined;
      iconColor = colors.primary;
    } else {
      icon = Icons.info_outline_rounded;
      iconColor = colors.textSecondary;
    }

    String title;
    String subtitle;

    if (isScore) {
      title = event.payload['player'] as String? ?? 'Goal Scored';
      subtitle = 'Team: ${event.payload['team_id']}';
    } else if (isCompensation) {
      title = 'Score Correction (Compensated)';
      subtitle = 'Reason: ${event.payload['reason']}';
    } else {
      title = 'Match Event (${event.type})';
      subtitle = 'Sequence #${event.sequence}';
    }

    return AppCard(
      padding: EdgeInsets.all(sizes.md),
      child: Row(
        children: [
          Container(
            width: sizes.huge,
            height: sizes.huge,
            decoration: BoxDecoration(
              color: isCompensated ? colors.surfaceVariant : colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: sizes.iconSm,
              color: isCompensated ? colors.textTertiary : iconColor,
            ),
          ),
          SizedBox(width: sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textStyles.titleMd.copyWith(
                    decoration: isCompensated ? TextDecoration.lineThrough : null,
                    color: isCompensated ? colors.textTertiary : colors.textPrimary,
                  ),
                ),
                SizedBox(height: sizes.xxs),
                Text(
                  subtitle,
                  style: textStyles.bodySm.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (isCompensated)
            Container(
              padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xxs),
              decoration: BoxDecoration(
                color: colors.errorBg,
                borderRadius: BorderRadius.circular(sizes.radiusPill),
              ),
              child: Text(
                'Compensated',
                style: textStyles.labelMd.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}
