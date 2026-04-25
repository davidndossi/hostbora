import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/add_listing_controller.dart';

class AddListingView extends BaseView<AddListingController> {
  AddListingView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return _buildStepAppBar(context);
  }

  PreferredSizeWidget _buildStepAppBar(BuildContext context) {
    return CustomAppBar(
      // appBarTitleText: appLocalization.listing,
      appBarTitleText: controller.isEditing.value
        ? _t(context, sw: 'Hariri Mali', en: 'Edit Property')
        : _t(context, sw: 'Ongeza Mjengo', en: 'Add Property'),
      isCentered: true,
      actions: [
        IconButton(
          onPressed: controller.openHelp,
          icon: const Icon(Icons.help_outline, size: 24),
          color: _isDark(context) ? Colors.white : AppColors.textColorPrimary,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      final dividerColor = _isDark(context) ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED);
      if (controller.loadingListing.value && controller.isEditMode.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    // Obx(
                    //   () => Text(
                    //     controller.isEditMode.value
                    //         ? _t(context, en: 'Edit Property', sw: 'Hariri Mali')
                    //         : _t(context, en: 'Add New Property', sw: 'Ongeza Mali Mpya'),
                    //     style: TextStyle(
                    //       fontSize: 26,
                    //       fontWeight: FontWeight.w700,
                    //       color: _isDark(context)
                    //           ? Colors.white
                    //           : AppColors.textColorPrimary,
                    //       letterSpacing: -0.5,
                    //     ),
                    //   ),
                    // ),
                    _buildLabel(_t(context, en: 'PROPERTY LOCATION', sw: 'MAHALI ILIPO JENGO')),
                    TextFormField(
                      controller: controller.propertyLocationController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDark(context) ? Colors.white : const Color(0xFF2E2E2E),
                      ),
                      decoration: _inputDecoration(
                        hint: _t(
                          context,
                          en: 'Enter street address or area',
                          sw: 'Weka anwani kamili ya mtaa au eneo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(_t(context, en: 'PROPERTY NAME', sw: 'JINA LA MALI')),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.propertyNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        hint: _t(
                          context,
                          en: 'e.g., AB Apartment',
                          sw: 'mf., AB Apartment',
                        ),
                      ),
                      validator: (v) => controller.validateRequired(
                        v,
                        _t(context, en: 'Property name', sw: 'Jina la mali'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(_t(context, en: 'PROPERTY TYPE', sw: 'AINA YA MALI')),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.selectedPropertyType.value,
                        decoration: _inputDecoration(
                          hint: _t(
                            context,
                            en: 'Select property type',
                            sw: 'Chagua aina ya mali',
                          ),
                        ),
                        hint: Text(
                          _t(
                            context,
                            en: 'Select property type',
                            sw: 'Chagua aina ya mali',
                          ),
                          style: TextStyle(
                            color: _isDark(context)
                                ? Colors.white70
                                : AppColors.designPlaceholder,
                            fontSize: 16,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.designPlaceholder,
                        ),
                        items: controller.propertyTypes
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: controller.selectPropertyType,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return _t(
                              context,
                              en: 'Property type is required',
                              sw: 'Aina ya mali inahitajika',
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (!controller.isApartmentProperty) {
                        return const SizedBox.shrink();
                      }
                      return _addUnitsSection(isDark: _isDark(context));
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
                          _buildLabel('RENT AMOUNT'),
                          const SizedBox(height: 8),
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
                                    color: _isDark(context) ? Colors.white : const Color(0xFF2E2E2E),
                                  ),
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      'Tshs ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _isDark(context) ? const Color(0xFFAEAEB2) : const Color(0xFF4A4A4A),
                                      ),
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      color: _isDark(context) ? const Color(0xFF8E8E93) : const Color(0xFF7A7A7A),
                                    ),
                                    isDense: false,
                                    contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                                    // filled: true,
                                    // fillColor: _isDark(context) ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    _buildLabel('MINIMUM RENTAL DURATION'),
                    const SizedBox(height: 8),
                    Obx(() => _dropdownInput(
                      isDark: _isDark(context),
                      value: controller.minRentalDuration.value,
                      options: controller.minRentalDurationOptions,
                      onChanged: controller.updateMinRentalDuration,
                    )),
                    const SizedBox(height: 20),
                    Text(
                      _t(
                        context,
                        en: 'By clicking "Publish Listing", you agree to our Hosting Terms and Cancellation Policies.',
                        sw: 'Kwa kubofya "Chapisha Tangazo", unakubali Masharti ya Ukaribishaji na Sera za Kughairi.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDark(context)
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                        height: 1.4,
                      ),
                    ),

                  ],
                ),
              )
            ),
          ),
          _buildBottomBar(context),
        ],
      );
    });
  }

  Widget _buildLabel(String text) {
    final context = Get.context!;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: _isDark(context) ? Colors.white : AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
    final context = Get.context!;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _isDark(context) ? Colors.white70 : AppColors.designPlaceholder,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _isDark(context)
          ? const Color(0xFF1F1F1F)
          : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: _isDark(context)
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: _isDark(context)
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.designInputBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppValues.largePadding),
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
                ? (_t(context, en: 'Save changes', sw: 'Hifadhi mabadiliko'))
                : (_t(context, en: 'Save Property', sw: 'Hifadhi Mali')),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
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
            tooltip: _t(Get.context!, en: 'Remove unit', sw: 'Ondoa chumba'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _addUnitsSection({required bool isDark}) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    final labelColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLabel('ADD UNIT'),
        const SizedBox(height: 8),
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
        _formCard(
          isDark: isDark,
          children: [
            const SizedBox(height: 8),
            Text(
              'UNIT NAME',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            _plainInput(
              isDark: isDark,
              fieldController: controller.draftUnitNameController,
              hint: _t(Get.context!, en: 'e.g. 4B or Unit 1', sw: 'mf. 4B au Unit 1'),
            ),
            const SizedBox(height: 12),
            Text(
              'UNIT RENT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
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
                      text: _t(Get.context!, en: ' (optional)', sw: ' (hiari)'),
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
                hintText: _t(Get.context!, en: 'Short note for this unit', sw: 'Maelezo mafupi ya hiki chumba'),
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
                label: Text(_t(Get.context!, en: 'Add unit', sw: 'Ongeza chumba'), style: const TextStyle(fontWeight: FontWeight.w700)),
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
          ]
        )
      ],
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
      ).toList(),
      onChanged: onChanged,
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
}
