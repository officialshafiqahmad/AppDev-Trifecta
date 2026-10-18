import 'package:get/get.dart';

import '../../../services/streaming/streaming_service.dart';
import '../controller/co_stream_controller.dart';

class CoStreamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoStreamController>(
      () => CoStreamController(
        streamingService: Get.isRegistered<StreamingService>() ? Get.find<StreamingService>() : null,
      ),
    );
  }
}
