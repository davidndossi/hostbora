import 'package:get/get.dart';

import '../controllers/rent_monthly_pl_summary_controller.dart';

class RentMonthlyPlSummaryBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentMonthlyPlSummaryController>(
        () => RentMonthlyPlSummaryController(),
      );
}
