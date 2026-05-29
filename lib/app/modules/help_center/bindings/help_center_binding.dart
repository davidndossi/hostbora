import 'package:get/get.dart';

import '../../../data/help/guided_tour_service.dart';
import '../controllers/help_center_controller.dart';
import '../controllers/help_guide_detail_controller.dart';

class HelpCenterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GuidedTourService>()) {
      Get.put<GuidedTourService>(GuidedTourService(), permanent: true);
    }
    Get.lazyPut<HelpCenterController>(() => HelpCenterController());
  }
}

class HelpGuideDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GuidedTourService>()) {
      Get.put<GuidedTourService>(GuidedTourService(), permanent: true);
    }
    Get.lazyPut<HelpGuideDetailController>(() => HelpGuideDetailController());
  }
}
