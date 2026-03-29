import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';

enum ListingUnitStatus { vacant, occupied, overdue }

class ListingDetailUnit {
  const ListingDetailUnit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.beds,
    required this.baths,
    required this.status,
    this.highlighted = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final int beds;
  final int baths;
  final ListingUnitStatus status;
  final bool highlighted;
}

class ListingActivityItem {
  const ListingActivityItem({
    required this.title,
    required this.subtitle,
    required this.metaRight,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String metaRight;
  final int iconColor;
}

class ListingStaffMember {
  const ListingStaffMember({required this.name, required this.role, this.initials});

  final String name;
  final String role;
  final String? initials;
}

class ListingQuickAction {
  const ListingQuickAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class RentListingDetailsController extends BaseController {
  String get estateTitle => 'Evergreen Estate';

  String get heroImageAsset => 'images/luxury_room_view.png';

  String get listingTitle => 'Sea View Apartment - Unit 402';

  String get listingDescription =>
      'This is a sea view unit on floor 4 of the building with panoramic ocean views and premium finishes.';

  double get occupancyPercent => 0.85;

  String get occupancyLabel => '85%';

  String get monthlyRevenueLabel => '4.5M';

  String get revenueTrendLabel => '12% from last month';

  final quickActions = const <ListingQuickAction>[
    ListingQuickAction(label: 'Add Tenant', icon: Icons.person_add_alt_outlined),
    ListingQuickAction(label: 'Add Income', icon: Icons.description_outlined),
    ListingQuickAction(label: 'Add Expenses', icon: Icons.receipt_long_outlined),
    ListingQuickAction(label: 'Schedule Maintenance', icon: Icons.calendar_month_outlined),
    ListingQuickAction(label: 'Smart Lock Control', icon: Icons.lock_open_rounded),
    ListingQuickAction(label: 'Luku Dashboard', icon: Icons.bolt_outlined),
  ];

  final units = <ListingDetailUnit>[
    const ListingDetailUnit(
      id: '401',
      title: 'Unit 401',
      subtitle: 'Penthouse B',
      beds: 3,
      baths: 2,
      status: ListingUnitStatus.vacant,
    ),
    const ListingDetailUnit(
      id: '402',
      title: 'Unit 402',
      subtitle: 'Sea View',
      beds: 3,
      baths: 2,
      status: ListingUnitStatus.occupied,
      highlighted: true,
    ),
    const ListingDetailUnit(
      id: '403',
      title: 'Unit 403',
      subtitle: 'Garden level',
      beds: 2,
      baths: 2,
      status: ListingUnitStatus.overdue,
    ),
  ];

  final activities = <ListingActivityItem>[
    const ListingActivityItem(
      title: 'M-Pesa payment received',
      subtitle: 'Unit 402 — Rent',
      metaRight: 'TZS 1.2M · 2h ago',
      iconColor: 0xFF047857,
    ),
    const ListingActivityItem(
      title: 'Maintenance scheduled',
      subtitle: 'HVAC — Unit 401',
      metaRight: 'Tomorrow',
      iconColor: 0xFF0369A1,
    ),
    const ListingActivityItem(
      title: 'Lease renewal sent',
      subtitle: 'Unit 403',
      metaRight: 'Mar 28',
      iconColor: 0xFFB45309,
    ),
  ];

  final staff = const <ListingStaffMember>[
    ListingStaffMember(name: 'Zuwena Rashid', role: 'Primary Manager', initials: 'ZR'),
    ListingStaffMember(name: 'Amara Okafor', role: 'Concierge', initials: 'AO'),
  ];

  String get unitNoteTitle => 'Unit Note';

  String get unitNoteBody =>
      'Guest feedback noted odors from the hallway carpet on floor 4. Schedule deep cleaning and inspect HVAC filters before next check-in.';

  final selectedBottomNavIndex = 1.obs;

  void onBottomNavTap(int index) => selectedBottomNavIndex.value = index;

  void onEditListing() {}

  void onManageModules() {}

  void onAddNewUnit() {}

  void onViewAllLog() {}

  void onManageStaff() {}

  void onQuickAction(int index) {}

  void onUnitPrimaryAction(ListingDetailUnit unit) {}

  void onReadUnitNote() {}
}
