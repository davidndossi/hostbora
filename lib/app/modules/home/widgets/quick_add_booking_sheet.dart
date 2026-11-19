import 'package:get/get.dart';

import '../../add_new_booking/controllers/add_new_booking_controller.dart';
import '../../add_new_booking/views/add_new_booking_view.dart';
import 'quick_wizard_shell.dart';

/// Same bottom sheet used when Add Booking is chosen from the home quick actions.
Future<bool?> showQuickAddBookingSheet() async {
  if (Get.isRegistered<AddNewBookingController>()) {
    await Get.delete<AddNewBookingController>(force: true);
  }
  Get.put(AddNewBookingController());
  try {
    return await showQuickWizardSheet<bool>(
      title: 'Add Booking',
      builder: (_) => AddNewBookingView(),
    );
  } finally {
    if (Get.isRegistered<AddNewBookingController>()) {
      await Get.delete<AddNewBookingController>(force: true);
    }
  }
}
