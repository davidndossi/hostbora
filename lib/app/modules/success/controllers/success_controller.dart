import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

class SuccessController extends BaseController {

  final msg = ''.obs;

  @override
  void onInit() {
    if (Get.arguments != null) {
      if (Get.arguments['message'] != null) {
        String value = Get.arguments['message'];
        msg(value);
      }
    }
    super.onInit();
  }
}
