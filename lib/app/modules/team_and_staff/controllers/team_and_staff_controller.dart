import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class TeamAndStaffController extends BaseController {
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  final staffList = <StaffMember>[
    StaffMember(
      id: '1',
      name: 'Sarah Jenkins',
      role: 'Head Cleaner',
      tasksToday: 3,
      isHighTaskCount: false,
      isOnDuty: true,
      avatarUrl: 'https://placehold.co/56x56',
    ),
    StaffMember(
      id: '2',
      name: 'Elena Thorne',
      role: 'Maintenance',
      tasksToday: 5,
      isHighTaskCount: true,
      isOnDuty: true,
      avatarUrl: 'https://placehold.co/56x56',
    ),
    StaffMember(
      id: '3',
      name: 'Mike Richards',
      role: 'Groundskeeper',
      tasksToday: 2,
      isHighTaskCount: false,
      isOnDuty: false,
      avatarUrl: 'https://placehold.co/56x56',
    ),
    StaffMember(
      id: '4',
      name: 'David Kim',
      role: 'Housekeeper',
      tasksToday: 4,
      isHighTaskCount: false,
      isOnDuty: true,
      avatarUrl: 'https://placehold.co/56x56',
    ),
  ].obs;

  List<StaffMember> get filteredStaff {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return staffList;
    return staffList
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.role.toLowerCase().contains(q),
        )
        .toList();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void addStaff() {
    // TODO: navigate to add staff screen
  }

  void messageStaff(StaffMember member) {
    // TODO: open chat with staff
  }

  void editStaff(StaffMember member) {
    // TODO: navigate to edit staff
  }

  void openStaffDetail(StaffMember member) {
    Get.toNamed(Routes.STAFF_DETAIL, arguments: member);
  }

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.toNamed(Routes.ADD_LISTING);
        break;
      case 1:
        // TODO: Bookings
        break;
      case 2:
        // TEAM - current screen
        break;
      case 3:
        // TODO: Profile
        break;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class StaffMember {
  final String id;
  final String name;
  final String role;
  final int tasksToday;
  final bool isHighTaskCount;
  final bool isOnDuty;
  final String avatarUrl;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.tasksToday,
    required this.isHighTaskCount,
    required this.isOnDuty,
    required this.avatarUrl,
  });
}
