import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/repository/app_repository.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../routes/app_pages.dart';

class AllBookingsController extends BaseController {
  final AppRepository _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final bookings = <CheckInItem>[].obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllBookings();
  }

  Future<void> loadAllBookings() async {
    loading.value = true;
    try {
      final res = await _repository.getAllBookings();
      if (res.responseCode != '0' || res.data == null) {
        bookings.clear();
        return;
      }
      final list = res.data!['bookings'] as List<dynamic>? ?? [];
      final items = list.map((e) {
        final m = e as Map<String, dynamic>;
        final checkIn = m['checkIn'] as String? ?? '';
        final checkOut = m['checkOut'] as String? ?? '';
        final nights = (m['numberOfNights'] as num?)?.toInt() ?? 0;
        final dates = _formatDates(checkIn, checkOut, nights);
        return CheckInItem(
          bookingId: m['bookingId'] as String?,
          imageUrl: m['imageUrl'] as String? ?? '',
          guestName: m['guestName'] as String? ?? '',
          guestAvatarUrl: m['guestAvatarUrl'] as String? ?? '',
          propertyType: m['propertyType'] as String? ?? m['propertyName'] as String? ?? '',
          dates: dates,
          isConfirmed: m['isConfirmed'] as bool? ?? false,
        );
      }).toList();
      bookings.assignAll(items);
    } catch (_) {
      bookings.clear();
    } finally {
      loading.value = false;
    }
  }

  String _formatDates(String checkIn, String checkOut, int nights) {
    try {
      final ci = DateTime.tryParse(checkIn);
      final co = DateTime.tryParse(checkOut);
      if (ci != null && co != null) {
        final fmt = DateFormat('MMM d');
        final n = nights > 0 ? nights : co.difference(ci).inDays;
        return '${fmt.format(ci)} - ${fmt.format(co)} • $n Night${n == 1 ? '' : 's'}';
      }
    } catch (_) {}
    return '$checkIn - $checkOut';
  }

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item);
}
