import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../services/match/match_service.dart';

/// Single event timeline row designed to sit inside a single AppCard with dividers (Rule C4 & C15).
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

    final (IconData icon, Color iconColor) = switch (event.type) {
      'compensation' => (Icons.undo_outlined, colors.warning),
      'score' => (Icons.sports_soccer_outlined, colors.primary),
      'discipline' => (Icons.warning_amber_outlined, colors.error),
      _ => (Icons.info_outline, colors.textSecondary),
    };

    String title;
    String subtitle;
    final minute = event.payload['minute'] ?? (event.sequence * 12);

    if (isScore) {
      final playerName = event.payload['player'] as String? ?? 'Goal';
      final teamName = event.payload['team_name'] as String? ??
          (event.payload['team_id'] == 'club-alpha-1'
              ? 'Lahore FC'
              : event.payload['team_id'] == 'club-alpha-2'
                  ? 'Karachi City'
                  : 'Team');
      title = playerName;
      subtitle = '$teamName · Goal';
    } else if (isCompensation) {
      title = 'Score Correction';
      subtitle = event.payload['reason'] as String? ?? 'Disallowed by referee';
    } else {
      title = event.type == 'match_start' ? 'Match Kickoff' : 'Match Event';
      subtitle = 'First Half';
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: sizes.cardPadding,
        vertical: sizes.md,
      ),
      child: Row(
        children: [
          // Minute badge
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCompensated ? colors.surfaceVariant : colors.primaryContainer,
              borderRadius: BorderRadius.circular(sizes.radiusSm),
            ),
            child: Text(
              "$minute'",
              style: textStyles.labelMd.copyWith(
                fontWeight: FontWeight.bold,
                color: isCompensated ? colors.textTertiary : colors.primary,
              ),
            ),
          ),
          SizedBox(width: sizes.md),

          // Event Icon
          Icon(
            icon,
            size: sizes.iconSm,
            color: isCompensated ? colors.textTertiary : iconColor,
          ),
          SizedBox(width: sizes.md),

          // Event Detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompensated ? TextDecoration.lineThrough : null,
                    color: isCompensated ? colors.textTertiary : colors.textPrimary,
                  ),
                ),
                SizedBox(height: sizes.xxs),
                Text(
                  subtitle,
                  style: textStyles.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),

          // Compensated pill
          if (isCompensated) ...[
            SizedBox(width: sizes.sm),
            const AppStatusChip(
              label: 'Compensated',
              tone: AppStatusTone.danger,
            ),
          ],
        ],
      ),
    );
  }
}
