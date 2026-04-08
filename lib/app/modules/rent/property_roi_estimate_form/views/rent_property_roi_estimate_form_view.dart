import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/app/core/base/base_view.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_estimate_form_controller.dart';

class RentPropertyRoiEstimateFormView
    extends BaseView<RentPropertyRoiEstimateFormController> {
  RentPropertyRoiEstimateFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Makadirio ya ROI ya Mali' : 'Property ROI estimates');

  @override
  Widget body(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          rentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.propertyLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSw
                      ? 'Ongeza makadirio ya gharama na mapato kufuatilia ROI ya mali hii.'
                      : 'Add cost and income estimates to track ROI for this property.',
                ),
                const SizedBox(height: 16),
                _field(
                  _isSw ? 'Gharama ya ununuzi (TZS)' : 'Purchase cost (TZS)',
                  controller.purchaseCostController,
                  validator: controller.validateRequiredAmount,
                ),
                _field(
                  _isSw ? 'Gharama ya ukarabati (TZS)' : 'Renovation cost (TZS)',
                  controller.renovationCostController,
                  validator: controller.validateRequiredAmount,
                ),
                _field(
                  _isSw ? 'Mapato ya mwezi yanayotarajiwa (TZS)' : 'Expected monthly income (TZS)',
                  controller.expectedMonthlyIncomeController,
                  validator: controller.validateRequiredAmount,
                ),
                _field(
                  _isSw ? 'Gharama za mwezi zinazotarajiwa (TZS)' : 'Expected monthly expense (TZS)',
                  controller.expectedMonthlyExpenseController,
                  validator: controller.validateRequiredAmount,
                ),
                _field(
                  _isSw ? 'Lengo la ujazaji (%)' : 'Target occupancy (%)',
                  controller.targetOccupancyController,
                  validator: controller.validatePercent,
                ),
                const SizedBox(height: 10),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: controller.saving.value ? null : controller.save,
                      child: Text(
                        controller.saving.value
                            ? (_isSw ? 'Inahifadhi...' : 'Saving...')
                            : (_isSw ? 'Hifadhi makadirio' : 'Save estimates'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController textController, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: textController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
        ),
      ),
    );
  }
}
