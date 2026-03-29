import 'package:get/get.dart';

import '../controllers/rent_loyalty_thresholds_controller.dart';

class RentLoyaltyThresholdsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentLoyaltyThresholdsController>(
        () => RentLoyaltyThresholdsController(),
      );
}
