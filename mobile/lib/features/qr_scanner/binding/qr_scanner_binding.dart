import 'package:get/get.dart';

import '../../../services/deeplink/deeplink_service.dart';
import '../../../services/streaming/streaming_service.dart';
import '../controller/qr_scanner_controller.dart';

class QrScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QrScannerController>(
      () => QrScannerController(
        streamingService: Get.isRegistered<StreamingService>() ? Get.find<StreamingService>() : null,
        deepLinkService: Get.isRegistered<DeepLinkService>() ? Get.find<DeepLinkService>() : null,
      ),
    );
  }
}
