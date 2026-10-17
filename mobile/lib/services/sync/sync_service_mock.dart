import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import '../settings/settings_service.dart';
import 'sync_service.dart';

/// Mock SyncService with dedicated disk-persisted offline action queue and real network detection.
/// Partitioned separately from CacheService so CacheService.clear() never wipes queued actions.
class SyncServiceMock implements SyncService {
  SyncServiceMock({
    required this.cacheService,
    required this.settingsService,
  }) {
    _initService();
  }

  final CacheService cacheService;
  final SettingsService settingsService;

  final RxBool _isOnline = true.obs;
  final RxBool _isSyncing = false.obs;
  final RxInt _pendingCount = 0.obs;
  final RxList<QueuedAction> _actions = <QueuedAction>[].obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  File? _queueFile;
  bool _manualOfflineSimulation = false;

  @override
  bool get isOnline => _isOnline.value;

  @override
  bool get isSyncing => _isSyncing.value;

  @override
  int get pendingCount => _pendingCount.value;

  @override
  RxBool get isOnlineRx => _isOnline;

  @override
  RxBool get isSyncingRx => _isSyncing;

  @override
  RxInt get pendingCountRx => _pendingCount;

  RxList<QueuedAction> get rxActions => _actions;

  Future<void> _initService() async {
    await _loadQueueFromDisk();
    _initConnectivity();
  }

  Future<File> _getQueueFile() async {
    if (_queueFile != null) return _queueFile!;
    final appDir = await getApplicationDocumentsDirectory();
    _queueFile = File('${appDir.path}/trifecta_offline_queue.json');
    return _queueFile!;
  }

  Future<void> _loadQueueFromDisk() async {
    try {
      final file = await _getQueueFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic> && decoded.containsKey('actions')) {
            final list = (decoded['actions'] as List<dynamic>)
                .map((item) => QueuedAction.fromJson(item as Map<String, dynamic>))
                .toList();
            _actions.assignAll(list);
            _updatePendingCount();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveQueueToDisk() async {
    try {
      final file = await _getQueueFile();
      await file.writeAsString(
        jsonEncode({
          'actions': _actions.map((a) => a.toStorageJson()).toList(),
        }),
        flush: true,
      );
      _updatePendingCount();
    } catch (_) {}
  }

  void _updatePendingCount() {
    _pendingCount.value = _actions.where((a) => a.isPending).length;
  }

  Future<void> _initConnectivity() async {
    try {
      // Probe connectivity first; if platform channel is missing, this throws into catch
      final initial = await Connectivity().checkConnectivity();
      _handleConnectivityChange(initial);

      // Only attach stream listener if native plugin is present
      _connectivitySub = Connectivity().onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // Native plugin not compiled into currently running binary (hot restart fallback)
      _isOnline.value = true;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (_manualOfflineSimulation) return;

    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    final wasOffline = !_isOnline.value;
    _isOnline.value = hasConnection;

    if (wasOffline && hasConnection && pendingCount > 0) {
      // Auto-sync when reconnecting
      syncNow();
    }
  }

  @override
  void toggleNetworkSimulation() {
    _manualOfflineSimulation = !_manualOfflineSimulation;
    if (_manualOfflineSimulation) {
      _isOnline.value = false;
    } else {
      _isOnline.value = true;
      try {
        Connectivity()
            .checkConnectivity()
            .then(_handleConnectivityChange)
            .catchError((_) {});
      } catch (_) {}
    }
  }

  @override
  void setOnline(bool online) {
    _manualOfflineSimulation = !online;
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
    await Future<void>.delayed(const Duration(milliseconds: 600));

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

      if (item.baseVersion == 99) {
        // Simulated conflict
        rejected++;
        const errCode = 'INVALID_BASE_VERSION';
        const userMsg = AppStrings.errInvalidBaseVersion;
        results.add(
          ActionResult(
            actionId: item.actionId,
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
        // Rebased append
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
        // Clean append
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

  void dispose() {
    _connectivitySub?.cancel();
  }
}
