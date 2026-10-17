import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../services/standings/standings_service.dart';
import '../controller/standings_controller.dart';

/// Dumb layout view for Standings table adhering to rules A1, C16, C17, and G15.
class StandingsView extends GetView<StandingsController> {
  const StandingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    return Obx(() {
      if (controller.isLoading.value) {
        return const LoadingOverlay.staged(
          labelKey: AppStrings.commonLoading,
        );
      }

      if (controller.hasError.value || controller.result.value == null) {
        return ErrorView(
          messageKey: controller.errorMessageKey.value,
          onRetry: controller.loadStandings,
        );
      }

      final data = controller.result.value!;
      final rows = data.rows;

      return RefreshIndicator(
        onRefresh: controller.loadStandings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rule G15: League Selector Segmented Control
              AppSegmentedControl<String>(
                items: const [
                  SegmentedItem(value: 'league-alpha-1', label: 'Premier Division'),
                  SegmentedItem(value: 'league-beta-1', label: 'Division One'),
                ],
                selectedValue: controller.selectedLeagueId.value,
                onChanged: controller.changeLeague,
              ),
              SizedBox(height: sizes.md),

              // League Qualification Banner
              AppCard(
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.cardPadding,
                  vertical: sizes.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: sizes.iconMd,
                      color: colors.primary,
                    ),
                    SizedBox(width: sizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.leagueName,
                            style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: sizes.xxs),
                          Text(
                            'Top ${data.qualificationSpots} clubs qualify for regional knockouts',
                            style: textStyles.caption.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.md),

              if (rows.isEmpty)
                const EmptyView(
                  messageKey: AppStrings.standingsEmpty,
                  icon: Icons.table_chart_outlined,
                )
              else ...[
                // Rule C16: Responsive 360dp Standings Table inside single AppCard
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Table Header Row
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes.md,
                          vertical: sizes.sm + 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(sizes.radiusLg)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                AppStrings.standingsRank.tr,
                                style: textStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: sizes.xs),
                            Expanded(
                              child: Text(
                                AppStrings.standingsTeam.tr,
                                style: textStyles.caption.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildHeaderCell('P', 28, textStyles),
                            _buildHeaderCell('W', 24, textStyles),
                            _buildHeaderCell('D', 24, textStyles),
                            _buildHeaderCell('L', 24, textStyles),
                            _buildHeaderCell('GD', 32, textStyles),
                            _buildHeaderCell('Pts', 32, textStyles, isBold: true),
                          ],
                        ),
                      ),

                      // Table Body Rows
                      for (int i = 0; i < rows.length; i++) ...[
                        _buildTableRow(context, rows[i]),
                        if (i < rows.length - 1)
                          Divider(height: 1, color: colors.border),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: sizes.md),

                // Rule C17: Status Dots Legend
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.sm),
                  child: Row(
                    children: [
                      _buildLegendDot(colors.success, 'Clinched (Top ${data.qualificationSpots})', textStyles, colors),
                      SizedBox(width: sizes.lg),
                      _buildLegendDot(colors.error, 'Eliminated', textStyles, colors),
                      SizedBox(width: sizes.lg),
                      _buildLegendDot(colors.textTertiary, 'In Contention', textStyles, colors),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeaderCell(String label, double width, dynamic textStyles, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: textStyles.caption.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, StandingRow row) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;

    // Rule C17: 6dp colored dot for status
    Color dotColor = colors.textTertiary;
    if (row.isClinched) {
      dotColor = colors.success;
    } else if (row.isEliminated) {
      dotColor = colors.error;
    }

    return InkWell(
      // Rule A1: Tapping row opens match drill-down bottom sheet
      onTap: () => controller.openTeamMatches(row),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sizes.md,
          vertical: sizes.md,
        ),
        child: Row(
          children: [
            // Pos with Status Dot
            SizedBox(
              width: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: sizes.xs),
                  Text(
                    '${row.rank}',
                    style: textStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(width: sizes.xs),

            // Club Name (Flexible, never overflows)
            Expanded(
              child: Text(
                row.teamName,
                style: textStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Stats Columns strictly sized for 360dp
            _buildDataCell('${row.played}', 28, textStyles, colors.textSecondary),
            _buildDataCell('${row.won}', 24, textStyles, colors.textSecondary),
            _buildDataCell('${row.drawn}', 24, textStyles, colors.textSecondary),
            _buildDataCell('${row.lost}', 24, textStyles, colors.textSecondary),
            _buildDataCell(
              row.diff > 0 ? '+${row.diff}' : '${row.diff}',
              32,
              textStyles,
              colors.textSecondary,
            ),
            _buildDataCell(
              '${row.points}',
              32,
              textStyles,
              colors.textPrimary,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String value, double width, dynamic textStyles, Color color, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: textStyles.bodyMd.copyWith(
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, dynamic textStyles, dynamic colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textStyles.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
