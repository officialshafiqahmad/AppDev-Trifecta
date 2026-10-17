import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../../services/fixtures/fixtures_service.dart';

/// Compact 4-element match card strictly adhering to UX rule C10:
/// 1. Top row: Status chip on left, Kickoff time on right
/// 2. Center row: Home team name, Score block (titleLg bold), Away team name
/// 3. Bottom row: Venue name with outlined pin icon, sport/league name
/// 4. Tap anywhere opens Match Detail
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  final MatchSummary match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    final (String statusLabel, AppStatusTone tone, bool dot) = switch (match.status) {
      'in_progress' => ('LIVE', AppStatusTone.danger, true),
      'completed' => ('FT', AppStatusTone.neutral, false),
      'postponed' => ('POSTPONED', AppStatusTone.warning, false),
      _ => (DateFormat('HH:mm').format(match.startsAt), AppStatusTone.info, false),
    };

    final scoreDisplay = match.isUpcoming
        ? 'vs'
        : '${match.homeScore ?? 0} - ${match.awayScore ?? 0}';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(sizes.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Status chip on left, Kickoff time/date on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppStatusChip(
                label: statusLabel,
                tone: tone,
                showDot: dot,
              ),
              Text(
                DateFormat('EEE, d MMM · HH:mm').format(match.startsAt),
                style: textStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          SizedBox(height: sizes.md),

          // 2. Center Row: Home Team - Score Block - Away Team
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  match.homeTeamName,
                  style: textStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sizes.md,
                      vertical: sizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: match.isLive ? colors.primaryContainer : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(sizes.radiusSm),
                    ),
                    child: Text(
                      scoreDisplay,
                      style: textStyles.titleLg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: match.isLive ? colors.primary : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  match.awayTeamName,
                  style: textStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.md),

          // 3. Bottom Row: Venue with outlined location pin, sport/league name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: sizes.iconSm - 4,
                    color: colors.textTertiary,
                  ),
                  SizedBox(width: sizes.xs),
                  Text(
                    match.venueName,
                    style: textStyles.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
              Text(
                match.sport,
                style: textStyles.caption.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
