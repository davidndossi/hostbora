import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/check_in_item.dart';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';

class HostDashboardController extends BaseController {
  final activeBookings = 12;
  final monthlyRevenue = '\$4,250';
  final bookingsChange = '+15% from last month';
  final revenueChange = '+8.2% from last month';

  /// Placeholder rows for the legacy host dashboard layout (real data lives on Home).
  final checkIns = [
    CheckInItem(
      checkInIso: '2026-10-12',
      checkOutIso: '2026-10-15',
      imageUrl: 'https://placehold.co/280x160/f0f0f0/999?text=Downtown+Loft',
      guestName: 'Sarah M.',
      guestAvatarUrl: 'https://placehold.co/48x48',
      propertyType: 'Downtown Loft',
      dates: 'Oct 12 - Oct 15 • 3 Nights',
      isConfirmed: true,
    ),
    CheckInItem(
      checkInIso: '2026-10-14',
      checkOutIso: '2026-10-18',
      imageUrl: 'https://placehold.co/280x160/e3f2f1/999?text=Seaside',
      guestName: 'James',
      guestAvatarUrl: 'https://placehold.co/48x48',
      propertyType: 'Seaside',
      dates: 'Oct 14 - Oct 18 • 4 Nights',
      isConfirmed: false,
    ),
  ];

  void viewTrends() {
    // TODO: navigate to trends screen
  }

  void seeAllCheckIns() => Get.toNamed(Routes.ALL_BOOKINGS);

  void addListing() => Get.toNamed(Routes.ADD_LISTING);

  void addNewBooking() {
    Get.toNamed(Routes.ADD_NEW_BOOKING)?.then((saved) async {
      if (saved == true) {
        await HostCalendarController.refreshIfRegistered();
        await DashboardController.refreshIfRegistered();
      }
    });
  }

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void viewCalendar() => Get.toNamed(Routes.HOST_CALENDAR);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void reports() => Get.toNamed(Routes.REPORTS_HUB);

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item);
}
