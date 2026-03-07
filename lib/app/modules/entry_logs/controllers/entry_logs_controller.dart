import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../model/entry_log_item.dart';

enum EntryLogFilter { all, appUnlocks, pinCodes }

class EntryLogsController extends BaseController {
  final selectedFilter = EntryLogFilter.all.obs;
  final lastSynced = '2m ago'.obs;
  final deviceName = 'Tuya Smart Lock';
  final locationName = 'Front Door';

  final _allItems = <EntryLogItem>[
    EntryLogItem(
      id: '1',
      iconType: EntryLogIconType.phone,
      title: 'Unlocked by John Smith',
      detail: 'Mobile App • Host Access',
      time: '10:30 AM',
      status: EntryLogStatus.success,
      date: DateTime.now(),
      isAppUnlock: true,
    ),
    EntryLogItem(
      id: '2',
      iconType: EntryLogIconType.lock,
      title: 'Auto-locked',
      detail: 'System • Secure Mode',
      time: '09:15 AM',
      status: EntryLogStatus.completed,
      date: DateTime.now(),
    ),
    EntryLogItem(
      id: '3',
      iconType: EntryLogIconType.key,
      title: 'Manual Lock',
      detail: 'Physical Key • Interior Thumbturn',
      time: '08:45 AM',
      status: EntryLogStatus.manual,
      date: DateTime.now(),
    ),
    EntryLogItem(
      id: '4',
      iconType: EntryLogIconType.keypad,
      title: 'Unlocked by Guest: Sarah W.',
      detail: 'PIN Code • Checkout Access',
      time: '11:02 AM',
      status: EntryLogStatus.success,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isPinCode: true,
    ),
    EntryLogItem(
      id: '5',
      iconType: EntryLogIconType.warning,
      title: 'Failed Unlock Attempt',
      detail: 'Wrong PIN • 3rd Attempt',
      time: '10:58 AM',
      status: EntryLogStatus.alert,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isPinCode: true,
    ),
  ];

  List<EntryLogItem> get filteredItems {
    switch (selectedFilter.value) {
      case EntryLogFilter.all:
        return _allItems;
      case EntryLogFilter.appUnlocks:
        return _allItems.where((e) => e.isAppUnlock).toList();
      case EntryLogFilter.pinCodes:
        return _allItems.where((e) => e.isPinCode).toList();
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
      list.sort((a, b) => b.time.compareTo(a.time));
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void setFilter(EntryLogFilter filter) {
    selectedFilter.value = filter;
  }

  void refresh() {
    lastSynced.value = 'Just now';
    Get.snackbar('Synced', 'Entry logs refreshed.');
  }
}
