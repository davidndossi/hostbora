import 'package:get/get.dart';

import '../controllers/rent_tenant_ledger_occupancy_controller.dart';

class RentTenantLedgerOccupancyBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<RentTenantLedgerOccupancyController>(
        () => RentTenantLedgerOccupancyController(),
      );
}
