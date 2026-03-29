import 'package:get/get.dart';

import '../controllers/rent_property_roi_analysis_controller.dart';

class RentPropertyRoiAnalysisBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentPropertyRoiAnalysisController>(
        () => RentPropertyRoiAnalysisController(),
      );
}
