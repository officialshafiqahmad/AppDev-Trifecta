import 'package:get/get.dart';

import '../controller/co_stream_controller.dart';

class CoStreamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoStreamController>(() => CoStreamController());
  }
}
