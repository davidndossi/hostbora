import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/utils/money_input_helper.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/lease_income_extension.dart';
import '../../../data/local/service/tenant_lease_remote_sync.dart';
import '../../../data/local/bnb_booking_merge.dart';
import '../../../data/local/bnb_booking_pending_loader.dart';
import '../../../data/local/db/client_event_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/pending_bookings_store.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/service/property_break_even_notification_service.dart';
import '../../../data/local/service/remote_account_sync_service.dart';
import '../../../data/model/check_in_item.dart';
import '../../../data/model/record_payment_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../add_listing/models/apartment_unit_draft.dart';
import '../../booking_details/controllers/booking_details_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../rent/tenant_ledger_occupancy/controllers/rent_tenant_ledger_occupancy_controller.dart';
import '../../rent/tenant_ledger_occupancy/utils/tenant_ledger_finance.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../../../data/service/analytics_service.dart';
import '../../../core/constants/ui_preference_keys.dart';
import '../../../core/utils/form_recall.dart';

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

class RecordPaymentController extends BaseController with FormRecallMixin {
  RecordPaymentController()
    : _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _tenantLocal = Get.find<TenantLocalDataSource>(),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>(),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _pendingBookingsStore = PendingBookingsStore(),
      _pendingBookingLoader = BnbBookingPendingLoader(
        syncQueue: Get.find<OfflineSyncQueueLocalDataSource>(),
      ),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );

  final IncomeLocalDataSource _incomeLocal;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final _clientEventLocal = Get.find<ClientEventLocalDataSource>();
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final AppRepository _repository;
  final PendingBookingsStore _pendingBookingsStore;
  final BnbBookingPendingLoader _pendingBookingLoader;
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
  final paymentMethods = [
    'Cash',
    'Card',
    'Bank Transfer',
    'Mobile Money',
    'Other',
  ];

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

  int? _linkedTenantId;

  String get selectedCategory => categories[selectedCategoryIndex.value];
  bool get hasProperties => propertyOptions.isNotEmpty;

  String get paymentDateLabel =>
      DateFormat(_dateFormat).format(paymentDate.value);

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
      locale: const Locale('en', 'GB'),
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
      options.map((o) => '${o.bookingKey}#${o.label}').join(','),
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
    final want = key.trim();
    final lower = want.toLowerCase();
    for (final u in incomeUnitsForSelectedProperty) {
      if (u.selectionKey == want) return u;
      if (u.unitId.trim() == want) return u;
      if (u.unitName.trim().toLowerCase() == lower) return u;
    }
    return null;
  }

  String _workspaceForIncomeSave(ApartmentUnitDraft? unitDraft) {
    final propertyMode = _normalizeWorkspace(
      selectedPropertyRecord?.workspaceType,
    );
    if (propertyMode == 'both') {
      return _normalizeWorkspace(unitDraft?.operationMode, fallback: 'bnb');
    }
    return propertyMode;
  }

  String _normalizeWorkspace(String? raw, {String fallback = 'bnb'}) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value == 'bnb' || value == 'rent' || value == 'both') {
      return value;
    }
    return fallback;
  }

  static bool _tenantMatchesProperty(TenantRecord t, PropertyRecord p) {
    final loc = p.propertyLocation.trim();
    final suite = p.propertyName.trim();
    final title = suite.isNotEmpty ? '$loc · $suite' : loc;
    final refs = <String>{
      if (p.propertyRef.trim().isNotEmpty) p.propertyRef.trim(),
      'legacy_${p.id}',
      'local_${p.id}',
    };
    final r = t.propertyRef.trim();
    if (r.isNotEmpty && refs.contains(r)) return true;
    if (r.isNotEmpty) return false;
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

  /// BnB income with no active guest on that unit. A linked booking already
  /// has a guest, so it does not ask again.
  Future<({String place, ApartmentUnitDraft? unit})?> _bnbGuestPromptTarget({
    required ApartmentUnitDraft? unit,
    required String bookingId,
  }) async {
    if (bookingId.trim().isNotEmpty) return null;
    if (_workspaceForIncomeSave(unit) != 'bnb') return null;
    final prop = selectedPropertyRecord;
    if (prop == null) return null;

    var target = unit;
    if (target == null && incomeUnitsForSelectedProperty.length == 1) {
      final only = incomeUnitsForSelectedProperty.first;
      if (_workspaceForIncomeSave(only) == 'bnb') target = only;
    }
    if (target == null && incomeUnitsForSelectedProperty.length > 1) {
      return null;
    }

    final tenants = await _tenantLocal.getActiveTenants();
    final hasGuest = target == null
        ? tenants.any((t) => _tenantMatchesProperty(t, prop))
        : tenants.any((t) => _tenantMatchesUnit(t, target!, prop));
    if (hasGuest) return null;

    final place = target != null && target.unitName.trim().isNotEmpty
        ? target.unitName.trim()
        : selectedProperty.value.trim();
    if (place.isEmpty) return null;
    return (place: place, unit: target);
  }

  Future<bool?> _promptAddGuestAfterBnbIncome(String place) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(appLocalization.bnbIncomeAddGuestPromptTitle),
        content: Text(appLocalization.bnbIncomeAddGuestPromptBody(place)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appLocalization.bnbIncomeAddGuestPromptLater),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(appLocalization.bnbIncomeAddGuestPromptAdd),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Map<String, dynamic> _guestNavigationArgs({
    required ApartmentUnitDraft? unit,
    required String guestName,
  }) {
    final ref = _propertyRefForIncomeInsert();
    final property = selectedProperty.value.trim();
    final unitId = unit?.unitId.trim() ?? '';
    final unitName = unit?.unitName.trim() ?? '';
    final name = guestName.trim();
    return {
      if (property.isNotEmpty) 'property': property,
      if (ref.isNotEmpty) 'propertyRef': ref,
      'workspaceType': 'bnb',
      if (unitId.isNotEmpty) 'unitId': unitId,
      if (unitName.isNotEmpty) 'unitName': unitName,
      if (name.isNotEmpty) 'guestName': name,
    };
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
        _linkedTenantId ??= t.id;
        expectedRent.value = t.rentAmountValue;
        return;
      }
    }
    if (tenantController.text.trim().isEmpty && _linkedTenantId == null) {
      tenantController.clear();
      expectedRent.value = 0;
    }
  }

  /// Rent on the lease behind the selected unit, or 0 when no tenant resolves.
  ///
  /// Drives the amount presets. It is the contracted figure rather than a
  /// round number, which is what makes a one-tap "full rent" chip safe to
  /// offer against a field that files money.
  final expectedRent = 0.0.obs;

  /// Writes a preset into the amount field, formatted the way the field's own
  /// thousands formatter would leave it so the two never disagree.
  void applyAmountPreset(double amount) {
    if (amount <= 0) return;
    final formatted = amountThousandsFormatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: amount.toStringAsFixed(0)),
    );
    amountController.value = formatted.copyWith(
      selection: TextSelection.collapsed(offset: formatted.text.length),
    );
  }

  /// Lease payments cover whole rent periods. 1,200,000 against a 200,000
  /// monthly rent adds 6 months, starting from the current lease end even
  /// when that date is already past.
  Future<String?> _extendTenancyForIncome({
    required String tenantName,
    required int? tenantId,
    required ApartmentUnitDraft? unit,
    required double inputAmount,
    required String inputCurrency,
    required int incomeId,
  }) async {
    if (selectedCategory != 'Lease') return null;
    try {
      final tenant = await _tenantForIncome(
        tenantName: tenantName,
        tenantId: tenantId,
        unit: unit,
      );
      if (tenant == null) return null;
      final rate = _periodicRent(tenant, unit);
      if (rate == null || rate.amount <= 0) return null;
      final periods = (_paidPeriods(
        paidAmount: inputAmount,
        paidCurrency: inputCurrency,
        rentAmount: rate.amount,
        rentCurrency: rate.currency,
      )).floor();
      if (periods <= 0) return null;

      final end = _parseLeaseDay(tenant.leaseEndIso) ??
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
      final nextEnd = _advanceByFrequency(end, rate.frequency, periods);
      final nextEndIso = DateFormat('yyyy-MM-dd').format(nextEnd);
      await _tenantLocal.updateLeaseTerms(
        id: tenant.id,
        rentAmountValue: tenant.rentAmountValue,
        leaseStartIso: tenant.leaseStartIso,
        leaseEndIso: nextEndIso,
      );
      await TenantLeaseRemoteSync.push(
        tenant: tenant,
        leaseEndIso: nextEndIso,
      );
      if (incomeId > 0) {
        await LeaseIncomeExtension.markApplied(incomeId);
      }
      return 'Tenancy extended by $periods ${_periodLabel(rate.frequency)}.';
    } catch (_) {
      return null;
    }
  }

  Future<TenantRecord?> _tenantForIncome({
    required String tenantName,
    required int? tenantId,
    required ApartmentUnitDraft? unit,
  }) async {
    if (tenantId != null && tenantId > 0) {
      final byId = await _tenantLocal.findById(tenantId);
      if (byId != null) return byId;
    }
    final prop = selectedPropertyRecord;
    final tenants = await _tenantLocal.getAllNewestFirst();
    if (prop != null && unit != null) {
      for (final t in tenants) {
        if (_tenantMatchesUnit(t, unit, prop)) return t;
      }
    }
    final name = tenantName.trim().toLowerCase();
    if (name.isEmpty) return null;
    final named = tenants
        .where((t) => t.tenantName.trim().toLowerCase() == name)
        .toList();
    if (named.isEmpty) return null;
    if (prop != null) {
      final onProperty =
          named.where((t) => _tenantMatchesProperty(t, prop)).toList();
      if (onProperty.isNotEmpty) return onProperty.first;
    }
    return named.first;
  }

  ({double amount, String frequency, String currency})? _periodicRent(
    TenantRecord tenant,
    ApartmentUnitDraft? unit,
  ) {
    final freq = tenant.rentFrequency.trim();
    if (_isRepeatingRent(freq) && tenant.rentAmountValue > 0) {
      return (
        amount: tenant.rentAmountValue,
        frequency: freq,
        currency: tenant.rentCurrency,
      );
    }
    if (unit != null) {
      final amount = double.tryParse(unit.unitRent.replaceAll(',', '').trim());
      final unitFreq = unit.unitRentFrequency.trim();
      if (amount != null && amount > 0 && _isRepeatingRent(unitFreq)) {
        return (
          amount: amount,
          frequency: unitFreq,
          currency: unit.unitRentCurrency,
        );
      }
    }
    return null;
  }

  static bool _isRepeatingRent(String frequency) {
    final value = frequency.trim().toLowerCase();
    return value.contains('month') ||
        value.contains('week') ||
        value.contains('year') ||
        value.contains('day') ||
        value.contains('night');
  }

  double _paidPeriods({
    required double paidAmount,
    required String paidCurrency,
    required double rentAmount,
    required String rentCurrency,
  }) {
    if (rentAmount <= 0 || paidAmount <= 0) return 0;
    final paid = paidCurrency.trim().toUpperCase();
    final rent = rentCurrency.trim().toUpperCase();
    if (paid.isEmpty || rent.isEmpty || paid == rent) {
      return paidAmount / rentAmount;
    }
    final cs = Get.find<CurrencyService>();
    final paidBase = cs.toBaseAmount(
      inputAmount: paidAmount,
      inputCurrency: paid,
    );
    final rentBase = cs.toBaseAmount(
      inputAmount: rentAmount,
      inputCurrency: rent,
    );
    if (rentBase <= 0) return 0;
    return paidBase / rentBase;
  }

  static DateTime? _parseLeaseDay(String raw) {
    final text = raw.trim();
    if (text.length < 10) return null;
    final y = int.tryParse(text.substring(0, 4));
    final m = int.tryParse(text.substring(5, 7));
    final d = int.tryParse(text.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  static DateTime _advanceByFrequency(
    DateTime base,
    String frequency,
    int units,
  ) {
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
      case 'per night':
        return base.add(Duration(days: units));
      case 'per week':
        return base.add(Duration(days: units * 7));
      case 'per year':
        return DateTime(base.year + units, base.month, base.day);
      case 'per month':
      default:
        return DateTime(base.year, base.month + units, base.day);
    }
  }

  static String _periodLabel(String frequency) {
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
      case 'per night':
        return frequency.toLowerCase().contains('night') ? 'nights' : 'days';
      case 'per week':
        return 'weeks';
      case 'per year':
        return 'years';
      case 'per month':
      default:
        return 'months';
    }
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initForm());
  }

  Future<void> _initForm() async {
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    // Payments are almost always recorded on the day they are received, and a
    // blank field here hard-blocks the save on a format error.
    if (datePaidController.text.trim().isEmpty) {
      datePaidController.text = DateFormat(_dateFormat).format(paymentDate.value);
    }
    // Prefer an explicit route workspace; otherwise load every workspace so
    // rent-only hosts are not stuck with an empty "bnb"-filtered dropdown.
    final routeWorkspace = Get.parameters['workspaceType']?.toString().trim();
    final String workspace;
    if (routeWorkspace != null && routeWorkspace.isNotEmpty) {
      workspace = _normalizeWorkspace(routeWorkspace);
    } else if (selectedPropertyRecord != null) {
      workspace = _normalizeWorkspace(selectedPropertyRecord?.workspaceType);
    } else {
      workspace = 'all';
    }
    final presetBooking = _routeBookingId();
    if (presetBooking.isNotEmpty) {
      selectedBookingKey.value = presetBooking;
    }
    await _loadProperties(workspace);
    // Properties page merges remote listings; income form is local-only.
    // If local is empty, pull remote then reload once.
    if (propertyOptions.isEmpty) {
      try {
        if (Get.isRegistered<RemoteAccountSyncService>()) {
          await Get.find<RemoteAccountSyncService>().syncPropertiesFromRemote();
        }
      } catch (_) {}
      await _loadProperties(workspace);
    }
    await _loadBookingsForSelectedProperty();
    final preset = selectedBookingKey.value?.trim();
    if (preset != null && preset.isNotEmpty) {
      updateSelectedBooking(preset);
    }
    await _applyIncomePrefill();
  }

  void selectCategory(int index) {
    if (index >= 0 && index < categories.length) {
      selectedCategoryIndex.value = index;
    }
  }

  Future<void> _loadProperties(String workspace) async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    var rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspace,
    );
    // Owner-id mismatch can hide rows that My Properties still shows via
    // remote merge — fall back to unscoped local rows before giving up.
    if (rows.isEmpty && userId.isNotEmpty) {
      rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: workspace,
      );
    }
    if (rows.isEmpty) {
      rows = await _propertyLocal.getAllNewestFirst();
    }
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
    final fromRoute = fromArgs.isNotEmpty
        ? fromArgs
        : (Get.parameters['property']?.trim() ?? '');
    if (fromRoute.isNotEmpty && options.contains(fromRoute)) {
      selectedProperty.value = fromRoute;
      return;
    }
    // Left blank with two or more properties and no recall: an arbitrary
    // pre-selection here would file money against the wrong building, which
    // is worse than one extra tap.
    selectedProperty.value = await recallChoice(
      key: UiPreferenceKeys.recordPaymentProperty,
      options: options,
    );
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
    selectedBookingKey.value = bookingKey == null || bookingKey.trim().isEmpty
        ? null
        : bookingKey.trim();
    if (bookingKey == null || bookingKey.trim().isEmpty) return;
    for (final o in bookingOptions) {
      if (o.bookingKey == bookingKey) {
        final guest = o.guestName.trim();
        if (guest.isNotEmpty && !_looksLikeInternalBookingId(guest)) {
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

  static bool _looksLikeInternalBookingId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    return value.startsWith('local_sync_') ||
        value.startsWith('local_') ||
        value.startsWith('legacy_');
  }

  static String _bookingPickerLabel({
    required String guestName,
    required String dates,
  }) {
    var guest = guestName.trim();
    if (guest.isEmpty || _looksLikeInternalBookingId(guest)) {
      guest = 'Guest';
    }
    final datePart = dates.trim();
    return datePart.isEmpty ? guest : '$guest • $datePart';
  }

  static bool _itemMatchesBookingKey(CheckInItem item, String key) {
    final wanted = key.trim();
    if (wanted.isEmpty) return false;
    if (item.bookingKey == wanted) return true;
    if ((item.bookingId ?? '').trim() == wanted) return true;
    if (item.guestCheckInKey == wanted) return true;
    final queueId = item.syncQueueId;
    return queueId != null && wanted == 'local_sync_$queueId';
  }

  BookingPickerOption _optionFromBooking(
    CheckInItem item, {
    String? bookingKey,
  }) {
    final guest = item.guestName.trim();
    return BookingPickerOption(
      bookingKey: (bookingKey ?? item.bookingKey).trim(),
      guestName: guest,
      label: _bookingPickerLabel(guestName: guest, dates: item.dates),
    );
  }

  CheckInItem? _findMergedBooking(
    Iterable<CheckInItem> items,
    String bookingKey,
  ) {
    for (final item in items) {
      if (_itemMatchesBookingKey(item, bookingKey)) return item;
    }
    return null;
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
        if (res.responseCode == '0' &&
            data is Map &&
            data['bookings'] is List) {
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
        await mergePendingBnbBookings(
          merge: merge,
          merged: merged,
          properties: _propertyRows,
          loader: _pendingBookingLoader,
        );
      } catch (_) {}

      final options = <BookingPickerOption>[];
      for (final item in merged.values) {
        if (!_bookingMatchesProperty(item, prop)) continue;
        if (!_isActiveOrUpcoming(item)) continue;
        options.add(_optionFromBooking(item));
      }
      options.sort((a, b) => a.label.compareTo(b.label));

      final preset = selectedBookingKey.value?.trim() ?? _routeBookingId();
      if (preset.isNotEmpty &&
          options.every((o) => o.bookingKey != preset) &&
          _routeBookingId().isNotEmpty) {
        final matched = _findMergedBooking(merged.values, preset);
        if (matched != null) {
          options.insert(0, _optionFromBooking(matched, bookingKey: preset));
        } else {
          final guest = _routeGuestName();
          final dates = _routeBookingDates();
          options.insert(
            0,
            BookingPickerOption(
              bookingKey: preset,
              guestName: guest,
              label: _bookingPickerLabel(guestName: guest, dates: dates),
            ),
          );
        }
      }
      bookingOptions.assignAll(options);
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

  Future<void> _applyIncomePrefill() async {
    final args = Get.arguments;
    final raw = args is Map ? args['prefillIncome'] : null;
    final prefill = raw is Map ? Map<String, dynamic>.from(raw) : const {};

    _linkedTenantId = _firstInt([
      prefill['tenantId'],
      args is Map ? args['tenantId'] : null,
      Get.parameters['tenantId'],
    ]);

    final name = (prefill['tenantName'] ??
            Get.parameters['tenant'] ??
            '')
        .toString()
        .trim();
    if (name.isNotEmpty) {
      tenantController.text = name;
    } else if (_linkedTenantId != null && _linkedTenantId! > 0) {
      final linked = await _tenantLocal.findById(_linkedTenantId!);
      if (linked != null) {
        tenantController.text = linked.tenantName.trim();
      }
    }

    final amountRaw =
        (prefill['amount'] ?? '').toString().trim().replaceAll(',', '');
    final amount = double.tryParse(amountRaw);
    if (amount != null && amount > 0) {
      applyAmountPreset(amount);
    }

    final categoryIndex = prefill['categoryIndex'];
    if (categoryIndex is int) {
      selectCategory(categoryIndex);
    }

    final unitKey = (prefill['unitSelectionKey'] ?? '').toString().trim();
    if (unitKey.isNotEmpty) {
      selectedIncomeUnitKey.value = unitKey;
      await _syncTenantFieldToSelectedUnit();
    }
  }

  Future<int?> _resolveLinkedTenantId({
    required String tenantName,
    required ApartmentUnitDraft? unit,
  }) async {
    if (_linkedTenantId != null && _linkedTenantId! > 0) {
      return _linkedTenantId;
    }
    final fromRoute = int.tryParse(Get.parameters['tenantId'] ?? '');
    if (fromRoute != null && fromRoute > 0) return fromRoute;
    final args = Get.arguments;
    if (args is Map) {
      final fromArgs = int.tryParse('${args['tenantId'] ?? ''}');
      if (fromArgs != null && fromArgs > 0) return fromArgs;
    }
    final tenant = await _tenantForIncome(
      tenantName: tenantName,
      tenantId: null,
      unit: unit,
    );
    return tenant?.id;
  }

  static int? _firstInt(List<Object?> values) {
    for (final value in values) {
      final parsed = int.tryParse('${value ?? ''}');
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
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
    return _routeArg(['bookingId', 'booking_id', 'bookingKey']);
  }

  String _routeGuestName() {
    final fromParams = Get.parameters['guestName']?.trim() ?? '';
    if (fromParams.isNotEmpty) return fromParams;
    return _routeArg(['guestName', 'guest_name']);
  }

  String _routeBookingDates() {
    final fromParams = Get.parameters['dates']?.trim() ?? '';
    if (fromParams.isNotEmpty) return fromParams;
    return _routeArg(['dates', 'bookingDates', 'stayDates']);
  }

  String _routeArg(List<String> keys) {
    final args = Get.arguments;
    if (args is! Map) return '';
    for (final key in keys) {
      final v = (args[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
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

  /// Rent (Lease) income must belong to a tenant. BnB income is per booking,
  /// and other categories (service charge, maintenance, other) are allowed to
  /// stand alone.
  bool _requiresTenantLink(String workspaceType) =>
      workspaceType.trim().toLowerCase() == 'rent' &&
      selectedCategory == 'Lease';

  /// The only tenant on the selected property, or null when there are none or
  /// several (then the user has to say which).
  Future<TenantRecord?> _soleTenantOnSelectedProperty() async {
    final prop = selectedPropertyRecord;
    if (prop == null) return null;
    final tenants = await _tenantLocal.getAllNewestFirst();
    final onProperty = tenants
        .where((t) => _tenantMatchesProperty(t, prop))
        .toList();
    return onProperty.length == 1 ? onProperty.first : null;
  }

  Future<void> saveIncomeOffline() async {
    if (saving.value) return;
    // Only validate FormState when a Form is mounted (full Record Payment
    // screen). The quick-add income wizard has no Form(key: formKey), so
    // formKey.currentState is null — treating that as failure made Submit
    // return immediately with no feedback.
    final formState = formKey.currentState;
    if (formState != null && !formState.validate()) return;
    if (selectedProperty.value.trim().isEmpty) {
      showErrorMessage('Please select a property');
      return;
    }

    final tenant = tenantController.text.trim();
    final amountRaw = amountController.text.trim().replaceAll(',', '');
    final dateRaw = datePaidController.text.trim();
    final notes = notesController.text.trim();
    final property = selectedProperty.value.trim();

    final parsed = _parseMoneyForSave(amountRaw);
    if (parsed == null) return;
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

    saving.value = true;
    final unitDraft = _draftForIncomeUnitKey(selectedIncomeUnitKey.value);
    final unitName = unitDraft?.unitName.trim() ?? '';
    final workspaceType = _workspaceForIncomeSave(unitDraft);
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
    int? tenantIdParam;
    try {
      tenantIdParam = await _resolveLinkedTenantId(
        tenantName: tenant,
        unit: unitDraft,
      );
      if (tenantIdParam == null || tenantIdParam <= 0) {
        // A property with a single tenant is unambiguous; link to them.
        tenantIdParam = (await _soleTenantOnSelectedProperty())?.id;
      }
      if ((tenantIdParam == null || tenantIdParam <= 0) &&
          _requiresTenantLink(workspaceType)) {
        // Rent paid with no tenant can't be allocated to a month, so it would
        // never reduce "yet to collect". Ask for the tenant instead of
        // saving a payment that silently doesn't count.
        showErrorMessage(
          'Select the unit or enter the exact name of the tenant this rent '
          'payment is for. If they are not listed, add the tenant first.',
        );
        return;
      }
    if (tenantIdParam != null && tenantIdParam > 0) {
      _linkedTenantId = tenantIdParam;
      if (tenant.isEmpty) {
        final linked = await _tenantLocal.findById(tenantIdParam);
        if (linked != null) {
          tenantController.text = linked.tenantName.trim();
        }
      }
      baseNotes.writeln(
        TenantLedgerFinance.appendTenantIdNote('', tenantIdParam),
      );
    }
    final tenantNameForSave = tenantController.text.trim().isNotEmpty
        ? tenantController.text.trim()
        : tenant;

    final bookingId = _selectedBookingIdForSave() ?? '';

      final localIncomeId = await _incomeLocal.insert(
        tenantName: tenantNameForSave,
        amountValue: parsed.baseAmount,
        datePaidIso: DateFormat('yyyy-MM-dd').format(paidDate),
        category: selectedCategory,
        workspaceType: workspaceType,
        notes: baseNotes.toString().trim(),
        apartment: property,
        apartmentUnit: unitName,
        propertyRef: _propertyRefForIncomeInsert(),
        bookingId: bookingId,
        currencyCode: parsed.currency,
        inputAmountValue: parsed.inputAmount,
        tenantId: tenantIdParam ?? 0,
      );

      // Write client event for this payment (phone resolved later via tenant lookup)
      unawaited(_clientEventLocal.insert(
        phoneNumber: '',
        clientName: tenant,
        propertyRef: _propertyRefForIncomeInsert(),
        propertyLabel: property,
        unitLabel: unitName,
        workspace: workspaceType,
        eventType: ClientEventType.paymentPartial,
        amountTsh: parsed.baseAmount.round(),
        metadata: {
          'category': selectedCategory,
          'bookingId': bookingId,
          'localIncomeId': localIncomeId,
        },
      ));

      final request = RecordPaymentRequest(
        amount: parsed.baseAmount,
        paymentMethod: selectedPaymentMethod.value,
        bookingId: bookingId.isEmpty ? null : bookingId,
        paymentDate: DateFormat(_isoDateFormat).format(paidDate),
        status: status.value == PaymentStatus.paid ? 'PAID' : 'PENDING',
        idempotencyKey: 'payment:create:$localIncomeId',
      );
      final payload = <String, dynamic>{
        ...request.toJson(),
        'localIncomeId': localIncomeId,
      };
      await _syncQueue.enqueue(
        entityType: 'payment',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey: 'payment:create:$localIncomeId',
      );
      unawaited(_syncWorker.runNow(maxItems: 1));
      final extensionNote = await _extendTenancyForIncome(
        tenantName: tenantNameForSave,
        tenantId: tenantIdParam,
        unit: unitDraft,
        inputAmount: parsed.inputAmount,
        inputCurrency: parsed.currency,
        incomeId: localIncomeId,
      );
      final pending = await _syncQueue.pendingCountByEntity(
        entityType: 'payment',
        operation: 'create',
      );
      analytics?.logPaymentRecorded(
        workspace: workspaceType,
        currency: parsed.currency,
        paymentMethod: selectedPaymentMethod.value,
        category: selectedCategory,
      );
      rememberChoice(UiPreferenceKeys.recordPaymentProperty, property);
      hapticPrimaryConfirm();
      final saved = pending > 0
          ? 'Income saved offline. Will sync when internet is available.'
          : 'Income saved and synced.';
      showSuccessMessage(
        extensionNote == null ? saved : '$saved $extensionNote',
      );
      await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
      await RentTenantLedgerOccupancyController.refreshIfRegistered();
      await BookingDetailsController.refreshIfRegistered();
      await HomeController.refreshIfRegistered();
      await PropertyBreakEvenNotificationService.checkPropertyIfRegistered(
        _propertyRefForIncomeInsert(),
      );
      final guestPrompt = await _bnbGuestPromptTarget(
        unit: unitDraft,
        bookingId: bookingId,
      );
      saving.value = false;
      if (guestPrompt != null) {
        final addGuest = await _promptAddGuestAfterBnbIncome(guestPrompt.place);
        if (addGuest == true) {
          final nav = _guestNavigationArgs(
            unit: guestPrompt.unit,
            guestName: tenant,
          );
          Get.back(result: true);
          await Get.toNamed(
            Routes.ADD_NEW_TENANT,
            parameters: {
              if (nav['property'] != null) 'property': nav['property'] as String,
              if (nav['propertyRef'] != null)
                'propertyRef': nav['propertyRef'] as String,
            },
            arguments: nav,
          );
          return;
        }
      }
      Get.back(result: true);
    } catch (e) {
      showErrorMessage('Failed to save income: $e');
    } finally {
      saving.value = false;
    }
  }

  ({double baseAmount, double inputAmount, String currency})?
  _parseMoneyForSave(String amountRaw) {
    try {
      return MoneyInputHelper.forSave(
        amountRaw: amountRaw,
        selectedCurrency: selectedCurrency.value,
      );
    } on CurrencyConversionException catch (e) {
      showErrorMessage(e.message);
      return null;
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
