import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';

/// Host payment alerts hub — demo actions; replace with API / real navigation.
class RentHostDashboardPaymentAlertsController extends BaseController {
  void openSetReminder() {
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        'name': 'Amara Okafor',
        'property': 'Premier Suite 402, Evergreen Estate',
        'balance': '400000',
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
    showSuccessMessage('Opening delinquencies');
  }

  void onSendLateNotice() {
    showSuccessMessage('Late notice sent');
  }

  void onMonitorNewTenant() {
    showSuccessMessage('Monitor new tenant');
  }
}
