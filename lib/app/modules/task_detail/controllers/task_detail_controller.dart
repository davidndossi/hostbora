import 'dart:convert';

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../maintenance_tasks/model/maintenance_task.dart';

class TaskDetailController extends BaseController {
  TaskDetailController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
        _syncWorker = Get.find<OfflineSyncWorkerService>();

  final AppRepository _repository;
  final RentStaffLocalDataSource _staffLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final OfflineSyncWorkerService _syncWorker;

  final task = Rxn<MaintenanceTask>();
  final loading = false.obs;
  final loadError = RxnString();

  /// Staff names loaded from local DB for the assign sheet.
  final staffNames = <String>[].obs;
  final assigningStaff = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      task.value =
          MaintenanceTask.fromArguments(Map<String, dynamic>.from(args));
    }
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
      staffNames.assignAll(names);
    } catch (_) {
      staffNames.clear();
    }
  }

  Future<void> assignStaff(String name) async {
    final t = task.value;
    if (t == null || name.trim().isEmpty) return;
    assigningStaff.value = true;
    final trimmed = name.trim();
    final request = t.toUpdateRequest(assigneeOverride: trimmed);
    try {
      final res = await _repository.updateTask(t.id, request);
      if (res.isSuccess) {
        task.value = t.copyWith(assignee: trimmed);
        showSuccessMessage('Assigned to $trimmed');
      } else {
        await _queueTaskUpdate(t.id, request);
        task.value = t.copyWith(assignee: trimmed);
        showSuccessMessage('Assigned locally — will sync when online');
      }
    } catch (_) {
      await _queueTaskUpdate(t.id, request);
      task.value = t.copyWith(assignee: trimmed);
      showSuccessMessage('Assigned locally — will sync when online');
    } finally {
      assigningStaff.value = false;
    }
  }

  Future<void> _queueTaskUpdate(String taskId, AddTaskRequest request) async {
    try {
      await _syncQueue.enqueue(
        entityType: 'task',
        operation: 'update',
        payloadJson: jsonEncode({
          'taskId': taskId,
          ...request.toJson(),
        }),
        dedupeKey: 'task:update:$taskId',
      );
      _syncWorker.runNow();
    } catch (_) {}
  }

  @override
  void onReady() {
    super.onReady();
    loadTask();
  }

  Future<void> loadTask() async {
    final cached = task.value;
    final id = cached?.id;
    if (id == null || id.isEmpty) {
      loadError.value = 'Missing task id';
      return;
    }
    loading.value = true;
    loadError.value = null;
    try {
      final res = await _repository.getTask(id);
      if (res.isSuccess && res.data != null) {
        final map = _unwrapTaskMap(res.data);
        if (map != null) {
          final remote = MaintenanceTask.fromApiMap(map);
          task.value = _mergeWithCached(cached, remote);
          return;
        }
      }
      if (cached != null && cached.id.isNotEmpty) {
        // Keep showing the task passed from the list; detail fetch is optional.
        return;
      }
      loadError.value = res.message ?? 'Could not load task';
    } catch (_) {
      if (cached != null && cached.id.isNotEmpty) {
        return;
      }
      loadError.value = 'Could not load task details';
    } finally {
      loading.value = false;
    }
  }

  MaintenanceTask _mergeWithCached(MaintenanceTask? cached, MaintenanceTask remote) {
    if (cached == null) return remote;
    final assignee = _isUnassigned(remote.assignee) && !_isUnassigned(cached.assignee)
        ? cached.assignee
        : remote.assignee;
    return remote.copyWith(assignee: assignee);
  }

  static bool _isUnassigned(String value) {
    final s = value.trim().toLowerCase();
    return s.isEmpty || s == 'unassigned' || s == '—' || s == '-';
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

  void goBack() {
    final t = task.value;
    if (t != null) {
      Get.back(result: t.toArguments());
    } else {
      Get.back();
    }
  }

  void openEdit() {
    final t = task.value;
    if (t == null) return;
    Get.toNamed(Routes.EDIT_TASK, arguments: t.toArguments())?.then((saved) {
      if (saved == true) loadTask();
    });
  }

  void toggleComplete() {
    final t = task.value;
    if (t == null) return;
    final now = DateTime.now();
    task.value = t.copyWith(
      isCompleted: !t.isCompleted,
      status: t.isCompleted ? TaskStatus.pending : TaskStatus.completed,
      completedAt: t.isCompleted ? null : now,
    );
  }
}
