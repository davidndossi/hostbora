import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/offline_sync_worker_service.dart';
import '../../../../data/model/add_expense_request.dart';
import '../../add_new_listing/models/apartment_unit_draft.dart';

class RentAddNewExpenseController extends BaseController {
  RentAddNewExpenseController()
      : _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        );

  final ExpenseLocalDataSource _expenseLocal;
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

  /// Expense category options (single selection).
  final expenses = const ['Maintenance', 'Utilities', 'Salary', 'Other'];

  final selectedExpenseIndex = 0.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;
  /// Optional apartment unit ([ApartmentUnitDraft.selectionKey]); null = not specified.
  final selectedExpenseUnitKey = Rxn<String>();

  List<PropertyRecord> _propertyRows = [];

  String get selectedExpense => expenses[selectedExpenseIndex.value];
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

  List<ApartmentUnitDraft> get expenseUnitsForSelectedProperty {
    selectedProperty.value;
    final r = selectedPropertyRecord;
    if (r == null) return const [];
    return _parseUnitsJson(r.unitsJson);
  }

  bool get showExpenseUnitPicker {
    selectedProperty.value;
    final r = selectedPropertyRecord;
    if (r == null) return false;
    if (r.propertyType.trim().toLowerCase() != 'apartment') return false;
    return expenseUnitsForSelectedProperty.isNotEmpty;
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
    final key = selectedExpenseUnitKey.value?.trim();
    if (key == null || key.isEmpty) return '';
    for (final u in expenseUnitsForSelectedProperty) {
      if (u.selectionKey == key) {
        return 'Unit: ${u.unitName.trim()}';
      }
    }
    return '';
  }

  ApartmentUnitDraft? _draftForExpenseUnitKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    for (final u in expenseUnitsForSelectedProperty) {
      if (u.selectionKey == key) return u;
    }
    return null;
  }

  /// Same rules as rent hub: match [RentTenantRecord] to property by ref or label.
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
    final key = selectedExpenseUnitKey.value?.trim();
    final prop = selectedPropertyRecord;
    if (key == null || key.isEmpty || prop == null) {
      return;
    }
    final unit = _draftForExpenseUnitKey(key);
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
    _loadProperties();
  }

  void selectExpense(int index) {
    if (index >= 0 && index < expenses.length) {
      selectedExpenseIndex.value = index;
    }
  }

  Future<void> _loadProperties() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: 'rent',
    );
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

    final fromRoute = Get.parameters['property']?.trim() ?? '';
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
    selectedExpenseUnitKey.value = null;
    selectedProperty.value = value;
    tenantController.clear();
  }

  void updateSelectedExpenseUnit(String? unitKey) {
    selectedExpenseUnitKey.value = unitKey;
    if (unitKey == null || unitKey.trim().isEmpty) {
      return;
    }
    _syncTenantFieldToSelectedUnit();
  }

  Future<void> saveExpenseOffline() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedProperty.value.trim().isEmpty) {
      showErrorMessage('Please select a property');
      return;
    }

    final amountRaw = amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountRaw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid amount greater than 0');
      return;
    }

    final dateRaw = datePaidController.text.trim();
    DateTime paidDate;
    try {
      paidDate = DateFormat('dd/MM/yyyy').parseStrict(dateRaw);
    } catch (_) {
      showErrorMessage('Use date format dd/MM/yyyy');
      return;
    }

    final property = selectedProperty.value.trim();
    final unitDraft = _draftForExpenseUnitKey(selectedExpenseUnitKey.value);
    final unitName = unitDraft?.unitName.trim() ?? '';
    final unitLine = _optionalUnitNotesLine();
    final baseNotes = StringBuffer('Property: $property');
    if (unitLine.isNotEmpty) {
      baseNotes.write(", ");
      baseNotes.writeln(unitLine);
    }
    final extra = notesController.text.trim();
    if (extra.isNotEmpty) {
      baseNotes.write(" ");
      baseNotes.writeln(extra);
    }
    await _expenseLocal.insert(
      tenantName: tenantController.text.trim(),
      amountValue: amount,
      datePaidIso: DateFormat('yyyy-MM-dd').format(paidDate),
      category: selectedExpense,
      workspaceType: 'rent',
      notes: baseNotes.toString().trim(),
      apartment: property,
      apartmentUnit: unitName,
    );

    final request = AddExpenseRequest(
      amount: amount,
      category: selectedExpense,
      expenseDate: DateFormat('yyyy-MM-dd').format(paidDate),
      vendor: tenantController.text.trim().isNotEmpty
          ? tenantController.text.trim()
          : property,
      taxDeductible: true,
      description: baseNotes.toString().trim(),
    );
    await _syncQueue.enqueue(
      entityType: 'expense',
      operation: 'create',
      payloadJson: jsonEncode(request.toJson()),
    );
    await _syncWorker.runNow(maxItems: 20);
    final pending = await _syncQueue.pendingCountByEntity(
      entityType: 'expense',
      operation: 'create',
    );
    if (pending > 0) {
      showSuccessMessage('Expense saved offline. Will sync when internet is available.');
    } else {
      showSuccessMessage('Expense saved and synced.');
    }
    Get.back(result: true);
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
    if (v.isEmpty) return 'Transaction date is required';
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
