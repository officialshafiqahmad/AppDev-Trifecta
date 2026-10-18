import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';

abstract class DeepLinkService {
  String? get lastMatchId;
  String? get lastSessionId;
  void handleUri(String uri, {bool isColdStart = false});
}

class DeepLinkServiceImpl extends GetxService implements DeepLinkService {
  DeepLinkServiceImpl({String? initialUri}) : _initialUri = initialUri {
    if (initialUri != null && initialUri.isNotEmpty) {
      _parseAndStore(initialUri);
    }
  }

  static const MethodChannel _channel = MethodChannel('com.trifecta.app/deeplink');

  final String? _initialUri;
  String? _lastMatchId;
  String? _lastSessionId;

  @override
  String? get lastMatchId => _lastMatchId;

  @override
  String? get lastSessionId => _lastSessionId;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final uri = call.arguments as String?;
        if (uri != null) {
          handleUri(uri);
        }
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    if (_initialUri != null && _initialUri.startsWith('nascon://')) {
      handleUri(_initialUri, isColdStart: true);
    }
  }

  void _parseAndStore(String uri) {
    if (uri.startsWith('nascon://entity/')) {
      final rest = uri.substring('nascon://entity/'.length);
      _lastMatchId = rest.split('/')[0].split('?')[0];
    } else if (uri.startsWith('nascon://stream/')) {
      final rest = uri.substring('nascon://stream/'.length);
      _lastSessionId = rest.split('/')[0].split('?')[0];
    }
  }

  @override
  void handleUri(String uri, {bool isColdStart = false}) {
    _parseAndStore(uri);

    if (uri.startsWith('nascon://entity/')) {
      final matchId = _lastMatchId ?? 'match-m1';
      if (Get.currentRoute == AppRoutes.matchLive) {
        return;
      }
      if (isColdStart) {
        Get.offAllNamed(AppRoutes.matchLive, arguments: matchId);
      } else {
        Get.toNamed(AppRoutes.matchLive, arguments: matchId);
      }
    } else if (uri.startsWith('nascon://stream/')) {
      final sessionId = _lastSessionId ?? 'cs-session-101';
      if (Get.currentRoute == AppRoutes.coStream) {
        return;
      }
      if (isColdStart) {
        Get.offAllNamed(AppRoutes.coStream, arguments: sessionId);
      } else {
        Get.toNamed(AppRoutes.coStream, arguments: sessionId);
      }
    }
  }
}
