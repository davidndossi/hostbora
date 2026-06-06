import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';

class AddTaskController extends BaseController {
  AddTaskController()
    : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _staffLocal = Get.find<RentStaffLocalDataSource>(),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _syncWorker = Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final RentStaffLocalDataSource _staffLocal;
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
      final routeProperty = _routePropertyLabel();
      if (routeProperty.isNotEmpty && propertyOptions.contains(routeProperty)) {
        selectedProperty.value = routeProperty;
      } else if (propertyOptions.length == 1) {
        selectedProperty.value = propertyOptions.first;
      }
    } finally {
      loadingProperties.value = false;
    }
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
    final assigneeName = selectedAssignee.value.trim();
    final request = AddTaskRequest(
      title: title,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      dueDate: dueDateLabel,
      propertyLabel: _propertyLabel(property),
      propertyRef: _propertyRef(property),
      workspaceType: _normalizedWorkspace(property),
      assignee: assigneeName.isEmpty ? null : assigneeName,
    );
    saving.value = true;
    try {
      bool synced = false;
      try {
        final res = await _repository.addTask(request);
        synced = res.responseCode == '201' ||
            res.responseCode == '200' ||
            res.responseCode == '0';
      } catch (_) {
        synced = false;
      }

      if (!synced) {
        await _syncQueue.enqueue(
          entityType: 'task',
          operation: 'create',
          payloadJson: jsonEncode(request.toJson()),
          dedupeKey: 'task:create:${DateTime.now().millisecondsSinceEpoch}',
        );
        _syncWorker.runNow();
        Get.back(result: true);
        Get.snackbar('Task saved', 'Task will sync when online.');
      } else {
        Get.back(result: true);
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
