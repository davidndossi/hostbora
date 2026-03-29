import 'package:get/get.dart';

import '../controllers/rent_contract_hub_controller.dart';

class RentContractHubBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentContractHubController>(
        () => RentContractHubController(),
      );
}
