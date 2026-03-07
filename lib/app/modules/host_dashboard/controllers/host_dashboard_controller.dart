import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class HostDashboardController extends BaseController {
  final activeBookings = 12;
  final monthlyRevenue = '\$4,250';
  final bookingsChange = '+15% from last month';
  final revenueChange = '+8.2% from last month';

  final checkIns = [
    CheckInItem(
      imageUrl: 'https://placehold.co/280x160/f0f0f0/999?text=Downtown+Loft',
      guestName: 'Sarah M.',
      guestAvatarUrl: 'https://placehold.co/48x48',
      propertyType: 'Downtown Loft',
      dates: 'Oct 12 - Oct 15 • 3 Nights',
      isConfirmed: true,
    ),
    CheckInItem(
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

  void seeAllCheckIns() {
    // TODO: navigate to check-ins list
  }

  void addListing() => Get.toNamed(Routes.ADD_LISTING);

  void addNewBooking() => Get.toNamed(Routes.ADD_NEW_BOOKING);

  void smartAccess() => Get.toNamed(Routes.SMART_ACCESS);

  void viewCalendar() => Get.toNamed(Routes.HOST_CALENDAR);

  void assignTasks() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void reports() => Get.toNamed(Routes.FINANCIAL_OVERVIEW);

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item);
}

class CheckInItem {
  final String imageUrl;
  final String guestName;
  final String guestAvatarUrl;
  final String propertyType;
  final String dates;
  final bool isConfirmed;

  CheckInItem({
    required this.imageUrl,
    required this.guestName,
    required this.guestAvatarUrl,
    required this.propertyType,
    required this.dates,
    required this.isConfirmed,
  });
}
