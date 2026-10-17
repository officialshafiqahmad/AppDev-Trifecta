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

  factory QueuedAction.fromJson(Map<String, dynamic> json) {
    return QueuedAction(
      actionId: json['action_id'] as String,
      type: json['type'] as String,
      queuedAt: DateTime.tryParse(json['queued_at'] as String? ?? '') ?? DateTime.now(),
      baseVersion: json['base_version'] as int? ?? 1,
      payload: (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      status: json['status'] as String? ?? 'pending',
      resolution: json['resolution'] as String?,
      errorCode: json['error_code'] as String?,
      userMessage: json['user_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
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
}

/// Sync and connectivity service contract.
abstract class SyncService {
  bool get isOnline;
  bool get isSyncing;
  int get pendingCount;

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
