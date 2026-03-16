import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

class AddTaskController extends BaseController {
  final AppRepository _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dueDate = Rxn<DateTime>();
  final saving = false.obs;

  String? get dueDateLabel {
    final d = dueDate.value;
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate.value ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) dueDate.value = picked;
  }

  void clearDueDate() => dueDate.value = null;

  Future<void> submit() async {
    if (saving.value) return;
    if (formKey.currentState?.validate() != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    final request = AddTaskRequest(
      title: title,
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      dueDate: dueDateLabel,
    );
    saving.value = true;
    try {
      final res = await _repository.addTask(request);
      if (res.responseCode == '201' || res.responseCode == '200') {
        Get.back(result: true);
        Get.snackbar('Done', 'Task added.');
      } else {
        Get.snackbar('Error', res.message ?? 'Could not add task.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add task: $e');
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
