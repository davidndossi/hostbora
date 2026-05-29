import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/help/guided_tour_service.dart';
import '../../../data/help/help_center_catalog.dart';
import '../../../data/help/help_center_models.dart';
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

  void goToStep(HelpGuideStep step) {
    if (step.route == null || step.route!.isEmpty) return;
    if (step.routeArguments != null) {
      Get.toNamed(
        step.route!,
        parameters: step.routeParameters ?? {},
        arguments: step.routeArguments,
      );
    } else {
      Get.toNamed(
        step.route!,
        parameters: step.routeParameters ?? {},
      );
    }
  }

  void openRelatedFeature() {
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
      if (feature.routeArguments != null) {
        Get.toNamed(
          feature.route,
          parameters: feature.routeParameters ?? {},
          arguments: feature.routeArguments,
        );
      } else {
        Get.toNamed(feature.route, parameters: feature.routeParameters ?? {});
      }
    }
  }
}
