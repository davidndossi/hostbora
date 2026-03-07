import 'package:get/get.dart';

import '../controllers/record_payment_controller.dart';

class RecordPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecordPaymentController>(RecordPaymentController.new);
  }
}
