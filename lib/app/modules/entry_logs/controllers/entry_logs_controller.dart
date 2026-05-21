import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/service/entry_logs_service.dart';
import '../model/entry_log_item.dart';

enum EntryLogFilter { all, appUnlocks, pinCodes }

class EntryLogsController extends BaseController {
  EntryLogsController({EntryLogsService? entryLogsService})
      : _service = entryLogsService ?? EntryLogsService();

  final EntryLogsService _service;

  final selectedFilter = EntryLogFilter.all.obs;
  final lastSynced = '—'.obs;
  final deviceName = 'Smart Lock'.obs;
  final locationName = ''.obs;
  final allItems = <EntryLogItem>[].obs;
  final isLoading = false.obs;
  final loadError = ''.obs;
  final fromCacheOnly = true.obs;

  List<EntryLogItem> get filteredItems {
    switch (selectedFilter.value) {
      case EntryLogFilter.all:
        return allItems.toList();
      case EntryLogFilter.appUnlocks:
        return allItems.where((e) => e.isAppUnlock).toList();
      case EntryLogFilter.pinCodes:
        return allItems.where((e) => e.isPinCode).toList();
    }
  }

  Map<String, List<EntryLogItem>> get itemsByDay {
    final map = <String, List<EntryLogItem>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in filteredItems) {
      final d = DateTime(item.date.year, item.date.month, item.date.day);
      final key = d == today
          ? 'TODAY'
          : d == yesterday
              ? 'YESTERDAY'
              : _formatSectionDate(d);
      map.putIfAbsent(key, () => []).add(item);
    }

    for (final list in map.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    const order = ['TODAY', 'YESTERDAY'];
    final ordered = <String, List<EntryLogItem>>{};
    for (final k in order) {
      if (map.containsKey(k)) ordered[k] = map[k]!;
    }
    for (final k in map.keys) {
      if (!ordered.containsKey(k)) ordered[k] = map[k]!;
    }
    return ordered;
  }

  String _formatSectionDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  Future<void> loadLogs({bool refresh = false}) async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final result = await _service.load(refresh: refresh);
      allItems.assignAll(result.items);
      if (result.deviceName != null && result.deviceName!.isNotEmpty) {
        deviceName.value = result.deviceName!;
      }
      locationName.value = result.locationName ?? '';
      lastSynced.value = result.lastSyncedLabel ?? '—';
      fromCacheOnly.value = result.fromCacheOnly;
      if (result.errorMessage != null &&
          result.errorMessage!.isNotEmpty &&
          result.items.isEmpty) {
        loadError.value = result.errorMessage!;
      }
    } catch (e) {
      allItems.assignAll(_service.loadLocalItems());
      loadError.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(EntryLogFilter filter) {
    selectedFilter.value = filter;
  }

  Future<void> refresh() async {
    await loadLogs(refresh: true);
    if (loadError.value.isEmpty) {
      Get.snackbar('Synced', 'Entry logs refreshed.');
    }
  }
}
