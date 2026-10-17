import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../services/api/api_service.dart';
import '../../services/api/api_service_impl.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_service_impl.dart';
import '../../services/storage/storage_service.dart';
import '../../services/storage/storage_service_impl.dart';

/// Registers global services (interfaces -> implementations), permanent.
/// This is the ONLY place global permanent service registrations live.
class InitialBinding extends Bindings {
  InitialBinding(this.config);

  final AppConfig config;

  @override
  void dependencies() {
    Get.put<AppConfig>(config, permanent: true);

    final storageService = StorageServiceImpl();
    Get.put<StorageService>(storageService, permanent: true);

    final apiService = ApiServiceImpl(config: config);
    Get.put<ApiService>(apiService, permanent: true);

    final authService = AuthServiceImpl(storageService: storageService);
    Get.put<AuthService>(authService, permanent: true);
  }
}
