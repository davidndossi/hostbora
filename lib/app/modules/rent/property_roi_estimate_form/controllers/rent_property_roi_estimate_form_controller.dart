import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/app/core/base/base_controller.dart';
import '/app/data/local/db/rent_property_estimate_local_data_source.dart';

class RentPropertyRoiEstimateFormController extends BaseController {
  RentPropertyRoiEstimateFormController()
      : _estimateLocal = Get.find<RentPropertyEstimateLocalDataSource>();

  final RentPropertyEstimateLocalDataSource _estimateLocal;

  final formKey = GlobalKey<FormState>();

  final purchaseCostController = TextEditingController();
  final renovationCostController = TextEditingController();
  final expectedMonthlyIncomeController = TextEditingController();
  final expectedMonthlyExpenseController = TextEditingController();
  final targetOccupancyController = TextEditingController();

  final saving = false.obs;

  String get propertyRef => (Get.parameters['propertyRef'] ?? '').trim();
  String get propertyLabel {
    final label = (Get.parameters['propertyLabel'] ?? '').trim();
    return label.isEmpty ? 'Property' : label;
  }

  @override
  void onReady() {
    super.onReady();
    _loadExisting();
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

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (propertyRef.isEmpty) {
      showErrorMessage('Property reference missing');
      return;
    }
    saving.value = true;
    try {
      await _estimateLocal.upsert(
        propertyRef: propertyRef,
        propertyLabel: propertyLabel,
        purchaseCost: double.parse(purchaseCostController.text.replaceAll(',', '')),
        renovationCost: double.parse(renovationCostController.text.replaceAll(',', '')),
        expectedMonthlyIncome: double.parse(expectedMonthlyIncomeController.text.replaceAll(',', '')),
        expectedMonthlyExpense: double.parse(expectedMonthlyExpenseController.text.replaceAll(',', '')),
        targetOccupancyPercent: double.parse(targetOccupancyController.text.replaceAll(',', '')),
      );
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
    purchaseCostController.dispose();
    renovationCostController.dispose();
    expectedMonthlyIncomeController.dispose();
    expectedMonthlyExpenseController.dispose();
    targetOccupancyController.dispose();
    super.onClose();
  }
}
