import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../flavors/build_config.dart';
import '../../../core/base/base_controller.dart';
import '../../../data/local/pending_bookings_store.dart';
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

/// AzamPay mobile money providers (Tanzania).
const List<String> azamPayProviders = <String>[
  'Mpesa',
  'Airtel',
  'Tigo',
  'Halopesa',
  'Azampesa',
];

class AddNewBookingController extends BaseController {
  AddNewBookingController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _azamPay = AzamPayService(),
        _pendingStore = PendingBookingsStore();

  final AppRepository _repository;
  final AzamPayService _azamPay;
  final PendingBookingsStore _pendingStore;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final formKey = GlobalKey<FormState>();
  final guestNameController = TextEditingController();
  final guestPhoneController = TextEditingController();
  final notesController = TextEditingController();
  final numberOfGuestsController = TextEditingController();
  final pushToPayAmountController = TextEditingController();

  final listings = <ListingItem>[].obs;
  final listingsLoading = false.obs;
  final selectedListingId = Rx<String?>(null);
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
    _syncPendingWhenOnline();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (_hasConnectivity(results)) _syncPendingWhenOnline();
    });
  }

  bool _hasConnectivity(List<ConnectivityResult> results) {
    return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return _hasConnectivity(results);
  }

  void _updatePendingCount() {
    pendingCount.value = _pendingStore.count;
  }

  /// Syncs pending bookings to the server. Call when online.
  Future<void> _syncPendingWhenOnline() async {
    if (syncing.value) return;
    if (!await _isOnline()) return;
    final list = _pendingStore.load();
    if (list.isEmpty) return;
    syncing.value = true;
    try {
      final toKeep = <Map<String, dynamic>>[];
      var synced = 0;
      for (final item in list) {
        try {
          final request = CreateBookingRequest.fromJson(item);
          final res = await _repository.createBooking(request);
          if (res.responseCode == '200' || res.responseCode == '201') {
            synced++;
          } else {
            toKeep.add(item);
          }
        } catch (_) {
          toKeep.add(item);
        }
      }
      await _pendingStore.save(toKeep);
      _updatePendingCount();
      if (synced > 0) {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.snackbar('Synced', synced == 1 ? 'Offline booking synced.' : '$synced offline bookings synced.');
      }
    } finally {
      syncing.value = false;
    }
  }

  Future<void> loadListings() async {
    listingsLoading.value = true;
    try {
      final res = await _repository.getMyListings();
      final data = res.data;
      if (data is List) {
        listings.assignAll(
          (data as List)
              .map((e) => ListingItem(
                    id: (e is Map ? e['id'] : null)?.toString() ?? '',
                    propertyName:
                        (e is Map ? e['propertyName'] : null)?.toString() ??
                            (e is Map ? e['id'] : null)?.toString() ??
                            'Property',
                  ))
              .where((e) => e.id.isNotEmpty)
              .toList(),
        );
        if (listings.isNotEmpty && selectedListingId.value == null) {
          selectedListingId.value = listings.first.id;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load properties: $e');
    } finally {
      listingsLoading.value = false;
    }
  }

  void goBack() => Get.back();

  void selectProperty(String? listingId) {
    selectedListingId.value = listingId;
  }

  Future<void> pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkInDate.value ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) checkInDate.value = picked;
  }

  Future<void> pickCheckOut() async {
    final from = checkInDate.value ?? DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkOutDate.value ?? from.add(const Duration(days: 1)),
      firstDate: from,
      lastDate: from.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) checkOutDate.value = picked;
  }

  Future<void> saveBooking() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final listingId = selectedListingId.value;
    if (listingId == null || listingId.isEmpty) {
      Get.snackbar('Required', 'Please select a property');
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
      final online = await _isOnline();
      if (!online) {
        await _pendingStore.add(request.toJson());
        _updatePendingCount();
        Get.back();
        Get.snackbar(
          'Saved offline',
          'Booking will sync when you\'re back online.',
          duration: const Duration(seconds: 4),
        );
        saving.value = false;
        return;
      }
      await _syncPendingWhenOnline();
      final res = await _repository.createBooking(request);
      if (res.responseCode == '201' || res.responseCode == '200') {
        final bookingId = res.data is Map
            ? (res.data as Map)['id']?.toString()
            : DateTime.now().millisecondsSinceEpoch.toString();
        if (sendPushToPay.value &&
            guestPhone.isNotEmpty &&
            isAzamPayEnabled &&
            pushToPayAmountController.text.trim().isNotEmpty) {
          await _sendPushToPay(
            customerPhone: guestPhone,
            amount: pushToPayAmountController.text.trim(),
            externalId: bookingId ?? '',
          );
        }
        Get.back();
        Get.snackbar('Success', 'Booking created');
      } else {
        Get.snackbar('Error', res.message ?? 'Could not create booking');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create booking: $e');
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
    _connectivitySubscription?.cancel();
    guestNameController.dispose();
    guestPhoneController.dispose();
    notesController.dispose();
    numberOfGuestsController.dispose();
    pushToPayAmountController.dispose();
    super.onClose();
  }
}
