import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/money_input_helper.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/model/record_payment_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../add_listing/models/apartment_unit_draft.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';

enum PaymentStatus { paid, pending }

class BookingPickerOption {
  const BookingPickerOption({
    required this.bookingKey,
    required this.label,
    required this.guestName,
  });

  final String bookingKey;
  final String label;
  final String guestName;
}

class RecordPaymentController extends BaseController {
  RecordPaymentController()
      : _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _pendingBookingsStore = PendingBookingsStore(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );

  final IncomeLocalDataSource _incomeLocal;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final AppRepository _repository;
  final PendingBookingsStore _pendingBookingsStore;
  final PreferenceManager _preferenceManager;

  final tenantController = TextEditingController();
  final amountController = TextEditingController();
  final datePaidController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Reused across rebuilds so opening the keyboard does not allocate a new
  /// [intl.NumberFormat] on every frame ([ThousandsSeparatorInputFormatter]).
  final ThousandsSeparatorInputFormatter amountThousandsFormatter =
  ThousandsSeparatorInputFormatter();

  /// Income category options (single selection).
  final categories = const ['Lease', 'Service Charge', 'Maintenance', 'Other'];
  final paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Mobile Money', 'Other'];

  final selectedCategoryIndex = 0.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;
  /// Optional apartment unit ([ApartmentUnitDraft.selectionKey]); null = not specified.
  final selectedIncomeUnitKey = Rxn<String>();
  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;
  /// Optional BnB booking ([CheckInItem.bookingKey]); null = not linked.
  final selectedBookingKey = Rxn<String>();
  final bookingOptions = <BookingPickerOption>[].obs;
  final loadingBookings = false.obs;
  final selectedPaymentMethod = Rx<String>('Cash');
  final paymentDate = Rx<DateTime>(DateTime.now());
  final status = PaymentStatus.paid.obs;
  final saving = false.obs;
  final syncing = false.obs;

  static const _dateFormat = 'dd/MM/yyyy';
  static const _isoDateFormat = 'yyyy-MM-dd';

  List<PropertyRecord> _propertyRows = [];

  int? _cachedUnitsPropertyId;
  String _cachedUnitsJsonSnapshot = '';
  List<ApartmentUnitDraft> _cachedIncomeUnits = const [];

  List<String> _propertyMenuSource = const [];
  List<DropdownMenuItem<String>> _propertyMenuItems = const [];
  Color? _propertyMenuFg;

  Object? _unitMenuItemsCacheKey;
  List<DropdownMenuItem<String?>> _cachedUnitMenuItems = const [];

  String get selectedCategory => categories[selectedCategoryIndex.value];
  bool get hasProperties => propertyOptions.isNotEmpty;

  String get paymentDateLabel => DateFormat(_dateFormat).format(paymentDate.value);

  void goBack() => Get.back();

  void selectPaymentMethod(String? value) {
    if (value != null) selectedPaymentMethod.value = value;
  }

  Future<void> pickPaymentDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: paymentDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) paymentDate.value = picked;
  }

  PropertyRecord? get selectedPropertyRecord {
    selectedProperty.value;
    final selected = selectedProperty.value.trim();
    if (selected.isEmpty) return null;
    for (final r in _propertyRows) {
      final suite = r.propertyName.trim();
      final fallback = r.propertyLocation.trim();
      if (suite == selected || fallback == selected) return r;
    }
    return null;
  }

  List<ApartmentUnitDraft> get incomeUnitsForSelectedProperty {
    selectedProperty.value;
    final r = selectedPropertyRecord;
    if (r == null) return const [];
    if (_cachedUnitsPropertyId != r.id ||
        _cachedUnitsJsonSnapshot != r.unitsJson) {
      _cachedUnitsPropertyId = r.id;
      _cachedUnitsJsonSnapshot = r.unitsJson;
      _cachedIncomeUnits = _parseUnitsJson(r.unitsJson);
      _unitMenuItemsCacheKey = null;
    }
    return _cachedIncomeUnits;
  }

  /// Cached menu rows — avoids rebuilding every [DropdownMenuItem] on each
  /// keyboard inset/layout pass (see [Obx] in the form view).
  List<DropdownMenuItem<String>> propertyDropdownMenuItems(Color itemColor) {
    final list = List<String>.from(propertyOptions);
    if (_propertyMenuFg != itemColor ||
        _propertyMenuSource.length != list.length ||
        !listEquals(_propertyMenuSource, list)) {
      _propertyMenuSource = list;
      _propertyMenuFg = itemColor;
      _propertyMenuItems = list
          .map(
            (p) => DropdownMenuItem<String>(
          value: p,
          child: Text(
            p,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: itemColor,
            ),
          ),
        ),
      )
          .toList();
    }
    return _propertyMenuItems;
  }

  List<DropdownMenuItem<String?>> unitIncomeDropdownMenuItems({
    required Color itemColor,
    required Color hintColor,
    required String optionalWholePropertyLabel,
  }) {
    final r = selectedPropertyRecord;
    final units = incomeUnitsForSelectedProperty;
    final cacheKey = Object.hash(
      r?.id ?? 0,
      r?.unitsJson.hashCode ?? 0,
      units.length,
      units.map((u) => u.selectionKey).join(','),
      optionalWholePropertyLabel,
      itemColor,
      hintColor,
    );
    if (_unitMenuItemsCacheKey == cacheKey) {
      return _cachedUnitMenuItems;
    }
    _unitMenuItemsCacheKey = cacheKey;
    _cachedUnitMenuItems = [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(
          optionalWholePropertyLabel,
          style: TextStyle(
            fontSize: 15,
            color: hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      ...units.map(
            (u) => DropdownMenuItem<String?>(
          value: u.selectionKey,
          child: Text(
            u.unitName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: itemColor,
            ),
          ),
        ),
      ),
    ];
    return _cachedUnitMenuItems;
  }

  bool get showIncomeUnitPicker {
    selectedProperty.value;
    final r = selectedPropertyRecord;
    if (r == null) return false;
    if (r.propertyType.trim().toLowerCase() != 'apartment') return false;
    return incomeUnitsForSelectedProperty.isNotEmpty;
  }

  Object? _bookingMenuItemsCacheKey;
  List<DropdownMenuItem<String?>> _cachedBookingMenuItems = const [];

  List<DropdownMenuItem<String?>> bookingDropdownMenuItems({
    required Color itemColor,
    required Color hintColor,
    required String optionalNoBookingLabel,
  }) {
    final options = List<BookingPickerOption>.from(bookingOptions);
    final cacheKey = Object.hash(
      options.length,
      options.map((o) => o.bookingKey).join(','),
      optionalNoBookingLabel,
      itemColor,
      hintColor,
    );
    if (_bookingMenuItemsCacheKey == cacheKey) {
      return _cachedBookingMenuItems;
    }
    _bookingMenuItemsCacheKey = cacheKey;
    _cachedBookingMenuItems = [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(
          optionalNoBookingLabel,
          style: TextStyle(
            fontSize: 15,
            color: hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      ...options.map(
        (o) => DropdownMenuItem<String?>(
          value: o.bookingKey,
          child: Text(
            o.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: itemColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
    return _cachedBookingMenuItems;
  }

  static List<ApartmentUnitDraft> _parseUnitsJson(String unitsJson) {
    final raw = unitsJson.trim();
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _optionalUnitNotesLine() {
    final key = selectedIncomeUnitKey.value?.trim();
    if (key == null || key.isEmpty) return '';
    for (final u in incomeUnitsForSelectedProperty) {
      if (u.selectionKey == key) {
        return 'Unit: ${u.unitName.trim()}';
      }
    }
    return '';
  }

  ApartmentUnitDraft? _draftForIncomeUnitKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    for (final u in incomeUnitsForSelectedProperty) {
      if (u.selectionKey == key) return u;
    }
    return null;
  }

  static bool _tenantMatchesProperty(
      TenantRecord t,
      PropertyRecord p,
      ) {
    final loc = p.propertyLocation.trim();
    final suite = p.propertyName.trim();
    final title = suite.isNotEmpty ? '$loc · $suite' : loc;
    final propertyRef = p.propertyRef.trim().isNotEmpty ? p.propertyRef.trim() : 'legacy_${p.id}';
    final r = t.propertyRef.trim();
    if (r.isNotEmpty) {
      return r == propertyRef;
    }
    final pl = t.propertyLabel.trim();
    if (pl == title) return true;
    if (pl == loc) return true;
    if (suite.isNotEmpty && pl == '$loc · $suite') return true;
    return false;
  }

  static bool _tenantMatchesUnit(
      TenantRecord t,
      ApartmentUnitDraft u,
      PropertyRecord p,
      ) {
    if (!_tenantMatchesProperty(t, p)) return false;
    final tid = t.apartmentUnitId.trim();
    final uid = u.unitId.trim();
    if (tid.isNotEmpty && uid.isNotEmpty) return tid == uid;
    return t.unitLabel.trim() == u.unitName.trim();
  }

  Future<void> _syncTenantFieldToSelectedUnit() async {
    final key = selectedIncomeUnitKey.value?.trim();
    final prop = selectedPropertyRecord;
    if (key == null || key.isEmpty || prop == null) {
      return;
    }
    final unit = _draftForIncomeUnitKey(key);
    if (unit == null) return;

    final tenants = await _tenantLocal.getAllNewestFirst();
    for (final t in tenants) {
      if (_tenantMatchesUnit(t, unit, prop)) {
        tenantController.text = t.tenantName.trim();
        return;
      }
    }
    tenantController.clear();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initForm());
  }

  Future<void> _initForm() async {
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    final presetBooking = _routeBookingId();
    if (presetBooking.isNotEmpty) {
      selectedBookingKey.value = presetBooking;
    }
    await _loadProperties();
    await _loadBookingsForSelectedProperty();
    final preset = selectedBookingKey.value?.trim();
    if (preset != null && preset.isNotEmpty) {
      updateSelectedBooking(preset);
    }
  }

  void selectCategory(int index) {
    if (index >= 0 && index < categories.length) {
      selectedCategoryIndex.value = index;
    }
  }

  Future<void> _loadProperties() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: 'bnb',
    );
    _cachedUnitsPropertyId = null;
    _cachedUnitsJsonSnapshot = '';
    _cachedIncomeUnits = const [];
    _unitMenuItemsCacheKey = null;
    _propertyRows = rows;
    final options = rows
        .map((e) {
      final suite = e.propertyName.trim();
      return suite.isNotEmpty ? suite : e.propertyLocation.trim();
    })
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    propertyOptions.assignAll(options);

    final fromArgs = _routePropertyLabel();
    final fromRoute =
    fromArgs.isNotEmpty ? fromArgs : (Get.parameters['property']?.trim() ?? '');
    if (fromRoute.isNotEmpty && options.contains(fromRoute)) {
      selectedProperty.value = fromRoute;
      return;
    }
    if (options.length == 1) {
      selectedProperty.value = options.first;
    }
  }

  void updateSelectedProperty(String? value) {
    if (value == null) return;
    selectedIncomeUnitKey.value = null;
    final presetBooking = _routeBookingId();
    if (presetBooking.isEmpty) {
      selectedBookingKey.value = null;
    }
    selectedProperty.value = value;
    tenantController.clear();
    unawaited(_loadBookingsForSelectedProperty());
  }

  void updateSelectedBooking(String? bookingKey) {
    selectedBookingKey.value =
        bookingKey == null || bookingKey.trim().isEmpty ? null : bookingKey.trim();
    if (bookingKey == null || bookingKey.trim().isEmpty) return;
    for (final o in bookingOptions) {
      if (o.bookingKey == bookingKey) {
        final guest = o.guestName.trim();
        if (guest.isNotEmpty) {
          tenantController.text = guest;
        }
        return;
      }
    }
  }

  bool _bookingMatchesProperty(CheckInItem item, PropertyRecord property) {
    final listing = (item.listingId ?? '').trim();
    final ref = property.propertyRef.trim();
    final legacy = 'legacy_${property.id}';
    final local = 'local_${property.id}';
    if (listing.isNotEmpty) {
      if (ref.isNotEmpty && listing == ref) return true;
      if (listing == legacy || listing == local) return true;
    }
    final label = property.propertyName.trim().isNotEmpty
        ? property.propertyName.trim()
        : property.propertyLocation.trim();
    return label.isNotEmpty && item.propertyType.trim() == label;
  }

  static bool _isActiveOrUpcoming(CheckInItem item) {
    if (item.isInactive) return false;
    final co = DateTime.tryParse(item.checkOutIso);
    if (co == null) return true;
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day);
    final checkOutDay = DateTime(co.year, co.month, co.day);
    return !checkOutDay.isBefore(endOfToday);
  }

  Future<void> _loadBookingsForSelectedProperty() async {
    final prop = selectedPropertyRecord;
    if (prop == null) {
      bookingOptions.clear();
      return;
    }

    loadingBookings.value = true;
    try {
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
        for (final m in _pendingBookingsStore.load()) {
          final listingId = (m['listingId'] ?? '').toString().trim();
          final checkIn = (m['checkIn'] ?? '').toString();
          final checkOut = (m['checkOut'] ?? '').toString();
          if (listingId.isEmpty || checkIn.isEmpty || checkOut.isEmpty) continue;
          final propertyLabel = prop.propertyName.trim().isNotEmpty
              ? prop.propertyName.trim()
              : prop.propertyLocation.trim();
          final localId = 'local_${m['createdAt'] ?? '${listingId}_$checkIn'}';
          final item = merge.fromPendingMap(
            m,
            propertyLabel: propertyLabel.isNotEmpty ? propertyLabel : 'Property',
            localId: localId,
          );
          merged[localId] = item;
        }
      } catch (_) {}

      final options = <BookingPickerOption>[];
      for (final item in merged.values) {
        if (!_bookingMatchesProperty(item, prop)) continue;
        if (!_isActiveOrUpcoming(item)) continue;
        final guest = item.guestName.trim().isEmpty ? 'Guest' : item.guestName.trim();
        final dates = item.dates.trim();
        options.add(
          BookingPickerOption(
            bookingKey: item.bookingKey,
            guestName: guest,
            label: dates.isEmpty ? guest : '$guest • $dates',
          ),
        );
      }
      options.sort((a, b) => a.label.compareTo(b.label));
      bookingOptions.assignAll(options);

      final preset = selectedBookingKey.value?.trim() ?? _routeBookingId();
      if (preset.isNotEmpty &&
          options.every((o) => o.bookingKey != preset) &&
          _routeBookingId().isNotEmpty) {
        bookingOptions.insert(
          0,
          BookingPickerOption(
            bookingKey: preset,
            guestName: tenantController.text.trim(),
            label: tenantController.text.trim().isNotEmpty
                ? tenantController.text.trim()
                : preset,
          ),
        );
      }
    } finally {
      loadingBookings.value = false;
    }
  }

  void updateSelectedIncomeUnit(String? unitKey) {
    selectedIncomeUnitKey.value = unitKey;
    if (unitKey == null || unitKey.trim().isEmpty) {
      return;
    }
    _syncTenantFieldToSelectedUnit();
  }

  String _routePropertyLabel() {
    final args = Get.arguments;
    if (args is Map) {
      for (final key in ['property', 'property_name']) {
        final v = (args[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return '';
  }

  String _routeBookingId() {
    final fromParams = Get.parameters['bookingId']?.trim() ?? '';
    if (fromParams.isNotEmpty) return fromParams;
    final args = Get.arguments;
    if (args is Map) {
      for (final key in ['bookingId', 'booking_id', 'bookingKey']) {
        final v = (args[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return '';
  }

  String? _selectedBookingIdForSave() {
    final key = selectedBookingKey.value?.trim();
    if (key != null && key.isNotEmpty) return key;
    return null;
  }

  /// Persisted on each income row so listing details can sum revenue by property.
  String _propertyRefForIncomeInsert() {
    final args = Get.arguments;
    if (args is Map) {
      for (final key in ['propertyRef', 'property_ref', 'property_id']) {
        final v = (args[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    final fromRoute = Get.parameters['propertyRef']?.trim() ?? '';
    if (fromRoute.isNotEmpty) return fromRoute;
    final r = selectedPropertyRecord;
    if (r == null) return '';
    final ref = r.propertyRef.trim();
    if (ref.isNotEmpty) return ref;
    return 'legacy_${r.id}';
  }

  Future<void> saveIncomeOffline() async {
    if (saving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedProperty.value.trim().isEmpty) {
      showErrorMessage('Please select a property');
      return;
    }

    final tenant = tenantController.text.trim();
    final amountRaw = amountController.text.trim().replaceAll(',', '');
    final dateRaw = datePaidController.text.trim();
    final notes = notesController.text.trim();
    final property = selectedProperty.value.trim();

    final parsed = MoneyInputHelper.forSave(
      amountRaw: amountRaw,
      selectedCurrency: selectedCurrency.value,
    );
    if (parsed.inputAmount <= 0) {
      showErrorMessage('Enter a valid amount greater than 0');
      return;
    }

    DateTime paidDate;
    try {
      paidDate = DateFormat('dd/MM/yyyy').parseStrict(dateRaw);
    } catch (_) {
      showErrorMessage('Use date format dd/MM/yyyy');
      return;
    }

    final unitDraft = _draftForIncomeUnitKey(selectedIncomeUnitKey.value);
    final unitName = unitDraft?.unitName.trim() ?? '';
    final unitLine = _optionalUnitNotesLine();
    final baseNotes = StringBuffer('Property: $property');
    if (unitLine.isNotEmpty) {
      baseNotes.write(", ");
      baseNotes.writeln(unitLine);
    }
    if (notes.isNotEmpty) {
      baseNotes.write(" ");
      baseNotes.writeln(notes);
    }

    final bookingId = _selectedBookingIdForSave() ?? '';

    saving.value = true;
    try {
      await _incomeLocal.insert(
        tenantName: tenant,
        amountValue: parsed.baseAmount,
        datePaidIso: DateFormat('yyyy-MM-dd').format(paidDate),
        category: selectedCategory,
        workspaceType: 'bnb',
        notes: baseNotes.toString().trim(),
        apartment: property,
        apartmentUnit: unitName,
        propertyRef: _propertyRefForIncomeInsert(),
        bookingId: bookingId,
        currencyCode: parsed.currency,
        inputAmountValue: parsed.inputAmount,
      );

      final request = RecordPaymentRequest(
        amount: parsed.baseAmount,
        paymentMethod: selectedPaymentMethod.value,
        bookingId: bookingId.isEmpty ? null : bookingId,
        paymentDate: DateFormat(_isoDateFormat).format(paidDate),
        status: status.value == PaymentStatus.paid ? 'PAID' : 'PENDING',
      );
      await _syncQueue.enqueue(
        entityType: 'payment',
        operation: 'create',
        payloadJson: jsonEncode(request.toJson()),
      );
      await _syncWorker.runNow(maxItems: 20);
      final pending = await _syncQueue.pendingCountByEntity(
        entityType: 'payment',
        operation: 'create',
      );
      if (pending > 0) {
        showSuccessMessage(
            'Income saved offline. Will sync when internet is available.');
      } else {
        showSuccessMessage('Income saved and synced.');
      }
      await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
      Get.back(result: true);
    } catch (e) {
      showErrorMessage('Failed to save income: $e');
    } finally {
      saving.value = false;
    }
  }

  String? validateTenant(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Tenant is required';
    if (v.length < 2) return 'Enter a valid tenant name';
    return null;
  }

  String? validateAmount(String? value) {
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Amount is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validateDatePaid(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Date paid is required';
    try {
      DateFormat('dd/MM/yyyy').parseStrict(v);
      return null;
    } catch (_) {
      return 'Use dd/MM/yyyy';
    }
  }

  String? validateSelectedProperty(String? value) {
    if (!hasProperties) return null;
    final v = (value ?? selectedProperty.value).trim();
    if (v.isEmpty) return 'Property is required';
    return null;
  }

  @override
  void onClose() {
    tenantController.dispose();
    amountController.dispose();
    datePaidController.dispose();
    notesController.dispose();
    super.onClose();
  }
  // RecordPaymentController()
  //     : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
  //       _preferenceManager = Get.find<PreferenceManager>(tag: (PreferenceManager).toString()),
  //       _pendingStore = PendingPaymentsStore();
  //
  // final AppRepository _repository;
  // final PreferenceManager _preferenceManager;
  // final PendingPaymentsStore _pendingStore;
  // StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  //
  // final formKey = GlobalKey<FormState>();
  // final amountController = TextEditingController();
  // final linkedBookingController = TextEditingController();
  //
  // final selectedPaymentMethod = Rx<String>('Cash');
  // final paymentDate = Rx<DateTime>(DateTime.now());
  // final status = PaymentStatus.paid.obs;
  // final saving = false.obs;
  // final syncing = false.obs;
  //
  // static const _dateFormat = 'MM/dd/yyyy';
  // static const _isoDateFormat = 'yyyy-MM-dd';
  //
  // final paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Mobile Money', 'Other'];
  //
  // String get paymentDateLabel => DateFormat(_dateFormat).format(paymentDate.value);
  //
  // void goBack() => Get.back();
  //
  // void selectPaymentMethod(String? value) {
  //   if (value != null) selectedPaymentMethod.value = value;
  // }
  //
  // Future<void> pickPaymentDate() async {
  //   final picked = await showDatePicker(
  //     context: Get.context!,
  //     initialDate: paymentDate.value,
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //   );
  //   if (picked != null) paymentDate.value = picked;
  // }
  //
  // void setStatus(PaymentStatus value) {
  //   status.value = value;
  // }
  //
  // @override
  // void onReady() {
  //   super.onReady();
  //   _syncPendingWhenOnline();
  //   _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
  //     if (results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
  //       _syncPendingWhenOnline();
  //     }
  //   });
  // }
  //
  // Future<bool> _isOnline() async {
  //   final results = await Connectivity().checkConnectivity();
  //   return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
  // }
  //
  // Future<void> _syncPendingWhenOnline() async {
  //   if (syncing.value) return;
  //   if (!await _isOnline()) return;
  //   final list = _pendingStore.load();
  //   if (list.isEmpty) return;
  //   syncing.value = true;
  //   try {
  //     final toKeep = <Map<String, dynamic>>[];
  //     var synced = 0;
  //     for (final item in list) {
  //       try {
  //         final request = RecordPaymentRequest.fromJson(item);
  //         final res = await _repository.recordPayment(request);
  //         if (res.responseCode == '200' || res.responseCode == '201') {
  //           synced++;
  //         } else {
  //           toKeep.add(item);
  //         }
  //       } catch (_) {
  //         toKeep.add(item);
  //       }
  //     }
  //     await _pendingStore.save(toKeep);
  //     if (synced > 0) {
  //       if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  //       Get.snackbar('Synced', synced == 1 ? 'Offline payment synced.' : '$synced offline payments synced.');
  //     }
  //   } finally {
  //     syncing.value = false;
  //   }
  // }
  //
  // Future<void> recordPayment() async {
  //   if (!(formKey.currentState?.validate() ?? false)) return;
  //   final amountText = amountController.text.trim().replaceFirst(RegExp(r'^(TZS|\$)\s*'), '').trim();
  //   final amount = double.tryParse(amountText);
  //   if (amount == null || amount <= 0) {
  //     Get.snackbar('Invalid amount', 'Please enter a valid amount');
  //     return;
  //   }
  //   if (saving.value) return;
  //
  //   final request = RecordPaymentRequest(
  //     amount: amount,
  //     paymentMethod: selectedPaymentMethod.value,
  //     bookingId: linkedBookingController.text.trim().isEmpty
  //         ? null
  //         : linkedBookingController.text.trim(),
  //     paymentDate: DateFormat(_isoDateFormat).format(paymentDate.value),
  //     status: status.value == PaymentStatus.paid ? 'PAID' : 'PENDING',
  //   );
  //
  //   saving.value = true;
  //   try {
  //     final online = await _isOnline();
  //     if (!online) {
  //       await _pendingStore.add(request.toJson());
  //       Get.back();
  //       Get.snackbar(
  //         'Saved offline',
  //         'Payment will sync when you\'re back online.',
  //         duration: const Duration(seconds: 4),
  //       );
  //       saving.value = false;
  //       return;
  //     }
  //     await _syncPendingWhenOnline();
  //     final token = await _preferenceManager.getString(PreferenceManager.keyToken, defaultValue: '');
  //     if (token.isEmpty) {
  //       Get.snackbar(
  //         'Login required',
  //         'Please log in to record payments.',
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //       Get.offAllNamed(Routes.AUTH);
  //       saving.value = false;
  //       return;
  //     }
  //     final res = await _repository.recordPayment(request);
  //     if (res.responseCode == '201' || res.responseCode == '200') {
  //       Get.back();
  //       Get.snackbar('Success', 'Payment recorded');
  //     } else {
  //       Get.snackbar('Error', res.message ?? 'Could not record payment');
  //     }
  //   } on UnauthorizedException catch (_) {
  //     Get.snackbar(
  //       'Session expired',
  //       'Please log in again to record payments.',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //     Get.offAllNamed(Routes.AUTH);
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to record payment: $e');
  //   } finally {
  //     saving.value = false;
  //   }
  // }
  //
  // @override
  // void onClose() {
  //   _connectivitySubscription?.cancel();
  //   amountController.dispose();
  //   linkedBookingController.dispose();
  //   super.onClose();
  // }
}
