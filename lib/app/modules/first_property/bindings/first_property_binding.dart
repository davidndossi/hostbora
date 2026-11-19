import 'package:get/get.dart';

import '../controllers/first_property_controller.dart';

class FirstPropertyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirstPropertyController>(
      () => FirstPropertyController(),
      fenix: true,
    );
  }
}
