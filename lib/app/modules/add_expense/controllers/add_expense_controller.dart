import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/money_input_helper.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/inventory_item_local_data_source.dart';
import '../../../data/local/db/inventory_movement_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/local/service/remote_account_sync_service.dart';
import '../../../data/model/add_expense_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../add_listing/models/apartment_unit_draft.dart';

class AddExpenseController extends BaseController {
  AddExpenseController()
    : _expenseLocal = Get.find<ExpenseLocalDataSource>(),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _tenantLocal = Get.find<TenantLocalDataSource>(),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>(),
      _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      );

  final ExpenseLocalDataSource _expenseLocal;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;
  final AppRepository _repository;
  final PreferenceManager _preferenceManager;

  final tenantController = TextEditingController();
  final amountController = TextEditingController();
  final datePaidController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Expense category options (single selection).
  final expenses = const [
    'Supplies',
    'Maintenance',
    'Utilities',
    'Salary',
    'Yearly tax',
    'Other',
  ];

  /// Categories that likely involve physical items that should be restocked.
  static const _restockCategories = {'Supplies', 'Maintenance'};
  bool get isRestockCategory =>
      _restockCategories.contains(selectedExpense);

  final selectedExpenseIndex = 0.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;

  /// Optional apartment unit ([ApartmentUnitDraft.selectionKey]); null = not specified.
  final selectedExpenseUnitKey = Rxn<String>();
  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;
  final editExpenseId = RxnInt();

  List<PropertyRecord> _propertyRows = [];

  String get selectedExpense => expenses[selectedExpenseIndex.value];
  bool get hasProperties => propertyOptions.isNotEmpty;
  bool get isEditMode => editExpenseId.value != null;

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

  String _workspaceForExpenseSave(ApartmentUnitDraft? unitDraft) {
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

  /// Same rules as rent hub: match [RentTenantRecord] to property by ref or label.
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
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    _captureEditArgs();
    _loadProperties().then((_) => _loadExpenseForEdit());
  }

  void _captureEditArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    final raw = args['expenseId'];
    final id = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (id != null && id > 0) {
      editExpenseId.value = id;
    }
  }

  void selectExpense(int index) {
    if (index >= 0 && index < expenses.length) {
      selectedExpenseIndex.value = index;
    }
  }

  Future<void> _loadProperties() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    // Same as Record Payment: without a selected property, do not default to
    // "bnb" or the dropdown stays empty for rent-only portfolios.
    final propertyMode = selectedPropertyRecord != null
        ? _normalizeWorkspace(selectedPropertyRecord?.workspaceType)
        : 'all';
    var rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: propertyMode,
    );
    if (rows.isEmpty && userId.isNotEmpty) {
      rows = await _propertyLocal.getAllVisibleNewestFirst(
        userId: '',
        workspaceType: propertyMode,
      );
    }
    if (rows.isEmpty) {
      rows = await _propertyLocal.getAllNewestFirst();
    }
    if (rows.isEmpty) {
      try {
        if (Get.isRegistered<RemoteAccountSyncService>()) {
          await Get.find<RemoteAccountSyncService>().syncPropertiesFromRemote();
        }
        rows = await _propertyLocal.getAllVisibleNewestFirst(
          userId: userId,
          workspaceType: propertyMode,
        );
        if (rows.isEmpty) {
          rows = await _propertyLocal.getAllNewestFirst();
        }
      } catch (_) {}
    }
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

    final fromRoute = isEditMode
        ? ''
        : (Get.parameters['property']?.trim() ?? '');
    if (fromRoute.isNotEmpty && options.contains(fromRoute)) {
      selectedProperty.value = fromRoute;
      return;
    }
    if (!isEditMode && options.length == 1) {
      selectedProperty.value = options.first;
    }
  }

  Future<void> _loadExpenseForEdit() async {
    final id = editExpenseId.value;
    if (id == null) return;
    final row = await _expenseLocal.getById(id);
    if (row == null) {
      showErrorMessage('Expense not found');
      return;
    }
    tenantController.text = row.tenantName.trim();
    amountController.text = _formatAmountForInput(
      row.inputAmountValue > 0 ? row.inputAmountValue : row.amountValue,
    );
    selectedCurrency.value = row.currencyCode.trim().isEmpty
        ? Get.find<CurrencyService>().baseCurrency.value
        : row.currencyCode.trim().toUpperCase();
    datePaidController.text = _formatDateForInput(
      row.datePaidIso,
      row.createdAtMs,
    );
    notesController.text = _editableNotesFromStored(row.notes);

    final categoryIndex = expenses.indexWhere(
      (e) => e.toLowerCase() == row.category.trim().toLowerCase(),
    );
    if (categoryIndex >= 0) {
      selectedExpenseIndex.value = categoryIndex;
    }

    final property = row.apartment.trim();
    if (property.isNotEmpty) {
      if (!propertyOptions.contains(property)) {
        propertyOptions.add(property);
      }
      selectedProperty.value = property;
    }

    final unit = row.apartmentUnit.trim();
    if (unit.isNotEmpty) {
      for (final draft in expenseUnitsForSelectedProperty) {
        if (draft.unitName.trim().toLowerCase() == unit.toLowerCase()) {
          selectedExpenseUnitKey.value = draft.selectionKey;
          break;
        }
      }
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

  /// Returns `true` when the expense was saved (and the screen was closed).
  /// Returns `false` when validation failed or an error occurred — callers
  /// outside [BaseView] (e.g. quick-add wizard) should surface
  /// [errorMessage] themselves.
  Future<bool> saveExpenseOffline() async {
    // Only validate FormState when a Form is mounted (full Add Expense
    // screen). The quick-add expense wizard has no Form(key: formKey), so
    // formKey.currentState is null — treating that as failure made Submit
    // return immediately with no feedback.
    final formState = formKey.currentState;
    if (formState != null && !formState.validate()) return false;
    if (selectedProperty.value.trim().isEmpty) {
      showErrorMessage('Please select a property');
      return false;
    }

    final parsed = _parseMoneyForSave(amountController.text.trim());
    if (parsed == null) return false;
    if (parsed.inputAmount <= 0) {
      showErrorMessage('Enter a valid amount greater than 0');
      return false;
    }

    final dateRaw = datePaidController.text.trim();
    DateTime paidDate;
    try {
      paidDate = DateFormat('dd/MM/yyyy').parseStrict(dateRaw);
    } catch (_) {
      showErrorMessage('Use date format dd/MM/yyyy');
      return false;
    }

    try {
      final saved = await runBusy(() async {
        final property = selectedProperty.value.trim();
        final unitDraft = _draftForExpenseUnitKey(selectedExpenseUnitKey.value);
        final unitName = unitDraft?.unitName.trim() ?? '';
        final workspaceType = _workspaceForExpenseSave(unitDraft);
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
        final notesStr = baseNotes.toString().trim();
        final isoDate = DateFormat('yyyy-MM-dd').format(paidDate);
        final vendor = tenantController.text.trim().isNotEmpty
            ? tenantController.text.trim()
            : property;

        final request = AddExpenseRequest(
          amount: parsed.baseAmount,
          category: selectedExpense,
          expenseDate: isoDate,
          vendor: vendor,
          taxDeductible: true,
          description: notesStr,
        );

        final editId = editExpenseId.value;
        if (editId != null) {
          // ── Edit mode: update locally first ──────────────────────────────
          await _expenseLocal.update(
            id: editId,
            tenantName: tenantController.text.trim(),
            amountValue: parsed.baseAmount,
            datePaidIso: isoDate,
            category: selectedExpense,
            workspaceType: workspaceType,
            notes: notesStr,
            apartment: property,
            apartmentUnit: unitName,
            currencyCode: parsed.currency,
            inputAmountValue: parsed.inputAmount,
          );

          // Try to update on backend if we have the backend UUID
          final backendId = await _expenseLocal.getBackendExpenseId(editId);
          if (backendId != null) {
            try {
              await _repository.updateExpense(backendId, request);
            } catch (_) {
              // Queue for later retry
              await _syncQueue.enqueue(
                entityType: 'expense',
                operation: 'update',
                payloadJson: jsonEncode({
                  ...request.toJson(),
                  'backendExpenseId': backendId,
                }),
                dedupeKey: 'expense:update:$backendId',
              );
              Future.microtask(() => _syncWorker.runNow(maxItems: 5));
            }
          }

          showSuccessMessage('Expense updated.');
          Get.back(result: true);
          return true;
        }

        // ── Create mode: save locally ─────────────────────────────────────
        final localExpenseId = await _expenseLocal.insert(
          tenantName: tenantController.text.trim(),
          amountValue: parsed.baseAmount,
          datePaidIso: isoDate,
          category: selectedExpense,
          workspaceType: workspaceType,
          notes: notesStr,
          apartment: property,
          apartmentUnit: unitName,
          currencyCode: parsed.currency,
          inputAmountValue: parsed.inputAmount,
        );

        // Try to save to backend directly; queue as fallback
        try {
          final res = await _repository.addExpense(request);
          final ok = res.responseCode == '0' ||
              res.responseCode == '200' ||
              res.responseCode == '201';
          if (ok) {
            // Persist backend UUID for future edits
            final backendId = (res.data is Map)
                ? (res.data as Map)['expenseId']?.toString() ?? ''
                : '';
            if (backendId.isNotEmpty) {
              await _expenseLocal.saveBackendExpenseId(
                localId: localExpenseId,
                backendId: backendId,
              );
            }
            showSuccessMessage('Expense saved and synced.');
            await _maybePromptRestock(propertyRef: _propertyRefForExpense());
            Get.back(result: true);
            return true;
          }
        } catch (_) {
          // Fall through to offline queue
        }

        // Backend unreachable – queue for later
        await _syncQueue.enqueue(
          entityType: 'expense',
          operation: 'create',
          payloadJson: jsonEncode({
            ...request.toJson(),
            'localExpenseId': localExpenseId,
          }),
          dedupeKey: 'expense:create:$localExpenseId',
        );
        Future.microtask(() => _syncWorker.runNow(maxItems: 20));
        showSuccessMessage(
          'Expense saved. Will sync when internet is available.',
        );
        await _maybePromptRestock(propertyRef: _propertyRefForExpense());
        Get.back(result: true);
        return true;
      });
      return saved ?? false;
    } catch (_) {
      showErrorMessage(
        'Failed to save expense. Please try again.',
      );
      return false;
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

  static String _formatAmountForInput(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  static String _formatDateForInput(String iso, int createdAtMs) {
    DateTime date;
    try {
      date = DateTime.parse(iso.trim());
    } catch (_) {
      date = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String _editableNotesFromStored(String value) {
    var text = value.trim();
    text = text.replaceFirst(RegExp(r'^Property:\s*[^,\n]+,?\s*'), '');
    text = text.replaceFirst(RegExp(r'^Unit:\s*[^,\n]+,?\s*'), '');
    return text.trim();
  }

  @override
  void onClose() {
    tenantController.dispose();
    amountController.dispose();
    datePaidController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ── Expense → restock linkage ────────────────────────────────────────────

  String _propertyRefForExpense() {
    final rec = selectedPropertyRecord;
    if (rec == null) return '';
    final ref = rec.propertyRef.trim();
    return ref.isNotEmpty ? ref : 'local_${rec.id}';
  }

  Future<void> _maybePromptRestock({required String propertyRef}) async {
    if (!isRestockCategory) return;
    if (propertyRef.isEmpty) return;

    final isSw = Get.locale?.languageCode == 'sw';
    await Get.dialog(
      AlertDialog(
        title: Text(
          isSw ? 'Ongeza hisa tena?' : 'Record a restock?',
        ),
        content: Text(
          isSw
              ? 'Gharama ya "${selectedExpense}" imehifadhiwa. Je, ungependa kurekodi '
                  'ongezeko la hisa kwa mali hii?'
              : 'The "${selectedExpense}" expense was saved. Would you like to record '
                  'a restock movement for an inventory item on this property?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(isSw ? 'Hapana' : 'Skip'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _openRestockPicker(propertyRef: propertyRef);
            },
            child: Text(
              isSw ? 'Ndio' : 'Yes',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRestockPicker({required String propertyRef}) async {
    final isSw = Get.locale?.languageCode == 'sw';
    final itemSrc = Get.find<InventoryItemLocalDataSource>();
    final movementSrc = Get.find<InventoryMovementLocalDataSource>();

    final items = await itemSrc.listAllForProperty(propertyRef);
    if (items.isEmpty) {
      showErrorMessage(
        isSw
            ? 'Hakuna vifaa vilivyorekodiwa kwa mali hii.'
            : 'No inventory items found for this property.',
      );
      return;
    }

    // Simple selection dialog
    InventoryItemRecord? picked;
    await Get.dialog<void>(
      AlertDialog(
        title: Text(isSw ? 'Chagua kifaa' : 'Select item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              return ListTile(
                title: Text(it.name),
                subtitle: Text('${it.category} · qty ${it.quantity}'),
                onTap: () {
                  picked = it;
                  Get.back();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(isSw ? 'Ghairi' : 'Cancel'),
          ),
        ],
      ),
    );

    if (picked == null) return;

    final qty = await _askRestockQty(isSw: isSw);
    if (qty == null || qty <= 0) return;

    final clientMovementId =
        'restock_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
    await movementSrc.insert(
      itemLocalId: picked!.id,
      clientMovementId: clientMovementId,
      movementType: 'restock',
      quantityDelta: qty,
      notes: isSw
          ? 'Kutoka gharama ya $selectedExpense'
          : 'From $selectedExpense expense',
    );
    final newQty = picked!.quantity + qty;
    await itemSrc.updateQuantity(picked!.id, newQty);

    final pickedName = picked!.name;
    showSuccessMessage(isSw
        ? 'Hisa ya "$pickedName" imesasishwa (+$qty).'
        : '"$pickedName" restocked (+$qty).');
  }

  Future<int?> _askRestockQty({required bool isSw}) async {
    final ctrl = TextEditingController(text: '1');
    int? result;
    await Get.dialog<void>(
      AlertDialog(
        title: Text(isSw ? 'Idadi ya ziada' : 'Restock quantity'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isSw ? 'Idadi' : 'Quantity',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: Get.back, child: Text(isSw ? 'Ghairi' : 'Cancel')),
          TextButton(
            onPressed: () {
              result = int.tryParse(ctrl.text.trim());
              Get.back();
            },
            child: Text(isSw ? 'Hifadhi' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }
}
