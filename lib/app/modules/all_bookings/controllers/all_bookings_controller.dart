import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../routes/app_pages.dart';

class AllBookingsController extends BaseController {
  final AppRepository _repository = Get.find<AppRepository>(tag: (AppRepository).toString());
  final PropertyLocalDataSource _propertyLocal = Get.find<PropertyLocalDataSource>();
  final PendingBookingsStore _pendingBookingsStore = PendingBookingsStore();
  late final BnbBookingPendingLoader _pendingBookingLoader =
      BnbBookingPendingLoader(
    syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
  );

  final bookings = <CheckInItem>[].obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllBookings();
  }

  Future<void> loadAllBookings() async {
    loading.value = true;
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final merged = <String, CheckInItem>{};
    try {
      final res = await _repository.getAllBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final item = merge.fromApiMap(Map<String, dynamic>.from(e));
        merged[item.bookingKey] = item;
      }
    } catch (_) {}

    try {
      final properties = await _propertyLocal.getAllVisibleNewestFirst(
          userId: '', workspaceType: 'bnb');
      await mergePendingBnbBookings(
        merge: merge,
        merged: merged,
        properties: properties,
        loader: _pendingBookingLoader,
      );
    } catch (_) {}

    bookings.assignAll(merged.values.toList());
    loading.value = false;
  }

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item)?.then((_) {
        loadAllBookings();
      });
}
