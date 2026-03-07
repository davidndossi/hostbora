import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

enum AccessStatus { active, scheduled }

class GuestAccessItem {
  final String guestName;
  final AccessStatus status;
  final String pinVisible; // e.g. "482"
  final String pinFull; // e.g. "482391"
  final String dateRange;

  const GuestAccessItem({
    required this.guestName,
    required this.status,
    required this.pinVisible,
    required this.pinFull,
    required this.dateRange,
  });
}

class GuestAccessCodesController extends BaseController {
  final lastSynced = 'Just now';

  final revealedGuestName = Rx<String?>(null);

  final activeAccess = <GuestAccessItem>[
    const GuestAccessItem(
      guestName: 'Sarah Jenkins',
      status: AccessStatus.active,
      pinVisible: '482',
      pinFull: '482391',
      dateRange: 'Oct 12, 3:00 PM — Oct 15, 11:00 AM',
    ),
  ];

  final upcomingAccess = <GuestAccessItem>[
    const GuestAccessItem(
      guestName: 'Michael Chen',
      status: AccessStatus.scheduled,
      pinVisible: '915',
      pinFull: '915624',
      dateRange: 'Oct 17, 3:00 PM — Oct 20, 11:00 AM',
    ),
    const GuestAccessItem(
      guestName: 'Elena Rodriguez',
      status: AccessStatus.scheduled,
      pinVisible: '204',
      pinFull: '204837',
      dateRange: 'Oct 22, 4:00 PM — Oct 25, 10:00 AM',
    ),
  ];

  void goBack() => Get.back();

  void toggleReveal(GuestAccessItem item) {
    revealedGuestName.value =
        revealedGuestName.value == item.guestName ? null : item.guestName;
  }

  void shareCode(GuestAccessItem item) {
    // TODO: share pin/code
  }

  void copyCode(GuestAccessItem item) {
    // TODO: copy to clipboard
  }

  void openOptions(GuestAccessItem item) {
    // TODO: show menu (edit, revoke, etc.)
  }

  void createCustomCode() {
    // TODO: navigate to create custom code flow
  }
}
