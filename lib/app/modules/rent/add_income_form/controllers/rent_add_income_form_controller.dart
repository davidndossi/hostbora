import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/money_input_helper.dart';
import '../../../../core/utils/thousand_separator.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/local/service/property_break_even_notification_service.dart';
import '../../../../data/model/record_payment_request.dart';
import '../../add_new_listing/models/apartment_unit_draft.dart';
import '../../listing_details/controllers/rent_listing_details_controller.dart';
import '../../tenant_ledger_occupancy/controllers/rent_tenant_ledger_occupancy_controller.dart';
import '../../tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';

class RentAddIncomeFormController extends BaseController {
  RentAddIncomeFormController()
    : _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _tenantLocal = Get.find<TenantLocalDataSource>(),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>(),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );

  final IncomeLocalDataSource _incomeLocal;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
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
  final categories = const ['Rent', 'Service Charge', 'Maintenance', 'Other'];

  final selectedCategoryIndex = 0.obs;
  final saving = false.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;

  /// Optional apartment unit ([ApartmentUnitDraft.selectionKey]); null = not specified.
  final selectedIncomeUnitKey = Rxn<String>();
  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;

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

  static bool _tenantMatchesProperty(TenantRecord t, PropertyRecord p) {
    final loc = p.propertyLocation.trim();
    final suite = p.propertyName.trim();
    final title = suite.isNotEmpty ? '$loc · $suite' : loc;
    final propertyRef = p.propertyRef.trim().isNotEmpty
        ? p.propertyRef.trim()
        : 'legacy_${p.id}';
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
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    _loadProperties().then((_) => _applyIncomePrefillFromRoute());
  }

  void _applyIncomePrefillFromRoute() {
    final args = Get.arguments;
    if (args is! Map) return;
    final prefill = args['prefillIncome'];
    if (prefill is! Map) return;

    final tenant = (prefill['tenantName'] ?? '').toString().trim();
    if (tenant.isNotEmpty) {
      tenantController.text = tenant;
    }

    final amount = (prefill['amount'] ?? '').toString().trim();
    if (amount.isNotEmpty) {
      amountController.text = amount;
    }

    datePaidController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final catIdx = prefill['categoryIndex'];
    if (catIdx is int && catIdx >= 0 && catIdx < categories.length) {
      selectedCategoryIndex.value = catIdx;
    }

    final propertyOption =
        (args['property'] ?? Get.parameters['property'] ?? '')
            .toString()
            .trim();
    if (propertyOption.isNotEmpty && propertyOptions.contains(propertyOption)) {
      selectedProperty.value = propertyOption;
    }

    final unitKey = prefill['unitSelectionKey']?.toString().trim();
    if (unitKey != null && unitKey.isNotEmpty) {
      selectedIncomeUnitKey.value = unitKey;
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
      workspaceType: 'rent',
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
    final fromRoute = fromArgs.isNotEmpty
        ? fromArgs
        : (Get.parameters['property']?.trim() ?? '');
    if (fromRoute.isNotEmpty && options.contains(fromRoute)) {
      selectedProperty.value = fromRoute;
    } else if (options.length == 1) {
      selectedProperty.value = options.first;
    }
  }

  void updateSelectedProperty(String? value) {
    if (value == null) return;
    selectedIncomeUnitKey.value = null;
    selectedProperty.value = value;
    tenantController.clear();
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

    saving.value = true;
    try {
      await _incomeLocal.insert(
        tenantName: tenant,
        amountValue: parsed.baseAmount,
        datePaidIso: DateFormat('yyyy-MM-dd').format(paidDate),
        category: selectedCategory,
        workspaceType: 'rent',
        notes: baseNotes.toString().trim(),
        apartment: property,
        apartmentUnit: unitName,
        propertyRef: _propertyRefForIncomeInsert(),
        currencyCode: parsed.currency,
        inputAmountValue: parsed.inputAmount,
      );

      final request = RecordPaymentRequest(
        amount: parsed.baseAmount,
        paymentMethod: 'Cash',
        paymentDate: DateFormat('yyyy-MM-dd').format(paidDate),
        status: 'PAID',
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
          'Income saved offline. Will sync when internet is available.',
        );
      } else {
        showSuccessMessage('Income saved and synced.');
      }
      await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
      await RentTenantLedgerOccupancyController.refreshIfRegistered();
      await RentListingDetailsController.refreshIfRegistered();
      await PropertyBreakEvenNotificationService.checkPropertyIfRegistered(
        _propertyRefForIncomeInsert(),
      );
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
}
