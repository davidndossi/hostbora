import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_tenant_local_data_source.dart';

class RentAddTenantFormController extends BaseController {
  RentAddTenantFormController()
      : _tenantLocal = Get.find<RentTenantLocalDataSource>();

  final RentTenantLocalDataSource _tenantLocal;

  final propertyContextLabel = 'Evergreen Estate Unit 4B'.obs;
  final formKey = GlobalKey<FormState>();

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

  Future<void> saveTenant() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (leaseStart.value == null || leaseEnd.value == null) {
      showErrorMessage('Lease period is required');
      return;
    }

    final amountRaw = rentAmountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountRaw);
    if (amount == null || amount <= 0) {
      showErrorMessage('Enter a valid rent amount');
      return;
    }

    await _tenantLocal.insert(
      propertyLabel: propertyContextLabel.value.trim(),
      tenantName: tenantNameController.text.trim(),
      gender: gender.value,
      rentAmountValue: amount,
      rentFrequency: rentFrequency.value,
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      isWhatsapp: isWhatsapp.value,
      leaseStartIso: DateFormat('yyyy-MM-dd').format(leaseStart.value!),
      leaseEndIso: DateFormat('yyyy-MM-dd').format(leaseEnd.value!),
      contractFilePath: '',
      contractFileName: '',
    );

    showSuccessMessage('Tenant saved offline');
    Get.back(result: true);
  }

  String? validateTenantName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Tenant name is required';
    if (v.length < 2) return 'Enter a valid name';
    return null;
  }

  String? validateRentAmount(String? value) {
    final raw = (value ?? '').trim().replaceAll(',', '');
    if (raw.isEmpty) return 'Rent amount is required';
    final n = double.tryParse(raw);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    if (v.length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? validateEmailOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final ok = GetUtils.isEmail(v);
    return ok ? null : 'Enter a valid email';
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
