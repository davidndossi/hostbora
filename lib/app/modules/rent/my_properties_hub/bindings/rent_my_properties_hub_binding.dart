import 'package:get/get.dart';

import '../controllers/rent_my_properties_hub_controller.dart';

class RentMyPropertiesHubBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentMyPropertiesHubController>(
        RentMyPropertiesHubController.new,
      );
}
