import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class BookingDetailsController extends BaseController {
  // Booking data - in real app would come from Get.arguments or API
  final propertyTitle = 'Modern Lakeside Villa';
  final propertyLocation = 'Lake Tahoe, California';
  final propertyImageUrl =
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800';

  final guestName = 'Alex Johnson';
  final guestAvatarUrl = 'https://placehold.co/56x56';
  final guestRating = 4.9;
  final guestReviewCount = 12;

  final checkInDate = 'Oct 12, 2023';
  final checkInTime = 'After 3:00 PM';
  final checkOutDate = 'Oct 15, 2023';
  final checkOutTime = 'By 11:00 AM';

  final isPaid = true;
  final totalPayout = '\$1,240.00';

  void goBack() => Get.back();

  void share() {
    // TODO: share booking
  }

  void moreOptions() {
    // TODO: show bottom sheet / menu
  }

  void messageGuest() {
    // TODO: open chat with guest
  }

  void modifyBooking() {
    // TODO: navigate to modify booking
  }

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.MAIN);
        break;
      case 1:
        // Bookings - current screen
        break;
      case 2:
        // TODO: Inbox
        break;
      case 3:
        // TODO: Profile
        break;
    }
  }
}
