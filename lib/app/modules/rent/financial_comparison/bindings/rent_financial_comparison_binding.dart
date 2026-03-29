import 'package:get/get.dart';

import '../controllers/rent_financial_comparison_controller.dart';

class RentFinancialComparisonBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentFinancialComparisonController>(
        () => RentFinancialComparisonController(),
      );
}
