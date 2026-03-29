import 'package:get/get.dart';

import '../controllers/rent_profit_analysis_dashboard_controller.dart';

class RentProfitAnalysisDashboardBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentProfitAnalysisDashboardController>(
        () => RentProfitAnalysisDashboardController(),
      );
}
