import 'package:get/get.dart';

import '../controllers/manage_payments_controller.dart';

class ManagePaymentsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagePaymentsController>(
      () => ManagePaymentsController(),
      fenix: true,
    );
  }
}
