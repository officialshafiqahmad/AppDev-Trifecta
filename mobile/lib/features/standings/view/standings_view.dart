import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../controller/standings_controller.dart';

/// Dumb layout view for Standings table.
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

      if (rows.isEmpty) {
        return const EmptyView(
          messageKey: AppStrings.standingsEmpty,
          icon: Icons.table_chart_outlined,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadStandings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // League Banner
              AppCard(
                padding: EdgeInsets.all(sizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.leagueName, style: textStyles.titleMd),
                        SizedBox(height: sizes.xxs),
                        Text(
                          'Top ${data.qualificationSpots} spots clinch qualification',
                          style: textStyles.caption,
                        ),
                      ],
                    ),
                    Icon(
                      Icons.emoji_events_outlined,
                      size: sizes.iconMd,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.lg),

              // Horizontal Scrollable Table (Guarantees zero overflow on 360dp)
              AppCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: sizes.lg,
                    horizontalMargin: sizes.md,
                    headingRowColor: WidgetStateProperty.all(colors.surfaceVariant),
                    columns: [
                      DataColumn(label: Text(AppStrings.standingsRank.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsTeam.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsPlayed.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsWon.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsDrawn.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsLost.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsDiff.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.standingsPoints.tr, style: textStyles.labelMd)),
                      DataColumn(label: Text(AppStrings.commonStatus.tr, style: textStyles.labelMd)),
                    ],
                    rows: rows.map((r) {
                      Color statusBg;
                      Color statusFg;
                      String statusLabel;

                      if (r.isClinched) {
                        statusBg = colors.successBg;
                        statusFg = colors.success;
                        statusLabel = AppStrings.statusClinched.tr;
                      } else if (r.isEliminated) {
                        statusBg = colors.surfaceVariant;
                        statusFg = colors.textTertiary;
                        statusLabel = AppStrings.statusEliminated.tr;
                      } else {
                        statusBg = colors.primaryContainer;
                        statusFg = colors.primary;
                        statusLabel = AppStrings.statusPossible.tr;
                      }

                      return DataRow(
                        onSelectChanged: (_) => controller.openClubProfile(r.teamId),
                        cells: [
                          DataCell(Text('${r.rank}', style: textStyles.bodyMd)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  r.teamName,
                                  style: textStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                                SizedBox(width: sizes.xs),
                                Icon(Icons.chevron_right_outlined, size: sizes.iconSm, color: colors.textTertiary),
                              ],
                            ),
                          ),
                          DataCell(Text('${r.played}', style: textStyles.bodyMd)),
                          DataCell(Text('${r.won}', style: textStyles.bodyMd)),
                          DataCell(Text('${r.drawn}', style: textStyles.bodyMd)),
                          DataCell(Text('${r.lost}', style: textStyles.bodyMd)),
                          DataCell(Text('${r.diff}', style: textStyles.bodyMd)),
                          DataCell(
                            Text(
                              '${r.points}',
                              style: textStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: sizes.sm,
                                vertical: sizes.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(sizes.radiusPill),
                              ),
                              child: Text(
                                statusLabel,
                                style: textStyles.labelMd.copyWith(color: statusFg),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
