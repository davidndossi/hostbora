import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../core/values/app_values.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../controllers/add_listing_controller.dart';

class AddListingView extends BaseView<AddListingController> {
  AddListingView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return _buildStepAppBar(context);
  }

  PreferredSizeWidget _buildStepAppBar(BuildContext context) {
    final c = FormSurfaceColors.of(context);
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
          color: c.headline,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      if (controller.loadingListing.value && controller.isEditMode.value) {
        return const DefaultScreenSkeleton();
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
                    _buildLabel(
                      context,
                      _t(
                        context,
                        en: 'PROPERTY LOCATION',
                        sw: 'MAHALI ILIPO JENGO',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.propertyLocationController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(fontSize: 16, color: c.headline),
                      decoration: _inputDecoration(
                        context,
                        hint: _t(
                          context,
                          en: 'Enter street address or area',
                          sw: 'Weka anwani kamili ya mtaa au eneo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(
                      context,
                      _t(context, en: 'PROPERTY NAME', sw: 'JINA LA MALI'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.propertyNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        context,
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
                    _buildLabel(
                      context,
                      _t(context, en: 'PROPERTY TYPE', sw: 'AINA YA MALI'),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.selectedPropertyType.value,
                        decoration: _inputDecoration(
                          context,
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
                          style: TextStyle(color: c.hint, fontSize: 16),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down, color: c.hint),
                        items: controller.propertyTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
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
                    _buildLabel(
                      context,
                      _t(context, en: 'LISTING MODE', sw: 'MATUMIZI YA MALI'),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.listingMode.value,
                        decoration: _inputDecoration(
                          context,
                          hint: _t(
                            context,
                            en: 'Select listing mode',
                            sw: 'Chagua matumizi ya mali',
                          ),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down, color: c.hint),
                        items: controller.listingModeOptions
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(switch (mode) {
                                  'bnb' => _t(
                                    context,
                                    en: 'BnB / short stays',
                                    sw: 'BnB / ukaaji mfupi',
                                  ),
                                  'rent' => _t(
                                    context,
                                    en: 'Rent / long-term',
                                    sw: 'Kodi / muda mrefu',
                                  ),
                                  _ => _t(
                                    context,
                                    en: 'Both BnB and Rent',
                                    sw: 'Zote BnB na Kodi',
                                  ),
                                }),
                              ),
                            )
                            .toList(),
                        onChanged: controller.updateListingMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel(
                      context,
                      AppLocalizations.of(context)!.propertyFloorCount,
                    ),
                    const SizedBox(height: 8),
                    _floorCountStepper(context),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (!controller.isApartmentProperty) {
                        return const SizedBox.shrink();
                      }
                      return _addUnitsSection(context);
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
                          _buildLabel(context, 'RENT AMOUNT'),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: controller.rentAmountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: controller.validateRentAmount,
                                  inputFormatters: [
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: c.headline,
                                  ),
                                  decoration: InputDecoration(
                                    prefix: Text(
                                      '${controller.selectedCurrency.value} ',
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
                                    contentPadding: const EdgeInsets.only(
                                      left: 12,
                                      right: 8,
                                      top: 4,
                                      bottom: 4,
                                    ),
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
                    _buildLabel(context, 'MINIMUM RENTAL DURATION'),
                    const SizedBox(height: 8),
                    Obx(
                      () => _dropdownInput(
                        context: context,
                        value: controller.minRentalDuration.value,
                        options: controller.minRentalDurationOptions,
                        onChanged: controller.updateMinRentalDuration,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _t(
                        context,
                        en: 'By clicking "Publish Listing", you agree to our Hosting Terms and Cancellation Policies.',
                        sw: 'Kwa kubofya "Chapisha Tangazo", unakubali Masharti ya Ukaribishaji na Sera za Kughairi.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: c.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      );
    });
  }

  Widget _buildLabel(BuildContext context, String text) {
    final c = FormSurfaceColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: c.headline,
      ),
    );
  }

  Widget _floorCountStepper(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(
      () => Container(
        height: 48,
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.inputBorder),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: controller.decrementFloorCount,
              icon: Icon(Icons.remove_rounded, color: c.headline),
            ),
            Expanded(
              child: Text(
                '${controller.floorCount.value}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.headline,
                ),
              ),
            ),
            IconButton(
              onPressed: controller.incrementFloorCount,
              icon: Icon(Icons.add_rounded, color: c.headline),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    Widget? prefixIcon,
  }) {
    final c = FormSurfaceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: c.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(color: c.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(color: c.inputBorder),
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
        () => LoadingButton(
          label: controller.isEditing.value
              ? (_t(context, en: 'Save changes', sw: 'Hifadhi mabadiliko'))
              : (_t(context, en: 'Save Property', sw: 'Hifadhi Mali')),
          onPressed: controller.saveProperty,
          isLoading: controller.isBusy.value,
        ),
      ),
    );
  }

  Widget _addedUnitTile(BuildContext context, int index) {
    final u = controller.apartmentUnits[index];
    final l10n = AppLocalizations.of(context)!;
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.divider),
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
                    color: c.headline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${PropertyUnitFloor.label(l10n, u.unitFloor)} · ${controller.selectedCurrency.value} ${u.unitRent} · ${u.unitRentFrequency}${controller.listingMode.value == 'both' ? ' · ${_unitModeLabel(context, u.operationMode)}' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.secondary,
                  ),
                ),
                if (u.unitDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    u.unitDescription,
                    style: TextStyle(fontSize: 13, height: 1.35, color: c.hint),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.removeApartmentUnit(index),
            icon: Icon(Icons.close_rounded, color: c.hint),
            tooltip: _t(context, en: 'Remove unit', sw: 'Ondoa chumba'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _addUnitsSection(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'ADD UNIT'),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            children: List.generate(
              controller.apartmentUnits.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _addedUnitTile(context, i),
              ),
            ),
          ),
        ),
        _formCard(
          context: context,
          children: [
            Text(
              'UNIT NAME',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: c.hint,
              ),
            ),
            const SizedBox(height: 8),
            _plainInput(
              context: context,
              fieldController: controller.draftUnitNameController,
              hint: _t(
                context,
                en: 'e.g. 4B or Unit 1',
                sw: 'mf. 4B au Unit 1',
              ),
            ),
            Obx(() {
              if (controller.listingMode.value != 'both') {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'UNIT MODE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: c.hint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: controller.draftUnitMode.value,
                    isExpanded: true,
                    icon: Icon(Icons.expand_more, color: c.secondary),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.headline,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.fill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: c.dropdownBg,
                    items: ['bnb', 'rent']
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(_unitModeLabel(context, mode)),
                          ),
                        )
                        .toList(),
                    onChanged: controller.updateDraftUnitMode,
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Text(
              l10n.unitFloorLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: c.hint,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => _unitFloorDropdown(
                context: context,
                l10n: l10n,
                value: controller.draftUnitFloor.value,
                onChanged: controller.updateDraftUnitFloor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'UNIT RENT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: c.hint,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: controller.draftUnitRentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: controller.validateDraftUnitRent,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: TextStyle(fontSize: 16, color: c.headline),
                    decoration: InputDecoration(
                      prefix: Text(
                        '${controller.selectedCurrency.value} ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.secondary,
                        ),
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(fontSize: 16, color: c.hint),
                      isDense: false,
                      contentPadding: const EdgeInsets.only(
                        left: 12,
                        right: 8,
                        top: 4,
                        bottom: 4,
                      ),
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
                SizedBox(
                  width: 110,
                  child: CurrencyDropdownField(
                    selectedCurrency: controller.selectedCurrency,
                    label: 'Currency',
                  ),
                ),
              ],
            )),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: c.hint,
                  ),
                  children: [
                    const TextSpan(text: 'UNIT DESCRIPTION'),
                    TextSpan(
                      text: _t(context, en: ' (optional)', sw: ' (hiari)'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.hint,
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
              style: TextStyle(fontSize: 16, color: c.headline),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.fill,
                hintText: _t(
                  context,
                  en: 'Short note for this unit',
                  sw: 'Maelezo mafupi ya hiki chumba',
                ),
                hintStyle: TextStyle(fontSize: 16, color: c.hint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.only(
                  left: 12,
                  right: 8,
                  top: 12,
                  bottom: 12,
                ),
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
                  color: c.isDark ? c.tokens.accent : null,
                ),
                label: Text(
                  _t(context, en: 'Add Unit', sw: 'Ongeza Chumba'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.isDark ? c.tokens.accent : c.headline,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _unitModeLabel(BuildContext context, String mode) {
    return mode.trim().toLowerCase() == 'rent'
        ? _t(context, en: 'Rent', sw: 'Kodi')
        : _t(context, en: 'BnB', sw: 'BnB');
  }

  Widget _plainInput({
    required BuildContext context,
    required TextEditingController fieldController,
    required String hint,
  }) {
    final c = FormSurfaceColors.of(context);
    return TextField(
      controller: fieldController,
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: 14, color: c.headline),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        isDense: false,
        filled: true,
        fillColor: c.fill,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: c.hint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.only(
          left: 12,
          right: 4,
          top: 4,
          bottom: 4,
        ),
      ),
    );
  }

  Widget _unitFloorDropdown({
    required BuildContext context,
    required AppLocalizations l10n,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    final c = FormSurfaceColors.of(context);
    final floor = PropertyUnitFloor.indices.contains(value)
        ? value
        : PropertyUnitFloor.defaultIndex;
    return DropdownButtonFormField<int>(
      initialValue: floor,
      isExpanded: true,
      icon: Icon(Icons.expand_more, color: c.secondary),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.headline,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: c.fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: c.dropdownBg,
      items: PropertyUnitFloor.indices
          .map(
            (f) => DropdownMenuItem<int>(
              value: f,
              child: Text(
                PropertyUnitFloor.label(l10n, f),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.headline,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dropdownInput({
    required BuildContext context,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool compact = false,
  }) {
    final c = FormSurfaceColors.of(context);
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      isExpanded: true,
      icon: Icon(Icons.expand_more, color: c.secondary),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: c.headline,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: c.fill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 12 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: c.dropdownBg,
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.headline,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _formCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final c = FormSurfaceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
