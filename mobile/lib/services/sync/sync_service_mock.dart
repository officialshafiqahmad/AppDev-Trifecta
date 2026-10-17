import 'package:get/get.dart';

import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import '../settings/settings_service.dart';
import 'sync_service.dart';

/// Mock SyncService with disk-persisted offline action queue.
class SyncServiceMock implements SyncService {
  SyncServiceMock({
    required this.cacheService,
    required this.settingsService,
  }) {
    _loadQueueFromDisk();
  }

  final CacheService cacheService;
  final SettingsService settingsService;

  static const String _cacheKeyQueue = 'offline_sync_queue';

  final RxBool _isOnline = true.obs;
  final RxBool _isSyncing = false.obs;
  final RxList<QueuedAction> _actions = <QueuedAction>[].obs;

  @override
  bool get isOnline => _isOnline.value;

  @override
  bool get isSyncing => _isSyncing.value;

  @override
  int get pendingCount => _actions.where((a) => a.isPending).length;

  RxBool get rxIsOnline => _isOnline;
  RxBool get rxIsSyncing => _isSyncing;
  RxList<QueuedAction> get rxActions => _actions;

  Future<void> _loadQueueFromDisk() async {
    try {
      final cachedRes = await cacheService.get(_cacheKeyQueue);
      final cached = cachedRes.dataOrNull;
      if (cached != null && cached.containsKey('actions')) {
        final list = (cached['actions'] as List<dynamic>)
            .map((item) => QueuedAction.fromJson(item as Map<String, dynamic>))
            .toList();
        _actions.assignAll(list);
      }
    } catch (_) {}
  }

  Future<void> _saveQueueToDisk() async {
    try {
      await cacheService.put(_cacheKeyQueue, {
        'actions': _actions.map((a) => a.toJson()).toList(),
      });
    } catch (_) {}
  }

  @override
  void toggleNetworkSimulation() {
    _isOnline.value = !_isOnline.value;
    if (_isOnline.value && pendingCount > 0) {
      // Auto-sync when reconnecting as requested in FRONTEND_BRIEF §Sync
      syncNow();
    }
  }

  @override
  void setOnline(bool online) {
    _isOnline.value = online;
    if (online && pendingCount > 0) {
      syncNow();
    }
  }

  @override
  Future<Result<void>> queueAction({
    required String type,
    required int baseVersion,
    required Map<String, dynamic> payload,
  }) async {
    final actionId = 'act-${DateTime.now().millisecondsSinceEpoch}';
    final action = QueuedAction(
      actionId: actionId,
      type: type,
      queuedAt: DateTime.now(),
      baseVersion: baseVersion,
      payload: payload,
      status: 'pending',
    );

    _actions.add(action);
    await _saveQueueToDisk();
    return const Success(null);
  }

  @override
  Future<Result<List<QueuedAction>>> getQueue() async {
    return Success(List.unmodifiable(_actions));
  }

  @override
  Future<Result<SyncBatchResult>> syncNow() async {
    if (!_isOnline.value) {
      return const Failure(
        AppFailure(
          code: 'OFFLINE',
          userMessageKey: AppStrings.errNetwork,
        ),
      );
    }

    _isSyncing.value = true;
    // Simulate realistic network sync delay
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final deviceIdRes = await settingsService.getDeviceId();
    final deviceId = deviceIdRes.dataOrNull ?? 'dev-1';

    final results = <ActionResult>[];
    int applied = 0;
    int rejected = 0;
    int duplicate = 0;

    final updated = <QueuedAction>[];

    for (int i = 0; i < _actions.length; i++) {
      final item = _actions[i];
      if (!item.isPending) {
        updated.add(item);
        continue;
      }

      // Determine simulated resolution
      if (item.baseVersion == 99) {
        // Simulated conflict / rejection
        rejected++;
        const errCode = 'INVALID_BASE_VERSION';
        const userMsg = AppStrings.errInvalidBaseVersion;
        results.add(
          const ActionResult(
            actionId: 'temp',
            status: 'rejected',
            resolution: 'server_wins',
            errorCode: errCode,
            userMessage: userMsg,
          ),
        );
        updated.add(
          item.copyWith(
            status: 'rejected',
            resolution: 'server_wins',
            errorCode: errCode,
            userMessage: userMsg,
          ),
        );
      } else if (item.baseVersion > 1 && i % 2 == 1) {
        // Simulated rebased append
        applied++;
        const resolution = 'rebased_append';
        const userMsg = AppStrings.syncRebased;
        results.add(
          ActionResult(
            actionId: item.actionId,
            status: 'applied',
            resolution: resolution,
            userMessage: userMsg,
          ),
        );
        updated.add(
          item.copyWith(
            status: 'applied',
            resolution: resolution,
            userMessage: userMsg,
          ),
        );
      } else {
        // Standard clean append
        applied++;
        const resolution = 'appended';
        const userMsg = AppStrings.syncApplied;
        results.add(
          ActionResult(
            actionId: item.actionId,
            status: 'applied',
            resolution: resolution,
            userMessage: userMsg,
          ),
        );
        updated.add(
          item.copyWith(
            status: 'applied',
            resolution: resolution,
            userMessage: userMsg,
          ),
        );
      }
    }

    _actions.assignAll(updated);
    await _saveQueueToDisk();
    _isSyncing.value = false;

    return Success(
      SyncBatchResult(
        deviceId: deviceId,
        results: results,
        summary: SyncSummary(
          applied: applied,
          rejected: rejected,
          duplicate: duplicate,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> clearCompleted() async {
    _actions.removeWhere((a) => !a.isPending);
    await _saveQueueToDisk();
    return const Success(null);
  }
}
