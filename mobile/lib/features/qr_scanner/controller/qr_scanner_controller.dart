import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../services/deeplink/deeplink_service.dart';
import '../../../services/streaming/streaming_service.dart';

/// Controller for QR code scanner and entity resolution (Phase II additive feature).
class QrScannerController extends GetxController {
  QrScannerController({this.streamingService, this.deepLinkService});

  final StreamingService? streamingService;
  final DeepLinkService? deepLinkService;

  final TextEditingController inputController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }

  Future<void> resolveCode([String? directCode]) async {
    final rawCode = (directCode ?? inputController.text).trim();
    if (rawCode.isEmpty) {
      errorMessage.value = 'Please enter or scan a valid code.';
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    try {
      // 1. Direct deep-link format
      if (rawCode.startsWith('nascon://')) {
        if (deepLinkService != null) {
          deepLinkService!.handleUri(rawCode);
        } else if (Get.isRegistered<DeepLinkService>()) {
          Get.find<DeepLinkService>().handleUri(rawCode);
        } else {
          _fallbackDeepLinkRoute(rawCode);
        }
        isLoading.value = false;
        return;
      }

      // 2. Resolve via StreamingService / Backend /audit/v1/qr
      final entitySlug = _extractSlug(rawCode);
      if (streamingService != null) {
        final res = await streamingService!.resolveQr(entitySlug, inspect: true);
        if (res.isSuccess && res.dataOrNull != null) {
          final targetRoute = res.dataOrNull!['target_route'] as String? ?? '';
          _navigateByTargetRoute(targetRoute, entitySlug);
          isLoading.value = false;
          return;
        }
      }

      // 3. Fallback resolution heuristic
      _navigateByTargetRoute('', entitySlug);
    } catch (e) {
      errorMessage.value = 'Failed to resolve QR code: $e';
    } finally {
      isLoading.value = false;
    }
  }

  String _extractSlug(String input) {
    if (input.contains('/q/')) {
      return input.split('/q/').last.split('?').first.split('/').first;
    }
    if (input.contains('/matches/')) {
      return input.split('/matches/').last.split('?').first.split('/').first;
    }
    return input;
  }

  void _fallbackDeepLinkRoute(String uri) {
    if (uri.startsWith('nascon://entity/')) {
      final id = uri.substring('nascon://entity/'.length).split('/')[0];
      Get.toNamed(AppRoutes.matchLive, arguments: id);
    } else if (uri.startsWith('nascon://stream/')) {
      final id = uri.substring('nascon://stream/'.length).split('/')[0];
      Get.toNamed(AppRoutes.coStream, arguments: id);
    }
  }

  void _navigateByTargetRoute(String targetRoute, String entitySlug) {
    if (targetRoute.contains('costream') || entitySlug.startsWith('cs-')) {
      Get.toNamed(AppRoutes.coStream, arguments: entitySlug);
    } else {
      Get.toNamed(AppRoutes.matchLive, arguments: entitySlug);
    }
  }
}
