import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class FailedController extends BaseController {
  final msg = ''.obs;
  final responseCode = ''.obs;
  final firstName = ''.obs;

  @override
  void onInit() {
    if (Get.arguments != null) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['message'] != null) msg.value = args['message'] as String;
        if (args['responseCode'] != null) {
          responseCode.value = args['responseCode'].toString();
        }
        if (args['firstName'] != null) firstName.value = args['firstName'] as String;
      }
    }
    super.onInit();
  }

  void goBack() => Get.back();
  void goToHome() => Get.offAllNamed(Routes.HOME);
}
