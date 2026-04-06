import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../../data/local/service/local_notification_scheduler_service.dart';
import '../../../../data/model/add_task_request.dart';
import '../../../../data/repository/app_repository.dart';

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
  final _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>();
  final _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();
  final _notificationScheduler = Get.find<LocalNotificationSchedulerService>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

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

  Future<void> scheduleTask() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final date = scheduleDate.value!;
    final scheduledAt = DateTime(date.year, date.month, date.day, 9, 0);
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    final localId = await _maintenanceLocal.insert(
      propertyLabel: selectedProperty.value,
      category: selectedCategory.value,
      description: descriptionController.text.trim(),
      scheduledDateIso: scheduledAt.toIso8601String(),
      priority: priority.value,
      notificationId: notificationId,
      syncStatus: 'pending',
    );

    final reminderAt = scheduledAt.subtract(const Duration(days: 1));
    await _notificationScheduler.scheduleOneShot(
      id: notificationId,
      when: reminderAt,
      title: 'Maintenance Reminder',
      body: '${selectedCategory.value} at ${selectedProperty.value} is tomorrow',
      payload: 'maintenance:$localId',
    );

    final taskRequest = AddTaskRequest(
      title: 'Maintenance: ${selectedCategory.value}',
      description: '${selectedProperty.value} - ${descriptionController.text.trim()}',
      dueDate: DateFormat('yyyy-MM-dd').format(scheduledAt),
    );

    try {
      await _repository.addTask(taskRequest);
      await _maintenanceLocal.updateSyncStatus(localId, 'synced');
      showSuccessMessage('Saved offline and online. Reminder scheduled.');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'rent_scheduled_maintenance',
        operation: 'create',
        payloadJson: jsonEncode({
          'localId': localId,
          'title': taskRequest.title,
          'description': taskRequest.description,
          'dueDate': taskRequest.dueDate,
        }),
      );
      showSuccessMessage('Saved offline. Will sync when internet is available.');
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    scheduleDateFieldController.dispose();
    super.onClose();
  }
}
