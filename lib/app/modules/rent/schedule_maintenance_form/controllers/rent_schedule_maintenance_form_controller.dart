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
import '../../../../data/model/add_task_request.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../add_listing/models/apartment_unit_draft.dart';
import '../../../host_calendar/controllers/host_calendar_controller.dart';

class RentScheduleMaintenanceFormController extends BaseController {
  final formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();
  final scheduleDateFieldController = TextEditingController();

  final propertyOptions = <String>[].obs;
  final availableUnitDrafts = <ApartmentUnitDraft>[].obs;
  final selectedUnitKey = RxnString();

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
  final saving = false.obs;

  final _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>();
  final _propertyLocal = Get.find<PropertyLocalDataSource>();
  final _preferenceManager = Get.find<PreferenceManager>(
    tag: (PreferenceManager).toString(),
  );
  final _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();
  final _notificationScheduler = Get.find<LocalNotificationSchedulerService>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  List<PropertyRecord> _propertyRows = [];
  String _routeWorkspaceHint = 'rent';

  bool get hasProperties => propertyOptions.isNotEmpty;

  PropertyRecord? get selectedPropertyRecord {
    selectedProperty.value;
    final selected = selectedProperty.value.trim();
    if (selected.isEmpty) return null;
    for (final r in _propertyRows) {
      if (_propertyLabel(r) == selected) return r;
    }
    return null;
  }

  bool get showUnitPicker {
    selectedProperty.value;
    final r = selectedPropertyRecord;
    if (r == null) return false;
    if (r.propertyType.trim().toLowerCase() != 'apartment') return false;
    return availableUnitDrafts.isNotEmpty;
  }

  List<String> get unitSelectionKeys =>
      availableUnitDrafts.map((u) => u.selectionKey).toList();

  String unitDisplayLabel(String selectionKey) {
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == selectionKey) return u.unitName.trim();
    }
    return selectionKey;
  }

  ApartmentUnitDraft? get selectedUnitDraft =>
      _draftForKey(selectedUnitKey.value);

  @override
  void onInit() {
    super.onInit();
    _initRouteWorkspaceHint();
    _loadPropertyOptions();
  }

  void _initRouteWorkspaceHint() {
    final args = Get.arguments;
    String? raw;
    if (args is Map) {
      raw = (args['workspaceType'] ?? args['workspace'] ?? '').toString();
    }
    raw = raw?.trim().isNotEmpty == true
        ? raw
        : (Get.parameters['workspaceType'] ?? Get.parameters['workspace']);
    final value = raw?.trim().toLowerCase();
    if (value == 'bnb' || value == 'rent') {
      _routeWorkspaceHint = value!;
    }
  }

  Future<void> _loadPropertyOptions() async {
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

    final localNames = _propertyRows
        .map(_propertyLabel)
        .where((e) => e.isNotEmpty)
        .toList();
    final remoteNames = await _loadRemotePropertyNames();
    final merged = <String>{...localNames, ...remoteNames}.toList();
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

    final requestedRef =
        pickString('propertyRef') ?? pickString('property_id') ?? '';
    final requestedName = pickString('property') ?? pickString('property_name');

    if (requestedRef.isNotEmpty) {
      for (final r in _propertyRows) {
        if (_propertyRef(r) == requestedRef ||
            'legacy_${r.id}' == requestedRef ||
            'local_${r.id}' == requestedRef) {
          selectedProperty.value = _propertyLabel(r);
          break;
        }
      }
    }
    if (selectedProperty.value.isEmpty &&
        requestedName != null &&
        requestedName.isNotEmpty) {
      final match = propertyOptions.firstWhereOrNull(
        (p) => p.toLowerCase() == requestedName.toLowerCase(),
      );
      if (match != null) {
        selectedProperty.value = match;
      }
    }
    if (selectedProperty.value.isEmpty && propertyOptions.isNotEmpty) {
      selectedProperty.value = propertyOptions.first;
    }

    _reloadUnitsForSelectedProperty();

    final unitId =
        pickString('apartmentUnitId') ??
        pickString('unitId') ??
        pickString('apartment_unit_id') ??
        '';
    if (unitId.isNotEmpty) {
      for (final u in availableUnitDrafts) {
        if (u.unitId == unitId) {
          selectedUnitKey.value = u.selectionKey;
          break;
        }
      }
    }
    final unitName = pickString('unitName');
    if (selectedUnitKey.value == null &&
        unitName != null &&
        unitName.isNotEmpty) {
      for (final u in availableUnitDrafts) {
        if (u.unitName.trim() == unitName) {
          selectedUnitKey.value = u.selectionKey;
          break;
        }
      }
    }

    final cat = pickString('category');
    if (cat != null && cat.isNotEmpty && categoryOptions.contains(cat)) {
      selectedCategory.value = cat;
    }

    final desc = pickString('description');
    if (desc != null && desc.isNotEmpty) {
      descriptionController.text = desc;
    }
  }

  void _reloadUnitsForSelectedProperty() {
    final r = selectedPropertyRecord;
    if (r == null) {
      availableUnitDrafts.clear();
      return;
    }
    availableUnitDrafts.assignAll(_parseUnitDrafts(r.unitsJson));
    if (availableUnitDrafts.length == 1) {
      selectedUnitKey.value = availableUnitDrafts.first.selectionKey;
    }
  }

  ApartmentUnitDraft? _draftForKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final u in availableUnitDrafts) {
      if (u.selectionKey == key) return u;
    }
    return null;
  }

  static List<ApartmentUnitDraft> _parseUnitDrafts(String unitsJson) {
    if (unitsJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(unitsJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => u.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
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

  String _normalizeWorkspace(String? raw, {String fallback = 'bnb'}) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value == 'bnb' || value == 'rent' || value == 'both') return value;
    return fallback;
  }

  String _workspaceForMaintenanceSave(ApartmentUnitDraft? unitDraft) {
    final propertyMode = _normalizeWorkspace(
      selectedPropertyRecord?.workspaceType,
      fallback: _routeWorkspaceHint,
    );
    if (propertyMode == 'both') {
      if (unitDraft != null) {
        return _normalizeWorkspace(unitDraft.operationMode, fallback: 'bnb');
      }
      return _normalizeWorkspace(_routeWorkspaceHint, fallback: 'bnb');
    }
    return propertyMode;
  }

  Future<List<String>> _loadRemotePropertyNames() async {
    try {
      final res = await _repository.getMyListings(status: null);
      if (res.responseCode != '0' || res.data == null) return const [];
      final list = _extractListingsFromResponse(res.data);
      return list
          .map(
            (m) =>
                (m['propertyName'] ?? m['title'] ?? m['name'])
                    ?.toString()
                    .trim() ??
                '',
          )
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _extractListingsFromResponse(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    if (data is Map && data['listings'] is List) {
      return (data['listings'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
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
    if (v == null || v.isEmpty) return;
    selectedProperty.value = v;
    selectedUnitKey.value = null;
    _reloadUnitsForSelectedProperty();
  }

  void updateSelectedUnit(String? key) {
    if (key == null || key.isEmpty) {
      selectedUnitKey.value = null;
      return;
    }
    selectedUnitKey.value = key;
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
      scheduleDateFieldController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(picked);
    }
  }

  String _descriptionWithUnit(String base, ApartmentUnitDraft? unit) {
    final trimmed = base.trim();
    if (unit == null) return trimmed;
    final unitLine = 'Unit: ${unit.unitName.trim()}';
    if (trimmed.isEmpty) return unitLine;
    return '$trimmed\n$unitLine';
  }

  Future<void> scheduleTask() async {
    if (saving.value) return;
    if (!hasProperties) {
      showErrorMessage('No properties yet — add a property first.');
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    final date = scheduleDate.value!;
    final scheduledAt = DateTime(date.year, date.month, date.day, 9, 0);
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    final property = selectedPropertyRecord;
    final propertyRef = property != null ? _propertyRef(property) : '';
    final unit = selectedUnitDraft;
    final apartmentUnitId = unit?.unitId.trim() ?? '';
    final workspaceType = _workspaceForMaintenanceSave(unit);
    final propertyLabel = selectedProperty.value.trim();
    final issueDescription = descriptionController.text.trim();
    final fullDescription = _descriptionWithUnit(issueDescription, unit);

    saving.value = true;
    try {
      final localId = await _maintenanceLocal.insert(
        propertyLabel: propertyLabel,
        category: selectedCategory.value,
        description: fullDescription,
        scheduledDateIso: scheduledAt.toIso8601String(),
        priority: priority.value,
        notificationId: notificationId,
        syncStatus: 'pending',
        propertyRef: propertyRef,
        apartmentUnitId: apartmentUnitId,
        workspaceType: workspaceType,
      );

      final reminderAt = scheduledAt.subtract(const Duration(days: 1));
      await _notificationScheduler.scheduleOneShot(
        id: notificationId,
        when: reminderAt,
        title: 'Maintenance Reminder',
        body:
            '${selectedCategory.value} at $propertyLabel is tomorrow',
        payload: 'maintenance:$localId',
      );

      final taskRequest = AddTaskRequest(
        title: 'Maintenance: ${selectedCategory.value}',
        description: '$propertyLabel - $fullDescription',
        dueDate: DateFormat('yyyy-MM-dd').format(scheduledAt),
        propertyLabel: propertyLabel,
        propertyRef: propertyRef,
        workspaceType: workspaceType,
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
            'propertyLabel': taskRequest.propertyLabel,
            'propertyRef': taskRequest.propertyRef,
            'workspaceType': taskRequest.workspaceType,
            'apartmentUnitId': apartmentUnitId,
          }),
        );
        successMsg = 'Saved offline. Will sync when internet is available.';
      }

      await HostCalendarController.refreshIfRegistered();

      showSuccessMessage(successMsg);
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back(result: true);
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    scheduleDateFieldController.dispose();
    super.onClose();
  }
}
