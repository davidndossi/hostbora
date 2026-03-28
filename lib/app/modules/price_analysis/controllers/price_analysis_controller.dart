import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

class PriceAnalysisController extends BaseController {
  final suggestedPrice = 240.obs;
  final competitorAverage = 215.obs;

  void applyToCalendar() {
    showSuccessMessage('Applied recommended rate to calendar');
  }
}
