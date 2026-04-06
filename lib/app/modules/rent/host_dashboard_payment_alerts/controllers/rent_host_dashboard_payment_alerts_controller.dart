import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentHostDashboardPaymentAlertsController extends BaseController
    with RentRealDataControllerMixin {
  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }

  void openSetReminder() {
    final data = realData.value;
    final tenantName = data != null && data.tenants > 0 ? 'Tenant payment reminder' : '';
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        'name': tenantName,
        'property': '',
        'balance': '',
      },
    );
  }

  void openProfitAnalysisDashboard() {
    Get.toNamed(Routes.RENT_PROFIT_ANALYSIS_DASHBOARD);
  }

  void onNotifyFeaturedTenant() {
    showSuccessMessage('Notification queued');
  }

  void onViewAllDelinquencies() {
    showSuccessMessage('Opening real payment delinquencies');
  }

  void onSendLateNotice() {
    showSuccessMessage('Late notice sent');
  }

  void onMonitorNewTenant() {
    showSuccessMessage('Monitoring tenant payments');
  }
}
