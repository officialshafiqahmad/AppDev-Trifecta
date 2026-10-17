import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/api/api_service.dart';
import '../model/home_args.dart';
import '../model/home_feed_item.dart';
import '../widgets/home_sheet_content.dart';

/// Controller for the Home feature.
/// Registered ONLY in [HomeBinding].
class HomeController extends GetxController {
  HomeController({
    required this.apiService,
    this.args,
  });

  final ApiService apiService;
  final HomeArgs? args;

  // Reactive state
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageKey = AppStrings.errorDefault.obs;

  final RxList<HomeStat> stats = <HomeStat>[].obs;
  final RxList<HomeFeedItem> feedItems = <HomeFeedItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Fetches operational stats and recent feed items.
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    hasError.value = false;

    // Simulate service call through ApiService interface
    final result = await apiService.get('/operations/overview');

    if (result.isSuccess) {
      stats.assignAll([
        const HomeStat(
          titleKey: AppStrings.homeStatActiveLeagues,
          count: 4,
          iconCodePoint: 0xe24e, // emoji_events_outlined
        ),
        const HomeStat(
          titleKey: AppStrings.homeStatUpcomingMatches,
          count: 18,
          iconCodePoint: 0xe5ce, // sports_soccer_outlined
        ),
        const HomeStat(
          titleKey: AppStrings.homeStatTotalClubs,
          count: 32,
          iconCodePoint: 0xe318, // groups_outlined
        ),
      ]);

      feedItems.assignAll([
        HomeFeedItem(
          id: '1',
          title: 'Championship Round 3 Fixtures Published',
          subtitle: 'Matches scheduled across venues A-01 and A-02',
          timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
          category: 'Football',
        ),
        HomeFeedItem(
          id: '2',
          title: 'Roster Submission Deadline',
          subtitle: 'All clubs must lock rosters by 15:00 PKT today',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          category: 'Operations',
        ),
        HomeFeedItem(
          id: '3',
          title: 'Court Maintenance Notice',
          subtitle: 'Venue A-101 indoor surfaces approved for play',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          category: 'Futsal',
        ),
      ]);

      isLoading.value = false;
    } else {
      final failure = result.failureOrNull;
      errorMessageKey.value = failure?.userMessageKey ?? AppStrings.errorDefault;
      hasError.value = true;
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh / reload handler.
  Future<void> onRefresh() async {
    await loadDashboardData();
    AppSnackbar.success(AppStrings.successSaved);
  }

  /// Trigger dialog from sanctioned widget kit
  Future<void> onShowDialogDemo() async {
    final confirmed = await AppDialog.confirm(
      titleKey: AppStrings.homeDialogTitle,
      bodyKey: AppStrings.homeDialogBody,
      confirmLabelKey: AppStrings.commonConfirm,
      cancelLabelKey: AppStrings.commonCancel,
    );

    if (confirmed) {
      AppSnackbar.info(AppStrings.commonSubmit);
    }
  }

  /// Trigger sheet from sanctioned widget kit
  Future<void> onShowSheetDemo() async {
    await AppSheet.show(child: const HomeSheetContent());
  }
}
