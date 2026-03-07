import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';

class AddExpenseController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final vendorController = TextEditingController();

  final selectedCategory = Rx<String?>(null);
  final taxDeductible = true.obs;
  final selectedDate = Rx<DateTime?>(null);

  final categories = [
    'Maintenance',
    'Utilities',
    'Staffing',
    'Supplies',
    'Cleaning',
    'Insurance',
    'Repairs',
    'Other',
  ];

  void selectCategory(String? value) {
    selectedCategory.value = value;
  }

  void setTaxDeductible(bool value) {
    taxDeductible.value = value;
  }

  Future<void> pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      selectedDate.value = date;
      dateController.text = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  void uploadReceipt() {
    Get.snackbar('Upload', 'Select receipt (PDF, JPG up to 10MB).');
  }

  void submit() {
    if (formKey.currentState?.validate() ?? false) {
      Get.back();
      Get.snackbar('Expense added', 'Your expense has been recorded.');
    }
  }

  String? validateRequired(String? value, [String name = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$name is required';
    return null;
  }

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final n = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  @override
  void onClose() {
    amountController.dispose();
    dateController.dispose();
    vendorController.dispose();
    super.onClose();
  }
}
