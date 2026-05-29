import 'dart:async';

import 'package:get/get.dart';

import '../../../modules/all_bookings/controllers/all_bookings_controller.dart';
import '../../../modules/booking_details/controllers/booking_details_controller.dart';
import '../../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../modules/host_calendar/controllers/host_calendar_controller.dart';
import '../../../modules/rent/manage_expenses/controllers/manage_expenses_controller.dart';
import '../../../modules/rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import 'offline_sync_worker_service.dart';

/// Refreshes visible BnB/rent lists after the offline sync worker drains the queue.
void registerOfflineSyncUiRefresh(OfflineSyncWorkerService syncWorker) {
  syncWorker.addOnDrainListener(_refreshAfterSync);
}

Future<void> _refreshAfterSync() async {
  await HomeController.refreshIfRegistered();
  await AllBookingsController.refreshIfRegistered();
  await DashboardController.refreshIfRegistered(quiet: true);
  await HostCalendarController.refreshIfRegistered();
  await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
  await BookingDetailsController.refreshIfRegistered();
  if (Get.isRegistered<ManageExpensesController>()) {
    unawaited(Get.find<ManageExpensesController>().refreshRows());
  }
}
