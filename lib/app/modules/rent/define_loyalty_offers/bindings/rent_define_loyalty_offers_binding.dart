import 'package:get/get.dart';

import '../controllers/rent_define_loyalty_offers_controller.dart';

class RentDefineLoyaltyOffersBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentDefineLoyaltyOffersController>(
        () => RentDefineLoyaltyOffersController(),
      );
}
