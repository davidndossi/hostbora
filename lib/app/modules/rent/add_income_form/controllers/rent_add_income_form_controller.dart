import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';

class RentAddIncomeFormController extends BaseController {
  final tenantController = TextEditingController();
  final amountController = TextEditingController();
  final datePaidController = TextEditingController();
  final notesController = TextEditingController();

  /// Income category options (single selection).
  final categories = const ['Rent', 'Service Charge', 'Maintenance', 'Other'];

  final selectedCategoryIndex = 0.obs;

  String get selectedCategory => categories[selectedCategoryIndex.value];

  void selectCategory(int index) {
    if (index >= 0 && index < categories.length) {
      selectedCategoryIndex.value = index;
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
