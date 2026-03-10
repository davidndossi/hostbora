import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class BookingDetailsController extends BaseController {
  /// True when opened from My Properties (select listing) to check availability.
  late final bool isListingMode;

  // Property/listing - from args in listing mode or defaults
  final propertyTitle = ''.obs;
  final propertyLocation = ''.obs;
  final propertyImageUrl = ''.obs;

  // Booking data - used when not in listing mode (from Get.arguments or API)
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

  /// Availability: 'today' (default), 'month', 'month_date'
  final availabilityMode = 'today'.obs;
  final selectedMonth = Rxn<DateTime>();
  final selectedDate = Rxn<DateTime>();

  BookingDetailsController() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final id = args['listingId'];
      if (id != null && id.toString().isNotEmpty) {
        isListingMode = true;
        propertyTitle.value = args['listingTitle']?.toString() ?? '';
        propertyLocation.value = args['listingLocation']?.toString() ?? '';
        propertyImageUrl.value = args['listingImageUrl']?.toString() ?? '';
        return;
      }
    }
    isListingMode = false;
    propertyTitle.value = 'Modern Lakeside Villa';
    propertyLocation.value = 'Lake Tahoe, California';
    propertyImageUrl.value =
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800';
  }

  void setAvailabilityMode(String mode) {
    availabilityMode.value = mode;
    if (mode == 'today') {
      selectedMonth.value = null;
      selectedDate.value = null;
    } else if (mode == 'month') {
      selectedDate.value = null;
      if (selectedMonth.value == null) {
        selectedMonth.value = DateTime(DateTime.now().year, DateTime.now().month);
      }
    } else if (mode == 'month_date') {
      if (selectedMonth.value == null) {
        selectedMonth.value = DateTime(DateTime.now().year, DateTime.now().month);
      }
      if (selectedDate.value == null) {
        selectedDate.value = DateTime.now();
      }
    }
  }

  void pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      selectedMonth.value = DateTime(picked.year, picked.month);
    }
  }

  void pickDate(BuildContext context) async {
    final now = DateTime.now();
    final month = selectedMonth.value ?? now;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final firstDate = (month.year == now.year && month.month == now.month)
        ? DateTime(now.year, now.month, now.day)
        : monthStart;
    final initial = selectedDate.value ?? month;
    final initialDate = initial.isBefore(firstDate) ? firstDate : initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: monthEnd,
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  /// Date we're showing availability for: today (default), or selected month/date.
  String get availabilitySummary {
    if (availabilityMode.value == 'today') {
      final t = DateTime.now();
      return DateFormat('EEEE, MMM d').format(t);
    }
    if (availabilityMode.value == 'month') {
      final m = selectedMonth.value;
      if (m == null) return 'Select month';
      return DateFormat('MMMM yyyy').format(m);
    }
    final d = selectedDate.value;
    if (d == null) return 'Select date';
    return DateFormat('EEEE, MMM d').format(d);
  }

  /// Placeholder availability status (replace with API later).
  String get availabilityStatus {
    if (availabilityMode.value == 'today') {
      return 'Available';
    }
    if (availabilityMode.value == 'month') {
      return '22 days available';
    }
    return 'Available';
  }

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
