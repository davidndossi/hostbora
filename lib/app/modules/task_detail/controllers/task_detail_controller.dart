import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/model/add_task_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../maintenance_tasks/model/maintenance_task.dart';

class TaskDetailController extends BaseController {
  TaskDetailController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
        _staffLocal = Get.find<RentStaffLocalDataSource>();

  final AppRepository _repository;
  final RentStaffLocalDataSource _staffLocal;

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
    try {
      final request = AddTaskRequest(
        title: t.title,
        description: t.description.trim().isEmpty ? null : t.description.trim(),
        assignee: name.trim(),
      );
      final res = await _repository.updateTask(t.id, request);
      if (res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201') {
        task.value = t.copyWith(assignee: name.trim());
        showSuccessMessage('Assigned to $name');
      } else {
        // Optimistic local update even if API fails
        task.value = t.copyWith(assignee: name.trim());
        showSuccessMessage('Assigned locally');
      }
    } catch (_) {
      final t2 = task.value;
      if (t2 != null) task.value = t2.copyWith(assignee: name.trim());
      showSuccessMessage('Assigned locally');
    } finally {
      assigningStaff.value = false;
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadTask();
  }

  Future<void> loadTask() async {
    final id = task.value?.id;
    if (id == null || id.isEmpty) {
      loadError.value = 'Missing task id';
      return;
    }
    loading.value = true;
    loadError.value = null;
    try {
      final res = await _repository.getTask(id);
      if (res.responseCode == '0' && res.data != null) {
        final map = _unwrapTaskMap(res.data);
        if (map != null) {
          task.value = MaintenanceTask.fromApiMap(map);
        } else {
          loadError.value = 'Unexpected response';
        }
      } else {
        loadError.value = res.message ?? 'Could not load task';
      }
    } catch (e) {
      loadError.value = e.toString();
    } finally {
      loading.value = false;
    }
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

  void goBack() => Get.back();

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
