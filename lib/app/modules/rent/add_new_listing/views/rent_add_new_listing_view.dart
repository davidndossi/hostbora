import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/form_surface_colors.dart';
import '../../../../core/utils/thousand_separator.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/property_unit_floor.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../controllers/rent_add_new_listing_controller.dart';

class RentAddNewListingView extends RentBaseView<RentAddNewListingController> {
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
      final c = FormSurfaceColors.of(context);
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
                  colors: c,
                  children: [
                    const SizedBox(height: 14),
                    _fieldLabel('PROPERTY LOCATION', colors: c),
                    _inputRow(
                      colors: c,
                      fieldController: controller.propertyLocationController,
                      hint: _isSw ? 'Weka anwani kamili ya mtaa au wilaya' : 'Enter full street address or district',
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('PROPERTY TYPE', colors: c),
                    Obx(() => _dropdownInput(
                      colors: c,
                      value: controller.propertyType.value,
                      options: controller.propertyTypeOptions,
                      onChanged: controller.updatePropertyType,
                    )),
                    const SizedBox(height: 16),
                    _fieldLabel(_isSw ? 'IDADI YA GHOROFA' : 'NUMBER OF FLOORS', colors: c),
                    _floorCountStepper(colors: c),
                    const SizedBox(height: 16),
                    _fieldLabel(_isSw ? 'JINA/NAMBA YA MALI' : 'PROPERTY NAME/NUMBER', colors: c),
                    _plainInput(
                      colors: c,
                      fieldController: controller.apartmentSuiteController,
                      hint: _isSw ? 'mf. Uzuri House' : 'e.g. Uzuri House',
                    ),
                    Obx(() {
                      if (!controller.isApartmentProperty) {
                        return const SizedBox.shrink();
                      }
                      return _addUnitsSection(context, colors: c);
                    }),
                    Obx(() {
                      if (controller.hideListingRentAmount) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Divider(height: 1, color: c.divider),
                            const SizedBox(height: 18),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Divider(height: 1, color: c.divider),
                          const SizedBox(height: 18),
                          _fieldLabel('RENT AMOUNT', colors: c),
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
                                    color: c.headline,
                                  ),
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      'Tshs ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: c.secondary,
                                      ),
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      color: c.hint,
                                    ),
                                    isDense: false,
                                    contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                                    filled: true,
                                    fillColor: c.fill,
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
                                  colors: c,
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
                    _fieldLabel('MINIMUM RENTAL DURATION', colors: c),
                    Obx(() => _dropdownInput(
                      colors: c,
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
                          foregroundColor: c.secondary,
                          backgroundColor: c.isDark ? c.fill : c.chipUnselectedBg,
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

  Widget _addUnitsSection(BuildContext context, {required FormSurfaceColors colors}) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _fieldLabel('ADD UNIT', colors: colors),
        Obx(
          () => Column(
            children: List.generate(
              controller.apartmentUnits.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _addedUnitTile(i, colors: colors, context: context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _fieldLabel('UNIT NAME', colors: colors),
        _plainInput(
          colors: colors,
          fieldController: controller.draftUnitNameController,
          hint: _isSw ? 'mf. 4B au Unit 1' : 'e.g. 4B or Unit 1',
        ),
        const SizedBox(height: 12),
        _fieldLabel(l10n.unitFloorLabel.toUpperCase(), colors: colors),
        const SizedBox(height: 8),
        Obx(
          () => _unitFloorDropdown(
            colors: colors,
            l10n: l10n,
            value: controller.draftUnitFloor.value,
            onChanged: controller.updateDraftUnitFloor,
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('UNIT RENT', colors: colors),
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
                  color: colors.headline,
                ),
                decoration: InputDecoration(
                  prefix: Text(
                    'Tshs ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.secondary,
                    ),
                  ),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: colors.hint,
                  ),
                  isDense: false,
                  contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                  filled: true,
                  fillColor: colors.fill,
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
                colors: colors,
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
                color: colors.sectionLabel,
              ),
              children: [
                const TextSpan(text: 'UNIT DESCRIPTION'),
                TextSpan(
                  text: _isSw ? ' (hiari)' : ' (optional)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: colors.hint,
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
            color: colors.headline,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.fill,
            hintText: _isSw ? 'Maelezo mafupi ya hiki chumba' : 'Short note for this unit',
            hintStyle: TextStyle(
              fontSize: 14,
              color: colors.hint,
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
            icon: Icon(
              Icons.add_circle_outline,
              size: 20,
              color: colors.isDark ? colors.tokens.accent : null,
            ),
            label: Text(_isSw ? 'Ongeza chumba' : 'Add unit', style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.isDark ? colors.tokens.accent : colors.headline,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addedUnitTile(int index, {required FormSurfaceColors colors, required BuildContext context}) {
    final u = controller.apartmentUnits[index];
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
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
                    color: colors.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${PropertyUnitFloor.label(l10n, u.unitFloor)} · Tshs ${u.unitRent} · ${u.unitRentFrequency}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.secondary,
                  ),
                ),
                if (u.unitDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    u.unitDescription,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: colors.hint,
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
              color: colors.hint,
            ),
            tooltip: _isSw ? 'Ondoa chumba' : 'Remove unit',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _formCard({required FormSurfaceColors colors, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: colors.isDark ? Border.all(color: colors.border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _fieldLabel(String text, {required FormSurfaceColors colors}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: colors.sectionLabel,
        ),
      ),
    );
  }

  Widget _floorCountStepper({required FormSurfaceColors colors}) {
    return Obx(
      () => Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: controller.decrementFloorCount,
              icon: Icon(Icons.remove_rounded, color: colors.headline),
              tooltip: _isSw ? 'Punguza' : 'Decrease',
            ),
            Expanded(
              child: Text(
                '${controller.floorCount.value}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.headline,
                ),
              ),
            ),
            IconButton(
              onPressed: controller.incrementFloorCount,
              icon: Icon(Icons.add_rounded, color: colors.headline),
              tooltip: _isSw ? 'Ongeza' : 'Increase',
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputRow({
    required FormSurfaceColors colors,
    required TextEditingController fieldController,
    required String hint,
  }) {
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
        color: colors.headline,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: colors.hint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: false,
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        filled: true,
        fillColor: colors.fill,
      ),
    );
  }

  Widget _plainInput({
    required FormSurfaceColors colors,
    required TextEditingController fieldController,
    required String hint,
  }) {
    return TextField(
      controller: fieldController,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 14,
        color: colors.headline,
      ),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        isDense: false,
        filled: true,
        fillColor: colors.fill,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: colors.hint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      ),
    );
  }

  Widget _unitFloorDropdown({
    required FormSurfaceColors colors,
    required AppLocalizations l10n,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    final floor = PropertyUnitFloor.indices.contains(value)
        ? value
        : PropertyUnitFloor.defaultIndex;
    return DropdownButtonFormField<int>(
      initialValue: floor,
      isExpanded: true,
      icon: Icon(Icons.expand_more, color: colors.secondary),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.headline),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: colors.dropdownBg,
      items: PropertyUnitFloor.indices
          .map(
            (f) => DropdownMenuItem<int>(
              value: f,
              child: Text(
                PropertyUnitFloor.label(l10n, f),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.headline,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dropdownInput({
    required FormSurfaceColors colors,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool compact = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      isExpanded: true,
      icon: Icon(Icons.expand_more, color: colors.secondary),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.headline),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.fill,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 12 : 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: colors.dropdownBg,
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.headline,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
