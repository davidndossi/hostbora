import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/getx_instance_probe.dart';
import '../../../modules/all_bookings/controllers/all_bookings_controller.dart';
import '../../../modules/booking_details/controllers/booking_details_controller.dart';
import '../../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../modules/host_calendar/controllers/host_calendar_controller.dart';
import '../../../modules/rent/manage_expenses/controllers/manage_expenses_controller.dart';
import '../../../modules/rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import 'offline_sync_worker_service.dart';

Timer? _debounce;
bool _refreshRunning = false;
bool _refreshQueued = false;

/// Refreshes **already-open** BnB/rent screens after the offline sync worker
/// drains the queue. Debounced so rapid drains (login + connectivity) do not
/// stampede Home/Dashboard/Calendar on the UI isolate.
void registerOfflineSyncUiRefresh(OfflineSyncWorkerService syncWorker) {
  syncWorker.addOnDrainListener(_scheduleRefreshAfterSync);
}

void _scheduleRefreshAfterSync() {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 1200), () {
    unawaited(_refreshAfterSync());
  });
}

Future<void> _refreshAfterSync() async {
  if (_refreshRunning) {
    _refreshQueued = true;
    return;
  }
  _refreshRunning = true;
  try {
    // Only touch controllers that are already constructed. Never Get.find a
    // lazyPut that would create Dashboard/Calendar just to refresh them.
    if (GetxInstanceProbe.isAlive<HomeController>()) {
      await HomeController.refreshIfRegistered();
    }
    if (GetxInstanceProbe.isAlive<AllBookingsController>()) {
      await AllBookingsController.refreshIfRegistered();
    }
    if (GetxInstanceProbe.isAlive<DashboardController>()) {
      await DashboardController.refreshIfRegistered(quiet: true);
    }
    if (GetxInstanceProbe.isAlive<HostCalendarController>()) {
      await HostCalendarController.refreshIfRegistered();
    }
    if (GetxInstanceProbe.isAlive<
        RentTenantResidencyPaymentTrackerController>()) {
      await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
    }
    if (GetxInstanceProbe.isAlive<BookingDetailsController>()) {
      await BookingDetailsController.refreshIfRegistered();
    }
    if (GetxInstanceProbe.isAlive<ManageExpensesController>()) {
      unawaited(Get.find<ManageExpensesController>().refreshRows());
    }
  } finally {
    _refreshRunning = false;
    if (_refreshQueued) {
      _refreshQueued = false;
      _scheduleRefreshAfterSync();
    }
  }
}
