import 'package:get/get.dart';

import '../controllers/create_host_account_controller.dart';

class CreateHostAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateHostAccountController>(
      () => CreateHostAccountController(),
      fenix: true,
    );
  }
}
