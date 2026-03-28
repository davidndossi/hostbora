import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

class AiPricingOptimizerController extends BaseController {
  final autoApplyEnabled = true.obs;

  void setAutoApply(bool value) => autoApplyEnabled.value = value;
}
