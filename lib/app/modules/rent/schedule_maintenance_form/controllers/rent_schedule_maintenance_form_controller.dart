import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';

class RentScheduleMaintenanceFormController extends BaseController {
  final formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();
  final scheduleDateFieldController = TextEditingController();

  final propertyOptions = const [
    'The Azure Penthouse',
    'Evergreen Estate Unit 4B',
    'Harbor View Loft',
    'Summit Gardens A2',
  ];

  final categoryOptions = const [
    'Plumbing',
    'Electrical',
    'HVAC',
    'Appliances',
    'Structural',
    'Landscaping',
    'General',
  ];

  final selectedProperty = 'The Azure Penthouse'.obs;
  final selectedCategory = 'Plumbing'.obs;
  final scheduleDate = Rx<DateTime?>(null);
  /// `low` | `medium` | `high`
  final priority = 'medium'.obs;

  void updateProperty(String? v) {
    if (v != null && v.isNotEmpty) selectedProperty.value = v;
  }

  void updateCategory(String? v) {
    if (v != null && v.isNotEmpty) selectedCategory.value = v;
  }

  void setPriority(String p) {
    priority.value = p;
  }

  Future<void> pickScheduleDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = scheduleDate.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      scheduleDate.value = picked;
      scheduleDateFieldController.text = DateFormat('MM/dd/yyyy').format(picked);
    }
  }

  void scheduleTask() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    Get.snackbar(
      'Maintenance',
      'Task scheduled for ${selectedProperty.value} · ${selectedCategory.value}',
    );
  }

  @override
  void onClose() {
    descriptionController.dispose();
    scheduleDateFieldController.dispose();
    super.onClose();
  }
}
