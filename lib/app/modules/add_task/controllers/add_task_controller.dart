import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/access/plan_agents.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/utils/plan_gate.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../maintenance_tasks/model/maintenance_task.dart';
import '../../maintenance_tasks/task_assignment_store.dart';
import '../../../core/constants/ui_preference_keys.dart';
import '../../../core/utils/form_recall.dart';

class AddTaskController extends BaseController with FormRecallMixin {
  AddTaskController()
    : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _staffLocal = Get.find<RentStaffLocalDataSource>(),
      _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>(),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final RentStaffLocalDataSource _staffLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;
  final PreferenceManager _preferenceManager;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final dueDate = Rxn<DateTime>();
  final saving = false.obs;
  final loadingProperties = false.obs;
  final propertyOptions = <String>[].obs;
  final selectedProperty = ''.obs;

  /// Staff name options loaded from local DB.
  final staffOptions = <String>[].obs;
  final selectedAssignee = ''.obs;

  List<PropertyRecord> _propertyRows = [];

  bool get hasProperties => propertyOptions.isNotEmpty;

  PropertyRecord? get selectedPropertyRecord {
    selectedProperty.value;
    final selected = selectedProperty.value.trim();
    if (selected.isEmpty) return null;
    for (final r in _propertyRows) {
      final label = _propertyLabel(r);
      if (label == selected) return r;
    }
    return null;
  }

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
      locale: const Locale('en', 'GB'),
    );

    if (picked != null) dueDate.value = picked;
  }

  void clearDueDate() => dueDate.value = null;

  void updateSelectedAssignee(String? value) {
    selectedAssignee.value = value?.trim() ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    _loadProperties();
    _loadStaff();
    final args = Get.arguments;
    if (args is Map) {
      final assignee = (args['assignee'] ?? args['assigneeName'] ?? '')
          .toString()
          .trim();
      final desc = (args['description'] ?? '').toString().trim();
      if (assignee.isNotEmpty) {
        selectedAssignee.value = assignee;
      }
      final assignedLine = RegExp(
        r'^Assigned to:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(desc);
      if (selectedAssignee.value.trim().isEmpty && assignedLine != null) {
        selectedAssignee.value = assignedLine.group(1)!.trim();
      }
      if (desc.isNotEmpty && assignedLine == null) {
        descriptionController.text = desc;
      }
    }
  }

  Future<void> _loadStaff() async {
    try {
      final rows = await _staffLocal.getAllNewestFirst();
      final names = rows
          .map((r) => r.name.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      staffOptions.assignAll(names);
      // With a single staff member there is no choice to make; anything more
      // is left blank because assignment is optional and picking for the host
      // would put someone's name on work they were not given.
      if (selectedAssignee.value.trim().isEmpty && names.length == 1) {
        selectedAssignee.value = names.first;
      }
    } catch (_) {
      staffOptions.clear();
    }
  }

  Future<void> _loadProperties() async {
    loadingProperties.value = true;
    try {
      final userId = (await _preferenceManager.getUser()).id ?? '';
      final rowsByKey = <String, PropertyRecord>{};
      for (final workspace in const ['bnb', 'rent']) {
        final rows = await _propertyLocal.getAllVisibleNewestFirst(
          userId: userId,
          workspaceType: workspace,
        );
        for (final row in rows) {
          rowsByKey[_propertyKey(row)] = row;
        }
      }
      _propertyRows = rowsByKey.values.toList()
        ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      propertyOptions.assignAll(
        _propertyRows.map(_propertyLabel).where((e) => e.isNotEmpty).toList(),
      );
      await _preselectPropertyFromRoute();
    } finally {
      loadingProperties.value = false;
    }
  }

  Future<void> _preselectPropertyFromRoute() async {
    final routeRef = _routePropertyRef();
    if (routeRef.isNotEmpty) {
      for (final row in _propertyRows) {
        if (_propertyRef(row) == routeRef ||
            'local_${row.id}' == routeRef ||
            'legacy_${row.id}' == routeRef) {
          selectedProperty.value = _propertyLabel(row);
          return;
        }
      }
    }
    final routeProperty = _routePropertyLabel();
    if (routeProperty.isNotEmpty && propertyOptions.contains(routeProperty)) {
      selectedProperty.value = routeProperty;
      return;
    }
    // A task carries no money, so falling through to the first property is
    // safe and still beats an empty picker.
    selectedProperty.value = await recallChoice(
      key: UiPreferenceKeys.addTaskProperty,
      options: propertyOptions,
      fallback: RecallFallback.firstOption,
    );
  }

  void updateSelectedProperty(String? value) {
    selectedProperty.value = value?.trim() ?? '';
  }

  String _routePropertyLabel() {
    final args = Get.arguments;
    if (args is Map) {
      for (final key in ['property', 'propertyName', 'property_name']) {
        final value = (args[key] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
    return Get.parameters['property']?.trim() ?? '';
  }

  String _routePropertyRef() {
    final args = Get.arguments;
    if (args is Map) {
      for (final key in [
        'propertyRef',
        'property_ref',
        'property_id',
        'propertyId',
      ]) {
        final value = (args[key] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
    return (Get.parameters['propertyRef'] ??
            Get.parameters['property_ref'] ??
            Get.parameters['property_id'] ??
            '')
        .trim();
  }

  String _propertyKey(PropertyRecord row) {
    final ref = row.propertyRef.trim();
    if (ref.isNotEmpty) return ref;
    return 'legacy_${row.id}';
  }

  String _propertyLabel(PropertyRecord row) {
    final name = row.propertyName.trim();
    if (name.isNotEmpty) return name;
    return row.propertyLocation.trim();
  }

  String _propertyRef(PropertyRecord row) {
    final ref = row.propertyRef.trim();
    if (ref.isNotEmpty) return ref;
    return 'legacy_${row.id}';
  }

  String _normalizedWorkspace(PropertyRecord row) {
    final mode = row.workspaceType.trim().toLowerCase();
    if (mode == 'bnb' || mode == 'rent' || mode == 'both') return mode;
    return 'rent';
  }

  String _localTaskDescription({
    required String title,
    required String description,
    required String assignee,
  }) {
    final parts = <String>[title.trim()];
    final desc = description.trim();
    if (desc.isNotEmpty) parts.add(desc);
    final who = assignee.trim();
    if (who.isNotEmpty) parts.add('Assigned to: $who');
    return parts.join('\n');
  }

  DateTime _scheduledDateTime() {
    final d = dueDate.value;
    if (d != null) {
      return DateTime(d.year, d.month, d.day, 9, 0);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 9, 0);
  }

  Future<int> _persistLocalMaintenanceRow({
    required PropertyRecord property,
    required String title,
    required String description,
    required String assignee,
    required bool synced,
    String backendTaskId = '',
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
    final localId = await _maintenanceLocal.insert(
      propertyLabel: _propertyLabel(property),
      category: title.length > 48 ? '${title.substring(0, 45)}…' : title,
      description: _localTaskDescription(
        title: title,
        description: description,
        assignee: assignee,
      ),
      scheduledDateIso: _scheduledDateTime().toIso8601String(),
      priority: 'medium',
      notificationId: notificationId,
      syncStatus: synced ? 'synced' : 'pending',
      propertyRef: _propertyRef(property),
      workspaceType: _normalizedWorkspace(property),
    );
    if (backendTaskId.trim().isNotEmpty) {
      await _maintenanceLocal.saveBackendTaskId(
        localId: localId,
        backendId: backendTaskId.trim(),
      );
    }
    return localId;
  }

  MaintenanceTask _createdTask({
    required String id,
    required String title,
    required String description,
    required String assignee,
  }) {
    final name = assignee.trim();
    return MaintenanceTask(
      id: id,
      title: title,
      assignee: name.isEmpty ? 'Unassigned' : name,
      description: description,
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      dueDate: dueDate.value,
    );
  }

  Future<({String phone, String staffId})> _staffIdentity(String name) async {
    if (name.trim().isEmpty) return (phone: '', staffId: '');
    try {
      final row = await _staffLocal.findByNameIgnoreCase(name);
      if (row == null) return (phone: '', staffId: '');
      final backendId = await _staffLocal.backendIdForLocal(row.id);
      return (phone: row.phone.trim(), staffId: backendId ?? '');
    } catch (_) {
      return (phone: '', staffId: '');
    }
  }

  String? _backendIdFromResponse(dynamic data) {
    if (data is Map) {
      final nested = data['data'];
      if (nested is Map) {
        return (nested['id'] ?? nested['taskId'] ?? nested['maintenanceId'])
            ?.toString();
      }
      return (data['id'] ?? data['taskId'] ?? data['maintenanceId'])?.toString();
    }
    return null;
  }

  Future<void> submit() async {
    if (saving.value) return;
    if (formKey.currentState?.validate() != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    final property = selectedPropertyRecord;
    if (property == null) {
      Get.snackbar('Error', 'Please select a property.');
      return;
    }
    rememberChoice(UiPreferenceKeys.addTaskProperty, selectedProperty.value);
    final assigneeName = selectedAssignee.value.trim();
    if (assigneeName.isNotEmpty &&
        !PlanAccess.agent.allows(PlanCapability.pro)) {
      PlanGate.showUpgradeSheet(RequiredPlan.pro, featureName: 'Task assignment');
      return;
    }
    final description = descriptionController.text.trim();
    final identity = await _staffIdentity(assigneeName);
    final request = AddTaskRequest(
      title: title,
      description: description.isEmpty ? null : description,
      dueDate: dueDateLabel,
      propertyLabel: _propertyLabel(property),
      propertyRef: _propertyRef(property),
      workspaceType: _normalizedWorkspace(property),
      assignee: assigneeName.isEmpty ? null : assigneeName,
      assigneePhone: identity.phone.isEmpty ? null : identity.phone,
      staffId: identity.staffId.isEmpty ? null : identity.staffId,
    );
    saving.value = true;
    try {
      var synced = false;
      var backendId = '';
      try {
        final res = await _repository.addTask(request);
        synced = res.responseCode == '201' ||
            res.responseCode == '200' ||
            res.responseCode == '0';
        if (synced) {
          backendId = _backendIdFromResponse(res.data) ?? '';
        }
      } catch (_) {
        synced = false;
      }

      // Mirror into local scheduled-maintenance so Property → Maintenance
      // shows the task immediately after "Task saved".
      final localId = await _persistLocalMaintenanceRow(
        property: property,
        title: title,
        description: description,
        assignee: assigneeName,
        synced: synced,
        backendTaskId: backendId,
      );
      final created = _createdTask(
        id: backendId.trim().isNotEmpty ? backendId.trim() : 'local_$localId',
        title: title,
        description: description,
        assignee: assigneeName,
      );
      await TaskAssignmentStore.remember(created);

      if (!synced) {
        await _syncQueue.enqueue(
          entityType: 'task',
          operation: 'create',
          payloadJson: jsonEncode(request.toJson()),
          dedupeKey: 'task:create:${DateTime.now().millisecondsSinceEpoch}',
        );
        _syncWorker.runNow();
        Get.back(result: created.toArguments());
        Get.snackbar('Task saved', 'Task will sync when online.');
      } else {
        Get.back(result: created.toArguments());
        Get.snackbar('Done', 'Task saved.');
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
