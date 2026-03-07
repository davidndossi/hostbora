import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

class AddNewBookingController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final guestNameController = TextEditingController();
  final notesController = TextEditingController();
  final numberOfGuestsController = TextEditingController();

  final selectedProperty = Rx<String?>(null);
  final checkInDate = Rx<DateTime?>(null);
  final checkOutDate = Rx<DateTime?>(null);

  static const _dateFormat = 'MMM d, yyyy';

  final propertyOptions = [
    'Beachfront Villa',
    'City Apartment',
    'Garden House',
    'Studio Loft',
  ];

  String get checkInLabel =>
      checkInDate.value != null
          ? DateFormat(_dateFormat).format(checkInDate.value!)
          : 'Select date';

  String get checkOutLabel =>
      checkOutDate.value != null
          ? DateFormat(_dateFormat).format(checkOutDate.value!)
          : 'Select date';

  void goBack() => Get.back();

  void selectProperty(String? value) {
    selectedProperty.value = value;
  }

  Future<void> pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkInDate.value ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) checkInDate.value = picked;
  }

  Future<void> pickCheckOut() async {
    final from = checkInDate.value ?? DateTime.now();
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: checkOutDate.value ?? from.add(const Duration(days: 1)),
      firstDate: from,
      lastDate: from.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) checkOutDate.value = picked;
  }

  void saveBooking() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedProperty.value == null || selectedProperty.value!.isEmpty) {
      Get.snackbar('Required', 'Please select a property');
      return;
    }
    if (checkInDate.value == null) {
      Get.snackbar('Required', 'Please select check-in date');
      return;
    }
    if (checkOutDate.value == null) {
      Get.snackbar('Required', 'Please select check-out date');
      return;
    }
    if (checkOutDate.value!.isBefore(checkInDate.value!) ||
        checkOutDate.value!.isAtSameMomentAs(checkInDate.value!)) {
      Get.snackbar('Invalid', 'Check-out must be after check-in');
      return;
    }
    // TODO: persist booking and navigate
    Get.back();
  }

  void onNavTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.MAIN);
        break;
      case 1:
        break; // Bookings - current screen
      case 2:
        Get.offAllNamed(Routes.HOST_CALENDAR);
        break;
      case 3:
        Get.offAllNamed(Routes.SETTINGS);
        break; // Profile placeholder
    }
  }

  @override
  void onClose() {
    guestNameController.dispose();
    notesController.dispose();
    numberOfGuestsController.dispose();
    super.onClose();
  }
}
