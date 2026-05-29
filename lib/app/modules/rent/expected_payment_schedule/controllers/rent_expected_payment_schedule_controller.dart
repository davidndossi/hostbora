import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/rent_expected_payment_schedule.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';

class RentExpectedPaymentScheduleController extends BaseController {
  RentExpectedPaymentScheduleController()
      : _tenantLocal = Get.find<TenantLocalDataSource>();

  final TenantLocalDataSource _tenantLocal;

  final loading = false.obs;
  final schedule = Rxn<ExpectedPaymentScheduleSnapshot>();
  final expandedPropertyKeys = <String>{}.obs;

  int get displayYear => DateTime.now().year;

  @override
  void onReady() {
    super.onReady();
    loadSchedule();
  }

  static Future<void> refreshIfRegistered() async {
    if (!Get.isRegistered<RentExpectedPaymentScheduleController>()) return;
    await Get.find<RentExpectedPaymentScheduleController>().loadSchedule();
  }

  Future<void> loadSchedule() async {
    loading.value = true;
    try {
      final tenants = await _tenantLocal.getAllNewestFirstByWorkspace('rent');
      schedule.value = RentExpectedPaymentScheduleBuilder.build(
        year: displayYear,
        tenants: tenants,
      );
    } finally {
      loading.value = false;
    }
  }

  void togglePropertyExpanded(String propertyKey) {
    if (expandedPropertyKeys.contains(propertyKey)) {
      expandedPropertyKeys.remove(propertyKey);
    } else {
      expandedPropertyKeys.add(propertyKey);
    }
  }

  bool isPropertyExpanded(String propertyKey) =>
      expandedPropertyKeys.contains(propertyKey);
}
