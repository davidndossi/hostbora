import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_expense_local_data_source.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/workspace_context_service.dart';

class RentAddNewExpenseController extends BaseController {
  RentAddNewExpenseController()
      : _expenseLocal = Get.find<RentExpenseLocalDataSource>(),
        _propertyLocal = Get.find<RentPropertyLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        _workspaceContext = Get.find<WorkspaceContextService>();

  final RentExpenseLocalDataSource _expenseLocal;
  final RentPropertyLocalDataSource _propertyLocal;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService _workspaceContext;

  final tenantController = TextEditingController();
  final amountController = TextEditingController();
  final datePaidController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Expense category options (single selection).
  final expenses = const ['Rent', 'Maintenance', 'Utilities', 'Salary', 'Other'];

  final selectedExpenseIndex = 0.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;

  String get selectedExpense => expenses[selectedExpenseIndex.value];
  bool get hasProperties => propertyOptions.isNotEmpty;

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
    final workspaceType = await _workspaceContext.getWorkspaceType();
    final rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspaceType,
    );
    final options = rows
        .map((e) => e.propertyLocation.trim())
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
    selectedProperty.value = value;
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
    await _expenseLocal.insert(
      tenantName: tenantController.text.trim(),
      amountValue: amount,
      datePaidIso: DateFormat('yyyy-MM-dd').format(paidDate),
      category: selectedExpense,
      notes: notesController.text.trim().isEmpty
          ? 'Property: $property'
          : 'Property: $property\n${notesController.text.trim()}',
    );

    showSuccessMessage('Expense saved offline');
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
