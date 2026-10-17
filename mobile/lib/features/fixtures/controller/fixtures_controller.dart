import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/strings/app_strings.dart';
import '../../../services/fixtures/fixtures_service.dart';

/// Controller managing fixtures listing, caching, and filtering.
class FixturesController extends GetxController {
  FixturesController({required this.fixturesService});

  final FixturesService fixturesService;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errDefault.obs;

  final RxList<MatchSummary> allMatches = <MatchSummary>[].obs;
  final RxString activeFilter = 'all'.obs; // all | live | upcoming | completed

  @override
  void onInit() {
    super.onInit();
    loadFixtures();
  }

  Future<void> loadFixtures() async {
    isLoading.value = true;
    hasError.value = false;

    final result = await fixturesService.getFixtures();

    isLoading.value = false;

    if (result.isSuccess) {
      allMatches.assignAll(result.dataOrNull ?? []);
    } else {
      hasError.value = true;
      errorMessageKey.value = result.failureOrNull?.userMessageKey ?? AppStrings.errDefault;
    }
  }

  void setFilter(String filter) {
    activeFilter.value = filter;
  }

  List<MatchSummary> get filteredMatches {
    final filter = activeFilter.value;
    if (filter == 'live') {
      return allMatches.where((m) => m.isLive).toList();
    } else if (filter == 'upcoming') {
      return allMatches.where((m) => m.isUpcoming).toList();
    } else if (filter == 'completed') {
      return allMatches.where((m) => m.isCompleted).toList();
    }
    return allMatches;
  }

  void openMatchDetail(MatchSummary match) {
    Get.toNamed(
      AppRoutes.matchDetail,
      arguments: match.matchId,
    );
  }
}
