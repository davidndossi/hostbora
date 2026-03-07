import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class PasswordUpdatedController extends BaseController {
  void backToLogin() => Get.offAllNamed(Routes.AUTH);

  void contactSupport() => Get.toNamed(Routes.SUPPORT);
}
