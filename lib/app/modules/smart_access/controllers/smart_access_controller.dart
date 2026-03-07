import 'dart:async';

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/service/tuya_smart_lock_service.dart';
import '../../../routes/app_pages.dart';

class ActivityEntry {
  final String guestName;
  final String detail;
  final String time;

  const ActivityEntry({
    required this.guestName,
    required this.detail,
    required this.time,
  });
}

class SmartAccessController extends BaseController {
  final isLocked = true.obs;
  final lastUpdated = '2 MINS AGO'.obs;
  final propertyLabel = 'WESTSIDE PENTHOUSE • UNIT 402';

  /// When Tuya Smart Lock is integrated, this is the device ID used for remote lock/unlock.
  String? _selectedLockDeviceId;
  StreamSubscription? _lockStateSubscription;

  final recentActivity = <ActivityEntry>[
    const ActivityEntry(
      guestName: 'Sarah Jenkins',
      detail: 'Unlocked via keypad',
      time: '1:42 PM',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initTuyaLock();
  }

  @override
  void onClose() {
    _lockStateSubscription?.cancel();
    super.onClose();
  }

  /// Bind to Tuya Smart Lock if available and subscribe to state updates.
  Future<void> _initTuyaLock() async {
    if (!Get.isRegistered<TuyaSmartLockService>()) return;
    final lockService = Get.find<TuyaSmartLockService>();
    final locks = await lockService.getLockDevices();
    if (locks.isEmpty) return;
    _selectedLockDeviceId = locks.first.devId;
    _lockStateSubscription = lockService
        .onLockStateUpdated(_selectedLockDeviceId!)
        .listen((dps) {
      isLocked.value = TuyaSmartLockService.isLockedFromDps(dps);
    });
  }

  void goBack() => Get.back();

  void openMoreOptions() {
  }

  /// Remote unlock via Tuya Smart Lock SDK when a lock device is available.
  Future<void> unlockDoor() async {
    if (Get.isRegistered<TuyaSmartLockService>() && _selectedLockDeviceId != null) {
      final lockService = Get.find<TuyaSmartLockService>();
      final ok = await lockService.unlock(_selectedLockDeviceId!);
      if (ok) isLocked.value = false;
      return;
    }
    isLocked.value = false;
  }

  /// Remote lock via Tuya Smart Lock SDK when a lock device is available.
  Future<void> lockDoor() async {
    if (Get.isRegistered<TuyaSmartLockService>() && _selectedLockDeviceId != null) {
      final lockService = Get.find<TuyaSmartLockService>();
      final ok = await lockService.lock(_selectedLockDeviceId!);
      if (ok) isLocked.value = true;
      return;
    }
    isLocked.value = true;
  }

  void generateGuestCode() {
    Get.toNamed(Routes.GUEST_ACCESS_CODES);
  }

  void viewAllActivity() {
    Get.toNamed(Routes.ENTRY_LOGS);
  }
}
