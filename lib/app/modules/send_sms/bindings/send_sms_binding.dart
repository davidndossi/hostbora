import 'package:get/get.dart';

import '../controllers/send_sms_controller.dart';

class SendSmsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SendSmsController>(
      () => SendSmsController()
    );
  }
}
