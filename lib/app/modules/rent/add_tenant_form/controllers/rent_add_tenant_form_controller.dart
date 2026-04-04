import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';

class RentAddTenantFormController extends BaseController {
  final propertyContextLabel = 'Evergreen Estate Unit 4B'.obs;

  final tenantNameController = TextEditingController();
  final rentAmountController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final gender = 'Female'.obs;
  final rentFrequency = 'Per Month'.obs;
  final isWhatsapp = false.obs;

  final leaseStart = Rx<DateTime?>(null);
  final leaseEnd = Rx<DateTime?>(null);

  static const genderOptions = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const rentFrequencyOptions = ['Per Day', 'Per Week', 'Per Month', 'Per Year'];

  @override
  void onInit() {
    super.onInit();
    final fromRoute = Get.parameters['property']?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) {
      propertyContextLabel.value = fromRoute;
    }
  }

  void setGender(String? value) {
    if (value != null && value.isNotEmpty) {
      gender.value = value;
    }
  }

  void setRentFrequency(String? value) {
    if (value != null && value.isNotEmpty) {
      rentFrequency.value = value;
    }
  }

  void setWhatsapp(bool? value) {
    if (value != null) {
      isWhatsapp.value = value;
    }
  }

  void setLeaseDateRange(DateTimeRange range) {
    leaseStart.value = DateTime(range.start.year, range.start.month, range.start.day);
    leaseEnd.value = DateTime(range.end.year, range.end.month, range.end.day);
  }

  void saveTenant() {
    Get.snackbar('Tenant', 'Saved locally (wire API when ready)');
    Get.back();
  }

  @override
  void onClose() {
    tenantNameController.dispose();
    rentAmountController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
