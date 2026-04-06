import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/values/app_colors.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_add_new_listing_controller.dart';

/// Concierge “Add New Listing” — cream background, teal primary (#005D5D).
// abstract class _AddListingTheme {
//   static const Color teal = Color(0xFF005D5D);
//   static const Color card = Colors.white;
//   static const Color inputBg = Color(0xFFF1F1F1);
//   static const Color label = Color(0xFF3D3D3D);
//   static const Color charcoal = Color(0xFF1A1A1A);
//   static const String serif = 'Georgia';
// }

class RentAddNewListingView extends BaseView<RentAddNewListingController> {
  RentAddNewListingView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: 'Add Property'
  );

  @override
  Widget body(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _whiteCard(
                  children: [
                    const SizedBox(height: 14),
                    _fieldLabel('PROPERTY LOCATION'),
                    _inputRow(
                      icon: Icons.location_on_outlined,
                      fieldController: controller.propertyLocationController,
                      hint: 'Enter full street address or district',
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('PROPERTY TYPE'),
                    Obx(() => _dropdownInput(
                      value: controller.propertyType.value,
                      options: controller.propertyTypeOptions,
                      onChanged: controller.updatePropertyType,
                    )),
                    Obx(() {
                      if (!controller.isApartmentProperty) {
                        return const SizedBox.shrink();
                      }
                      return _addUnitsSection();
                    }),
                    const SizedBox(height: 16),
                    _fieldLabel('PROPERTY NAME/NUMBER'),
                    _plainInput(
                      fieldController: controller.apartmentSuiteController,
                      hint: 'e.g. 4B or Penthouse 1',
                    ),
                    Obx(() {
                      if (controller.hideListingRentAmount) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Divider(height: 1, color: Color(0xFFEDEDED)),
                            SizedBox(height: 18),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFEDEDED)),
                          const SizedBox(height: 18),
                          _fieldLabel('RENT AMOUNT'),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: controller.rentAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: controller.validateRentAmount,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF2E2E2E)),
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      'Tshs ',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(fontSize: 16, color: Color(0xFF7A7A7A)),
                                    isDense: false,
                                    contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F1F1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Obx(() => _dropdownInput(
                                  value: controller.rentFrequency.value,
                                  options: controller.rentFrequencyOptions,
                                  onChanged: controller.updateRentFrequency,
                                  compact: true,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                    _fieldLabel('MINIMUM RENTAL DURATION'),
                    Obx(() => _dropdownInput(
                      value: controller.minRentalDuration.value,
                      options: controller.minRentalDurationOptions,
                      onChanged: controller.updateMinRentalDuration,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.designAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MARKET INSIGHTS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Long-term contracts in this district rent for 12% higher on average. Consider highlighting lease flexibility in your description.',
                              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3A3A3A),
                          backgroundColor: const Color(0xFFECEBE8),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.saveProperty,
                        style: FilledButton.styleFrom(
                          // backgroundColor: _AddListingTheme.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Property', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addUnitsSection() {
    const fill = Color(0xFFF1F1F1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _fieldLabel('ADD UNIT'),
        Obx(
          () => Column(
            children: List.generate(
              controller.apartmentUnits.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _addedUnitTile(i),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _fieldLabel('UNIT NAME'),
        _plainInput(
          fieldController: controller.draftUnitNameController,
          hint: 'e.g. 4B or Penthouse 1',
        ),
        const SizedBox(height: 12),
        _fieldLabel('UNIT RENT'),
        TextField(
          controller: controller.draftUnitRentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16, color: Color(0xFF2E2E2E)),
          decoration: InputDecoration(
            prefix: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text(
                'Tshs ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
              ),
            ),
            hintText: '0.00',
            hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF7A7A7A)),
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 14, bottom: 14),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: 'UNIT DESCRIPTION'),
                TextSpan(
                  text: ' (optional)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextField(
          controller: controller.draftUnitDescriptionController,
          textInputAction: TextInputAction.done,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, color: Color(0xFF2E2E2E)),
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            hintText: 'Short note for this unit',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.addApartmentUnit,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add unit', style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E2E2E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addedUnitTile(int index) {
    final u = controller.apartmentUnits[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.unitName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tshs ${u.unitRent}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                ),
                if (u.unitDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    u.unitDescription,
                    style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF4B5563)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.removeApartmentUnit(index),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
            tooltip: 'Remove unit',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          // color: _AddListingTheme.label,
        ),
      ),
    );
  }

  Widget _inputRow({
    required IconData icon,
    required TextEditingController fieldController,
    required String hint,
  }) {
    const fill = Color(0xFFF1F1F1);
    return TextFormField(
      controller: fieldController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.streetAddress,
      minLines: 1,
      maxLines: 3,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: controller.validateLocation,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2E2E2E)),
      decoration: InputDecoration(
        // prefix: Icon(icon, size: 14, color: const Color(0xFF6B6B6B)),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: false,
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        fillColor: fill
      ),
    );
  }

  Widget _plainInput({
    required TextEditingController fieldController,
    required String hint,
  }) {
    const fill = Color(0xFFF1F1F1);
    return TextField(
      controller: fieldController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2E2E2E)),
      decoration: InputDecoration(
        isDense: false,
        filled: true,
        fillColor: fill,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      ),
    );
  }

  Widget _dropdownInput({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool compact = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      isExpanded: true,
      icon: const Icon(Icons.expand_more, color: Color(0xFF3D3D3D)),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E2E2E)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.white,
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
