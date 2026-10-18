import 'package:get/get.dart';

import '../../../services/deeplink/deeplink_service.dart';
import '../../../services/streaming/streaming_service.dart';

/// Controller for Co-Stream 4-way multi-broadcaster screen (Phase II additive feature).
class CoStreamController extends GetxController {
  CoStreamController({this.streamingService});

  final StreamingService? streamingService;

  final RxString sessionId = 'cs-session-101'.obs;
  final RxString activeHost = 'player-alpha-1'.obs;
  final RxString layout = 'grid_4'.obs;
  final RxList<String> participants = <String>[
    'player-alpha-1',
    'player-alpha-2',
    'player-beta-1',
    'player-beta-2',
  ].obs;
  final RxList<Map<String, String>> chatMessages = <Map<String, String>>[
    {'sender': 'player-alpha-1', 'text': 'Welcome to the co-stream match preview!'},
    {'sender': 'player-beta-1', 'text': 'Ready for the big game today!'},
  ].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) {
      sessionId.value = args;
    } else if (args is Map && args['session_id'] != null) {
      sessionId.value = args['session_id'] as String;
    } else if (Get.isRegistered<DeepLinkService>()) {
      final initialId = Get.find<DeepLinkService>().lastSessionId;
      if (initialId != null && initialId.isNotEmpty) {
        sessionId.value = initialId;
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    _loadSession();
  }

  Future<void> _loadSession() async {
    if (streamingService != null) {
      final res = await streamingService!.getCoStreamSession(sessionId: sessionId.value);
      if (res.isSuccess && res.dataOrNull != null) {
        final data = res.dataOrNull!;
        if (data['active_host'] != null) {
          activeHost.value = data['active_host'] as String;
        }
        if (data['layout'] != null) {
          layout.value = data['layout'] as String;
        }
        if (data['active_participants'] is List) {
          participants.assignAll(
            (data['active_participants'] as List).map((e) => e.toString()).toList(),
          );
        }
      }
    }
  }

  void addChatMessage(String sender, String text) {
    chatMessages.add({'sender': sender, 'text': text});
  }
}
