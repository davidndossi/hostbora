import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../maintenance_tasks/model/maintenance_task.dart';

class EditTaskController extends BaseController {
  EditTaskController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dueDate = Rxn<DateTime>();
  final saving = false.obs;
  String taskId = '';
  Map<String, dynamic> _originalArgs = const {};

  String? get dueDateLabel {
    final d = dueDate.value;
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _originalArgs = Map<String, dynamic>.from(args);
      taskId = args['id']?.toString() ?? '';
      titleController.text = args['title']?.toString() ?? '';
      descriptionController.text = args['description']?.toString() ?? '';
      final dm = args['dueDateMs'];
      if (dm is int) {
        dueDate.value = DateTime.fromMillisecondsSinceEpoch(dm);
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    _refreshFromServer();
  }

  Future<void> _refreshFromServer() async {
    if (taskId.isEmpty) return;
    final typedTitle = titleController.text.trim();
    final originalTitle = (_originalArgs['title'] ?? '').toString().trim();
    if (typedTitle.isNotEmpty && typedTitle != originalTitle) return;
    try {
      final res = await _repository.getTask(taskId);
      if (res.responseCode != '0' || res.data == null) return;
      final map = _unwrapTaskMap(res.data);
      if (map == null) return;
      final t = MaintenanceTask.fromApiMap(map);
      titleController.text = t.title;
      descriptionController.text = t.description;
      dueDate.value = t.dueDate;
    } catch (_) {}
  }

  Map<String, dynamic>? _unwrapTaskMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['task'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      final d = data['data'];
      if (d is Map) {
        return Map<String, dynamic>.from(d);
      }
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('en', 'GB'),
    );
    
    if (picked != null) dueDate.value = picked;
  }

  void clearDueDate() => dueDate.value = null;

  Future<void> submit() async {
    if (saving.value || taskId.isEmpty) return;
    if (formKey.currentState?.validate() != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    final request = AddTaskRequest(
      title: title,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      dueDate: dueDateLabel,
    );
    saving.value = true;
    try {
      final res = await _repository.updateTask(taskId, request);
      if (res.responseCode == '200' ||
          res.responseCode == '201' ||
          res.responseCode == '0') {
        Get.back(result: _editedArguments());
      } else {
        showErrorMessage(res.message ?? 'Could not update task');
      }
    } catch (e) {
      showErrorMessage(e.toString());
    } finally {
      saving.value = false;
    }
  }

  Map<String, dynamic> _editedArguments() {
    final due = dueDate.value;
    final map = Map<String, dynamic>.from(_originalArgs);
    map['id'] = taskId;
    map['title'] = titleController.text.trim();
    map['description'] = descriptionController.text.trim();
    if (due != null) {
      map['dueDateMs'] = due.millisecondsSinceEpoch;
    } else {
      map.remove('dueDateMs');
    }
    return map;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
