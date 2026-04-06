import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_notification_log_local_data_source.dart';
import '../../../../routes/app_pages.dart';

/// Demo inbox content for Concierge (Evergreen Estate). Replace with API later.
class ConciergeUrgentItem {
  const ConciergeUrgentItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.isPrimaryAction,
    this.isRead = false,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String actionLabel;
  /// Teal full-width button vs light grey style.
  final bool isPrimaryAction;
  final bool isRead;
}

class ConciergeRenewalItem {
  const ConciergeRenewalItem({
    required this.unit,
    required this.propertyLine,
    required this.body,
    required this.dueLabel,
    required this.actionLabel,
    this.imageAsset,
  });

  final String unit;
  final String propertyLine;
  final String body;
  final String dueLabel;
  final String actionLabel;
  final String? imageAsset;
}

class ConciergeMaintenanceItem {
  const ConciergeMaintenanceItem({
    required this.categoryPill,
    required this.title,
    required this.subtitle,
    required this.scheduledCaption,
    required this.dateLine,
    required this.actionLabel,
    this.isRead = false,
  });

  final String categoryPill;
  final String title;
  final String subtitle;
  final String scheduledCaption;
  final String dateLine;
  final String actionLabel;
  final bool isRead;
}

class ConciergeGeneralItem {
  const ConciergeGeneralItem({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
}

class RentConciergeInboxController extends BaseController {
  RentConciergeInboxController()
      : _notificationLogLocal = Get.find<RentNotificationLogLocalDataSource>();

  final RentNotificationLogLocalDataSource _notificationLogLocal;
  final urgentItems = <ConciergeUrgentItem>[].obs;
  final renewalItems = <ConciergeRenewalItem>[].obs;
  final maintenanceItems = <ConciergeMaintenanceItem>[].obs;
  final generalItems = <ConciergeGeneralItem>[].obs;
  final selectedFilter = 'all'.obs;

  /// True when any inbox section has items (urgent, renewals, maintenance, or general).
  // final hasNotifications = false.obs;
  bool get hasNotifications =>
      filteredUrgentItems.isNotEmpty ||
      filteredMaintenanceItems.isNotEmpty;

  List<ConciergeUrgentItem> get filteredUrgentItems {
    final f = selectedFilter.value;
    if (f == 'maintenance') return const [];
    if (f == 'unread') return urgentItems.where((e) => !e.isRead).toList();
    return urgentItems.toList();
  }

  List<ConciergeMaintenanceItem> get filteredMaintenanceItems {
    final f = selectedFilter.value;
    if (f == 'urgent') return const [];
    if (f == 'unread') return maintenanceItems.where((e) => !e.isRead).toList();
    return maintenanceItems.toList();
  }

  int get allCount => urgentItems.length + maintenanceItems.length;
  int get urgentCount => urgentItems.length;
  int get maintenanceCount => maintenanceItems.length;
  int get unreadCount =>
      urgentItems.where((e) => !e.isRead).length +
      maintenanceItems.where((e) => !e.isRead).length;

  @override
  void onInit() {
    super.onInit();
    loadInbox();
  }

  Future<void> loadInbox() async {
    final rows = await _notificationLogLocal.getAllNewestFirst();

    urgentItems.assignAll(
      rows
          .where((e) => e.type == 'urgent')
          .map(
            (e) => ConciergeUrgentItem(
              tag: e.title.toUpperCase().contains('SALARY') ? 'PAYROLL' : 'RECEIVABLES',
              title: e.title,
              subtitle: e.subtitle,
              actionLabel: e.actionLabel.isEmpty ? 'Open' : e.actionLabel,
              isPrimaryAction: e.title.toUpperCase().contains('SALARY'),
              isRead: e.isRead,
            ),
          ),
    );

    maintenanceItems.assignAll(
      rows
          .where((e) => e.type == 'maintenance')
          .map(
            (e) => ConciergeMaintenanceItem(
              categoryPill: 'MAINTENANCE',
              title: e.title,
              subtitle: e.subtitle,
              scheduledCaption: 'NOTIFICATION',
              dateLine: _timeAgo(e.createdAtMs),
              actionLabel: e.actionLabel.isEmpty ? 'Open' : e.actionLabel,
              isRead: e.isRead,
            ),
          ),
    );

    renewalItems.clear();
    generalItems.clear();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<void> markAllAsRead() async {
    await _notificationLogLocal.markAllAsRead();
    await loadInbox();
    showSuccessMessage('All inbox items marked as read');
  }

  void returnToDashboard() {
    final ctx = Get.context;
    if (ctx != null && Navigator.canPop(ctx)) {
      Get.back();
    } else {
      Get.offNamed(Routes.RENT_HUB);
    }
  }

  void onUrgentAction(ConciergeUrgentItem item) {
    if (item.tag == 'PAYROLL') {
      Get.toNamed(Routes.RENT_STAFF_MANAGEMENT);
      return;
    }
    Get.toNamed(Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER);
  }

  void onRenewalAction(ConciergeRenewalItem item) {}

  void onMaintenanceAction(ConciergeMaintenanceItem item) {
    Get.toNamed(Routes.RENT_SCHEDULE_MAINTENANCE_FORM);
  }

  void onGeneralAction(ConciergeGeneralItem item) {}

  String _timeAgo(int timestampMs) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
