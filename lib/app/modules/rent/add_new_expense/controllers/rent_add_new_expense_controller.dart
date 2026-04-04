import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../../core/base/base_controller.dart';

class RentAddNewExpenseController extends BaseController {
  final tenantController = TextEditingController();
  final amountController = TextEditingController();
  final datePaidController = TextEditingController();
  final notesController = TextEditingController();

  /// Expense category options (single selection).
  final expenses = const ['Rent', 'Maintenance', 'Utilities', 'Salary', 'Other'];

  final selectedExpenseIndex = 0.obs;

  String get selectedExpense => expenses[selectedExpenseIndex.value];

  void selectExpense(int index) {
    if (index >= 0 && index < expenses.length) {
      selectedExpenseIndex.value = index;
    }
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
