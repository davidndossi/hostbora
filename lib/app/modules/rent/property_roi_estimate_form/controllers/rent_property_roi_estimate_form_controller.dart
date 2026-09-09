import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/app/core/base/base_controller.dart';
import '/app/data/local/db/offline_sync_queue_local_data_source.dart';
import '/app/data/local/db/rent_property_estimate_local_data_source.dart';
import '/app/data/local/service/currency_service.dart';
import '/app/data/local/service/offline_sync_worker_service.dart';
import '/app/data/local/service/property_break_even_notification_service.dart';
import '/app/data/repository/app_repository.dart';

enum EstimateInputMode { approximate, itemized }

class EstimateCostItem {
  const EstimateCostItem({
    required this.startDate,
    required this.completionDate,
    required this.category,
    required this.materialName,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
    required this.supplier,
    required this.paymentMethod,
    required this.receiptPath,
  });

  final DateTime startDate;
  final DateTime completionDate;
  final String category;
  final String materialName;
  final String description;
  final double quantity;
  final String unit;
  final double unitCost;
  final double totalCost;
  final String supplier;
  final String paymentMethod;
  final String receiptPath;
}

class RentPropertyRoiEstimateFormController extends BaseController {
  RentPropertyRoiEstimateFormController()
      : _estimateLocal = Get.find<RentPropertyEstimateLocalDataSource>(),
        _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final RentPropertyEstimateLocalDataSource _estimateLocal;
  final AppRepository _repository;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();

  final purchaseCostController = TextEditingController();
  final renovationCostController = TextEditingController();
  final expectedMonthlyIncomeController = TextEditingController();
  final expectedMonthlyExpenseController = TextEditingController();
  final targetOccupancyController = TextEditingController();
  final approximateTotalController = TextEditingController();

  final materialNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final unitCostController = TextEditingController();
  final supplierController = TextEditingController();
  final receiptPathController = TextEditingController();
  final searchController = TextEditingController();

  final mode = EstimateInputMode.approximate.obs;
  final selectedCategory = 'Structural Materials'.obs;
  final selectedUnit = 'kilo'.obs;
  final selectedPaymentMethod = 'Cash'.obs;
  final startDate = Rxn<DateTime>();
  final completionDate = Rxn<DateTime>();

  final filterCategory = 'All'.obs;
  final filterStartDate = Rxn<DateTime>();
  final filterEndDate = Rxn<DateTime>();

  final saving = false.obs;
  final entries = <EstimateCostItem>[].obs;
  final draftTotal = 0.0.obs;

  static const Map<String, List<String>> groupedMaterials = {
    'Structural Materials': ['Cement', 'Sand', 'Aggregates (gravel)', 'Steel (rebars, rods)', 'Blocks / Bricks'],
    'Plumbing Materials': ['Pipes (PVC, PPR)', 'Fittings', 'Water tanks', 'Bathroom fixtures'],
    'Electrical Materials': ['Wires & cables', 'Switches & sockets', 'Breakers', 'Lighting'],
    'Finishing Materials': ['Tiles', 'Paint', 'Doors & windows', 'Ceiling materials'],
    'Labor & Services': ['Masonry', 'Carpentry', 'Electrical labor', 'Plumbing labor'],
    'Logistics & Miscellaneous': ['Transport', 'Fuel', 'Equipment rental', 'Permits'],
  };

  static const List<String> unitOptions = [
    'kilo',
    'kg',
    'bags',
    'tons',
    'pieces',
    'meters',
    'liters',
    'hours',
    'days',
  ];
  static const List<String> paymentMethodOptions = [
    'Cash',
    'Bank',
    'Mobile Money',
    'Cheque',
    'Credit',
  ];

  final selectedCurrency = CurrencyService.defaultBaseCurrency.obs;

  String get propertyRef => (Get.parameters['propertyRef'] ?? '').trim();

  String get propertyLabel {
    final label = (Get.parameters['propertyLabel'] ?? '').trim();
    if (label.isNotEmpty) return label;
    final name = propertyName;
    final loc = propertyAddress;
    if (name.isNotEmpty && loc.isNotEmpty) return '$name · $loc';
    return name.isNotEmpty ? name : 'Property';
  }

  String get propertyName {
    final fromParam = (Get.parameters['propertyName'] ?? '').trim();
    if (fromParam.isNotEmpty) return fromParam;
    final label = (Get.parameters['propertyLabel'] ?? '').trim();
    if (label.contains('·')) {
      return label.split('·').first.trim();
    }
    return label.isEmpty ? 'Property' : label;
  }

  String get propertyAddress {
    final fromParam = (Get.parameters['propertyLocation'] ??
            Get.parameters['propertyAddress'] ??
            '')
        .trim();
    if (fromParam.isNotEmpty) return fromParam;
    final label = (Get.parameters['propertyLabel'] ?? '').trim();
    if (label.contains('·')) {
      return label.split('·').skip(1).join('·').trim();
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    selectedCurrency.value = Get.find<CurrencyService>().baseCurrency.value;
    selectedUnit.value = 'kilo';
    quantityController.addListener(_syncDraftTotal);
    unitCostController.addListener(_syncDraftTotal);
  }

  @override
  void onReady() {
    super.onReady();
    _loadExisting();
  }

  void _syncDraftTotal() {
    final q = double.tryParse(
          quantityController.text.trim().replaceAll(',', ''),
        ) ??
        0;
    final u = double.tryParse(
          unitCostController.text.trim().replaceAll(',', ''),
        ) ??
        0;
    draftTotal.value = q * u;
  }

  Future<void> _loadExisting() async {
    if (propertyRef.isEmpty) return;
    final existing = await _estimateLocal.findByPropertyRef(propertyRef);
    if (existing == null) return;
    purchaseCostController.text = existing.purchaseCost.toStringAsFixed(0);
    renovationCostController.text = existing.renovationCost.toStringAsFixed(0);
    expectedMonthlyIncomeController.text = existing.expectedMonthlyIncome.toStringAsFixed(0);
    expectedMonthlyExpenseController.text = existing.expectedMonthlyExpense.toStringAsFixed(0);
    targetOccupancyController.text = existing.targetOccupancyPercent.toStringAsFixed(0);
    approximateTotalController.text = (existing.purchaseCost + existing.renovationCost).toStringAsFixed(0);
  }

  String? validateRequiredAmount(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Required';
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null || parsed < 0) return 'Enter valid amount';
    return null;
  }

  String? validatePercent(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Required';
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null || parsed < 0 || parsed > 100) return '0 - 100 only';
    return null;
  }

  List<String> get expenseCategories => groupedMaterials.keys.toList();
  List<String> get filterCategories => ['All', ...expenseCategories];

  List<EstimateCostItem> get filteredEntries {
    final query = searchController.text.trim().toLowerCase();
    return entries.where((e) {
      if (filterCategory.value != 'All' && e.category != filterCategory.value) {
        return false;
      }
      if (filterStartDate.value != null && e.startDate.isBefore(filterStartDate.value!)) {
        return false;
      }
      if (filterEndDate.value != null && e.completionDate.isAfter(filterEndDate.value!)) {
        return false;
      }
      if (query.isEmpty) return true;
      return e.materialName.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, double> get categoryTotals {
    final out = <String, double>{};
    for (final e in filteredEntries) {
      out[e.category] = (out[e.category] ?? 0) + e.totalCost;
    }
    return out;
  }

  double get totalProjectCost {
    if (mode.value == EstimateInputMode.approximate) {
      return double.tryParse(approximateTotalController.text.trim().replaceAll(',', '')) ?? 0;
    }
    return categoryTotals.values.fold<double>(0, (a, b) => a + b);
  }

  String get highestCostCategory {
    String best = '';
    var top = 0.0;
    categoryTotals.forEach((k, v) {
      if (v > top) {
        top = v;
        best = k;
      }
    });
    return best;
  }

  double categoryPercent(String category) {
    final total = totalProjectCost;
    if (total <= 0) return 0;
    return ((categoryTotals[category] ?? 0) / total) * 100;
  }

  void setMode(EstimateInputMode next) => mode.value = next;

  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      initialDate: startDate.value ?? DateTime.now(),
    );
    if (picked != null) startDate.value = picked;
  }

  Future<void> pickCompletionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      initialDate: completionDate.value ?? startDate.value ?? DateTime.now(),
    );
    if (picked != null) completionDate.value = picked;
  }

  Future<void> pickFilterRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
      locale: const Locale('en', 'GB'),
      initialDateRange: (filterStartDate.value != null && filterEndDate.value != null)
          ? DateTimeRange(start: filterStartDate.value!, end: filterEndDate.value!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (range == null) return;
    filterStartDate.value = range.start;
    filterEndDate.value = range.end;
  }

  void clearFilters() {
    filterCategory.value = 'All';
    filterStartDate.value = null;
    filterEndDate.value = null;
    searchController.clear();
    entries.refresh();
  }

  void addItemCost() {
    if (startDate.value == null || completionDate.value == null) {
      showErrorMessage('Start and completion dates are required');
      return;
    }
    final name = materialNameController.text.trim();
    if (name.isEmpty) {
      showErrorMessage('Material/Item name is required');
      return;
    }
    final qty = double.tryParse(quantityController.text.trim().replaceAll(',', ''));
    final unitCost = double.tryParse(unitCostController.text.trim().replaceAll(',', ''));
    if (qty == null || qty <= 0 || unitCost == null || unitCost < 0) {
      showErrorMessage('Enter valid quantity and unit cost');
      return;
    }
    entries.add(
      EstimateCostItem(
        startDate: startDate.value!,
        completionDate: completionDate.value!,
        category: selectedCategory.value,
        materialName: name,
        description: descriptionController.text.trim(),
        quantity: qty,
        unit: selectedUnit.value,
        unitCost: unitCost,
        totalCost: qty * unitCost,
        supplier: supplierController.text.trim(),
        paymentMethod: selectedPaymentMethod.value.trim(),
        receiptPath: receiptPathController.text.trim(),
      ),
    );
    materialNameController.clear();
    descriptionController.clear();
    quantityController.text = '1';
    unitCostController.clear();
    supplierController.clear();
    receiptPathController.clear();
    selectedPaymentMethod.value = 'Cash';
    entries.refresh();
    showSuccessMessage(
      Get.locale?.languageCode == 'sw'
          ? 'Kipengele kimeongezwa'
          : 'Cost item added',
    );
  }

  Future<void> pickReceipt() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked == null) return;
      receiptPathController.text = picked.path;
      entries.refresh();
    } catch (_) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Imeshindikana kuchagua risiti'
            : 'Could not pick receipt',
      );
    }
  }

  void clearReceipt() {
    receiptPathController.clear();
    entries.refresh();
  }

  void removeEntry(int index) {
    if (index < 0 || index >= entries.length) return;
    entries.removeAt(index);
  }

  void exportExcel() => showSuccessMessage('Excel export prepared');
  void exportPdf() => showSuccessMessage('PDF export prepared');

  Future<void> save() async {
    if (propertyRef.isEmpty) {
      showErrorMessage('Property reference missing');
      return;
    }
    if (mode.value == EstimateInputMode.approximate) {
      if (!(formKey.currentState?.validate() ?? false)) return;
    } else {
      if (entries.isEmpty) {
        showErrorMessage('Add at least one item cost');
        return;
      }
    }
    saving.value = true;
    try {
      final total = totalProjectCost;
      final expectedIncome =
          double.tryParse(expectedMonthlyIncomeController.text.replaceAll(',', '').trim()) ?? 0;
      final expectedExpense =
          double.tryParse(expectedMonthlyExpenseController.text.replaceAll(',', '').trim()) ?? 0;
      final targetOccupancy =
          double.tryParse(targetOccupancyController.text.replaceAll(',', '').trim()) ?? 0;
      await _estimateLocal.upsert(
        propertyRef: propertyRef,
        propertyLabel: propertyLabel,
        purchaseCost: total,
        renovationCost: 0,
        expectedMonthlyIncome: expectedIncome,
        expectedMonthlyExpense: expectedExpense,
        targetOccupancyPercent: targetOccupancy,
      );

      final existing = await _estimateLocal.findByPropertyRef(propertyRef);
      final payload = <String, dynamic>{
        'propertyRef': propertyRef,
        'propertyLabel': propertyLabel,
        'purchaseCost': total,
        'renovationCost': 0,
        'expectedMonthlyIncome': expectedIncome,
        'expectedMonthlyExpense': expectedExpense,
        'targetOccupancyPercent': targetOccupancy,
      };
      try {
        final res = await _repository.saveEstimate(payload);
        final ok = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (!ok) throw Exception(res.message ?? 'API error');
      } catch (_) {
        await _syncQueue.enqueue(
          entityType: 'estimate',
          operation: existing != null ? 'update' : 'create',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'estimate:create:$propertyRef',
        );
        _syncWorker.runNow();
      }

      await PropertyBreakEvenNotificationService.refreshIfRegistered();
      showSuccessMessage('Estimates saved');
      Get.back(result: true);
    } catch (_) {
      showErrorMessage('Could not save estimates');
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    quantityController.removeListener(_syncDraftTotal);
    unitCostController.removeListener(_syncDraftTotal);
    purchaseCostController.dispose();
    renovationCostController.dispose();
    expectedMonthlyIncomeController.dispose();
    expectedMonthlyExpenseController.dispose();
    targetOccupancyController.dispose();
    approximateTotalController.dispose();
    materialNameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    unitCostController.dispose();
    supplierController.dispose();
    receiptPathController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
