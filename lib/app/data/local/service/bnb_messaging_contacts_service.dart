import 'package:get/get.dart';

import '../../model/check_in_item.dart';
import '../../model/messaging_contact.dart';
import '../../repository/app_repository.dart';
import '../bnb_booking_merge.dart';
import '../bnb_booking_pending_loader.dart' show BnbBookingPendingLoader, mergePendingBnbBookings;
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/tenant_local_data_source.dart';
import '../pending_bookings_store.dart';

/// Loads BnB guest phones from API bookings, pending creates, and stored overrides.
class BnbMessagingContactsService {
  BnbMessagingContactsService({
    AppRepository? repository,
    PropertyLocalDataSource? propertyLocal,
    TenantLocalDataSource? tenantLocal,
    PendingBookingsStore? pendingStore,
    OfflineSyncQueueLocalDataSource? syncQueue,
  })  : _repository = repository ?? Get.find(tag: (AppRepository).toString()),
        _propertyLocal = propertyLocal ?? Get.find<PropertyLocalDataSource>(),
        _tenantLocal = tenantLocal ?? Get.find<TenantLocalDataSource>(),
        _pending = pendingStore ?? PendingBookingsStore(),
        _pendingLoader = BnbBookingPendingLoader(
          syncQueue: syncQueue ?? Get.find<OfflineSyncQueueLocalDataSource>(),
        );

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final PendingBookingsStore _pending;
  final BnbBookingPendingLoader _pendingLoader;

  Future<List<MessagingContact>> loadGuestContacts({
    bool activeOnly = true,
  }) async {
    final merge = BnbBookingMerge(pending: _pending);
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
        userId: '',
        workspaceType: 'bnb',
      );
      await mergePendingBnbBookings(
        merge: merge,
        merged: merged,
        properties: properties,
        loader: _pendingLoader,
      );
    } catch (_) {}

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final contacts = <MessagingContact>[];
    final seenPhones = <String>{};

    for (final item in merged.values) {
      if (activeOnly && item.isInactive) continue;
      final phone = item.guestPhone.trim();
      if (phone.isEmpty) continue;
      if (!seenPhones.add(phone)) continue;
      contacts.add(
        MessagingContact(
          key: 'guest_${item.bookingKey}',
          label: item.guestName.trim().isEmpty ? phone : item.guestName.trim(),
          phone: phone,
          subtitle: item.propertyType,
          kind: 'guest',
        ),
      );
    }

    contacts.sort((a, b) => a.label.compareTo(b.label));
    return contacts;
  }

  Future<List<MessagingContact>> loadTenantContacts() async {
    final rows = await _tenantLocal.getAllNewestFirstByWorkspace('bnb');
    final contacts = <MessagingContact>[];
    final seen = <String>{};
    for (final t in rows) {
      final phone = t.phoneNumber.trim();
      if (phone.isEmpty || !seen.add(phone)) continue;
      contacts.add(
        MessagingContact(
          key: 'tenant_${t.id}',
          label: t.tenantName.trim().isEmpty ? phone : t.tenantName.trim(),
          phone: phone,
          subtitle: t.propertyLabel,
          kind: 'tenant',
        ),
      );
    }
    contacts.sort((a, b) => a.label.compareTo(b.label));
    return contacts;
  }

  /// All BnB guest + tenant phones for bulk messaging.
  Future<List<String>> collectAllRecipientPhones({bool activeGuestsOnly = true}) async {
    final guests = await loadGuestContacts(activeOnly: activeGuestsOnly);
    final tenants = await loadTenantContacts();
    final phones = <String>{
      ...guests.map((e) => e.phone),
      ...tenants.map((e) => e.phone),
    };
    return phones.toList();
  }
}
