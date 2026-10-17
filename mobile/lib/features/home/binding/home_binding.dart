import 'package:get/get.dart';

import '../../../services/api/api_service.dart';
import '../controller/home_controller.dart';
import '../model/home_args.dart';

/// GetX binding for the Home feature.
/// This is the ONLY place HomeController is instantiated and registered.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        apiService: Get.find<ApiService>(),
        args: Get.arguments is HomeArgs ? Get.arguments as HomeArgs : null,
      ),
    );
  }
}
