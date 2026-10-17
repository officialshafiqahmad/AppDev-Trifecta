import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/sync/sync_service_mock.dart';

/// Controller managing sync queue inspection, offline simulator toggle, and batch sync.
class SyncStatusController extends GetxController {
  SyncStatusController({required this.syncService});

  final SyncService syncService;

  SyncServiceMock get _mock => syncService as SyncServiceMock;

  bool get isOnline => _mock.rxIsOnline.value;
  bool get isSyncing => _mock.rxIsSyncing.value;
  List<QueuedAction> get actions => _mock.rxActions;

  void toggleOnline() {
    _mock.toggleNetworkSimulation();
  }

  Future<void> triggerSync() async {
    final res = await syncService.syncNow();
    if (res.isSuccess) {
      final summary = res.dataOrNull!.summary;
      AppSnackbar.success('Sync complete: ${summary.applied} applied, ${summary.rejected} rejected');
    } else {
      final msg = res.failureOrNull?.userMessageKey ?? AppStrings.errNetwork;
      AppSnackbar.error(msg);
    }
  }

  Future<void> clearCompletedActions() async {
    await syncService.clearCompleted();
    AppSnackbar.info('Completed sync logs cleared');
  }
}
