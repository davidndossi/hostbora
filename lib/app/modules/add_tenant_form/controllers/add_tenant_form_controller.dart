import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/bnb_stay_billing.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/db/client_event_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../add_listing/models/apartment_unit_draft.dart';
import '../../listing_details/controllers/listing_details_controller.dart';
import '../../rent/expected_payment_schedule/controllers/rent_expected_payment_schedule_controller.dart';
import '../../rent/tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';

class AddTenantFormController extends BaseController {
  AddTenantFormController()
      : _tenantLocal = Get.find<TenantLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final TenantLocalDataSource _tenantLocal;
  final PropertyLocalDataSource _propertyLocal;
  final PreferenceManager _preferenceManager;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final _clientEventLocal = Get.find<ClientEventLocalDataSource>();

  final propertyContextLabel = ''.obs;
  final propertyRef = ''.obs;
  final availableUnitDrafts = <ApartmentUnitDraft>[].obs;
  final selectedUnitKey = RxnString();
  final formKey = GlobalKey<FormState>();

  final tenantNameController = TextEditingController();
  final rentAmountController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;

  final gender = 'Female'.obs;
  final rentFrequency = 'Per Day'.obs;
  final isWhatsapp = false.obs;
  final saving = false.obs;

  /// True when saving a long-term rent tenant (not BnB stay billing).
  final isRentFlow = false.obs;

  final leaseStart = Rx<DateTime?>(null);
  final leaseEnd = Rx<DateTime?>(null);

  final ratePerPeriod = 0.0.obs;
  final stayBillingUnits = 0.obs;
  final stayTotalPreview = 0.0.obs;

  PropertyRecord? _linkedProperty;
  bool _routePrefersRent = false;

  static const genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];
  static const bnbRentFrequencyOptions = ['Per Night'];
  static const rentRentFrequencyOptions = ['Per Month', 'Per Year'];

  List<String> get rentFrequencyOptions =>
      isRentFlow.value ? rentRentFrequencyOptions : bnbRentFrequencyOptions;

  List<String> get unitSelectionKeys =>
      availableUnitDrafts.map((u) => u.selectionKey).toList();

  String unitDisplayLabel(String selectionKey) {
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == selectionKey) {
        final rent = u.unitRent.trim();
        if (rent.isEmpty) return u.unitName;
        return '${u.unitName} (Tshs $rent)';
      }
    }
    return selectionKey;
  }

  ApartmentUnitDraft? _draftForKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == key) return u;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    final ws = Get.parameters['workspaceType']?.trim().toLowerCase();
    _routePrefersRent = ws == 'rent' ||
        Get.currentRoute.contains(Routes.ADD_NEW_TENANT);

    final ref = Get.parameters['propertyRef']?.trim();
    if (ref != null && ref.isNotEmpty) {
      propertyRef.value = ref;
    }
    final fromRoute = Get.parameters['property']?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) {
      propertyContextLabel.value = fromRoute;
    }
    if (_routePrefersRent) {
      isRentFlow.value = true;
      rentFrequency.value = 'Per Month';
    }
    final paramUnitId = Get.parameters['unitId']?.trim() ?? '';
    final paramUnitName = Get.parameters['unitName']?.trim() ?? '';
    _loadPropertyUnits(
      preferredUnitId: paramUnitId,
      preferredUnitName: paramUnitName,
    );
  }

  Future<List<PropertyRecord>> _allVisibleProperties(String userId) async {
    final byKey = <String, PropertyRecord>{};
    for (final workspace in const ['bnb', 'rent']) {
      final rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: userId,
        workspaceType: workspace,
      );
      for (final row in rows) {
        final key = row.propertyRef.trim().isNotEmpty
            ? row.propertyRef.trim()
            : 'local_${row.id}';
        byKey[key] = row;
      }
    }
    return byKey.values.toList();
  }

  Future<void> _loadPropertyUnits({
    String preferredUnitId = '',
    String preferredUnitName = '',
  }) async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final properties = await _allVisibleProperties(userId);

    PropertyRecord? selected;
    if (propertyRef.value.isNotEmpty) {
      for (final p in properties) {
        if (p.propertyRef == propertyRef.value ||
            'legacy_${p.id}' == propertyRef.value ||
            'local_${p.id}' == propertyRef.value) {
          selected = p;
          break;
        }
      }
    }
    if (selected == null && propertyContextLabel.value.isNotEmpty) {
      final wanted = propertyContextLabel.value.trim();
      for (final p in properties) {
        if (_propertyMatchesLabel(p, wanted)) {
          selected = p;
          break;
        }
      }
    }
    if (selected == null) {
      _linkedProperty = null;
      availableUnitDrafts.clear();
      selectedUnitKey.value = null;
      return;
    }

    _linkedProperty = selected;
    propertyRef.value = selected.propertyRef.isNotEmpty
        ? selected.propertyRef
        : 'legacy_${selected.id}';
    final composed = selected.propertyName.trim().isNotEmpty
        ? '${selected.propertyName.trim()} · ${selected.propertyLocation.trim()}'
        : selected.propertyLocation.trim();
    if (composed.isNotEmpty) {
      propertyContextLabel.value = composed;
    }

    _updateFlowForProperty(selected);

    final drafts = _parseUnitDrafts(selected.unitsJson);
    availableUnitDrafts.assignAll(drafts);

    if (drafts.isEmpty) {
      selectedUnitKey.value = null;
      return;
    }

    if (preferredUnitId.isNotEmpty) {
      for (final u in drafts) {
        if (u.unitId == preferredUnitId) {
          selectedUnitKey.value = u.selectionKey;
          _prefillRentFromUnit(u, selected);
          return;
        }
      }
    }
    if (preferredUnitName.isNotEmpty) {
      for (final u in drafts) {
        if (u.unitName.trim() == preferredUnitName) {
          selectedUnitKey.value = u.selectionKey;
          _prefillRentFromUnit(u, selected);
          return;
        }
      }
    }
    selectedUnitKey.value =
        drafts.length == 1 ? drafts.first.selectionKey : null;
    if (drafts.length == 1) {
      _prefillRentFromUnit(drafts.first, selected);
    }
  }

  bool _propertyMatchesLabel(PropertyRecord p, String wanted) {
    final nameLoc = p.propertyName.trim().isNotEmpty
        ? '${p.propertyName.trim()} · ${p.propertyLocation.trim()}'
        : p.propertyLocation.trim();
    final locName = p.propertyName.trim().isNotEmpty
        ? '${p.propertyLocation.trim()} · ${p.propertyName.trim()}'
        : p.propertyLocation.trim();
    return nameLoc == wanted ||
        locName == wanted ||
        p.propertyLocation.trim() == wanted ||
        p.propertyName.trim() == wanted;
  }

  void _updateFlowForProperty(PropertyRecord property, {ApartmentUnitDraft? unit}) {
    final ws = property.workspaceType.trim().toLowerCase();
    if (unit != null && ws == 'both') {
      isRentFlow.value = unit.operationMode == 'rent';
    } else if (ws == 'rent') {
      isRentFlow.value = true;
    } else if (ws == 'bnb') {
      isRentFlow.value = false;
    } else if (ws == 'both') {
      isRentFlow.value = _routePrefersRent;
    } else {
      isRentFlow.value = _routePrefersRent;
    }
    _syncRentFrequencyForFlow();
  }

  void _syncRentFrequencyForFlow() {
    final options = rentFrequencyOptions;
    if (!options.contains(rentFrequency.value)) {
      rentFrequency.value = options.first;
    }
  }

  void _prefillRentFromUnit(ApartmentUnitDraft u, PropertyRecord property) {
    _updateFlowForProperty(property, unit: u);
    final raw = u.unitRent.trim().replaceAll(',', '');
    if (isRentFlow.value) {
      if (raw.isNotEmpty) {
        rentAmountController.text = raw;
      }
      return;
    }
    // Map legacy 'Per Day' from stored unit drafts to the new 'Per Night' label.
    var freq = u.unitRentFrequency.trim();
    if (freq.toLowerCase() == 'per day') freq = 'Per Night';
    if (freq.isNotEmpty && bnbRentFrequencyOptions.contains(freq)) {
      rentFrequency.value = freq;
    }
    if (raw.isEmpty) {
      _applyRatePerPeriod(0);
      return;
    }
    final n = double.tryParse(raw);
    if (n != null && n > 0) {
      _applyRatePerPeriod(n);
    }
  }

  void _applyRatePerPeriod(double rate) {
    ratePerPeriod.value = rate;
    if (rate > 0) {
      final formatted = rate == rate.roundToDouble()
          ? rate.round().toString()
          : rate.toStringAsFixed(2);
      rentAmountController.text = formatted;
    } else {
      rentAmountController.clear();
    }
    _refreshStayTotalPreview();
  }

  void _refreshStayTotalPreview() {
    if (isRentFlow.value) {
      stayBillingUnits.value = 0;
      stayTotalPreview.value = 0;
      return;
    }
    final start = leaseStart.value;
    final end = leaseEnd.value;
    final rate = ratePerPeriod.value;
    if (start == null || end == null || rate <= 0) {
      stayBillingUnits.value = 0;
      stayTotalPreview.value = 0;
      return;
    }
    final units = BnbStayBilling.billingUnitsBetween(
      start,
      end,
      rentFrequency.value,
    );
    stayBillingUnits.value = units;
    stayTotalPreview.value = BnbStayBilling.totalForStay(
      ratePerPeriod: rate,
      frequency: rentFrequency.value,
      checkIn: start,
      checkOut: end,
    );
  }

  void onRentAmountChanged(String value) {
    if (isRentFlow.value) return;
    final raw = value.trim().replaceAll(',', '');
    final n = double.tryParse(raw);
    ratePerPeriod.value = n != null && n > 0 ? n : 0;
    _refreshStayTotalPreview();
  }

  List<ApartmentUnitDraft> _parseUnitDrafts(String unitsJson) {
    if (unitsJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(unitsJson);
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

  void setSelectedUnitKey(String? key) {
    if (key == null || key.isEmpty) {
      selectedUnitKey.value = null;
      if (_linkedProperty != null) {
        _updateFlowForProperty(_linkedProperty!);
      }
      return;
    }
    selectedUnitKey.value = key;
    final d = _draftForKey(key);
    final property = _linkedProperty;
    if (d != null && property != null) {
      _prefillRentFromUnit(d, property);
    }
  }

  void setGender(String? value) {
    if (value != null && value.isNotEmpty) {
      gender.value = value;
    }
  }

  void setRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      rentFrequency.value = value;
      _refreshStayTotalPreview();
    }
  }

  void setWhatsapp(bool? value) {
    if (value != null) {
      isWhatsapp.value = value;
    }
  }

  void setLeaseDateRange(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    if (!isRentFlow.value && !BnbStayBilling.isValidStayRange(start, end)) {
      showErrorMessage('Check-out must be after check-in (at least one night)');
      return;
    }
    leaseStart.value = start;
    leaseEnd.value = end;
    _refreshStayTotalPreview();
  }

  Future<void> saveTenant() async {
    if (saving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      if (isRentFlow.value) hapticValidationError();
      return;
    }

    if (leaseStart.value == null || leaseEnd.value == null) {
      showErrorMessage('Lease period is required');
      return;
    }
    if (availableUnitDrafts.isNotEmpty) {
      if (selectedUnitKey.value == null || selectedUnitKey.value!.isEmpty) {
        showErrorMessage('Please select a unit');
        return;
      }
    }

    saving.value = true;
    try {
      if (isRentFlow.value) {
        await _saveRentTenant();
      } else {
        await _saveBnbTenant();
      }
    } finally {
      saving.value = false;
    }
  }

  Future<void> _saveBnbTenant() async {
    final amountRaw = rentAmountController.text.trim().replaceAll(',', '');
    final rate = double.tryParse(amountRaw);
    if (rate == null || rate <= 0) {
      showErrorMessage('Enter a valid rent amount');
      return;
    }

    final start = leaseStart.value!;
    final end = leaseEnd.value!;
    if (!BnbStayBilling.isValidStayRange(start, end)) {
      showErrorMessage('Check-out must be after check-in (at least one night)');
      return;
    }
    final stayTotal = BnbStayBilling.totalForStay(
      ratePerPeriod: rate,
      frequency: rentFrequency.value,
      checkIn: start,
      checkOut: end,
    );
    if (stayTotal <= 0) {
      showErrorMessage('Could not calculate rent for this stay');
      return;
    }

    final draft = _draftForKey(selectedUnitKey.value);
    final unitLabel = draft?.unitName.trim() ?? '';
    final apartmentUnitId = draft?.unitId.trim() ?? '';

    final bnbTenantId = await _tenantLocal.insert(
      propertyLabel: propertyContextLabel.value.trim(),
      propertyRef: propertyRef.value.trim(),
      apartmentUnitId: apartmentUnitId,
      unitLabel: unitLabel,
      tenantName: tenantNameController.text.trim(),
      gender: gender.value,
      rentAmountValue: stayTotal,
      rentFrequency: 'Per Stay',
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      isWhatsapp: isWhatsapp.value,
      leaseStartIso: DateFormat('yyyy-MM-dd').format(leaseStart.value!),
      leaseEndIso: DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
      rentCurrency: selectedCurrency.value,
    );
    unawaited(_clientEventLocal.insert(
      tenantLocalId: bnbTenantId,
      phoneNumber: phoneController.text.trim(),
      clientName: tenantNameController.text.trim(),
      propertyRef: propertyRef.value.trim(),
      propertyLabel: propertyContextLabel.value.trim(),
      unitLabel: unitLabel,
      workspace: 'bnb',
      eventType: ClientEventType.bookingCreated,
      metadata: {
        'leaseStart': DateFormat('yyyy-MM-dd').format(leaseStart.value!),
        'leaseEnd': DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
        'stayTotal': stayTotal,
      },
    ));

    final payload = {
      'name': tenantNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'propertyRef': propertyRef.value.trim(),
      'unitId': apartmentUnitId,
      'unitName': unitLabel,
      'leaseStart': DateFormat('yyyy-MM-dd').format(leaseStart.value!),
      'leaseEnd': DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
      'rentAmount': stayTotal,
      'rentFrequency': 'Per Stay',
      'operationMode': 'bnb',
      'rentCurrency': selectedCurrency.value,
      'localTenantId': bnbTenantId,
    };
    try {
      final res = await _repository.createTenant(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
      final backendId =
          (res.data is Map) ? (res.data as Map)['id']?.toString() ?? '' : '';
      if (backendId.isNotEmpty) {
        unawaited(_tenantLocal.saveBackendTenantId(
          localId: bnbTenantId,
          backendId: backendId,
        ));
      }
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'tenant',
        operation: 'create',
        payloadJson: jsonEncode(payload),
        dedupeKey:
            'tenant:create:${propertyRef.value.trim()}:${tenantNameController.text.trim()}',
      );
      _syncWorker.runNow();
    }

    final units = stayBillingUnits.value;
    if (stayTotal > 0 && units > 0) {
      final nightLabel = units == 1 ? 'night' : 'nights';
      showSuccessMessage(
        'Tenant saved. Total for stay ($units $nightLabel): '
        'TZS ${NumberFormat('#,###').format(stayTotal.round())}',
      );
    } else {
      showSuccessMessage('Tenant saved offline');
    }
    Get.back(result: true);
  }

  Future<void> _saveRentTenant() async {
    final amountRaw = rentAmountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountRaw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid rent amount');
      return;
    }

    final draft = _draftForKey(selectedUnitKey.value);
    final unitLabel = draft?.unitName.trim() ?? '';
    final apartmentUnitId = draft?.unitId.trim() ?? '';
    await _markUnitOccupied(
      unitId: apartmentUnitId,
      unitName: unitLabel,
      tenantName: tenantNameController.text.trim(),
    );

    final rentTenantId = await _tenantLocal.insert(
      propertyLabel: propertyContextLabel.value.trim(),
      propertyRef: propertyRef.value.trim(),
      apartmentUnitId: apartmentUnitId,
      unitLabel: unitLabel,
      tenantName: tenantNameController.text.trim(),
      gender: gender.value,
      rentAmountValue: amount,
      rentFrequency: rentFrequency.value,
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      isWhatsapp: isWhatsapp.value,
      leaseStartIso: DateFormat('yyyy-MM-dd').format(leaseStart.value!),
      leaseEndIso: DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
      contractFilePath: '',
      contractFileName: '',
      rentCurrency: selectedCurrency.value,
    );
    unawaited(_clientEventLocal.insert(
      tenantLocalId: rentTenantId,
      phoneNumber: phoneController.text.trim(),
      clientName: tenantNameController.text.trim(),
      propertyRef: propertyRef.value.trim(),
      propertyLabel: propertyContextLabel.value.trim(),
      unitLabel: unitLabel,
      workspace: 'rent',
      eventType: ClientEventType.tenantAdded,
      metadata: {
        'leaseStart': DateFormat('yyyy-MM-dd').format(leaseStart.value!),
        'leaseEnd': DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
        'rentAmount': amount,
        'rentFrequency': rentFrequency.value,
      },
    ));

    final rentPayload = {
      'name': tenantNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'propertyRef': propertyRef.value.trim(),
      'unitId': apartmentUnitId,
      'unitName': unitLabel,
      'leaseStart': DateFormat('yyyy-MM-dd').format(leaseStart.value!),
      'leaseEnd': DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
      'rentAmount': amount,
      'rentFrequency': rentFrequency.value,
      'operationMode': 'rent',
      'rentCurrency': selectedCurrency.value,
      'localTenantId': rentTenantId,
    };
    try {
      final res = await _repository.createTenant(rentPayload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
      final backendId =
          (res.data is Map) ? (res.data as Map)['id']?.toString() ?? '' : '';
      if (backendId.isNotEmpty) {
        unawaited(_tenantLocal.saveBackendTenantId(
          localId: rentTenantId,
          backendId: backendId,
        ));
      }
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'tenant',
        operation: 'create',
        payloadJson: jsonEncode(rentPayload),
        dedupeKey:
            'tenant:create:${propertyRef.value.trim()}:${tenantNameController.text.trim()}',
      );
      _syncWorker.runNow();
    }

    await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
    await ListingDetailsController.refreshIfRegistered();
    await RentExpectedPaymentScheduleController.refreshIfRegistered();

    hapticPrimaryConfirm();
    showSuccessMessage('Tenant saved offline');

    final addIncome = await _promptAddIncomeAfterTenant();
    if (addIncome == true) {
      final nav = _incomeNavigationArgs();
      Get.back(result: true);
      await Get.toNamed(
        Routes.RECORD_PAYMENT,
        parameters: {
          if (nav['property'] != null) 'property': nav['property'] as String,
          if (nav['propertyRef'] != null)
            'propertyRef': nav['propertyRef'] as String,
        },
        arguments: nav,
      );
      return;
    }

    Get.back(result: true);
  }

  Future<bool?> _promptAddIncomeAfterTenant() {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(appLocalization.rentAddTenantIncomePromptTitle),
        content: Text(appLocalization.rentAddTenantIncomePromptBody),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appLocalization.rentAddTenantIncomePromptLater),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(appLocalization.rentAddTenantIncomePromptAdd),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Map<String, dynamic> _incomeNavigationArgs() {
    final p = _linkedProperty;
    final propertyOption = p == null
        ? propertyContextLabel.value.trim()
        : (p.propertyName.trim().isNotEmpty
              ? p.propertyName.trim()
              : p.propertyLocation.trim());
    return {
      'property': propertyOption,
      'propertyRef': propertyRef.value.trim(),
      'prefillIncome': {
        'tenantName': tenantNameController.text.trim(),
        'amount': rentAmountController.text.trim().replaceAll(',', ''),
        'unitSelectionKey': selectedUnitKey.value,
        'categoryIndex': 0,
      },
    };
  }

  Future<void> _markUnitOccupied({
    required String unitId,
    required String unitName,
    required String tenantName,
  }) async {
    final ref = propertyRef.value.trim();
    if (ref.isEmpty) return;
    final property =
        await _propertyLocal.findByHubId(ref) ??
        await _propertyLocal.getByPropertyRef(ref);
    if (property == null) return;
    if (property.unitsJson.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(property.unitsJson);
      if (decoded is! List) return;
      var changed = false;
      final updated = decoded.map((entry) {
        if (entry is! Map) return entry;
        final unit = Map<String, dynamic>.from(entry);
        final existingId = (unit['unitId'] ?? unit['id'] ?? '')
            .toString()
            .trim();
        final existingName = (unit['unitName'] ?? unit['name'] ?? '')
            .toString()
            .trim();
        final idMatches =
            unitId.isNotEmpty && existingId.isNotEmpty && existingId == unitId;
        final nameMatches =
            unitName.isNotEmpty &&
            existingName.isNotEmpty &&
            existingName.toLowerCase() == unitName.toLowerCase();
        if (!idMatches && !nameMatches) return unit;
        changed = true;
        unit['status'] = 'occupied';
        unit['occupied'] = true;
        if (tenantName.isNotEmpty) {
          unit['tenantName'] = tenantName;
        }
        return unit;
      }).toList();
      if (!changed) return;
      await _propertyLocal.update(
        PropertyRecord(
          id: property.id,
          propertyLocation: property.propertyLocation,
          propertyName: property.propertyName,
          propertyType: property.propertyType,
          propertyRef: property.propertyRef,
          tenants: property.tenants,
          units: property.units,
          ownerUserId: property.ownerUserId,
          workspaceType: property.workspaceType,
          createdAtMs: property.createdAtMs,
          rentAmount: property.rentAmount,
          rentFrequency: property.rentFrequency,
          minRentalDuration: property.minRentalDuration,
          unitsJson: jsonEncode(updated),
          floorCount: property.floorCount,
          coverPhotoPath: property.coverPhotoPath,
        ),
      );
    } catch (_) {}
  }

  String? validateTenantName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Tenant name is required';
    if (v.length < 2) return 'Enter a valid name';
    return null;
  }

  String? validateRentAmount(String? value) {
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Rent amount is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    if (v.length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? validateEmailOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final ok = GetUtils.isEmail(v);
    return ok ? null : 'Enter a valid email';
  }

  @override
  void onClose() {
    tenantNameController.dispose();
    rentAmountController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
