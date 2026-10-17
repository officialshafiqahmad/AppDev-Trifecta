import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../services/standings/standings_service.dart';

/// Controller managing league table standings.
class StandingsController extends GetxController {
  StandingsController({required this.standingsService});

  final StandingsService standingsService;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final Rx<StandingsResult?> result = Rx<StandingsResult?>(null);

  @override
  void onInit() {
    super.onInit();
    loadStandings();
  }

  Future<void> loadStandings({String leagueId = 'league-alpha-1'}) async {
    isLoading.value = true;
    hasError.value = false;

    final res = await standingsService.getStandings(leagueId);

    isLoading.value = false;

    if (res.isSuccess) {
      result.value = res.dataOrNull;
    } else {
      hasError.value = true;
      errorMessageKey.value = res.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void openClubProfile(String teamId) {
    Get.toNamed(
      AppRoutes.clubProfile,
      arguments: teamId,
    );
  }
}
