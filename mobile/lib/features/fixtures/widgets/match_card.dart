import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/fixtures/fixtures_service.dart';

/// Standard match card conforming to DESIGN_RULES.md §2:
/// Home team left, score centre in headlineLg (largest text), away team right, status chip beneath.
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

    // Status chip styling
    Color chipBg;
    Color chipFg;
    String statusText;

    if (match.isLive) {
      chipBg = colors.errorBg;
      chipFg = colors.error;
      statusText = 'LIVE';
    } else if (match.isCompleted) {
      chipBg = colors.surfaceVariant;
      chipFg = colors.textSecondary;
      statusText = 'FT';
    } else {
      chipBg = colors.primaryContainer;
      chipFg = colors.primary;
      statusText = Formatters.timeOnly(match.startsAt);
    }

    final scoreDisplay = match.isUpcoming
        ? 'vs'
        : '${match.homeScore ?? 0} - ${match.awayScore ?? 0}';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(sizes.md),
      child: Column(
        children: [
          // Header: Sport & Venue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.sport.toUpperCase(),
                style: textStyles.overline,
              ),
              Text(
                match.venueName,
                style: textStyles.caption,
              ),
            ],
          ),
          SizedBox(height: sizes.md),

          // Main Row: Home Team - Score Center - Away Team
          Row(
            children: [
              // Home Team (Left)
              Expanded(
                child: Text(
                  match.homeTeamName,
                  style: textStyles.titleMd,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Score in Center (Largest text - headlineLg)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sizes.md),
                child: Column(
                  children: [
                    Text(
                      scoreDisplay,
                      style: textStyles.headlineLg.copyWith(
                        color: match.isLive ? colors.primary : colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: sizes.xs),
                    // Status Chip beneath score
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes.sm,
                        vertical: sizes.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(sizes.radiusPill),
                      ),
                      child: Text(
                        statusText,
                        style: textStyles.labelMd.copyWith(color: chipFg),
                      ),
                    ),
                  ],
                ),
              ),

              // Away Team (Right)
              Expanded(
                child: Text(
                  match.awayTeamName,
                  style: textStyles.titleMd,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
