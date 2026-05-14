import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../flavors/build_config.dart';
import '../../../core/base/base_controller.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/create_booking_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/service/azampay_service.dart';
import '../../../routes/app_pages.dart';

/// Lightweight listing for property dropdown (from GET /api/listings).
class ListingItem {
  ListingItem({required this.id, required this.propertyName});
  final String id;
  final String propertyName;
}

class BookingUnitItem {
  BookingUnitItem({required this.id, required this.unitName});
  final String id;
  final String unitName;
}

class AddNewBookingController extends BaseController {
  static const _chunkSize = 200;

  AddNewBookingController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _propertyUnitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _azamPay = AzamPayService(),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final PropertyUnitLocalDataSource _propertyUnitLocal;
  final AzamPayService _azamPay;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();
  final guestNameController = TextEditingController();
  final guestPhoneController = TextEditingController();
  final notesController = TextEditingController();
  final numberOfGuestsController = TextEditingController();
  final pushToPayAmountController = TextEditingController();
  final checkInDateController = TextEditingController(text: 'Select date');
  final checkOutDateController = TextEditingController(text: 'Select date');

  final listings = <ListingItem>[].obs;
  final listingsLoading = false.obs;
  final selectedListingId = Rx<String?>(null);
  final propertyUnits = <BookingUnitItem>[].obs;
  final selectedUnitId = Rx<String?>(null);
  final checkInDate = Rx<DateTime?>(null);
  final checkOutDate = Rx<DateTime?>(null);
  final saving = false.obs;
  final sendPushToPay = false.obs;
  final selectedProvider = 'Mpesa'.obs;
  final sendingPushToPay = false.obs;
  final pendingCount = 0.obs;
  final syncing = false.obs;

  bool get isAzamPayEnabled => BuildConfig.instance.config.isAzamPayConfigured;

  static const _dateFormat = 'MMM d, yyyy';
  static const _isoDateFormat = 'yyyy-MM-dd';

  String get checkInLabel =>
      checkInDate.value != null
          ? DateFormat(_dateFormat).format(checkInDate.value!)
          : 'Select date';

  String get checkOutLabel =>
      checkOutDate.value != null
          ? DateFormat(_dateFormat).format(checkOutDate.value!)
          : 'Select date';

  @override
  void onReady() {
    super.onReady();
    loadListings();
    _updatePendingCount();
  }

  Future<void> _updatePendingCount() async {
    try {
      pendingCount.value = await _syncQueue.pendingCountByEntity(
        entityType: 'booking',
        operation: 'create',
      );
    } catch (_) {}
  }

  Future<void> loadListings() async {
    listingsLoading.value = true;
    try {
      final localRows = await _propertyLocal.getAllNewestFirstChunked(
        chunkSize: _chunkSize,
      );
      final localItems = localRows
          .map(
            (r) => ListingItem(
              id: r.propertyRef.trim().isNotEmpty ? r.propertyRef.trim() : 'local_${r.id}',
              propertyName: r.propertyName.trim().isNotEmpty
                  ? r.propertyName.trim()
                  : (r.propertyLocation.trim().isNotEmpty ? r.propertyLocation.trim() : 'Property'),
            ),
          )
          .where((e) => e.id.isNotEmpty)
          .toList();

      final res = await _repository.getMyListings();
      final data = res.data;
      final merged = <String, ListingItem>{
        for (final item in localItems) item.id: item,
      };
      if (data is List) {
        final remoteItems = data
            .map(
              (e) => ListingItem(
                id: (e is Map ? e['id'] : null)?.toString() ?? '',
                propertyName: (e is Map ? e['propertyName'] : null)?.toString() ??
                    (e is Map ? e['id'] : null)?.toString() ??
                    'Property',
              ),
            )
            .where((e) => e.id.isNotEmpty);
        for (final item in remoteItems) {
          merged[item.id] = item;
        }
      }
      listings.assignAll(merged.values.toList());
      if (listings.isNotEmpty && selectedListingId.value == null) {
        selectedListingId.value = listings.first.id;
      }
      await _loadUnitsForListing(selectedListingId.value);
    } catch (e) {
      try {
        final localRows = await _propertyLocal.getAllNewestFirstChunked(
          chunkSize: _chunkSize,
        );
        listings.assignAll(
          localRows
              .map(
                (r) => ListingItem(
                  id: r.propertyRef.trim().isNotEmpty ? r.propertyRef.trim() : 'local_${r.id}',
                  propertyName: r.propertyName.trim().isNotEmpty
                      ? r.propertyName.trim()
                      : (r.propertyLocation.trim().isNotEmpty ? r.propertyLocation.trim() : 'Property'),
                ),
              )
              .where((e) => e.id.isNotEmpty)
              .toList(),
        );
        if (listings.isNotEmpty && selectedListingId.value == null) {
          selectedListingId.value = listings.first.id;
        }
        await _loadUnitsForListing(selectedListingId.value);
      } catch (_) {
        Get.snackbar('Error', 'Could not load properties: $e');
      }
    } finally {
      listingsLoading.value = false;
    }
  }

  void goBack() => Get.back();

  Future<void> selectProperty(String? listingId) async {
    selectedListingId.value = listingId;
    await _loadUnitsForListing(listingId);
  }

  Future<void> _loadUnitsForListing(String? listingId) async {
    final id = (listingId ?? '').trim();
    propertyUnits.clear();
    selectedUnitId.value = null;
    if (id.isEmpty) return;

    final units = <BookingUnitItem>[];
    try {
      final unitRows = await _propertyUnitLocal.getAllByPropertyRefNewestFirstChunked(
        propertyRef: id,
        chunkSize: _chunkSize,
      );
      for (final row in unitRows) {
        final unitName = row.unitName.trim();
        if (unitName.isEmpty) continue;
        units.add(
          BookingUnitItem(
            id: row.propertyUnitRef.trim().isNotEmpty ? row.propertyUnitRef.trim() : '${row.id}',
            unitName: unitName,
          ),
        );
      }

      if (units.isEmpty) {
        final localRows = await _propertyLocal.getAllNewestFirstChunked(
          chunkSize: _chunkSize,
        );
        final target = localRows.firstWhereOrNull(
          (r) => r.propertyRef.trim() == id || 'local_${r.id}' == id,
        );
        if (target != null && target.unitsJson.trim().isNotEmpty) {
          final decoded = jsonDecode(target.unitsJson);
          if (decoded is List) {
            for (final e in decoded.whereType<Map>()) {
              final m = Map<String, dynamic>.from(e);
              final unitName = (m['unitName'] ?? m['name'] ?? '').toString().trim();
              if (unitName.isEmpty) continue;
              final unitId = (m['unitId'] ?? '').toString().trim();
              units.add(
                BookingUnitItem(
                  id: unitId.isNotEmpty ? unitId : '__n:$unitName',
                  unitName: unitName,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    propertyUnits.assignAll(units);
    if (units.length == 1) {
      selectedUnitId.value = units.first.id;
    }
  }

  Future<void> pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkInDate.value ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      checkInDate.value = picked;
      checkInDateController.text = DateFormat(_dateFormat).format(picked);
      if (checkOutDate.value != null &&
          (checkOutDate.value!.isBefore(picked) ||
              checkOutDate.value!.isAtSameMomentAs(picked))) {
        checkOutDate.value = null;
        checkOutDateController.text = 'Select date';
      }
    }
  }

  Future<void> pickCheckOut() async {
    final from = checkInDate.value ?? DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkOutDate.value ?? from.add(const Duration(days: 1)),
      firstDate: from,
      lastDate: from.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      checkOutDate.value = picked;
      checkOutDateController.text = DateFormat(_dateFormat).format(picked);
    }
  }

  Future<void> saveBooking() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final listingId = selectedListingId.value;
    if (listingId == null || listingId.isEmpty) {
      Get.snackbar('Required', 'Please select a property');
      return;
    }
    if (propertyUnits.length > 1 &&
        (selectedUnitId.value == null || selectedUnitId.value!.isEmpty)) {
      Get.snackbar('Required', 'Please select a property unit');
      return;
    }
    if (checkInDate.value == null) {
      Get.snackbar('Required', 'Please select check-in date');
      return;
    }
    if (checkOutDate.value == null) {
      Get.snackbar('Required', 'Please select check-out date');
      return;
    }
    if (checkOutDate.value!.isBefore(checkInDate.value!) ||
        checkOutDate.value!.isAtSameMomentAs(checkInDate.value!)) {
      Get.snackbar('Invalid', 'Check-out must be after check-in');
      return;
    }
    if (sendPushToPay.value && isAzamPayEnabled) {
      final phone = guestPhoneController.text.trim();
      final amount = pushToPayAmountController.text.trim();
      if (phone.isEmpty) {
        Get.snackbar('Push to Pay', 'Enter guest phone number to send payment request.');
        return;
      }
      if (amount.isEmpty) {
        Get.snackbar('Push to Pay', 'Enter amount (TZS) to request from guest.');
        return;
      }
    }
    if (saving.value) return;

    final guestPhone = guestPhoneController.text.trim();
    final request = CreateBookingRequest(
      listingId: listingId,
      unitId: (selectedUnitId.value != null && selectedUnitId.value!.trim().isNotEmpty)
          ? selectedUnitId.value!.trim()
          : null,
      guestName: guestNameController.text.trim(),
      checkIn: DateFormat(_isoDateFormat).format(checkInDate.value!),
      checkOut: DateFormat(_isoDateFormat).format(checkOutDate.value!),
      numberOfGuests: int.tryParse(numberOfGuestsController.text.trim()) ?? 1,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      guestPhoneNumber: guestPhone.isEmpty ? null : guestPhone,
    );

    saving.value = true;
    try {
      await _syncQueue.enqueue(
        entityType: 'booking',
        operation: 'create',
        payloadJson: jsonEncode(request.toJson()),
      );
      await _syncWorker.runNow(maxItems: 20);
      _updatePendingCount();
      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      if (sendPushToPay.value &&
          guestPhone.isNotEmpty &&
          isAzamPayEnabled &&
          pushToPayAmountController.text.trim().isNotEmpty) {
        await _sendPushToPay(
          customerPhone: guestPhone,
          amount: pushToPayAmountController.text.trim(),
          externalId: bookingId,
        );
      }
      Get.back();
      final pending = pendingCount.value;
      if (pending > 0) {
        Get.snackbar(
          'Saved offline',
          'Booking saved on this device. Will sync when internet is available.',
        );
      } else {
        Get.snackbar('Saved', 'Booking synced successfully.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save booking: $e');
    } finally {
      saving.value = false;
    }
  }

  Future<void> _sendPushToPay({
    required String customerPhone,
    required String amount,
    required String externalId,
  }) async {
    sendingPushToPay.value = true;
    try {
      final result = await _azamPay.sendPushToPay(
        customerPhone: customerPhone,
        amount: amount,
        provider: selectedProvider.value,
        externalId: externalId,
      );
      if (result.success) {
        Get.snackbar(
          'Push to Pay',
          'Payment request sent to guest\'s phone.',
        );
      } else {
        Get.snackbar('Push to Pay', result.message);
      }
    } finally {
      sendingPushToPay.value = false;
    }
  }

  void setSendPushToPay(bool value) => sendPushToPay.value = value;

  void selectProvider(String? value) {
    if (value != null) selectedProvider.value = value;
  }

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.MAIN);
        break;
      case 1:
        break; // Bookings - current screen
      case 2:
        Get.offAllNamed(Routes.HOST_CALENDAR);
        break;
      case 3:
        Get.offAllNamed(Routes.SETTINGS);
        break; // Profile placeholder
    }
  }

  @override
  void onClose() {
    guestNameController.dispose();
    guestPhoneController.dispose();
    notesController.dispose();
    numberOfGuestsController.dispose();
    pushToPayAmountController.dispose();
    checkInDateController.dispose();
    checkOutDateController.dispose();
    super.onClose();
  }
}
