import 'package:get/get.dart';

import '../controllers/rent_whatsapp_template_builder_controller.dart';

class RentWhatsappTemplateBuilderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentWhatsappTemplateBuilderController>(
      () => RentWhatsappTemplateBuilderController(),
    );
  }
}
