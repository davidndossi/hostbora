import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../maintenance_tasks/model/maintenance_task.dart';

class TaskDetailController extends BaseController {
  TaskDetailController()
      : _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final AppRepository _repository;

  final task = Rxn<MaintenanceTask>();
  final loading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      task.value =
          MaintenanceTask.fromArguments(Map<String, dynamic>.from(args));
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
