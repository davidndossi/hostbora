import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentLeaseRenewalFormController extends BaseController
    with RentRealDataControllerMixin {
  final formKey = GlobalKey<FormState>();

  final tenantNameController = TextEditingController();
  final propertyLineController = TextEditingController();
  final rentAmountController = TextEditingController();
  final notesController = TextEditingController();

  final newLeaseStart = Rxn<DateTime>();
  final newLeaseEnd = Rxn<DateTime>();

  final rentFrequency = 'Monthly'.obs;

  static const frequencyOptions = ['Monthly', 'Quarterly', 'Annually'];

  @override
  void onInit() {
    super.onInit();
    final name = Get.parameters['tenantName']?.trim() ?? '';
    final prop = Get.parameters['property']?.trim() ?? '';
    if (name.isNotEmpty) tenantNameController.text = name;
    if (prop.isNotEmpty) propertyLineController.text = prop;
  }

  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
  }

  void setRentFrequency(String? v) {
    if (v != null && frequencyOptions.contains(v)) {
      rentFrequency.value = v;
    }
  }

  void setNewLeaseRange(DateTimeRange range) {
    newLeaseStart.value = DateTime(range.start.year, range.start.month, range.start.day);
    newLeaseEnd.value = DateTime(range.end.year, range.end.month, range.end.day);
  }

  String? validateTenantName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return Get.locale?.languageCode == 'sw'
          ? 'Jina la mpangaji linahitajika'
          : 'Tenant name is required';
    }
    return null;
  }

  String? validateProperty(String? v) {
    if (v == null || v.trim().isEmpty) {
      return Get.locale?.languageCode == 'sw'
          ? 'Mali au anwani inahitajika'
          : 'Property or address is required';
    }
    return null;
  }

  String? validateRent(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = double.tryParse(t.replaceAll(',', ''));
    if (n == null || n < 0) {
      return Get.locale?.languageCode == 'sw'
          ? 'Kiasi si halali'
          : 'Enter a valid amount';
    }
    return null;
  }

  bool _datesValid() {
    final s = newLeaseStart.value;
    final e = newLeaseEnd.value;
    return s != null && e != null && !e.isBefore(s);
  }

  void submitRenewal() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!_datesValid()) {
      showErrorMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Chagua tarehe za kuanza na kuisha za mkataba mpya.'
            : 'Pick new lease start and end dates.',
      );
      return;
    }
    showSuccessMessage(
      Get.locale?.languageCode == 'sw'
          ? 'Ombi la uhuishaji limewasilishwa (hifadhi ya ndani — hivi karibuni).'
          : 'Renewal request submitted (local save — coming soon).',
    );
  }

  @override
  void onClose() {
    tenantNameController.dispose();
    propertyLineController.dispose();
    rentAmountController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
