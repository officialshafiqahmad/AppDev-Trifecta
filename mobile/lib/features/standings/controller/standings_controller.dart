import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../services/fixtures/fixtures_service.dart';
import '../../../services/standings/standings_service.dart';

/// Controller managing league table standings, league selection, and team match drill-down.
class StandingsController extends GetxController {
  StandingsController({
    required this.standingsService,
    required this.fixturesService,
  });

  final StandingsService standingsService;
  final FixturesService fixturesService;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final Rx<StandingsResult?> result = Rx<StandingsResult?>(null);
  final RxString selectedLeagueId = 'league-alpha-1'.obs;

  @override
  void onInit() {
    super.onInit();
    loadStandings();
  }

  Future<void> loadStandings({String? leagueId}) async {
    final targetLeague = leagueId ?? selectedLeagueId.value;
    selectedLeagueId.value = targetLeague;

    isLoading.value = true;
    hasError.value = false;

    final res = await standingsService.getStandings(targetLeague);

    isLoading.value = false;

    if (res.isSuccess) {
      result.value = res.dataOrNull;
    } else {
      hasError.value = true;
      errorMessageKey.value = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void changeLeague(String leagueId) {
    if (selectedLeagueId.value == leagueId) return;
    loadStandings(leagueId: leagueId);
  }

  /// Rule A1: Open bottom sheet showing team matches with direct tap-through to MatchDetail
  Future<void> openTeamMatches(StandingRow team) async {
    final fixturesRes = await fixturesService.getFixtures(leagueId: selectedLeagueId.value);
    final allMatches = fixturesRes.dataOrNull ?? [];
    final teamMatches = allMatches.where((m) =>
        m.homeTeamId == team.teamId || m.awayTeamId == team.teamId).toList();

    AppSheet.show(
      child: Builder(builder: (context) {
        final colors = context.colors;
        final sizes = context.sizes;
        final textStyles = context.text;

        return Padding(
          padding: EdgeInsets.all(sizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${team.teamName} · Matches',
                style: textStyles.titleLg,
              ),
              SizedBox(height: sizes.md),
              teamMatches.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.lg),
                      child: Center(
                        child: Text(
                          'No matches scheduled for this team.',
                          style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < teamMatches.length; i++) ...[
                            InkWell(
                              onTap: () {
                                Get.back();
                                Get.toNamed(
                                  AppRoutes.matchDetail,
                                  arguments: teamMatches[i].matchId,
                                );
                              },
                              borderRadius: BorderRadius.circular(sizes.radiusSm),
                              child: Padding(
                                padding: EdgeInsets.all(sizes.cardPadding),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${teamMatches[i].homeTeamName} vs ${teamMatches[i].awayTeamName}',
                                            style: textStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(height: sizes.xxs),
                                          Text(
                                            teamMatches[i].venueName,
                                            style: textStyles.caption.copyWith(color: colors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      teamMatches[i].isUpcoming
                                          ? 'vs'
                                          : '${teamMatches[i].homeScore ?? 0} - ${teamMatches[i].awayScore ?? 0}',
                                      style: textStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: sizes.sm),
                                    Icon(
                                      Icons.chevron_right_outlined,
                                      size: sizes.iconSm,
                                      color: colors.textTertiary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i < teamMatches.length - 1)
                              Divider(height: 1, color: colors.border),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: sizes.md),
                    // Quick button to club profile
                    TextButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.toNamed(AppRoutes.clubProfile, arguments: team.teamId);
                      },
                      icon: Icon(Icons.shield_outlined, size: sizes.iconSm),
                      label: Text('View ${team.teamName} Profile'),
                    ),
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }
}
