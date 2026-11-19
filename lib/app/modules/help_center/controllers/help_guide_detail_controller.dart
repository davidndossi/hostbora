import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/help/guided_tour_service.dart';
import '../../../data/help/help_center_catalog.dart';
import '../../../data/help/help_center_models.dart';
import '../../../data/help/help_navigation_helper.dart';

class HelpGuideDetailController extends BaseController {
  final guide = Rxn<HelpGuide>();
  final completedStepIndices = <int>{}.obs;

  bool get isSw => Get.locale?.languageCode == 'sw';

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['guideId'] ?? '';
    guide.value = HelpCenterCatalog.guideById(id);
  }

  void toggleStepDone(int index) {
    if (completedStepIndices.contains(index)) {
      completedStepIndices.remove(index);
    } else {
      completedStepIndices.add(index);
    }
  }

  bool isStepDone(int index) => completedStepIndices.contains(index);

  Future<void> startGuidedTour() async {
    final g = guide.value;
    if (g == null) return;
    await Get.find<GuidedTourService>().startGuide(g);
  }

  Future<void> goToStep(HelpGuideStep step) async {
    await HelpNavigationHelper.openStep(step);
  }

  Future<void> openRelatedFeature() async {
    final g = guide.value;
    if (g == null) return;
    HelpFeature? feature;
    for (final f in HelpCenterCatalog.features) {
      if (f.relatedGuideId == g.id) {
        feature = f;
        break;
      }
    }
    if (feature != null) {
      await HelpNavigationHelper.openFeature(feature);
    }
  }
}
