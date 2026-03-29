import 'package:get/get.dart';

import '../controllers/rent_active_loyalty_programs_controller.dart';

class RentActiveLoyaltyProgramsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentActiveLoyaltyProgramsController>(
        () => RentActiveLoyaltyProgramsController(),
      );
}
