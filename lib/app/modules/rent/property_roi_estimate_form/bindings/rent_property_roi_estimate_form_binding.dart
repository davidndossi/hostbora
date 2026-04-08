import 'package:get/get.dart';

import '../controllers/rent_property_roi_estimate_form_controller.dart';

class RentPropertyRoiEstimateFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentPropertyRoiEstimateFormController>(
      () => RentPropertyRoiEstimateFormController(),
    );
  }
}
