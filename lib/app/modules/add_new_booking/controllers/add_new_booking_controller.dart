import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/constants/ui_preference_keys.dart';
import '../../../core/utils/form_recall.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/utils/bnb_stay_billing.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/create_booking_request.dart';
import '../../../data/model/send_payment_link_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../data/service/snippe_payment_link_service.dart';
import '../../../routes/app_pages.dart';
import '../../all_bookings/controllers/all_bookings_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../guest_access_codes/controllers/guest_access_codes_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../host_calendar/controllers/host_calendar_controller.dart';

/// Lightweight property for the booking dropdown (from local `properties`).
class ListingItem {
  ListingItem({
    required this.id,
    required this.propertyName,
    this.maxGuests = 0,
  });
  final String id;
  final String propertyName;

  /// Unit-level capacity when known. 0 = unknown.
  final int maxGuests;
}

class BookingUnitItem {
  BookingUnitItem({
    required this.id,
    required this.unitName,
    this.maxGuests = 0,
  });
  final String id;
  final String unitName;

  /// Unit capacity. 0 = unknown.
  final int maxGuests;
}

class AddNewBookingController extends BaseController with FormRecallMixin {
  static const _chunkSize = 200;

  AddNewBookingController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _propertyUnitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _paymentLinks = SnippePaymentLinkService(),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final PropertyUnitLocalDataSource _propertyUnitLocal;
  final SnippePaymentLinkService _paymentLinks;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();
  final guestNameController = TextEditingController();
  final guestPhoneController = TextEditingController();
  final notesController = TextEditingController();
  final numberOfGuestsController = TextEditingController();
  final pushToPayAmountController = TextEditingController();
  final checkInDateController = TextEditingController();
  final checkOutDateController = TextEditingController();

  final listings = <ListingItem>[].obs;
  final listingsLoading = false.obs;
  final selectedListingId = Rx<String?>(null);
  final propertyUnits = <BookingUnitItem>[].obs;
  final _freeUnitsByListingId = <String, List<BookingUnitItem>>{};
  final selectedUnitId = Rx<String?>(null);
  final checkInDate = Rx<DateTime?>(null);
  final checkOutDate = Rx<DateTime?>(null);
  final saving = false.obs;
  final sendPaymentLink = false.obs;
  final sendingPaymentLink = false.obs;
  final pendingCount = 0.obs;
  final syncing = false.obs;

  static const _minSnippeAmountTzs = 500;

  /// Hard ceiling when property/unit capacity is not configured.
  static const absoluteMaxGuests = 50;

  static const _dateFormat = 'MMM d, yyyy';
  static const _isoDateFormat = 'yyyy-MM-dd';

  /// Effective guest capacity for the selected property/unit, or null if unknown.
  int? get maxAllowedGuests {
    final unitId = selectedUnitId.value?.trim() ?? '';
    if (unitId.isNotEmpty) {
      final unit = propertyUnits.firstWhereOrNull((u) => u.id == unitId);
      if (unit != null && unit.maxGuests > 0) return unit.maxGuests;
    }
    if (propertyUnits.length == 1 && propertyUnits.first.maxGuests > 0) {
      return propertyUnits.first.maxGuests;
    }
    final listingId = selectedListingId.value;
    final listing =
        listings.firstWhereOrNull((l) => l.id == listingId);
    if (listing != null && listing.maxGuests > 0) return listing.maxGuests;
    final caps =
        propertyUnits.map((u) => u.maxGuests).where((g) => g > 0).toList();
    if (caps.isNotEmpty) {
      return caps.reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  String get checkInLabel =>
      checkInDate.value != null
          ? DateFormat(_dateFormat).format(checkInDate.value!)
          : 'Select date';

  String get checkOutLabel =>
      checkOutDate.value != null
          ? DateFormat(_dateFormat).format(checkOutDate.value!)
          : 'Select date';

  @override
  void onInit() {
    super.onInit();
    _seedDefaults();
  }

  /// Seeds the one-night stay starting today that [pickCheckOut] already treats
  /// as the common case, and makes the implicit single guest visible. Both
  /// dates are otherwise blank and fail validation on save.
  void _seedDefaults() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    checkInDate.value = today;
    checkInDateController.text = DateFormat(_dateFormat).format(today);
    checkOutDate.value = tomorrow;
    checkOutDateController.text = DateFormat(_dateFormat).format(tomorrow);

    if (numberOfGuestsController.text.trim().isEmpty) {
      numberOfGuestsController.text = '1';
    }
  }

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
      final occupied = await _loadOccupiedStays();
      final tenants = await _loadActiveTenants();
      final items = <ListingItem>[];
      _freeUnitsByListingId.clear();

      for (final property in localRows) {
        final id = property.propertyRef.trim().isNotEmpty
            ? property.propertyRef.trim()
            : 'local_${property.id}';
        if (id.isEmpty) continue;
        final freeUnits = await _freeBnbUnits(
          property: property,
          listingId: id,
          occupied: occupied,
          tenants: tenants,
        );
        if (freeUnits.isEmpty) continue;
        _freeUnitsByListingId[id] = freeUnits;
        items.add(
          ListingItem(
            id: id,
            propertyName: property.propertyName.trim().isNotEmpty
                ? property.propertyName.trim()
                : (property.propertyLocation.trim().isNotEmpty
                    ? property.propertyLocation.trim()
                    : 'Property'),
          ),
        );
      }

      listings.assignAll(items);
      final selected = selectedListingId.value;
      if (selected == null || !items.any((item) => item.id == selected)) {
        // Opens on the listing the host booked against last. A booking is
        // cheap to re-point, so falling through to the first keeps the
        // picker usable rather than empty.
        final recalled = await recallChoice(
          key: UiPreferenceKeys.addBookingListing,
          options: items.map((item) => item.id),
          fallback: RecallFallback.firstOption,
        );
        selectedListingId.value = recalled.isEmpty ? null : recalled;
      }
      await _loadUnitsForListing(selectedListingId.value);
    } catch (e) {
      listings.clear();
      propertyUnits.clear();
      selectedListingId.value = null;
      Get.snackbar('Error', 'Could not load properties: $e');
    } finally {
      listingsLoading.value = false;
    }
  }

  void goBack() => Get.back();

  Future<void> selectProperty(String? listingId) async {
    selectedListingId.value = listingId;
    await _loadUnitsForListing(listingId);
    formKey.currentState?.validate();
  }

  Future<void> _loadUnitsForListing(String? listingId) async {
    final id = (listingId ?? '').trim();
    propertyUnits.clear();
    selectedUnitId.value = null;
    if (id.isEmpty) return;

    final cached = _freeUnitsByListingId[id];
    if (cached != null) {
      propertyUnits.assignAll(cached);
      if (cached.length == 1) selectedUnitId.value = cached.first.id;
      return;
    }

    try {
      final localRows = await _propertyLocal.getAllNewestFirstChunked(
        chunkSize: _chunkSize,
      );
      final property = localRows.firstWhereOrNull(
        (r) => r.propertyRef.trim() == id || 'local_${r.id}' == id,
      );
      if (property == null) return;
      final units = await _freeBnbUnits(
        property: property,
        listingId: id,
        occupied: await _loadOccupiedStays(),
        tenants: await _loadActiveTenants(),
      );
      _freeUnitsByListingId[id] = units;
      propertyUnits.assignAll(units);
      if (units.length == 1) selectedUnitId.value = units.first.id;
    } catch (_) {}
  }

  Future<List<BookingUnitItem>> _freeBnbUnits({
    required PropertyRecord property,
    required String listingId,
    required _OccupiedStays occupied,
    required List<TenantRecord> tenants,
  }) async {
    final workspace = property.workspaceType.trim().toLowerCase();
    final candidates = <_BnbUnitCandidate>[];

    final refs = <String>{
      listingId,
      if (property.propertyRef.trim().isNotEmpty) property.propertyRef.trim(),
      'local_${property.id}',
      'legacy_${property.id}',
    };
    final seen = <String>{};
    for (final ref in refs) {
      if (ref.trim().isEmpty) continue;
      final rows = await _propertyUnitLocal.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
        chunkSize: _chunkSize,
      );
      for (final row in rows) {
        final unitName = row.unitName.trim();
        if (unitName.isEmpty) continue;
        if (!_isBnbUnit(row.operationMode, workspace)) continue;
        final unitId = row.propertyUnitRef.trim().isNotEmpty
            ? row.propertyUnitRef.trim()
            : '${row.id}';
        if (!seen.add(unitId.toLowerCase())) continue;
        candidates.add(
          _BnbUnitCandidate(
            id: unitId,
            unitName: unitName,
            maxGuests: row.maxGuests > 0 ? row.maxGuests : 0,
            status: row.status,
          ),
        );
      }
    }

    if (candidates.isEmpty && property.unitsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(property.unitsJson);
        if (decoded is List) {
          for (final e in decoded.whereType<Map>()) {
            final m = Map<String, dynamic>.from(e);
            final unitName = (m['unitName'] ?? '').toString().trim();
            if (unitName.isEmpty) continue;
            final mode = (m['operationMode'] ?? '').toString();
            if (!_isBnbUnit(mode, workspace)) continue;
            final unitId = (m['unitId'] ?? '').toString().trim();
            final id = unitId.isNotEmpty ? unitId : '__n:$unitName';
            if (!seen.add(id.toLowerCase())) continue;
            candidates.add(
              _BnbUnitCandidate(
                id: id,
                unitName: unitName,
              ),
            );
          }
        }
      } catch (_) {}
    }

    if (candidates.isEmpty && _propertyOffersBnb(workspace)) {
      final label = property.apartmentSuite.trim().isNotEmpty
          ? property.apartmentSuite.trim()
          : (property.propertyName.trim().isNotEmpty
              ? property.propertyName.trim()
              : property.propertyLocation.trim());
      if (label.isNotEmpty) {
        candidates.add(
          _BnbUnitCandidate(
            id: _wholePropertyUnitId,
            unitName: label,
            status: '',
          ),
        );
      }
    }

    final propertyTenants = tenants.where((t) => _tenantOnProperty(t, property, listingId));
    final listingIds = refs;
    final onlyUnit = candidates.length == 1;
    final free = <BookingUnitItem>[];
    for (final unit in candidates) {
      if (_isOccupiedUnit(
        unit: unit,
        listingIds: listingIds,
        occupied: occupied,
        tenants: propertyTenants,
        onlyUnitOnProperty: onlyUnit,
      )) {
        continue;
      }
      free.add(
        BookingUnitItem(
          id: unit.id,
          unitName: unit.unitName,
          maxGuests: unit.maxGuests,
        ),
      );
    }
    return free;
  }

  bool _propertyOffersBnb(String workspace) {
    return workspace.isEmpty || workspace == 'bnb' || workspace == 'both';
  }

  bool _isBnbUnit(String operationMode, String workspace) {
    final mode = operationMode.trim().toLowerCase();
    if (mode == 'rent') return false;
    if (workspace == 'rent') return mode == 'bnb' || mode == 'both';
    return mode.isEmpty || mode == 'bnb' || mode == 'both';
  }

  bool _tenantOnProperty(TenantRecord tenant, PropertyRecord property, String listingId) {
    final ref = tenant.propertyRef.trim();
    if (ref.isNotEmpty &&
        (ref == listingId ||
            ref == property.propertyRef.trim() ||
            ref == 'local_${property.id}' ||
            ref == 'legacy_${property.id}')) {
      return true;
    }
    final label = tenant.propertyLabel.trim().toLowerCase();
    final name = property.propertyName.trim().toLowerCase();
    return label.isNotEmpty && name.isNotEmpty && label == name;
  }

  bool _isOccupiedUnit({
    required _BnbUnitCandidate unit,
    required Set<String> listingIds,
    required _OccupiedStays occupied,
    required Iterable<TenantRecord> tenants,
    required bool onlyUnitOnProperty,
  }) {
    final status = unit.status.trim().toLowerCase();
    if (status == 'occupied' || status.contains('occupied')) return true;
    if (occupied.matchesUnit(
      listingIds: listingIds,
      unitId: unit.id == _wholePropertyUnitId ? '' : unit.id,
      unitName: unit.unitName,
      onlyUnitOnProperty: onlyUnitOnProperty,
    )) {
      return true;
    }
    final today = BnbStayBilling.dateOnly(DateTime.now());
    for (final tenant in tenants) {
      final unitId = tenant.apartmentUnitId.trim();
      final unitName = tenant.unitLabel.trim();
      final matches = unit.id == _wholePropertyUnitId ||
          (unitId.isNotEmpty && unitId == unit.id) ||
          (unitName.isNotEmpty &&
              unitName.toLowerCase() == unit.unitName.toLowerCase()) ||
          (onlyUnitOnProperty && unitId.isEmpty && unitName.isEmpty);
      if (!matches) continue;
      final start = DateTime.tryParse(tenant.leaseStartIso.trim()) ??
          DateTime.fromMillisecondsSinceEpoch(tenant.createdAtMs);
      final end = DateTime.tryParse(tenant.leaseEndIso.trim());
      if (end == null) return true;
      if (BnbStayBilling.dayInStay(today, start, end)) return true;
    }
    return false;
  }

  Future<List<TenantRecord>> _loadActiveTenants() async {
    try {
      if (!Get.isRegistered<TenantLocalDataSource>()) return const [];
      return Get.find<TenantLocalDataSource>().getActiveTenants();
    } catch (_) {
      return const [];
    }
  }

  Future<_OccupiedStays> _loadOccupiedStays() async {
    final stays = _OccupiedStays();
    final today = BnbStayBilling.dateOnly(DateTime.now());
    final merge = BnbBookingMerge(pending: PendingBookingsStore());

    void consider({
      required String listingId,
      required String checkInIso,
      required String checkOutIso,
      required bool inactive,
      String? unitRef,
    }) {
      if (inactive || listingId.trim().isEmpty) return;
      final checkIn = DateTime.tryParse(checkInIso.trim());
      final checkOut = DateTime.tryParse(checkOutIso.trim());
      if (checkIn == null || checkOut == null) return;
      if (!BnbStayBilling.dayInStay(today, checkIn, checkOut)) return;
      stays.add(
        listingId: listingId.trim(),
        unitRef: unitRef?.trim() ?? '',
      );
    }

    try {
      final res = await _repository.getAllBookings();
      final data = res.data;
      List<dynamic> rows = const [];
      if (data is Map && data['bookings'] is List) {
        rows = data['bookings'] as List;
      } else if (data is List) {
        rows = data;
      }
      for (final e in rows.whereType<Map>()) {
        final m = Map<String, dynamic>.from(e);
        final item = merge.fromApiMap(m);
        consider(
          listingId: item.listingId ?? '',
          checkInIso: item.checkInIso,
          checkOutIso: item.checkOutIso,
          inactive: item.isInactive,
          unitRef: _unitRefFromBookingMap(m),
        );
      }
    } catch (_) {}

    try {
      for (final raw in PendingBookingsStore().load()) {
        final m = Map<String, dynamic>.from(raw);
        consider(
          listingId: (m['listingId'] ?? '').toString(),
          checkInIso: (m['checkIn'] ?? '').toString(),
          checkOutIso: (m['checkOut'] ?? '').toString(),
          inactive: false,
          unitRef: _unitRefFromBookingMap(m),
        );
      }
    } catch (_) {}

    return stays;
  }

  String? _unitRefFromBookingMap(Map<String, dynamic> m) {
    for (final key in [
      'unitId',
      'propertyUnitRef',
      'unitRef',
      'roomId',
      'apartmentUnitId',
      'unitName',
    ]) {
      final value = (m[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _bookingUnitId(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isEmpty || id == _wholePropertyUnitId) return null;
    return id;
  }

  void selectUnit(String? unitId) {
    selectedUnitId.value = unitId;
    // Re-check guest count against the newly selected unit capacity.
    formKey.currentState?.validate();
  }

  Future<void> pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkInDate.value ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('en', 'GB'),
    );
    
    if (picked != null) {
      checkInDate.value = picked;
      checkInDateController.text = DateFormat(_dateFormat).format(picked);
      if (checkOutDate.value != null &&
          (checkOutDate.value!.isBefore(picked) ||
              checkOutDate.value!.isAtSameMomentAs(picked))) {
        checkOutDate.value = null;
        checkOutDateController.clear();
      }
      formKey.currentState?.validate();
    }
  }

  Future<void> pickCheckOut() async {
    final from = checkInDate.value ?? DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkOutDate.value ?? from.add(const Duration(days: 1)),
      firstDate: from,
      lastDate: from.add(const Duration(days: 365 * 2)),
      locale: const Locale('en', 'GB'),
    );

    if (picked != null) {
      checkOutDate.value = picked;
      checkOutDateController.text = DateFormat(_dateFormat).format(picked);
      formKey.currentState?.validate();
    }
  }

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  String? validateProperty(String? _) {
    final id = selectedListingId.value;
    if (id == null || id.isEmpty) {
      return _t('Please select a property', 'Tafadhali chagua mali');
    }
    return null;
  }

  String? validateUnit(String? _) {
    if (propertyUnits.length > 1 &&
        (selectedUnitId.value == null || selectedUnitId.value!.isEmpty)) {
      return _t(
        'Please select a property unit',
        'Tafadhali chagua unit ya jengo',
      );
    }
    return null;
  }

  String? validateCheckIn(String? _) {
    if (checkInDate.value == null) {
      return _t('Please select check-in date', 'Tafadhali chagua tarehe ya kuingia');
    }
    return null;
  }

  String? validateCheckOut(String? _) {
    if (checkOutDate.value == null) {
      return _t(
        'Please select check-out date',
        'Tafadhali chagua tarehe ya kutoka',
      );
    }
    final checkIn = checkInDate.value;
    if (checkIn != null &&
        (checkOutDate.value!.isBefore(checkIn) ||
            checkOutDate.value!.isAtSameMomentAs(checkIn))) {
      return _t(
        'Check-out must be after check-in',
        'Tarehe ya kutoka lazima iwe baada ya kuingia',
      );
    }
    return null;
  }

  String? validateNumberOfGuests(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t(
        'Number of guests is required',
        'Idadi ya wageni inahitajika',
      );
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 1) {
      return _t('Enter a valid number', 'Weka namba sahihi');
    }
    final cap = maxAllowedGuests;
    if (cap != null && n > cap) {
      return _t(
        'Maximum $cap guests allowed for this property',
        'Upeo ni wageni $cap kwa mali hii',
      );
    }
    if (cap == null && n > absoluteMaxGuests) {
      return _t(
        'Enter a realistic guest count (max $absoluteMaxGuests)',
        'Weka idadi ya wageni inayofaa (upeo $absoluteMaxGuests)',
      );
    }
    return null;
  }

  String? validateGuestPhone(String? value) {
    if (!sendPaymentLink.value) return null;
    if (value == null || value.trim().isEmpty) {
      return _t(
        'Enter guest phone number to send the payment link',
        'Weka namba ya simu ya mgeni kutuma kiungo cha malipo',
      );
    }
    return null;
  }

  String? validatePaymentLinkAmount(String? value) {
    if (!sendPaymentLink.value) return null;
    final amount = value?.trim() ?? '';
    if (amount.isEmpty) {
      final code = Get.find<CurrencyService>().inputSuffix;
      return _t(
        'Enter amount ($code) for the payment link',
        'Weka kiasi ($code) kwa kiungo cha malipo',
      );
    }
    final amountTzs = int.tryParse(amount.replaceAll(',', '')) ?? 0;
    if (amountTzs < _minSnippeAmountTzs) {
      return _t(
        'Minimum amount is ${Get.find<CurrencyService>().formatBase(_minSnippeAmountTzs)}',
        'Kiasi cha chini ni ${Get.find<CurrencyService>().formatBase(_minSnippeAmountTzs)}',
      );
    }
    return null;
  }

  Future<void> saveBooking() async {
    // All required-field checks are inline Form validators — no snackbars.
    if (!(formKey.currentState?.validate() ?? false)) {
      hapticValidationError();
      return;
    }
    final listingId = selectedListingId.value;
    if (listingId == null || listingId.isEmpty) return;
    if (checkInDate.value == null || checkOutDate.value == null) return;
    if (saving.value) return;
    rememberChoice(UiPreferenceKeys.addBookingListing, listingId);

    final guestPhone = guestPhoneController.text.trim();
    final guestName = guestNameController.text.trim();
    final checkIn = DateFormat(_isoDateFormat).format(checkInDate.value!);
    final checkOut = DateFormat(_isoDateFormat).format(checkOutDate.value!);
    final request = CreateBookingRequest(
      listingId: listingId,
      unitId: _bookingUnitId(selectedUnitId.value),
      guestName: guestName,
      checkIn: checkIn,
      checkOut: checkOut,
      numberOfGuests: int.tryParse(numberOfGuestsController.text.trim()) ?? 1,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      guestPhoneNumber: guestPhone.isEmpty ? null : guestPhone,
      idempotencyKey:
          'booking:create:$listingId:$checkIn:$checkOut:${guestName.toLowerCase()}',
    );

    saving.value = true;
    try {
      // TEMP: Meta WhatsApp send disabled — never send Snippe link via WhatsApp.
      sendPaymentLink.value = false;
      String? serverBookingId;
      if (sendPaymentLink.value) {
        final createRes = await _repository.createBooking(request);
        final ok = createRes.responseCode == null ||
            createRes.responseCode == '0' ||
            createRes.responseCode == '200' ||
            createRes.responseCode == '201';
        if (!ok) {
          throw Exception(createRes.message ?? 'Booking creation failed');
        }
        final data = createRes.data;
        if (data is Map<String, dynamic>) {
          serverBookingId = data['bookingId']?.toString();
        }
        if (serverBookingId == null || serverBookingId.isEmpty) {
          throw Exception('Booking created but no booking ID returned');
        }
      } else {
        await _syncQueue.enqueue(
          entityType: 'booking',
          operation: 'create',
          payloadJson: jsonEncode(request.toJson()),
          dedupeKey: request.idempotencyKey ??
              'booking:create:$listingId:$checkIn:$checkOut:${guestName.toLowerCase()}',
        );
        await _syncWorker.runNow(maxItems: 20);
      }
      _updatePendingCount();
      await HomeController.refreshIfRegistered();
      await AllBookingsController.refreshIfRegistered();
      if (sendPaymentLink.value &&
          guestPhone.isNotEmpty &&
          serverBookingId != null) {
        await _sendSnippePaymentLink(
          bookingId: serverBookingId,
          customerPhone: guestPhone,
          customerName: guestNameController.text.trim(),
          amountTzs: int.parse(
            pushToPayAmountController.text.trim().replaceAll(',', ''),
          ),
        );
      }
      await HostCalendarController.refreshIfRegistered();
      await DashboardController.refreshIfRegistered();
      await GuestAccessCodesController.refreshIfRegistered();
      hapticPrimaryConfirm();
      Get.back(result: true);
      if (sendPaymentLink.value) {
        Get.snackbar('Saved', 'Booking created and payment link sent via WhatsApp.');
      } else {
        final pending = pendingCount.value;
        if (pending > 0) {
          Get.snackbar(
            'Saved offline',
            'Booking saved on this device. Will sync when internet is available.',
          );
        } else {
          Get.snackbar('Saved', 'Booking synced successfully.');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save booking: $e');
    } finally {
      saving.value = false;
    }
  }

  Future<void> _sendSnippePaymentLink({
    required String bookingId,
    required String customerPhone,
    required String customerName,
    required int amountTzs,
  }) async {
    sendingPaymentLink.value = true;
    try {
      final property = listings
          .firstWhereOrNull((l) => l.id == selectedListingId.value)
          ?.propertyName;
      final result = await _paymentLinks.sendViaWhatsApp(
        SendPaymentLinkRequest(
          amount: amountTzs,
          customerName: customerName.isEmpty ? 'Guest' : customerName,
          customerPhone: customerPhone,
          bookingId: bookingId,
          description: property != null && property.isNotEmpty
              ? 'BnB booking — $property'
              : 'BnB booking',
        ),
      );
      if (!result.whatsappSuccess) {
        Get.snackbar(
          'WhatsApp',
          result.whatsappError ??
              'Payment link created but WhatsApp could not be sent.',
        );
      }
    } finally {
      sendingPaymentLink.value = false;
    }
  }

  void setSendPaymentLink(bool value) => sendPaymentLink.value = value;

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

  static const _wholePropertyUnitId = '__whole_property__';

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

class _BnbUnitCandidate {
  const _BnbUnitCandidate({
    required this.id,
    required this.unitName,
    this.maxGuests = 0,
    this.status = '',
  });

  final String id;
  final String unitName;
  final int maxGuests;
  final String status;
}

class _OccupiedStays {
  final _hits = <({String listingId, String unitRef})>[];

  void add({required String listingId, required String unitRef}) {
    final id = listingId.trim();
    if (id.isEmpty) return;
    _hits.add((listingId: id, unitRef: unitRef.trim()));
  }

  bool matchesUnit({
    required Set<String> listingIds,
    required String unitId,
    required String unitName,
    required bool onlyUnitOnProperty,
  }) {
    final ids = listingIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return false;
    final name = unitName.trim().toLowerCase();
    for (final hit in _hits) {
      if (!ids.contains(hit.listingId)) continue;
      final ref = hit.unitRef;
      if (ref.isEmpty) {
        if (onlyUnitOnProperty) return true;
        continue;
      }
      if (unitId.isNotEmpty && ref == unitId) return true;
      if (name.isNotEmpty && ref.toLowerCase() == name) return true;
    }
    return false;
  }
}
