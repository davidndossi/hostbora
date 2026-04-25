import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

enum ListingUnitStatus { short, occupied, dueDate }

class ListingUnitRowVm {
  ListingUnitRowVm({
    required this.name,
    required this.subtitle,
    required this.status,
  });

  final String name;
  final String subtitle;
  final ListingUnitStatus status;
}

class ListingActivityVm {
  ListingActivityVm({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.timeLabel,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String timeLabel;
  final Color accentColor;
}

class ListingStaffVm {
  ListingStaffVm({required this.name, required this.jobTitle});

  final String name;
  final String jobTitle;
}

class ListingDetailsController extends BaseController {
  final loadingListing = true.obs;
  final listingTitle = 'Evergreen Estate'.obs;
  final heroOverlayTitle = 'Sky View Apartment • Unit 402'.obs;
  final occupancyPercent = 85.obs;
  final monthlyRevenueLabel = '4.5M'.obs;

  final listingScrollController = ScrollController();

  final unitRows = <ListingUnitRowVm>[].obs;
  final recentActivity = <ListingActivityVm>[].obs;
  final staffPreview = <ListingStaffVm>[].obs;

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  void onReady() {
    super.onReady();
    loadListingDetail();
  }

  @override
  void onClose() {
    listingScrollController.dispose();
    super.onClose();
  }

  Future<void> loadListingDetail() async {
    loadingListing.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      unitRows.assignAll([
        ListingUnitRowVm(
          name: 'Unit 401',
          subtitle: _isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant',
          status: ListingUnitStatus.short,
        ),
        ListingUnitRowVm(
          name: 'Unit 402',
          subtitle: _isSw ? 'Kodi imelipwa' : 'Rent fully paid',
          status: ListingUnitStatus.occupied,
        ),
        ListingUnitRowVm(
          name: 'Unit 403',
          subtitle: _isSw ? 'Malipo yamechelewa' : 'Payment overdue',
          status: ListingUnitStatus.dueDate,
        ),
        ListingUnitRowVm(
          name: 'Unit 404',
          subtitle: _isSw ? 'Inasubiri uthibitisho' : 'Awaiting confirmation',
          status: ListingUnitStatus.short,
        ),
      ]);

      recentActivity.assignAll([
        ListingActivityVm(
          title: _isSw ? 'Malipo yamepokelewa' : 'Payment Received',
          subtitle: _isSw ? 'Rent paid' : 'Rent paid',
          trailing: '+ TZS 1.1M',
          timeLabel: '14:20',
          accentColor: const Color(0xFF0EA5A4),
        ),
        ListingActivityVm(
          title: _isSw ? 'Kumbukumbu imetumwa' : 'Rent Notice Sent',
          subtitle: _isSw ? 'Ufuatiliaji' : 'Reminder',
          trailing: 'SENT',
          timeLabel: '10:45',
          accentColor: const Color(0xFFF59E0B),
        ),
        ListingActivityVm(
          title: _isSw ? 'Ombi la matengenezo' : 'AC Maintenance',
          subtitle: _isSw ? 'Imewekwa' : 'Scheduled',
          trailing: 'PENDING',
          timeLabel: 'YEST',
          accentColor: const Color(0xFF9CA3AF),
        ),
      ]);

      staffPreview.assignAll([
        ListingStaffVm(name: 'Neema Felix', jobTitle: _isSw ? 'Msimamizi' : 'Property Manager'),
        ListingStaffVm(name: 'Saidi Moyo', jobTitle: _isSw ? 'Fundi' : 'Maintenance'),
      ]);
    } finally {
      loadingListing.value = false;
    }
  }

  Future<void> loadRealDataSnapshot() async {
    // Kept for refresh compatibility with the view.
  }

  void onEditListing() => showSuccessMessage(_isSw ? 'Hariri listing' : 'Edit listing');

  void onAddNewUnit() => showSuccessMessage(_isSw ? 'Ongeza unit' : 'Add new unit');

  void onViewAllLog() => showSuccessMessage(_isSw ? 'Kumbukumbu zote' : 'Viewing full activity log');

  void onManageStaff() => showSuccessMessage(_isSw ? 'Usimamizi wa staff' : 'Manage staff');

  void onQuickAction(int index) {
    switch (index) {
      case 0:
        showSuccessMessage(_isSw ? 'Ongeza mpangaji' : 'Add tenant');
        break;
      case 1:
        showSuccessMessage(_isSw ? 'Ongeza mapato' : 'Add income');
        break;
      case 2:
        showSuccessMessage(_isSw ? 'Ongeza gharama' : 'Add expense');
        break;
      case 3:
        showSuccessMessage(_isSw ? 'Panga matengenezo' : 'Schedule maintenance');
        break;
      case 4:
        showSuccessMessage(_isSw ? 'Udhibiti wa lock' : 'Unit lock control');
        break;
      case 5:
        Get.toNamed(Routes.RENT_SMART_UTILITY_DASHBOARD);
        break;
      default:
        break;
    }
  }

  void onAnalyticsQuickAction(int index) {
    if (index == 1) {
      Get.toNamed(Routes.RENT_MONTHLY_PL_SUMMARY);
    }
  }

  void onUnitPrimaryAction(ListingUnitRowVm row) {
    switch (row.status) {
      case ListingUnitStatus.dueDate:
        showSuccessMessage(_isSw ? 'Tuma ankara' : 'Send invoice');
        break;
      case ListingUnitStatus.occupied:
      case ListingUnitStatus.short:
        showSuccessMessage(_isSw ? 'Angalia maelezo' : 'View details');
        break;
    }
  }

  String primaryButtonLabel(ListingUnitRowVm row, bool isSw) {
    if (row.status == ListingUnitStatus.dueDate) {
      return isSw ? 'Send Invoice' : 'Send Invoice';
    }
    if (row.status == ListingUnitStatus.occupied) {
      return isSw ? 'View Details' : 'View Details';
    }
    return isSw ? 'Add Tenant' : 'Add Tenant';
  }
}
