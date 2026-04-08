import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_income_local_data_source.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/workspace_context_service.dart';

class RentAddIncomeFormController extends BaseController {
  RentAddIncomeFormController()
      : _incomeLocal = Get.find<RentIncomeLocalDataSource>(),
        _propertyLocal = Get.find<RentPropertyLocalDataSource>(),
        _preferenceManager = Get.find<PreferenceManager>(
          tag: (PreferenceManager).toString(),
        ),
        _workspaceContext = Get.find<WorkspaceContextService>();

  final RentIncomeLocalDataSource _incomeLocal;
  final RentPropertyLocalDataSource _propertyLocal;
  final PreferenceManager _preferenceManager;
  final WorkspaceContextService _workspaceContext;

  final tenantController = TextEditingController();
  final amountController = TextEditingController();
  final datePaidController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Income category options (single selection).
  final categories = const ['Rent', 'Service Charge', 'Maintenance', 'Other'];

  final selectedCategoryIndex = 0.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;

  String get selectedCategory => categories[selectedCategoryIndex.value];
  bool get hasProperties => propertyOptions.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadProperties();
  }

  void selectCategory(int index) {
    if (index >= 0 && index < categories.length) {
      selectedCategoryIndex.value = index;
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

  Future<void> saveIncomeOffline() async {
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

    final amount = double.tryParse(amountRaw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid amount greater than 0');
      return;
    }

    DateTime paidDate;
    try {
      paidDate = DateFormat('MM/dd/yyyy').parseStrict(dateRaw);
    } catch (_) {
      showErrorMessage('Use date format mm/dd/yyyy');
      return;
    }

    await _incomeLocal.insert(
      tenantName: tenant,
      amountValue: amount,
      datePaidIso: DateFormat('yyyy-MM-dd').format(paidDate),
      category: selectedCategory,
      notes: notes.isEmpty ? 'Property: $property' : 'Property: $property\n$notes',
    );

    showSuccessMessage('Income saved offline');
    Get.back(result: true);
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
      DateFormat('MM/dd/yyyy').parseStrict(v);
      return null;
    } catch (_) {
      return 'Use mm/dd/yyyy';
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
