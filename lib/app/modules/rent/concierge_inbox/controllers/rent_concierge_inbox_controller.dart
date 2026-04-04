import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../routes/app_pages.dart';

/// Demo inbox content for Concierge (Evergreen Estate). Replace with API later.
class ConciergeUrgentItem {
  const ConciergeUrgentItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.isPrimaryAction,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String actionLabel;
  /// Teal full-width button vs light grey style.
  final bool isPrimaryAction;
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
  });

  final String categoryPill;
  final String title;
  final String subtitle;
  final String scheduledCaption;
  final String dateLine;
  final String actionLabel;
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
  final urgentItems = <ConciergeUrgentItem>[].obs;
  final renewalItems = <ConciergeRenewalItem>[].obs;
  final maintenanceItems = <ConciergeMaintenanceItem>[].obs;
  final generalItems = <ConciergeGeneralItem>[].obs;

  /// True when any inbox section has items (urgent, renewals, maintenance, or general).
  // final hasNotifications = false.obs;
  bool get hasNotifications =>
      urgentItems.isNotEmpty ||
      renewalItems.isNotEmpty ||
      maintenanceItems.isNotEmpty ||
      generalItems.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _seedDemoInbox();
  }

  /// Replace with API mapping. If all lists stay empty, the empty-state UI is shown.
  void _seedDemoInbox() {
    urgentItems.assignAll(const [
      ConciergeUrgentItem(
        tag: 'PAYROLL',
        title: 'Salary Due: Zuwena',
        subtitle: 'General Manager - Tsh 800,000 due in 2 days',
        actionLabel: 'Pay Now',
        isPrimaryAction: true,
      ),
      ConciergeUrgentItem(
        tag: 'RECEIVABLES',
        title: 'Partial Payment Follow-up',
        subtitle: 'Amara Okafor - Remaining Tsh 400,000 due tomorrow',
        actionLabel: 'Remind',
        isPrimaryAction: false,
      ),
    ]);
    renewalItems.assignAll(const [
      ConciergeRenewalItem(
        unit: 'Unit 402',
        propertyLine: 'SEAVIEW APARTMENT',
        body:
            'Lease expiration approaching. Tenant has expressed interest in 12-month extension.',
        dueLabel: 'DUE IN 5 DAYS',
        actionLabel: 'Renew',
        imageAsset: 'images/luxury_room_view.png',
      ),
    ]);
    maintenanceItems.assignAll(const [
      ConciergeMaintenanceItem(
        categoryPill: 'HVAC SERVICE',
        title: 'AC Repair',
        subtitle: 'Garden Villa C9 - Seasonal Checkup',
        scheduledCaption: 'SCHEDULED DATE',
        dateLine: 'July 15, 2024',
        actionLabel: 'Reschedule',
      ),
    ]);
    generalItems.assignAll(const [
      ConciergeGeneralItem(
        title: 'New Booking Confirmed',
        subtitle: 'Skyline Loft 1B - Guest arriving in 3 days',
        actionLabel: 'View Details',
      ),
    ]);
  }

  void markAllAsRead() {
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

  void onUrgentAction(ConciergeUrgentItem item) {}

  void onRenewalAction(ConciergeRenewalItem item) {}

  void onMaintenanceAction(ConciergeMaintenanceItem item) {}

  void onGeneralAction(ConciergeGeneralItem item) {}
}
