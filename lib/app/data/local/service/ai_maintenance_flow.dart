import 'dart:convert';

import 'package:get/get.dart';

import '../../../data/model/add_task_request.dart';
import '../../../data/model/scheduled_maintenance_request.dart';
import '../db/offline_sync_queue_local_data_source.dart';
import '../db/property_local_data_source.dart';
import '../db/rent_scheduled_maintenance_local_data_source.dart';
import '../service/offline_sync_worker_service.dart';
import '../../../modules/add_listing/models/apartment_unit_draft.dart';
import '../../../data/repository/app_repository.dart';

/// Conversational AI flow for:
///   • Scheduling property maintenance (property-linked, reminder-enabled)
///   • Adding a general task / to-do item
class AiMaintenanceFlow {
  AiMaintenanceFlow({
    required this.isSw,
    required List<PropertyRecord> properties,
  }) : _properties = List.unmodifiable(properties);

  final bool isSw;
  final List<PropertyRecord> _properties;

  _Action _action = _Action.unknown;
  _Step _step = _Step.askAction;

  bool get isComplete => _step == _Step.done;

  // ── Shared ─────────────────────────────────────────────────────────────
  PropertyRecord? _property;
  ApartmentUnitDraft? _unit;
  String _description = '';
  String _priority = 'medium';
  String _dueDateIso = '';

  // ── Maintenance-specific ───────────────────────────────────────────────
  String _category = 'General';
  String _scheduledDateIso = '';

  // ── Task-specific ──────────────────────────────────────────────────────
  String _taskTitle = '';
  String _assignee = '';

  // ── Statics ────────────────────────────────────────────────────────────
  static const _categories = [
    'Plumbing',
    'Electrical',
    'HVAC',
    'Appliances',
    'Structural',
    'Landscaping',
    'General',
  ];


  String get openingPrompt => _promptAction();

  Future<String> handleTurn(String userInput) async {
    final text = userInput.trim();
    switch (_step) {
      case _Step.askAction:        return _handleAction(text);
      // maintenance path
      case _Step.askProperty:      return _handleProperty(text);
      case _Step.askUnit:          return _handleUnit(text);
      case _Step.askCategory:      return _handleCategory(text);
      case _Step.askDescription:   return _handleDescription(text);
      case _Step.askScheduledDate: return _handleScheduledDate(text);
      case _Step.askPriority:      return _handlePriority(text);
      // task path
      case _Step.askTitle:         return _handleTitle(text);
      case _Step.askTaskDesc:      return _handleTaskDesc(text);
      case _Step.askTaskProperty:  return _handleTaskProperty(text);
      case _Step.askAssignee:      return _handleAssignee(text);
      case _Step.askDueDate:       return _handleDueDate(text);
      case _Step.askTaskPriority:  return _handleTaskPriority(text);
      // shared
      case _Step.confirm:          return await _handleConfirm(text);
      case _Step.done:             return '';
    }
  }

  // ── Step handlers: action ──────────────────────────────────────────────

  String _handleAction(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);

    if (idx == 1 || _containsAny(lower, [
      'maintenance', 'matengenezo', 'plumb', 'electric', 'repair',
      'schedule', 'kupanga', 'marekebisho', 'fundi', 'fix',
    ])) {
      _action = _Action.maintenance;
      _step   = _Step.askProperty;
      return _promptPropertyList();
    }
    if (idx == 2 || _containsAny(lower, [
      'task', 'todo', 'to-do', 'to do', 'kazi', 'ongeza kazi',
      'add task', 'new task', 'general task',
    ])) {
      _action = _Action.task;
      _step   = _Step.askTitle;
      return isSw
          ? '📝 Kichwa cha kazi ni nini? (k.m. "Nunua bulbs mpya")'
          : '📝 What is the task title? (e.g. "Buy replacement bulbs")';
    }
    return isSw
        ? '❓ Chagua:\n${_actionList()}'
        : '❓ Please choose:\n${_actionList()}';
  }

  // ── Maintenance path ───────────────────────────────────────────────────

  String _handleProperty(String text) {
    final match = _matchProperty(text);
    if (match == null) {
      return isSw
          ? '❓ Mali haikupatikana. Chagua:\n${_propertyList()}'
          : '❓ Property not found. Choose:\n${_propertyList()}';
    }
    _property = match;
    final units = _parseUnits(match.unitsJson);
    if (units.isNotEmpty) {
      _step = _Step.askUnit;
      return (isSw ? '🔑 Ni unit ipi? (au andika "mali nzima" kwa mali nzima)\n'
                   : '🔑 Which unit? (or type "whole" for the whole property)\n') +
             _unitList(units);
    }
    _step = _Step.askCategory;
    return _promptCategory();
  }

  String _handleUnit(String text) {
    final lower = text.toLowerCase().trim();
    if (_containsAny(lower, ['whole', 'all', 'mali nzima', 'nzima', 'all units'])) {
      _unit = null;
      _step = _Step.askCategory;
      return _promptCategory();
    }
    final units = _parseUnits(_property?.unitsJson ?? '');
    final match = _matchUnit(text, units);
    if (match == null) {
      return isSw
          ? '❓ Unit haikupatikana. Chagua:\n${_unitList(units)}'
          : '❓ Unit not found. Choose:\n${_unitList(units)}';
    }
    _unit = match;
    _step = _Step.askCategory;
    return _promptCategory();
  }

  String _handleCategory(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= _categories.length) {
      _category = _categories[idx - 1];
    } else {
      String? found;
      for (final c in _categories) {
        if (lower.contains(c.toLowerCase()) || c.toLowerCase().contains(lower)) {
          found = c;
          break;
        }
      }
      // Swahili keyword mapping
      if (found == null) {
        if (_containsAny(lower, ['maji', 'bomba', 'dreni', 'mfereji'])) {
          found = 'Plumbing';
        } else if (_containsAny(lower, ['umeme', 'stima', 'wiring'])) {
          found = 'Electrical';
        } else if (_containsAny(lower, ['hewa', 'ac ', 'air con', 'ventil'])) {
          found = 'HVAC';
        } else if (_containsAny(lower, ['vifaa', 'friji', 'jiko', 'mashine'])) {
          found = 'Appliances';
        } else if (_containsAny(lower, ['jengo', 'ukuta', 'dari', 'paa', 'roof', 'wall'])) {
          found = 'Structural';
        } else if (_containsAny(lower, ['bustani', 'lawn', 'mimea', 'garden'])) {
          found = 'Landscaping';
        }
      }
      if (found == null) {
        return isSw
            ? '❓ Aina haijulikani. Chagua:\n${_categoryList()}'
            : '❓ Category not recognised. Choose:\n${_categoryList()}';
      }
      _category = found;
    }
    _step = _Step.askDescription;
    return isSw
        ? '📋 Elezea tatizo kwa ufupi. (k.m. "Bomba la choo linalotumiwa")'
        : '📋 Briefly describe the issue. (e.g. "Leaking kitchen tap")';
  }

  String _handleDescription(String text) {
    if (text.isEmpty) {
      return isSw ? '❓ Maelezo hayawezi kuwa tupu.' : '❓ Description cannot be empty.';
    }
    _description = text;
    _step = _Step.askScheduledDate;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSw
        ? '📅 Tarehe ya kufanya matengenezo? (leo / kesho / yyyy-mm-dd)\n'
          '(Pendekezo: ${_fmtDate(tomorrow)})'
        : '📅 When should maintenance be scheduled? (today / tomorrow / yyyy-mm-dd)\n'
          '(Suggestion: ${_fmtDate(tomorrow)})';
  }

  String _handleScheduledDate(String text) {
    final d = _parseDate(text);
    if (d == null) {
      return isSw
          ? '❓ Tarehe sio sahihi. Andika "leo", "kesho", au yyyy-mm-dd.'
          : '❓ Date not recognised. Type "today", "tomorrow", or yyyy-mm-dd.';
    }
    _scheduledDateIso = d.toIso8601String();
    _step = _Step.askPriority;
    return _promptPriority();
  }

  String _handlePriority(String text) {
    final p = _parsePriority(text);
    if (p == null) {
      return isSw ? '❓ Chagua:\n${_priorityList()}' : '❓ Choose:\n${_priorityList()}';
    }
    _priority = p;
    _step = _Step.confirm;
    return _promptConfirmMaintenance();
  }

  // ── Task path ──────────────────────────────────────────────────────────

  String _handleTitle(String text) {
    if (text.isEmpty) {
      return isSw ? '❓ Kichwa haliwezi kuwa tupu.' : '❓ Title cannot be empty.';
    }
    _taskTitle = text;
    _step = _Step.askTaskDesc;
    return isSw
        ? '📝 Maelezo ya ziada? (au andika "skip" kuruka)'
        : '📝 Any additional description? (or type "skip" to skip)';
  }

  String _handleTaskDesc(String text) {
    final lower = text.toLowerCase().trim();
    _description = (lower == 'skip' || lower == 'ruka') ? '' : text;
    _step = _Step.askTaskProperty;
    if (_properties.isEmpty) {
      // No properties — skip to assignee
      _step = _Step.askAssignee;
      return isSw
          ? '👷 Kazi hii ni ya nani? (jina la mfanyakazi au andika "skip")'
          : '👷 Who should this task be assigned to? (staff name or type "skip")';
    }
    return (isSw
        ? '🏠 Kazi hii inahusiana na mali ipi? (au andika "skip" kama haina mali)\n'
        : '🏠 Which property is this task for? (or type "skip" if not property-specific)\n') +
        _propertyList();
  }

  String _handleTaskProperty(String text) {
    final lower = text.toLowerCase().trim();
    if (lower == 'skip' || lower == 'ruka' || lower == 'none' || lower == 'hapana') {
      _property = null;
    } else {
      _property = _matchProperty(text);
      // If no match but they typed something, that's ok — let it slide
    }
    _step = _Step.askAssignee;
    return isSw
        ? '👷 Kazi hii ni ya nani? (jina la mfanyakazi au "skip")'
        : '👷 Who should this task be assigned to? (staff name or "skip")';
  }

  String _handleAssignee(String text) {
    final lower = text.toLowerCase().trim();
    _assignee = (lower == 'skip' || lower == 'ruka') ? '' : text;
    _step = _Step.askDueDate;
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    return isSw
        ? '📅 Tarehe ya kumaliza? (k.m. ${_fmtDate(nextWeek)} au "skip")'
        : '📅 Due date? (e.g. ${_fmtDate(nextWeek)} or "skip")';
  }

  String _handleDueDate(String text) {
    final lower = text.toLowerCase().trim();
    if (lower == 'skip' || lower == 'ruka') {
      _dueDateIso = '';
    } else {
      final d = _parseDate(text);
      if (d == null) {
        return isSw
            ? '❓ Tarehe sio sahihi. Andika "kesho", yyyy-mm-dd au "skip".'
            : '❓ Date not recognised. Type "tomorrow", yyyy-mm-dd or "skip".';
      }
      _dueDateIso = _fmtDate(d);
    }
    _step = _Step.askTaskPriority;
    return _promptPriority();
  }

  String _handleTaskPriority(String text) {
    final p = _parsePriority(text);
    if (p == null) {
      return isSw ? '❓ Chagua:\n${_priorityList()}' : '❓ Choose:\n${_priorityList()}';
    }
    _priority = p;
    _step = _Step.confirm;
    return _promptConfirmTask();
  }

  // ── Confirm ────────────────────────────────────────────────────────────

  Future<String> _handleConfirm(String text) async {
    final lower = text.toLowerCase().trim();
    final yes = lower.startsWith('y') || lower == 'ndio' || lower == 'ndiyo' ||
        lower == 'confirm' || lower == 'save' || lower == 'hifadhi';
    final no  = lower.startsWith('n') || lower == 'hapana' ||
        lower == 'cancel' || lower == 'ghairi';

    if (no) {
      _step = _Step.done;
      return isSw ? '❌ Imeghairiwa.' : '❌ Cancelled.';
    }
    if (!yes) {
      return isSw
          ? 'Andika **ndio** kuhifadhi au **hapana** kughairi.'
          : 'Type **yes** to save or **no** to cancel.';
    }
    try {
      return _action == _Action.maintenance
          ? await _saveMaintenance()
          : await _saveTask();
    } catch (e) {
      _step = _Step.done;
      return isSw ? '❌ Imeshindwa: $e' : '❌ Failed: $e';
    }
  }

  // ── Save: maintenance ──────────────────────────────────────────────────

  Future<String> _saveMaintenance() async {
    final mainLocal  = _findOrThrow<RentScheduledMaintenanceLocalDataSource>();
    final syncQueue  = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker = _find<OfflineSyncWorkerService>();
    final repository = _find<AppRepository>(tag: (AppRepository).toString());

    final prop          = _property!;
    final unitId        = _unit?.unitId.trim() ?? '';
    final propLabel     = prop.propertyName.trim().isNotEmpty
        ? prop.propertyName.trim()
        : prop.propertyLocation.trim();
    final workspaceType = _workspaceFor(prop, _unit);
    final unitSuffix    = _unit != null ? '\nUnit: ${_unit!.unitName.trim()}' : '';
    final fullDesc      = _description + unitSuffix;
    final notifId       = DateTime.now().millisecondsSinceEpoch % 2147483647;

    final localId = await mainLocal.insert(
      propertyLabel: propLabel,
      category: _category,
      description: fullDesc,
      scheduledDateIso: _scheduledDateIso,
      priority: _priority,
      notificationId: notifId,
      syncStatus: 'pending',
      propertyRef: prop.propertyRef,
      apartmentUnitId: unitId,
      workspaceType: workspaceType,
    );

    final req = ScheduledMaintenanceRequest(
      propertyLabel: propLabel,
      propertyRef: prop.propertyRef.isNotEmpty ? prop.propertyRef : null,
      apartmentUnitId: unitId.isNotEmpty ? unitId : null,
      category: _category,
      description: fullDesc,
      scheduledDateIso: _scheduledDateIso,
      priority: _priority,
      workspaceType: workspaceType,
    );

    bool synced = false;
    if (repository != null) {
      try {
        final res = await repository.addScheduledMaintenance(req);
        synced = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
        if (synced) {
          await mainLocal.updateSyncStatus(localId, 'synced');
        }
      } catch (_) {}
    }

    if (!synced && syncQueue != null && syncWorker != null) {
      await syncQueue.enqueue(
        entityType: 'rent_scheduled_maintenance',
        operation: 'create',
        payloadJson: jsonEncode({
          'localId': localId,
          'propertyLabel': propLabel,
          'propertyRef': prop.propertyRef,
          'apartmentUnitId': unitId,
          'category': _category,
          'description': fullDesc,
          'scheduledDateIso': _scheduledDateIso,
          'priority': _priority,
          'workspaceType': workspaceType,
        }),
        dedupeKey: 'maintenance:create:${prop.propertyRef}:$localId',
      );
      syncWorker.runNow();
    }

    _step = _Step.done;
    final scheduled = _parseIso(_scheduledDateIso);
    final dateLabel = scheduled != null ? _fmtDate(scheduled) : _scheduledDateIso;
    return isSw
        ? '✅ Matengenezo yamepangwa:\n'
          '• Mali: $propLabel\n'
          '${_unit != null ? "• Unit: ${_unit!.unitName}\n" : ""}'
          '• Aina: $_category\n'
          '• Maelezo: $_description\n'
          '• Tarehe: $dateLabel\n'
          '• Kipaumbele: ${_priorityLabelSw(_priority)}\n'
          '${synced ? "✓ Imehifadhiwa mtandaoni" : "⏳ Itahifadhiwa mtandaoni baadaye"}'
        : '✅ Maintenance scheduled:\n'
          '• Property: $propLabel\n'
          '${_unit != null ? "• Unit: ${_unit!.unitName}\n" : ""}'
          '• Category: $_category\n'
          '• Description: $_description\n'
          '• Scheduled: $dateLabel\n'
          '• Priority: ${_priorityLabel(_priority)}\n'
          '${synced ? "✓ Saved online" : "⏳ Will sync when online"}';
  }

  // ── Save: task ─────────────────────────────────────────────────────────

  Future<String> _saveTask() async {
    final syncQueue  = _find<OfflineSyncQueueLocalDataSource>();
    final syncWorker = _find<OfflineSyncWorkerService>();
    final repository = _find<AppRepository>(tag: (AppRepository).toString());

    final propLabel = _property?.propertyName.trim().isNotEmpty == true
        ? _property!.propertyName.trim()
        : (_property?.propertyLocation.trim() ?? '');
    final propRef = _property?.propertyRef ?? '';
    final wsType  = _property != null
        ? _workspaceFor(_property!, null)
        : '';

    final req = AddTaskRequest(
      title: _taskTitle,
      description: _description.isNotEmpty ? _description : null,
      dueDate: _dueDateIso.isNotEmpty ? _dueDateIso : null,
      propertyLabel: propLabel.isNotEmpty ? propLabel : null,
      propertyRef: propRef.isNotEmpty ? propRef : null,
      workspaceType: wsType.isNotEmpty ? wsType : null,
      assignee: _assignee.isNotEmpty ? _assignee : null,
    );

    bool synced = false;
    if (repository != null) {
      try {
        final res = await repository.addTask(req);
        synced = res.responseCode == '0' ||
            res.responseCode == '200' ||
            res.responseCode == '201';
      } catch (_) {}
    }

    if (!synced && syncQueue != null && syncWorker != null) {
      final dedupeKey =
          'task:create:${_taskTitle.hashCode}:${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      await syncQueue.enqueue(
        entityType: 'task',
        operation: 'create',
        payloadJson: jsonEncode(req.toJson()),
        dedupeKey: dedupeKey,
      );
      syncWorker.runNow();
    }

    _step = _Step.done;
    return isSw
        ? '✅ Kazi imehifadhiwa:\n'
          '• Kichwa: $_taskTitle\n'
          '${_description.isNotEmpty ? "• Maelezo: $_description\n" : ""}'
          '${propLabel.isNotEmpty ? "• Mali: $propLabel\n" : ""}'
          '${_assignee.isNotEmpty ? "• Imekabidhiwa: $_assignee\n" : ""}'
          '${_dueDateIso.isNotEmpty ? "• Tarehe ya kumaliza: $_dueDateIso\n" : ""}'
          '• Kipaumbele: ${_priorityLabelSw(_priority)}\n'
          '${synced ? "✓ Imehifadhiwa mtandaoni" : "⏳ Itahifadhiwa mtandaoni baadaye"}'
        : '✅ Task saved:\n'
          '• Title: $_taskTitle\n'
          '${_description.isNotEmpty ? "• Description: $_description\n" : ""}'
          '${propLabel.isNotEmpty ? "• Property: $propLabel\n" : ""}'
          '${_assignee.isNotEmpty ? "• Assigned to: $_assignee\n" : ""}'
          '${_dueDateIso.isNotEmpty ? "• Due: $_dueDateIso\n" : ""}'
          '• Priority: ${_priorityLabel(_priority)}\n'
          '${synced ? "✓ Saved online" : "⏳ Will sync when online"}';
  }

  // ── Prompts ────────────────────────────────────────────────────────────

  String _promptAction() => isSw
      ? '🔧 Ungependa kufanya nini?\n${_actionList()}'
      : '🔧 What would you like to do?\n${_actionList()}';

  String _actionList() => isSw
      ? '1. Panga matengenezo ya mali\n2. Ongeza kazi / to-do'
      : '1. Schedule property maintenance\n2. Add a task / to-do';

  String _promptPropertyList() {
    if (_properties.isEmpty) {
      _step = _Step.done;
      return isSw
          ? 'Hakuna mali iliyopatikana. Ongeza mali kwanza.'
          : 'No properties found. Please add a property first.';
    }
    return (isSw ? '🏠 Matengenezo ni kwa mali ipi?\n' : '🏠 Which property needs maintenance?\n') +
        _propertyList();
  }

  String _propertyList() {
    final buf = StringBuffer();
    for (int i = 0; i < _properties.length; i++) {
      buf.writeln('${i + 1}. ${_properties[i].propertyName}');
    }
    return buf.toString().trimRight();
  }

  String _promptCategory() {
    return (isSw ? '🔧 Ni aina gani ya matengenezo?\n' : '🔧 What category of maintenance?\n') +
        _categoryList();
  }

  String _categoryList() {
    final buf = StringBuffer();
    for (int i = 0; i < _categories.length; i++) {
      final sw = _categorySw(_categories[i]);
      buf.writeln(isSw
          ? '${i + 1}. ${_categories[i]} ($sw)'
          : '${i + 1}. ${_categories[i]}');
    }
    return buf.toString().trimRight();
  }

  String _unitList(List<ApartmentUnitDraft> units) {
    final buf = StringBuffer();
    for (int i = 0; i < units.length; i++) {
      buf.writeln('${i + 1}. ${units[i].unitName}');
    }
    return buf.toString().trimRight();
  }

  String _promptPriority() {
    return isSw
        ? '⚡ Kipaumbele ni nini?\n${_priorityList()}'
        : '⚡ What is the priority?\n${_priorityList()}';
  }

  String _priorityList() => isSw
      ? '1. Chini (Low)\n2. Kati (Medium)\n3. Juu (High)'
      : '1. Low\n2. Medium\n3. High';

  String _promptConfirmMaintenance() {
    final prop = _property!;
    final propName = prop.propertyName.trim().isNotEmpty
        ? prop.propertyName.trim()
        : prop.propertyLocation.trim();
    final scheduled = _parseIso(_scheduledDateIso);
    final dateLabel = scheduled != null ? _fmtDate(scheduled) : _scheduledDateIso;
    return isSw
        ? '📋 Thibitisha matengenezo:\n'
          '• Mali: $propName\n'
          '${_unit != null ? "• Unit: ${_unit!.unitName}\n" : ""}'
          '• Aina: $_category\n'
          '• Maelezo: $_description\n'
          '• Tarehe: $dateLabel\n'
          '• Kipaumbele: ${_priorityLabelSw(_priority)}\n\n'
          'Andika **ndio** kuhifadhi au **hapana** kughairi.'
        : '📋 Confirm maintenance:\n'
          '• Property: $propName\n'
          '${_unit != null ? "• Unit: ${_unit!.unitName}\n" : ""}'
          '• Category: $_category\n'
          '• Description: $_description\n'
          '• Scheduled: $dateLabel\n'
          '• Priority: ${_priorityLabel(_priority)}\n\n'
          'Type **yes** to save or **no** to cancel.';
  }

  String _promptConfirmTask() {
    final propLine = _property != null
        ? (isSw ? '• Mali: ${_property!.propertyName}\n' : '• Property: ${_property!.propertyName}\n')
        : '';
    final assigneeLine = _assignee.isNotEmpty
        ? (isSw ? '• Imekabidhiwa: $_assignee\n' : '• Assigned to: $_assignee\n')
        : '';
    final dueLine = _dueDateIso.isNotEmpty
        ? (isSw ? '• Mwisho: $_dueDateIso\n' : '• Due: $_dueDateIso\n')
        : '';
    final descLine = _description.isNotEmpty
        ? (isSw ? '• Maelezo: $_description\n' : '• Description: $_description\n')
        : '';
    return isSw
        ? '📋 Thibitisha kazi:\n'
          '• Kichwa: $_taskTitle\n'
          '$descLine'
          '$propLine'
          '$assigneeLine'
          '$dueLine'
          '• Kipaumbele: ${_priorityLabelSw(_priority)}\n\n'
          'Andika **ndio** kuhifadhi au **hapana** kughairi.'
        : '📋 Confirm task:\n'
          '• Title: $_taskTitle\n'
          '$descLine'
          '$propLine'
          '$assigneeLine'
          '$dueLine'
          '• Priority: ${_priorityLabel(_priority)}\n\n'
          'Type **yes** to save or **no** to cancel.';
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  PropertyRecord? _matchProperty(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= _properties.length) {
      return _properties[idx - 1];
    }
    for (final p in _properties) {
      final n = p.propertyName.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return p;
    }
    return null;
  }

  ApartmentUnitDraft? _matchUnit(String text, List<ApartmentUnitDraft> units) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx != null && idx >= 1 && idx <= units.length) return units[idx - 1];
    for (final u in units) {
      final n = u.unitName.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return u;
    }
    return null;
  }

  List<ApartmentUnitDraft> _parseUnits(String json) {
    if (json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
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

  String _workspaceFor(PropertyRecord prop, ApartmentUnitDraft? unit) {
    final ws = prop.workspaceType.trim().toLowerCase();
    if (ws == 'bnb' || ws == 'rent') return ws;
    if (ws == 'both' && unit != null) {
      return unit.operationMode == 'rent' ? 'rent' : 'bnb';
    }
    return 'rent';
  }

  DateTime? _parseDate(String text) {
    final lower = text.toLowerCase().trim();
    if (lower == 'today' || lower == 'leo') return DateTime.now();
    if (lower == 'tomorrow' || lower == 'kesho') {
      return DateTime.now().add(const Duration(days: 1));
    }
    if (lower == 'next week' || lower == 'wiki ijayo') {
      return DateTime.now().add(const Duration(days: 7));
    }
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(lower);
    if (ymd != null) {
      final y = int.parse(ymd.group(1)!);
      final m = int.parse(ymd.group(2)!);
      final d = int.parse(ymd.group(3)!);
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) return DateTime(y, m, d);
    }
    final dmy = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(lower);
    if (dmy != null) {
      final d = int.parse(dmy.group(1)!);
      final m = int.parse(dmy.group(2)!);
      final y = int.parse(dmy.group(3)!);
      if (m >= 1 && m <= 12 && d >= 1 && d <= 31) return DateTime(y, m, d);
    }
    return null;
  }

  DateTime? _parseIso(String iso) {
    try { return DateTime.parse(iso); } catch (_) { return null; }
  }

  String? _parsePriority(String text) {
    final lower = text.toLowerCase().trim();
    final idx   = int.tryParse(lower);
    if (idx == 1) return 'low';
    if (idx == 2) return 'medium';
    if (idx == 3) return 'high';
    if (_containsAny(lower, ['high', 'juu', 'haraka', 'urgent', 'critical'])) return 'high';
    if (_containsAny(lower, ['low', 'chini', 'later', 'baadaye'])) return 'low';
    if (_containsAny(lower, ['medium', 'kati', 'normal', 'moderate'])) return 'medium';
    return null;
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _priorityLabel(String p) {
    switch (p) {
      case 'high':   return '🔴 High';
      case 'low':    return '🟢 Low';
      default:       return '🟡 Medium';
    }
  }

  static String _priorityLabelSw(String p) {
    switch (p) {
      case 'high':   return '🔴 Juu (High)';
      case 'low':    return '🟢 Chini (Low)';
      default:       return '🟡 Kati (Medium)';
    }
  }

  static String _categorySw(String c) {
    switch (c) {
      case 'Plumbing':    return 'Mabomba';
      case 'Electrical':  return 'Umeme';
      case 'HVAC':        return 'Hewa';
      case 'Appliances':  return 'Vifaa vya nyumba';
      case 'Structural':  return 'Ujenzi';
      case 'Landscaping': return 'Bustani';
      default:            return 'Jumla';
    }
  }

  static bool _containsAny(String text, List<String> tokens) =>
      tokens.any(text.contains);

  T _findOrThrow<T extends Object>({String? tag}) {
    if (!Get.isRegistered<T>(tag: tag)) throw StateError('$T is not registered');
    return Get.find<T>(tag: tag);
  }

  T? _find<T extends Object>({String? tag}) {
    try {
      return Get.isRegistered<T>(tag: tag) ? Get.find<T>(tag: tag) : null;
    } catch (_) {
      return null;
    }
  }

}

enum _Action { unknown, maintenance, task }

enum _Step {
  askAction,
  // maintenance
  askProperty,
  askUnit,
  askCategory,
  askDescription,
  askScheduledDate,
  askPriority,
  // task
  askTitle,
  askTaskDesc,
  askTaskProperty,
  askAssignee,
  askDueDate,
  askTaskPriority,
  // shared
  confirm,
  done,
}
