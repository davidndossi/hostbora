import 'package:get/get.dart';

import '../controllers/admin_whatsapp_credentials_controller.dart';

class AdminWhatsappCredentialsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminWhatsappCredentialsController>(
      () => AdminWhatsappCredentialsController(),
    );
  }
}
