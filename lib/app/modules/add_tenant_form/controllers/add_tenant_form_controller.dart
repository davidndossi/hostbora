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
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/service/remote_account_sync_service.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../add_listing/models/apartment_unit_draft.dart';
import '../../listing_details/controllers/listing_details_controller.dart';
import '../../my_properties/controllers/my_properties_controller.dart';
import '../../all_tenants/controllers/all_tenants_controller.dart';
import '../../rent/expected_payment_schedule/controllers/rent_expected_payment_schedule_controller.dart';
import '../../rent/tenant_ledger_occupancy/controllers/rent_tenant_ledger_occupancy_controller.dart';
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

  /// Every unit on this property is already occupied, so saving replaces
  /// the tenant on the selected unit.
  final replacingOccupiedUnit = false.obs;
  final formKey = GlobalKey<FormState>();

  final tenantNameController = TextEditingController();
  final rentAmountController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;

  final gender = 'Female'.obs;
  final rentFrequency = 'Per Night'.obs;
  final isWhatsapp = false.obs;
  final saving = false.obs;

  /// True when saving a long-term rent tenant (not BnB stay billing).
  final isRentFlow = false.obs;

  final leaseStart = Rx<DateTime?>(null);
  final leaseEnd = Rx<DateTime?>(null);

  /// Seeded dates are a placeholder. Save prompts until the host picks a
  /// range or types a term in the lease-term dialog.
  bool _leaseTermEnteredByUser = false;

  bool get _isSw => Get.locale?.languageCode == 'sw';
  String _t(String en, String sw) => _isSw ? sw : en;

  final ratePerPeriod = 0.0.obs;
  final stayBillingUnits = 0.obs;
  final stayTotalPreview = 0.0.obs;

  PropertyRecord? _linkedProperty;
  /// True when the route explicitly asked for rent (`workspaceType=rent`).
  bool _routePrefersRent = false;
  /// True when `workspaceType` was provided on the route (Rent/BnB tab intent).
  bool _routeWorkspaceExplicit = false;

  /// Quick Management asks for every unit, BnB and rent.
  bool _showAllUnits = false;

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

  /// Separates two units that would otherwise share one dropdown value.
  static const _dupKeySplit = '\u001f';

  List<String> get unitSelectionKeys => [
        for (var i = 0; i < availableUnitDrafts.length; i++) _unitKeyAt(i),
      ];

  String _unitKeyAt(int index) {
    final base = availableUnitDrafts[index].selectionKey;
    var copies = 0;
    for (final draft in availableUnitDrafts) {
      if (draft.selectionKey == base) copies++;
    }
    if (copies <= 1) return base;
    return '$base$_dupKeySplit$index';
  }

  String unitDisplayLabel(String selectionKey) {
    final u = _draftForKey(selectionKey);
    if (u == null) return selectionKey;
    final rent = u.unitRent.trim();
    if (rent.isEmpty) return u.unitName;
    final parsed = double.tryParse(rent.replaceAll(',', ''));
    if (parsed != null) {
      return '${u.unitName} (${Get.find<CurrencyService>().formatBase(parsed.round())})';
    }
    return '${u.unitName} ($rent)';
  }

  ApartmentUnitDraft? _draftForKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (var i = 0; i < availableUnitDrafts.length; i++) {
      if (_unitKeyAt(i) == key) return availableUnitDrafts[i];
    }
    final split = key.lastIndexOf(_dupKeySplit);
    if (split >= 0) {
      final index = int.tryParse(key.substring(split + _dupKeySplit.length));
      if (index != null &&
          index >= 0 &&
          index < availableUnitDrafts.length) {
        return availableUnitDrafts[index];
      }
    }
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == key) return u;
    }
    return null;
  }

  void _selectDraft(ApartmentUnitDraft unit, PropertyRecord property) {
    final index = availableUnitDrafts.indexWhere((d) => identical(d, unit));
    selectedUnitKey.value =
        index >= 0 ? _unitKeyAt(index) : unit.selectionKey;
    _prefillRentFromUnit(unit, property);
  }

  @override
  void onInit() {
    super.onInit();
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    _resolveRouteWorkspacePreference();

    final ref = Get.parameters['propertyRef']?.trim() ??
        _argString('propertyRef');
    if (ref != null && ref.isNotEmpty) {
      propertyRef.value = ref;
    }
    final fromRoute =
        Get.parameters['property']?.trim() ?? _argString('property');
    if (fromRoute != null && fromRoute.isNotEmpty) {
      propertyContextLabel.value = fromRoute;
    }
    if (_routePrefersRent) {
      isRentFlow.value = true;
      rentFrequency.value = 'Per Month';
    }
    _syncRentFrequencyForFlow();
    final paramUnitId = Get.parameters['unitId']?.trim() ??
        _argString('unitId') ??
        '';
    final paramUnitName = Get.parameters['unitName']?.trim() ??
        _argString('unitName') ??
        '';
    final guestName = _argString('guestName');
    if (guestName != null && tenantNameController.text.trim().isEmpty) {
      tenantNameController.text = guestName;
    }
    _seedLeasePeriod();
    _loadPropertyUnits(
      preferredUnitId: paramUnitId,
      preferredUnitName: paramUnitName,
    );
  }

  /// Seeds the lease range the flow implies: a twelve-month tenancy for rent,
  /// a one-night stay for BnB. Runs after [_syncRentFrequencyForFlow] so
  /// [isRentFlow] is settled, and skips any range already set from the route.
  void _seedLeasePeriod() {
    if (leaseStart.value != null || leaseEnd.value != null) return;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    leaseStart.value = start;
    leaseEnd.value = isRentFlow.value
        ? DateTime(start.year + 1, start.month, start.day)
        : start.add(const Duration(days: 1));
    _refreshStayTotalPreview();
  }

  String? _argString(String key) {
    final args = Get.arguments;
    if (args is Map) {
      final v = args[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Rent vs BnB is decided by the tab that opened this form, not by the
  /// shared `/add-new-tenant` route name (that path is used for both).
  ///
  /// Workspace comes from this navigation's arguments only. [Get.parameters]
  /// keeps `workspaceType` from earlier screens (Record Payment on a dual-mode
  /// property writes `bnb`), which removed rent units from the dropdown.
  void _resolveRouteWorkspacePreference() {
    final showAll = (_argString('showAllUnits') ?? '').trim().toLowerCase();
    if (showAll == 'true' || showAll == '1') {
      _showAllUnits = true;
      _routePrefersRent = false;
      _routeWorkspaceExplicit = false;
      return;
    }
    final ws = (_argString('workspaceType') ?? '').trim().toLowerCase();
    if (ws == 'rent') {
      _routePrefersRent = true;
      _routeWorkspaceExplicit = true;
    } else if (ws == 'bnb') {
      _routePrefersRent = false;
      _routeWorkspaceExplicit = true;
    } else {
      _routePrefersRent = false;
      _routeWorkspaceExplicit = false;
    }
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
        : 'local_${selected.id}';
    final propertyName = _nameOf(selected);
    if (propertyName.isNotEmpty) {
      propertyContextLabel.value = propertyName;
    }

    _updateFlowForProperty(selected);

    final drafts = await _unitDraftsFor(selected);
    final flowDrafts = _unitsForCurrentFlow(
      drafts,
      selected,
      keepUnitId: preferredUnitId,
      keepUnitName: preferredUnitName,
    );
    final tenants = await _tenantLocal.getActiveTenants();
    final freeDrafts = _excludeAssignedUnits(
      flowDrafts,
      property: selected,
      tenants: tenants,
    );
    final allOccupied = flowDrafts.isNotEmpty && freeDrafts.isEmpty;
    replacingOccupiedUnit.value = allOccupied;
    final visibleDrafts = _withRequestedUnit(
      flowDrafts,
      allOccupied ? flowDrafts : freeDrafts,
      unitId: preferredUnitId,
      unitName: preferredUnitName,
    );
    availableUnitDrafts.assignAll(visibleDrafts);

    if (visibleDrafts.isEmpty) {
      selectedUnitKey.value = null;
      return;
    }

    final requested = _findUnit(
      visibleDrafts,
      unitId: preferredUnitId,
      unitName: preferredUnitName,
    );
    if (requested != null) {
      _selectDraft(requested, selected);
      return;
    }

    // Prefer a unit that matches the tab that opened this form.
    final preferred = _preferredUnitForFlow(visibleDrafts);
    if (preferred != null) {
      _selectDraft(preferred, selected);
      return;
    }

    selectedUnitKey.value = null;
    if (visibleDrafts.length == 1) {
      _selectDraft(visibleDrafts.first, selected);
    }
  }

  /// Units already linked to an active tenant (or marked occupied in
  /// [PropertyRecord.unitsJson]) must not appear in the Add Tenant dropdown.
  List<ApartmentUnitDraft> _excludeAssignedUnits(
    List<ApartmentUnitDraft> drafts, {
    required PropertyRecord property,
    required List<TenantRecord> tenants,
  }) {
    if (drafts.isEmpty) return drafts;

    final propertyTenants =
        tenants.where((t) => _tenantMatchesProperty(t, property)).toList();
    final occupiedIds = <String>{};
    final occupiedNames = <String>{};

    for (final t in propertyTenants) {
      final id = t.apartmentUnitId.trim();
      if (id.isNotEmpty) occupiedIds.add(id);
      final name = t.unitLabel.trim();
      if (name.isNotEmpty) occupiedNames.add(name.toLowerCase());
    }

    try {
      final decoded = jsonDecode(property.unitsJson);
      if (decoded is List) {
        for (final e in decoded.whereType<Map>()) {
          final m = Map<String, dynamic>.from(e);
          final occupied = m['occupied'] == true ||
              m['status']?.toString().trim().toLowerCase() == 'occupied';
          if (!occupied) continue;
          final id = (m['unitId'] ?? m['id'] ?? '').toString().trim();
          final name = (m['unitName'] ?? m['name'] ?? '').toString().trim();
          if (id.isNotEmpty) occupiedIds.add(id);
          if (name.isNotEmpty) occupiedNames.add(name.toLowerCase());
        }
      }
    } catch (_) {}

    if (occupiedIds.isEmpty && occupiedNames.isEmpty) return drafts;

    return drafts.where((u) {
      final id = u.unitId.trim();
      if (id.isNotEmpty && occupiedIds.contains(id)) return false;
      final name = u.unitName.trim().toLowerCase();
      if (name.isNotEmpty && occupiedNames.contains(name)) return false;
      return true;
    }).toList();
  }

  Future<void> _replaceTenantOnUnit({
    required String unitId,
    required String unitName,
  }) async {
    final property = _linkedProperty;
    if (property == null) return;
    final tenants = await _tenantLocal.getActiveTenants();
    final now = DateTime.now();
    final endIso = DateFormat('yyyy-MM-dd').format(now);
    final endMs = now.millisecondsSinceEpoch;
    for (final tenant in tenants) {
      if (!_tenantMatchesProperty(tenant, property)) continue;
      if (!_tenantMatchesUnit(tenant, unitId: unitId, unitName: unitName)) {
        continue;
      }
      await _tenantLocal.endTenancy(
        id: tenant.id,
        endedAtIso: endIso,
        endedAtMs: endMs,
      );
      unawaited(_clientEventLocal.insert(
        tenantLocalId: tenant.id,
        phoneNumber: tenant.phoneNumber,
        clientName: tenant.tenantName,
        propertyRef: tenant.propertyRef,
        propertyLabel: tenant.propertyLabel,
        unitLabel: tenant.unitLabel,
        workspace: isRentFlow.value ? 'rent' : 'bnb',
        eventType: ClientEventType.leaseEnded,
        metadata: {'endedAt': endIso, 'replaced': true},
      ));
      final backendId = tenant.backendTenantId.trim();
      if (backendId.isEmpty) continue;
      try {
        final res = await _repository.deleteTenant(backendId);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201' ||
            res.responseCode == '204';
        if (!ok) throw Exception(res.message ?? 'API error');
      } catch (_) {
        await _syncQueue.enqueue(
          entityType: 'tenant',
          operation: 'delete',
          payloadJson: jsonEncode({'id': backendId}),
          dedupeKey: 'tenant:delete:$backendId',
        );
        _syncWorker.runNow();
      }
    }
  }

  bool _tenantMatchesUnit(
    TenantRecord tenant, {
    required String unitId,
    required String unitName,
  }) {
    final id = tenant.apartmentUnitId.trim();
    final name = tenant.unitLabel.trim();
    if (unitId.isNotEmpty && id.isNotEmpty && id == unitId) return true;
    if (unitName.isNotEmpty &&
        name.isNotEmpty &&
        name.toLowerCase() == unitName.toLowerCase()) {
      return true;
    }
    return unitId.isEmpty &&
        unitName.isEmpty &&
        id.isEmpty &&
        name.isEmpty;
  }

  bool _tenantMatchesProperty(TenantRecord t, PropertyRecord property) {
    final listingRef = property.propertyRef.trim().isNotEmpty
        ? property.propertyRef.trim()
        : 'local_${property.id}';
    final listingName = property.propertyName.trim().isNotEmpty
        ? property.propertyName.trim()
        : property.propertyLocation.trim();
    final listingLoc = property.propertyLocation.trim();

    final ref = t.propertyRef.trim();
    if (ref.isNotEmpty) {
      if (ref == listingRef) return true;
      if (ref == 'local_${property.id}' || ref == 'legacy_${property.id}') {
        return true;
      }
      final hub = property.propertyRef.trim();
      if (hub.isNotEmpty && ref == hub) return true;
    }

    final label = t.propertyLabel.trim().toLowerCase();
    if (listingName.isNotEmpty && label == listingName.toLowerCase()) {
      return true;
    }
    if (listingLoc.isNotEmpty && label == listingLoc.toLowerCase()) {
      return true;
    }
    if (listingName.isNotEmpty &&
        listingLoc.isNotEmpty &&
        (label == '${listingName.toLowerCase()} · ${listingLoc.toLowerCase()}' ||
            label ==
                '${listingLoc.toLowerCase()} · ${listingName.toLowerCase()}')) {
      return true;
    }
    return false;
  }

  List<ApartmentUnitDraft> _unitsForCurrentFlow(
    List<ApartmentUnitDraft> drafts,
    PropertyRecord property, {
    String keepUnitId = '',
    String keepUnitName = '',
  }) {
    if (_showAllUnits || !_routeWorkspaceExplicit) return drafts;
    final propertyWs = property.workspaceType.trim().toLowerCase();
    if (propertyWs == 'rent' || propertyWs == 'bnb') {
      // Single-mode listing: all units belong to that mode.
      return drafts;
    }
    // Dual-mode: only show units for the tab that opened add-tenant.
    // The unit the user just tapped is always kept, even if its stored mode
    // still says bnb.
    final filtered = drafts.where((u) {
      final rent = u.operationMode.trim().toLowerCase() == 'rent';
      return _routePrefersRent ? rent : !rent;
    }).toList();
    return _withRequestedUnit(
      drafts,
      filtered,
      unitId: keepUnitId,
      unitName: keepUnitName,
    );
  }

  List<ApartmentUnitDraft> _withRequestedUnit(
    List<ApartmentUnitDraft> all,
    List<ApartmentUnitDraft> visible, {
    required String unitId,
    required String unitName,
  }) {
    if (_findUnit(visible, unitId: unitId, unitName: unitName) != null) {
      return visible;
    }
    final requested = _findUnit(all, unitId: unitId, unitName: unitName);
    if (requested == null) return visible;
    return [...visible, requested];
  }

  ApartmentUnitDraft? _findUnit(
    List<ApartmentUnitDraft> drafts, {
    required String unitId,
    required String unitName,
  }) {
    final id = unitId.trim();
    final name = unitName.trim().toLowerCase();
    if (id.isEmpty && name.isEmpty) return null;
    if (id.isNotEmpty) {
      for (final unit in drafts) {
        if (unit.unitId.trim() == id) return unit;
      }
    }
    if (name.isEmpty) return null;
    for (final unit in drafts) {
      if (unit.unitName.trim().toLowerCase() == name) return unit;
    }
    return null;
  }

  ApartmentUnitDraft? _preferredUnitForFlow(List<ApartmentUnitDraft> drafts) {
    if (drafts.isEmpty) return null;
    if (drafts.length == 1) return drafts.first;
    if (!_routeWorkspaceExplicit) return null;
    for (final u in drafts) {
      final um = u.operationMode.trim().toLowerCase();
      if (_routePrefersRent && um == 'rent') return u;
      if (!_routePrefersRent && um != 'rent') return u;
    }
    return null;
  }

  String _nameOf(PropertyRecord property) {
    final name = property.propertyName.trim();
    if (name.isNotEmpty) return name;
    return property.propertyLocation.trim();
  }

  /// Name stored on the tenant. The property reference stays in [propertyRef].
  String _propertyNameForSave() {
    final linked = _linkedProperty;
    if (linked != null) {
      final name = _nameOf(linked);
      if (name.isNotEmpty) return name;
    }
    final label = propertyContextLabel.value.trim();
    final ref = propertyRef.value.trim();
    if (label.isEmpty || label == ref) return '';
    if (label.startsWith('local_') || label.startsWith('legacy_')) return '';
    return label;
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
    if (_showAllUnits && unit != null) {
      isRentFlow.value = unit.operationMode == 'rent';
      _syncRentFrequencyForFlow();
      return;
    }
    // Explicit Rent/BnB tab navigation must not be overridden by a unit whose
    // operationMode still defaults to "bnb" on dual-mode properties.
    if (_routeWorkspaceExplicit) {
      isRentFlow.value = _routePrefersRent;
      _syncRentFrequencyForFlow();
      return;
    }

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

  Future<List<ApartmentUnitDraft>> _unitDraftsFor(PropertyRecord property) async {
    final fromJson = _parseUnitDrafts(property.unitsJson);
    final fromTable = await _unitDraftsFromTable(property);
    if (fromJson.isEmpty) return fromTable;
    if (fromTable.isEmpty) return fromJson;

    final merged = [...fromJson];
    final seen = <String>{};
    for (final unit in fromJson) {
      final id = unit.unitId.trim().toLowerCase();
      final name = unit.unitName.trim().toLowerCase();
      if (id.isNotEmpty) seen.add('id:$id');
      if (name.isNotEmpty) seen.add('name:$name');
    }
    for (final unit in fromTable) {
      final id = unit.unitId.trim().toLowerCase();
      final name = unit.unitName.trim().toLowerCase();
      final known = (id.isNotEmpty && seen.contains('id:$id')) ||
          (name.isNotEmpty && seen.contains('name:$name'));
      if (known) continue;
      merged.add(unit);
      if (id.isNotEmpty) seen.add('id:$id');
      if (name.isNotEmpty) seen.add('name:$name');
    }
    return merged;
  }

  Future<List<ApartmentUnitDraft>> _unitDraftsFromTable(
    PropertyRecord property,
  ) async {
    if (!Get.isRegistered<PropertyUnitLocalDataSource>()) return const [];
    final local = Get.find<PropertyUnitLocalDataSource>();
    final refs = <String>{
      property.propertyRef.trim(),
      'local_${property.id}',
      'legacy_${property.id}',
    };
    final seen = <String>{};
    final out = <ApartmentUnitDraft>[];
    for (final ref in refs) {
      if (ref.isEmpty) continue;
      final rows = await local.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
      );
      for (final row in rows) {
        final name = row.unitName.trim();
        if (name.isEmpty) continue;
        final id = row.propertyUnitRef.trim().isNotEmpty
            ? row.propertyUnitRef.trim()
            : '${row.id}';
        if (!seen.add(id.toLowerCase())) continue;
        out.add(
          ApartmentUnitDraft(
            unitId: id,
            unitName: name,
            unitRent: row.rentAmount > 0 ? '${row.rentAmount}' : '',
            unitRentFrequency: row.rentFrequency.trim().isEmpty
                ? 'Per Month'
                : row.rentFrequency.trim(),
            unitFloor: row.floor,
            operationMode: ApartmentUnitDraft.resolveOperationMode(
              row.operationMode,
              row.rentFrequency,
            ),
            unitDescription: row.notes,
            unitRentCurrency: row.rentCurrency,
          ),
        );
      }
    }
    return out;
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
    _leaseTermEnteredByUser = true;
    _refreshStayTotalPreview();
  }

  Future<void> saveTenant() async {
    if (saving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      if (isRentFlow.value) hapticValidationError();
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
    if (replacingOccupiedUnit.value) {
      await _replaceTenantOnUnit(
        unitId: apartmentUnitId,
        unitName: unitLabel,
      );
    }

    final propertyName = _propertyNameForSave();
    final bnbTenantId = await _tenantLocal.insert(
      propertyLabel: propertyName,
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
      propertyLabel: propertyName,
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
      'property_name': propertyName,
      'propertyName': propertyName,
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
    var synced = false;
    try {
      final res = await _repository.createTenant(payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
      final backendId =
          (res.data is Map) ? (res.data as Map)['id']?.toString() ?? '' : '';
      if (backendId.isNotEmpty) {
        await _tenantLocal.saveBackendTenantId(
          localId: bnbTenantId,
          backendId: backendId,
        );
      }
      synced = true;
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

    RemoteAccountSyncService.publishTenantCountFor(propertyRef.value);

    if (replacingOccupiedUnit.value) {
      showSuccessMessage('Tenant replaced');
      await _refreshPropertyTenantSurfaces();
      Get.back(result: true);
      return;
    }

    final units = stayBillingUnits.value;
    if (stayTotal > 0 && units > 0) {
      final nightLabel = units == 1 ? 'night' : 'nights';
      showSuccessMessage(
        '${synced ? 'Tenant saved' : 'Tenant saved offline'}. Total for stay ($units $nightLabel): '
        '${Get.find<CurrencyService>().formatBase(stayTotal.round())}',
      );
    } else {
      showSuccessMessage(synced ? 'Tenant saved' : 'Tenant saved offline');
    }
    await _refreshPropertyTenantSurfaces();
    Get.back(result: true);
  }

  Future<void> _saveRentTenant() async {
    if (!await _ensureLeaseTerm()) return;

    final amountRaw = rentAmountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountRaw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid rent amount');
      return;
    }

    final draft = _draftForKey(selectedUnitKey.value);
    final unitLabel = draft?.unitName.trim() ?? '';
    final apartmentUnitId = draft?.unitId.trim() ?? '';
    if (replacingOccupiedUnit.value) {
      await _replaceTenantOnUnit(
        unitId: apartmentUnitId,
        unitName: unitLabel,
      );
    }
    await _markUnitOccupied(
      unitId: apartmentUnitId,
      unitName: unitLabel,
      tenantName: tenantNameController.text.trim(),
    );

    final propertyName = _propertyNameForSave();
    final rentTenantId = await _tenantLocal.insert(
      propertyLabel: propertyName,
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
      propertyLabel: propertyName,
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
      'property_name': propertyName,
      'propertyName': propertyName,
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
    var synced = false;
    try {
      final res = await _repository.createTenant(rentPayload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'API error');
      final backendId =
          (res.data is Map) ? (res.data as Map)['id']?.toString() ?? '' : '';
      if (backendId.isNotEmpty) {
        await _tenantLocal.saveBackendTenantId(
          localId: rentTenantId,
          backendId: backendId,
        );
      }
      synced = true;
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

    RemoteAccountSyncService.publishTenantCountFor(propertyRef.value);

    await _refreshPropertyTenantSurfaces();

    hapticPrimaryConfirm();
    showSuccessMessage(
      replacingOccupiedUnit.value
          ? 'Tenant replaced'
          : (synced ? 'Tenant saved' : 'Tenant saved offline'),
    );

    final addIncome = await _promptAddIncomeAfterTenant();
    if (addIncome == true) {
      final nav = _incomeNavigationArgs(tenantId: rentTenantId);
      Get.back(result: true);
      await Get.toNamed(
        Routes.RECORD_PAYMENT,
        parameters: {
          if (nav['property'] != null) 'property': nav['property'] as String,
          if (nav['propertyRef'] != null)
            'propertyRef': nav['propertyRef'] as String,
          'tenantId': '$rentTenantId',
        },
        arguments: nav,
      );
      return;
    }

    Get.back(result: true);
  }

  Future<void> _refreshPropertyTenantSurfaces() async {
    await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
    await RentTenantLedgerOccupancyController.refreshIfRegistered();
    await ListingDetailsController.refreshIfRegistered();
    await RentExpectedPaymentScheduleController.refreshIfRegistered();
    await MyPropertiesController.refreshIfRegistered();
    await AllTenantsController.refreshIfRegistered();
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

  Map<String, dynamic> _incomeNavigationArgs({required int tenantId}) {
    final p = _linkedProperty;
    final propertyOption = p == null
        ? propertyContextLabel.value.trim()
        : (p.propertyName.trim().isNotEmpty
              ? p.propertyName.trim()
              : p.propertyLocation.trim());
    return {
      'property': propertyOption,
      'propertyRef': propertyRef.value.trim(),
      'tenantId': tenantId,
      'prefillIncome': {
        'tenantId': tenantId,
        'tenantName': tenantNameController.text.trim(),
        'amount': rentAmountController.text.trim().replaceAll(',', ''),
        'unitSelectionKey': selectedUnitKey.value,
        'categoryIndex': 0,
      },
    };
  }

  Future<bool> _ensureLeaseTerm() async {
    if (_leaseTermEnteredByUser &&
        leaseStart.value != null &&
        leaseEnd.value != null) {
      return true;
    }
    final months = await _promptLeaseTermMonths();
    if (months == null) return false;
    final now = DateTime.now();
    final start = leaseStart.value ?? DateTime(now.year, now.month, now.day);
    leaseStart.value = start;
    leaseEnd.value = _addCalendarMonths(start, months);
    _leaseTermEnteredByUser = true;
    _refreshStayTotalPreview();
    return true;
  }

  Future<int?> _promptLeaseTermMonths() async {
    final controller = TextEditingController();
    final result = await Get.dialog<int>(
      AlertDialog(
        title: Text(_t('Enter lease term', 'Weka muda wa mkataba')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(
                'How many months is this tenancy?',
                'Mkataba huu ni miezi mingapi?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _t('Months', 'Miezi'),
                hintText: '6',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            onPressed: () {
              final months = int.tryParse(controller.text.trim());
              if (months == null || months <= 0) {
                Get.snackbar(
                  _t('Lease term', 'Muda wa mkataba'),
                  _t('Enter the number of months', 'Weka idadi ya miezi'),
                );
                return;
              }
              Get.back(result: months);
            },
            child: Text(_t('Save', 'Hifadhi')),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    controller.dispose();
    return result;
  }

  static DateTime _addCalendarMonths(DateTime start, int months) {
    final targetMonth = start.month + months;
    final year = start.year + ((targetMonth - 1) ~/ 12);
    final month = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return DateTime(year, month, day);
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

  String? validateLeasePeriod(DateTimeRange? _) {
    if (leaseStart.value == null || leaseEnd.value == null) {
      return 'Lease period is required';
    }
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
