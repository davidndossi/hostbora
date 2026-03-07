import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';
import '../../team_and_staff/controllers/team_and_staff_controller.dart';

class StaffDetailController extends BaseController {
  late final StaffMember member;

  /// Sample data for detail (in real app load by member.id)
  String get email => '${member.name.split(' ').map((e) => e[0].toLowerCase()).join('')}@staymanagement.com';
  String get phone => '+1 (555) 982-1043';
  String get joinedDate => 'Jan 2023';
  int get totalTasks => 124;
  double get rating => 4.9;
  bool get isPrimaryRole => true;
  String get performanceStatus => 'Top Performer';

  List<AssignedProperty> get assignedProperties => [
    AssignedProperty(title: 'The Beach House', location: 'Malibu, CA', imageUrl: ''),
    AssignedProperty(title: 'Downtown Loft', location: 'Los Angeles, CA', imageUrl: ''),
  ];

  List<RecentTask> get recentTasks => [
    RecentTask(title: 'Deep Cleaning & Sanitization', completedAt: 'Oct 24, 2023'),
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is StaffMember) {
      member = args;
    } else {
      member = StaffMember(
        id: '',
        name: 'Unknown',
        role: 'Staff',
        tasksToday: 0,
        isHighTaskCount: false,
        isOnDuty: false,
        avatarUrl: '',
      );
    }
  }

  void openMenu() {
    Get.snackbar('Options', 'Edit, Remove, or more options.');
  }

  void openEmail() {}
  void openPhone() {}
  void manageProperties() {
    Get.snackbar('Manage', 'Assign or unassign properties.');
  }

  void assignNewTask() {
    Get.snackbar('Assign Task', 'Open task assignment flow.');
  }

  void removeFromTeam() {
    Get.snackbar('Remove', 'Confirm removal from team.');
  }
}

class AssignedProperty {
  final String title;
  final String location;
  final String imageUrl;
  AssignedProperty({required this.title, required this.location, required this.imageUrl});
}

class RecentTask {
  final String title;
  final String completedAt;
  RecentTask({required this.title, required this.completedAt});
}
