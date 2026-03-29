import 'package:get/get.dart';

import '../controllers/rent_hub_controller.dart';

class RentHubBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentHubController>(() => RentHubController());
}
