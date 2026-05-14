import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/local_notification_scheduler_service.dart';
import '../../../../data/local/service/workspace_context_service.dart';
import '../../../../data/model/add_task_request.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../host_calendar/controllers/host_calendar_controller.dart';
import '../../host_calendar/controllers/rent_host_calendar_controller.dart';

class RentScheduleMaintenanceFormController extends BaseController {
  final formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();
  final scheduleDateFieldController = TextEditingController();

  final propertyOptions = <String>[].obs;

  final categoryOptions = const [
    'Plumbing',
    'Electrical',
    'HVAC',
    'Appliances',
    'Structural',
    'Landscaping',
    'General',
  ];

  final selectedProperty = ''.obs;
  final selectedCategory = 'Plumbing'.obs;
  final scheduleDate = Rx<DateTime?>(null);
  /// `low` | `medium` | `high`
  final priority = 'medium'.obs;
  final _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>();
  final _propertyLocal = Get.find<PropertyLocalDataSource>();
  final _preferenceManager =
      Get.find<PreferenceManager>(tag: (PreferenceManager).toString());
  final _workspaceContext = Get.find<WorkspaceContextService>();
  final _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();
  final _notificationScheduler = Get.find<LocalNotificationSchedulerService>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  bool get hasProperties => propertyOptions.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadPropertyOptions();
  }

  Future<void> _loadPropertyOptions() async {
    final userId = (await _preferenceManager.getUser()).id ?? '';
    final workspace = await _workspaceContext.getWorkspaceType();
    final rows = await _propertyLocal.getAllVisibleNewestFirst(
      userId: userId,
      workspaceType: workspace,
    );
    final localNames = rows
        .map((p) => p.propertyName.trim().isNotEmpty
            ? p.propertyName.trim()
            : p.propertyLocation.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final remoteNames = await _loadRemotePropertyNames();
    final merged = <String>{
      ...localNames,
      ...remoteNames,
    }.toList();
    merged.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    propertyOptions.assignAll(merged);
    _applyNavigationContext();
  }

  /// Reads [Get.arguments] (when a [Map]) and [Get.parameters] for route-driven defaults.
  void _applyNavigationContext() {
    final args = Get.arguments;

    String? pickString(String key) {
      if (args is Map && args[key] != null) {
        final v = args[key].toString().trim();
        if (v.isNotEmpty) return v;
      }
      final p = Get.parameters[key];
      if (p != null && p.trim().isNotEmpty) return p.trim();
      return null;
    }

    _resolvedPropertyRef =
        pickString('propertyRef') ?? pickString('property_id') ?? '';
    _resolvedApartmentUnitId = pickString('apartmentUnitId') ??
        pickString('unitId') ??
        pickString('apartment_unit_id') ??
        '';

    final requestedName =
        pickString('property') ?? pickString('property_name');
    if (propertyOptions.isNotEmpty) {
      if (requestedName != null && requestedName.isNotEmpty) {
        final match = propertyOptions.firstWhereOrNull(
          (p) => p.toLowerCase() == requestedName.toLowerCase(),
        );
        selectedProperty.value = match ?? propertyOptions.first;
      } else {
        selectedProperty.value = propertyOptions.first;
      }
    }

    final cat = pickString('category');
    if (cat != null &&
        cat.isNotEmpty &&
        categoryOptions.contains(cat)) {
      selectedCategory.value = cat;
    }

    final desc = pickString('description');
    if (desc != null && desc.isNotEmpty) {
      descriptionController.text = desc;
    }
  }

  /// From navigation ([Get.arguments] / [Get.parameters]); may be empty.
  String _resolvedPropertyRef = '';
  String _resolvedApartmentUnitId = '';

  Future<List<String>> _loadRemotePropertyNames() async {
    try {
      final res = await _repository.getMyListings(status: null);
      if (res.responseCode != '0' || res.data == null) return const [];
      final list = _extractListingsFromResponse(res.data);
      return list
          .map((m) =>
              (m['propertyName'] ?? m['title'] ?? m['name'])?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _extractListingsFromResponse(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map && data['listings'] is List) {
      return (data['listings'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  String? validateSelectedProperty(String? value) {
    if (!hasProperties) return null;
    final v = (value ?? selectedProperty.value).trim();
    if (v.isEmpty) return 'Property is required';
    return null;
  }

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
      scheduleDateFieldController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> scheduleTask() async {
    if (!hasProperties) {
      showErrorMessage('No properties yet — add a property first.');
      return;
    }
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
      propertyRef: _resolvedPropertyRef,
      apartmentUnitId: _resolvedApartmentUnitId,
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

    late final String successMsg;
    try {
      await _repository.addTask(taskRequest);
      await _maintenanceLocal.updateSyncStatus(localId, 'synced');
      successMsg = 'Saved offline and online. Reminder scheduled.';
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
      successMsg = 'Saved offline. Will sync when internet is available.';
    }

    if (Get.isRegistered<RentHostCalendarController>()) {
      await Get.find<RentHostCalendarController>().loadCalendarData();
    }
    if (Get.isRegistered<HostCalendarController>()) {
      await Get.find<HostCalendarController>().loadCalendarData();
    }

    showSuccessMessage(successMsg);
    await Future.delayed(const Duration(milliseconds: 500));
    Get.back(result: true);
  }

  @override
  void onClose() {
    descriptionController.dispose();
    scheduleDateFieldController.dispose();
    super.onClose();
  }
}
