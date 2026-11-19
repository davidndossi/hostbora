import 'package:get/get.dart';

import '../../../core/access/plan_agents.dart';
import '../../../core/access/staff_access.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/getx_instance_probe.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/synced_entity_store.dart';
import '../../../data/local/service/account_recency_sync.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/local/service/bnb_messaging_contacts_service.dart';
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
  final initialLoading = true.obs;
  final refreshing = false.obs;
  final hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllBookings();
  }

  Future<void> loadAllBookings({bool refresh = false}) async {
    if (refresh) {
      refreshing.value = true;
    } else if (!hasLoaded.value) {
      initialLoading.value = true;
    }
    final merge = BnbBookingMerge(pending: _pendingBookingsStore);
    final merged = <String, CheckInItem>{};
    var loadedFromNetwork = false;
    try {
      final res = await _repository.getAllBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (res.responseCode == '0' && data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
        loadedFromNetwork = true;
      } else if (res.responseCode == '0' && data is List) {
        rows = data;
        loadedFromNetwork = true;
      }
      final remoteMaps = <Map<String, dynamic>>[];
      for (final e in rows.whereType<Map>()) {
        final map = Map<String, dynamic>.from(e);
        remoteMaps.add(map);
        final item = merge.fromApiMap(map);
        merged[item.bookingKey] = item;
      }
      if (remoteMaps.isNotEmpty &&
          Get.isRegistered<OfflineSyncQueueLocalDataSource>()) {
        await AccountRecencySync(
          repository: _repository,
          syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
        ).reconcileBookings(remoteMaps);
      }
    } catch (_) {}

    if (!loadedFromNetwork) {
      try {
        final cached = await SyncedEntityStore().load(SyncedEntityStore.bookingType);
        for (final row in cached) {
          if (row.payload.isEmpty) continue;
          final item = merge.fromApiMap(row.payload);
          merged[item.bookingKey] = item;
        }
      } catch (_) {}
    }

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

    bookings.assignAll(
      merged.values.where(_bookingIsInPlanHistory).toList(),
    );
    initialLoading.value = false;
    refreshing.value = false;
    hasLoaded.value = true;
  }

  void openBookingDetails(CheckInItem item) =>
      Get.toNamed(Routes.BOOKING_DETAILS, arguments: item)?.then((_) {
        loadAllBookings();
      });

  /// Owners and staff with manage-bookings permission. View-only staff stay on the list.
  bool get canAddBooking {
    if (!Get.isRegistered<StaffAccessStore>()) return true;
    final access = Get.find<StaffAccessStore>();
    access.restricted.value;
    access.permissions.length;
    return access.allows(StaffPermissions.manageBookings);
  }

  Future<void> addBooking() async {
    final saved = await Get.toNamed(Routes.ADD_NEW_BOOKING);
    if (saved == true) {
      await loadAllBookings(refresh: true);
    }
  }

  Future<void> messageGuestsWithPhones() async {
    final isSw = Get.locale?.languageCode == 'sw';
    List<String> phones;
    try {
      final service = Get.isRegistered<BnbMessagingContactsService>()
          ? Get.find<BnbMessagingContactsService>()
          : BnbMessagingContactsService();
      phones = await service.collectAllRecipientPhones(activeGuestsOnly: false);
    } catch (_) {
      phones = const [];
    }
    if (phones.isEmpty) {
      showErrorMessage(
        isSw
            ? 'Hakuna namba za wageni katika uhifadhi'
            : 'No guest phone numbers found in bookings',
      );
      return;
    }
    Get.toNamed(
      Routes.SEND_SMS,
      arguments: {
        'phones': phones,
        'workspace': 'bnb',
        'contextLabel': isSw ? 'Wageni kutoka uhifadhi wote' : 'Guests from all bookings',
      },
    );
  }

  bool _bookingIsInPlanHistory(CheckInItem item) {
    final start = PlanAccess.historyStart();
    if (start == null) return true;
    final checkIn = DateTime.tryParse(item.checkInIso.trim());
    final checkOut = DateTime.tryParse(item.checkOutIso.trim());
    if (checkIn == null && checkOut == null) return true;
    final end = checkOut ?? checkIn!;
    final endDay = DateTime(end.year, end.month, end.day);
    return !endDay.isBefore(start);
  }

  static Future<void> refreshIfRegistered() async {
    if (GetxInstanceProbe.isAlive<AllBookingsController>()) {
      await Get.find<AllBookingsController>().loadAllBookings(refresh: true);
    }
  }

  Future<void> retryBookingSync(CheckInItem item) async {
    final queueId = item.syncQueueId;
    if (queueId == null) return;
    final queue = Get.find<OfflineSyncQueueLocalDataSource>();
    final worker = Get.find<OfflineSyncWorkerService>();
    await queue.retryItem(queueId);
    await worker.runNow(maxItems: 20);
    await loadAllBookings(refresh: true);
  }
}
