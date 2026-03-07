import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class SecurityController extends BaseController {
  final faceIdEnabled = true.obs;

  final devices = <DeviceSession>[
    DeviceSession(
      name: 'iPhone 14 Pro',
      location: 'London, UK',
      lastActive: 'Active Now',
      isCurrent: true,
    ),
    DeviceSession(
      name: 'MacBook Pro 16"',
      location: 'Manchester, UK',
      lastActive: '2 hours ago',
      isCurrent: false,
    ),
  ];

  void goBack() => Get.back();

  void changePassword() => Get.toNamed(Routes.CHANGE_PASSWORD);

  void openPinCode() {
    // TODO: navigate to PIN setup
  }

  void openTwoFactor() {
    // TODO: navigate to 2FA settings
  }

  void logoutAllDevices() {
    // TODO: confirm and call API to log out all sessions
    Get.back();
  }

  void logoutDevice(DeviceSession device) {
    // TODO: remove session
  }

  void openPrivacyPolicy() => Get.toNamed(Routes.PRIVACY);

  void onNavTap(int index) {
    switch (index) {
      case 0:
        break; // TODO: Inbox
      case 1:
        Get.offAllNamed(Routes.HOST_CALENDAR);
        break;
      case 2:
        Get.offAllNamed(Routes.MY_PROPERTIES);
        break;
      case 3:
        Get.back();
        break; // Settings - current
      case 4:
        break; // TODO: Menu
    }
  }
}

class DeviceSession {
  final String name;
  final String location;
  final String lastActive;
  final bool isCurrent;

  DeviceSession({
    required this.name,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });
}
