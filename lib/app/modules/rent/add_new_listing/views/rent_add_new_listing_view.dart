import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/utils/thousand_separator.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_add_new_listing_controller.dart';

class RentAddNewListingView extends BaseView<RentAddNewListingController> {
  RentAddNewListingView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(
        () => CustomAppBar(
          appBarTitleText: controller.isEditing.value
              ? (_isSw ? 'Hariri Mali' : 'Edit Property')
              : (_isSw ? 'Ongeza Mjengo' : 'Add Property'),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      if (controller.awaitingEditLoad.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dividerColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED);
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
                _formCard(
                  isDark: isDark,
                  children: [
                    const SizedBox(height: 14),
                    _fieldLabel('PROPERTY LOCATION', isDark: isDark),
                    _inputRow(
                      isDark: isDark,
                      fieldController: controller.propertyLocationController,
                      hint: _isSw ? 'Weka anwani kamili ya mtaa au wilaya' : 'Enter full street address or district',
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('PROPERTY TYPE', isDark: isDark),
                    Obx(() => _dropdownInput(
                      isDark: isDark,
                      value: controller.propertyType.value,
                      options: controller.propertyTypeOptions,
                      onChanged: controller.updatePropertyType,
                    )),
                    const SizedBox(height: 16),
                    _fieldLabel(_isSw ? 'JINA/NAMBA YA MALI' : 'PROPERTY NAME/NUMBER', isDark: isDark),
                    _plainInput(
                      isDark: isDark,
                      fieldController: controller.apartmentSuiteController,
                      hint: _isSw ? 'mf. Uzuri House' : 'e.g. Uzuri House',
                    ),
                    Obx(() {
                      if (!controller.isApartmentProperty) {
                        return const SizedBox.shrink();
                      }
                      return _addUnitsSection(isDark: isDark);
                    }),
                    Obx(() {
                      if (controller.hideListingRentAmount) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Divider(height: 1, color: dividerColor),
                            const SizedBox(height: 18),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Divider(height: 1, color: dividerColor),
                          const SizedBox(height: 18),
                          _fieldLabel('RENT AMOUNT', isDark: isDark),
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
                                  inputFormatters: [
                                    ThousandsSeparatorInputFormatter()
                                  ],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF2E2E2E),
                                  ),
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      'Tshs ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF4A4A4A),
                                      ),
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
                                    ),
                                    isDense: false,
                                    contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1),
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
                                  isDark: isDark,
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
                    _fieldLabel('MINIMUM RENTAL DURATION', isDark: isDark),
                    Obx(() => _dropdownInput(
                      isDark: isDark,
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
                          foregroundColor:
                              isDark ? const Color(0xFFE8E8ED) : const Color(0xFF3A3A3A),
                          backgroundColor:
                              isDark ? const Color(0xFF3A3A3C) : const Color(0xFFECEBE8),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isSw ? 'Ghairi' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => FilledButton(
                          onPressed: controller.saveProperty,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            controller.isEditing.value
                                ? (_isSw ? 'Hifadhi mabadiliko' : 'Save changes')
                                : (_isSw ? 'Hifadhi Mali' : 'Save Property'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
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
    });
  }

  Widget _addUnitsSection({required bool isDark}) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    final labelColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _fieldLabel('ADD UNIT', isDark: isDark),
        Obx(
          () => Column(
            children: List.generate(
              controller.apartmentUnits.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _addedUnitTile(i, isDark: isDark),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _fieldLabel('UNIT NAME', isDark: isDark),
        _plainInput(
          isDark: isDark,
          fieldController: controller.draftUnitNameController,
          hint: _isSw ? 'mf. 4B au Unit 1' : 'e.g. 4B or Unit 1',
        ),
        const SizedBox(height: 12),
        _fieldLabel('UNIT RENT', isDark: isDark),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controller.draftUnitRentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: controller.validateDraftUnitRent,
                inputFormatters: [
                  ThousandsSeparatorInputFormatter()
                ],
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF2E2E2E),
                ),
                decoration: InputDecoration(
                  prefix: Text(
                    'Tshs ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF4A4A4A),
                    ),
                  ),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
                  ),
                  isDense: false,
                  contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1),
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
                isDark: isDark,
                value: controller.draftUnitRentFrequency.value,
                options: controller.rentFrequencyOptions,
                onChanged: controller.updateDraftUnitRentFrequency,
                compact: true,
              )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
              children: [
                const TextSpan(text: 'UNIT DESCRIPTION'),
                TextSpan(
                  text: _isSw ? ' (hiari)' : ' (optional)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextField(
          controller: controller.draftUnitDescriptionController,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF2E2E2E),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            hintText: _isSw ? 'Maelezo mafupi ya hiki chumba' : 'Short note for this unit',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
            ),
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
            icon: Icon(Icons.add_circle_outline, size: 20, color: isDark ? const Color(0xFF5EC9C3) : null),
            label: Text(_isSw ? 'Ongeza chumba' : 'Add unit', style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF5EC9C3) : const Color(0xFF2E2E2E),
              side: BorderSide(
                color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5E5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addedUnitTile(int index, {required bool isDark}) {
    final u = controller.apartmentUnits[index];
    final tileBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8);
    final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tshs ${u.unitRent} · ${u.unitRentFrequency}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF374151),
                  ),
                ),
                if (u.unitDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    u.unitDescription,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.removeApartmentUnit(index),
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF),
            ),
            tooltip: _isSw ? 'Ondoa chumba' : 'Remove unit',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _formCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _fieldLabel(String text, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _inputRow({
    required bool isDark,
    required TextEditingController fieldController,
    required String hint,
  }) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    return TextFormField(
      controller: fieldController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.streetAddress,
      textCapitalization: TextCapitalization.words,
      minLines: 1,
      maxLines: 3,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: controller.validateLocation,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF2E2E2E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: false,
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        filled: true,
        fillColor: fill,
      ),
    );
  }

  Widget _plainInput({
    required bool isDark,
    required TextEditingController fieldController,
    required String hint,
  }) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    return TextField(
      controller: fieldController,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF2E2E2E),
      ),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        isDense: false,
        filled: true,
        fillColor: fill,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      ),
    );
  }

  Widget _dropdownInput({
    required bool isDark,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool compact = false,
  }) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    final textColor = isDark ? Colors.white : const Color(0xFF2E2E2E);
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      isExpanded: true,
      icon: Icon(
        Icons.expand_more,
        color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3D3D3D),
      ),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
