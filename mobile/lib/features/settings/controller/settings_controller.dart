import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/cache/cache_service.dart';
import '../../../services/settings/settings_service.dart';

/// Controller managing server host configuration and local cache clearance.
class SettingsController extends GetxController {
  SettingsController({
    required this.settingsService,
    required this.cacheService,
  });

  final SettingsService settingsService;
  final CacheService cacheService;

  final TextEditingController hostController = TextEditingController();
  final RxString deviceId = ''.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    hostController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    final res = await settingsService.getSettings();
    isLoading.value = false;

    if (res.isSuccess && res.dataOrNull != null) {
      final s = res.dataOrNull!;
      hostController.text = s.host;
      deviceId.value = s.deviceId;
    }
  }

  Future<void> saveServerHost() async {
    final host = hostController.text.trim();
    if (host.isEmpty) {
      AppSnackbar.error(AppStrings.errValidation);
      return;
    }

    await settingsService.updateServerHost(host);
    AppSnackbar.success(AppStrings.successSaved);
  }

  Future<void> clearCache() async {
    await cacheService.clear();
    AppSnackbar.info(AppStrings.settingsCacheCleared);
  }
}
