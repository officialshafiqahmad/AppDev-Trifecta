import 'package:get/get.dart';
import '../../core/utils/result.dart';

/// Queued action representation according to API_MODELS.md §3.
class QueuedAction {
  const QueuedAction({
    required this.actionId,
    required this.type,
    required this.queuedAt,
    required this.baseVersion,
    required this.payload,
    this.status = 'pending',
    this.resolution,
    this.errorCode,
    this.userMessage,
  });

  final String actionId;
  final String type; // 'score_event' | 'roster_transfer'
  final DateTime queuedAt;
  final int baseVersion;
  final Map<String, dynamic> payload;
  final String status; // 'pending' | 'applied' | 'rejected' | 'duplicate'
  final String? resolution;
  final String? errorCode;
  final String? userMessage;

  bool get isPending => status == 'pending';

  QueuedAction copyWith({
    String? status,
    String? resolution,
    String? errorCode,
    String? userMessage,
  }) {
    return QueuedAction(
      actionId: actionId,
      type: type,
      queuedAt: queuedAt,
      baseVersion: baseVersion,
      payload: payload,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      errorCode: errorCode ?? this.errorCode,
      userMessage: userMessage ?? this.userMessage,
    );
  }

  /// Strict wire payload representation adhering to API_MODELS.md §3.
  /// Hard law: Must NOT contain UI state fields (status, resolution, errorCode, userMessage).
  Map<String, dynamic> toWireJson() => {
        'action_id': actionId,
        'type': type,
        'queued_at': queuedAt.toIso8601String(),
        'base_version': baseVersion,
        'payload': payload,
      };

  /// Local storage representation for disk persistence of UI state.
  Map<String, dynamic> toStorageJson() => {
        'action_id': actionId,
        'type': type,
        'queued_at': queuedAt.toIso8601String(),
        'base_version': baseVersion,
        'payload': payload,
        'status': status,
        'resolution': resolution,
        'error_code': errorCode,
        'user_message': userMessage,
      };

  Map<String, dynamic> toJson() => toWireJson();

  factory QueuedAction.fromJson(Map<String, dynamic> json) {
    return QueuedAction(
      actionId: (json['action_id'] ?? json['actionId']) as String,
      type: (json['type']) as String,
      queuedAt: DateTime.tryParse((json['queued_at'] ?? json['queuedAt']) as String? ?? '') ?? DateTime.now(),
      baseVersion: (json['base_version'] ?? json['baseVersion']) as int? ?? 1,
      payload: (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      status: (json['status']) as String? ?? 'pending',
      resolution: (json['resolution']) as String?,
      errorCode: (json['error_code'] ?? json['errorCode']) as String?,
      userMessage: (json['user_message'] ?? json['userMessage']) as String?,
    );
  }
}

/// Action sync result from server.
class ActionResult {
  const ActionResult({
    required this.actionId,
    required this.status,
    required this.resolution,
    this.errorCode,
    this.userMessage,
  });

  final String actionId;
  final String status; // applied | duplicate | rejected
  final String resolution; // appended | rebased_append | skipped_duplicate | server_wins
  final String? errorCode;
  final String? userMessage;

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      actionId: (json['action_id'] ?? json['actionId']) as String,
      status: (json['status']) as String,
      resolution: (json['resolution']) as String,
      errorCode: (json['error_code'] ?? json['errorCode']) as String?,
      userMessage: (json['user_message'] ?? json['userMessage']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'action_id': actionId,
        'status': status,
        'resolution': resolution,
        'error_code': errorCode,
        'user_message': userMessage,
      };
}

/// Summary counts of batch sync.
class SyncSummary {
  const SyncSummary({
    required this.applied,
    required this.rejected,
    required this.duplicate,
  });

  final int applied;
  final int rejected;
  final int duplicate;

  factory SyncSummary.fromJson(Map<String, dynamic> json) {
    return SyncSummary(
      applied: (json['applied']) as int? ?? 0,
      rejected: (json['rejected']) as int? ?? 0,
      duplicate: (json['duplicate']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'applied': applied,
        'rejected': rejected,
        'duplicate': duplicate,
      };
}

/// Overall batch sync response.
class SyncBatchResult {
  const SyncBatchResult({
    required this.deviceId,
    required this.results,
    required this.summary,
  });

  final String deviceId;
  final List<ActionResult> results;
  final SyncSummary summary;

  factory SyncBatchResult.fromJson(Map<String, dynamic> json) {
    return SyncBatchResult(
      deviceId: (json['device_id'] ?? json['deviceId']) as String,
      results: ((json['results']) as List<dynamic>? ?? [])
          .map((r) => ActionResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      summary: SyncSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'results': results.map((r) => r.toJson()).toList(),
        'summary': summary.toJson(),
      };
}

/// Sync and connectivity service contract with reactive getters.
abstract class SyncService {
  bool get isOnline;
  bool get isSyncing;
  int get pendingCount;

  RxBool get isOnlineRx;
  RxBool get isSyncingRx;
  RxInt get pendingCountRx;

  void toggleNetworkSimulation();
  void setOnline(bool online);

  Future<Result<void>> queueAction({
    required String type,
    required int baseVersion,
    required Map<String, dynamic> payload,
  });

  Future<Result<List<QueuedAction>>> getQueue();

  Future<Result<SyncBatchResult>> syncNow();

  Future<Result<void>> clearCompleted();
}
