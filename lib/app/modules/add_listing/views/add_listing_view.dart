import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/utils/property_name_rules.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/property_unit_floor.dart';
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
    return Obx(() {
      if (controller.loadingListing.value && controller.isEditMode.value) {
        return const DefaultScreenSkeleton();
      }
      final step = controller.currentStep.value <= 1 ? 1 : 2;
      return PopScope(
        canPop: step == 1,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.goBack();
        },
        child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: step == 1
                  ? _buildPropertyStep(context)
                  : _buildUnitStep(context),
            ),
          ),
          _buildBottomBar(context, step),
        ],
        ),
      );
    });
  }

  Widget _buildPropertyStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    const SizedBox(height: 14),
                    Text(
                      _t(context, en: 'Step 1 of 2', sw: 'Hatua 1 kati ya 2'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.secondary,
                      ),
                    ),
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
                      validator: (v) => controller.validateRequired(
                        v,
                        _t(context, en: 'Location', sw: 'Mahali'),
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
                      maxLength: PropertyNameRules.maxLength,
                      decoration: _inputDecoration(
                        context,
                        hint: _t(
                          context,
                          en: 'e.g., AB Apartment',
                          sw: 'mf., AB Apartment',
                        ),
                      ).copyWith(counterText: ''),
                      validator: controller.validatePropertyName,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        icon: Icon(Icons.keyboard_arrow_down_outlined, color: c.hint),
                        items: controller.propertyTypeOptions
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
                        icon: Icon(Icons.keyboard_arrow_down_outlined, color: c.hint),
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
        ],
      ),
    );
  }

  Widget _buildUnitStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          _t(context, en: 'Step 2 of 2', sw: 'Hatua 2 kati ya 2'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.secondary,
          ),
        ),
        const SizedBox(height: 14),
        _buildLabel(context, _t(context, en: 'UNIT NAME', sw: 'JINA LA CHUMBA')),
        const SizedBox(height: 8),
        TextField(
          controller: controller.draftUnitNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _inputDecoration(
            context,
            hint: _t(context, en: 'e.g. 4B or Unit 1', sw: 'mf. 4B au Unit 1'),
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel(context, _t(context, en: 'UNIT MODE', sw: 'AINA YA CHUMBA')),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.draftUnitMode.value,
            isExpanded: true,
            decoration: _inputDecoration(
              context,
              hint: _t(context, en: 'Select unit mode', sw: 'Chagua aina ya chumba'),
            ),
            icon: Icon(Icons.keyboard_arrow_down_outlined, color: c.hint),
            items: ['bnb', 'rent']
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(
                      mode == 'rent'
                          ? _t(context, en: 'Rent', sw: 'Kodi')
                          : 'BnB',
                    ),
                  ),
                )
                .toList(),
            onChanged: controller.updateDraftUnitMode,
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel(context, l10n.unitFloorLabel.toUpperCase()),
        const SizedBox(height: 8),
        Obx(
          () {
            final floor = PropertyUnitFloor.indices.contains(
                  controller.draftUnitFloor.value,
                )
                ? controller.draftUnitFloor.value
                : PropertyUnitFloor.defaultIndex;
            return DropdownButtonFormField<int>(
              initialValue: floor,
              isExpanded: true,
              decoration: _inputDecoration(
                context,
                hint: l10n.unitFloorLabel,
              ),
              icon: Icon(Icons.keyboard_arrow_down_outlined, color: c.hint),
              items: PropertyUnitFloor.indices
                  .map(
                    (f) => DropdownMenuItem<int>(
                      value: f,
                      child: Text(PropertyUnitFloor.label(l10n, f)),
                    ),
                  )
                  .toList(),
              onChanged: controller.updateDraftUnitFloor,
            );
          },
        ),
        const SizedBox(height: 20),
        _buildLabel(context, _t(context, en: 'UNIT RENT', sw: 'KODI YA CHUMBA')),
        const SizedBox(height: 8),
        Obx(
          () => TextField(
            controller: controller.draftUnitRentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            style: TextStyle(fontSize: 16, color: c.headline),
            decoration: _inputDecoration(
              context,
              hint: '0.00',
            ).copyWith(
              prefix: Text(
                '${controller.selectedCurrency.value} ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.secondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel(context, _t(context, en: 'CURRENCY', sw: 'SARAFU')),
        const SizedBox(height: 8),
        CurrencyDropdownField(
          selectedCurrency: controller.selectedCurrency,
          label: _t(context, en: 'Currency', sw: 'Sarafu'),
        ),
        const SizedBox(height: 20),
        _buildLabel(
          context,
          _t(context, en: 'DESCRIPTION', sw: 'MAELEZO'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.draftUnitDescriptionController,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(fontSize: 16, color: c.headline),
          decoration: _inputDecoration(
            context,
            hint: _t(
              context,
              en: 'Short note for this unit',
              sw: 'Maelezo mafupi ya hiki chumba',
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
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
              icon: Icon(Icons.remove_outlined, color: c.headline),
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
              icon: Icon(Icons.add_outlined, color: c.headline),
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
        borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int step) {
    final onUnitStep = step == 2;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppValues.largePadding),
      child: Obx(() {
        // Read before the step test. Inlining this as `onUnitStep && isBusy`
        // short-circuits on step 1, leaving the Obx with no observable to
        // depend on, which GetX treats as a misuse and throws on.
        final busy = controller.isBusy.value;
        return LoadingButton(
          label: onUnitStep
              ? _t(context, en: 'Save Property', sw: 'Hifadhi Mali')
              : _t(context, en: 'Continue', sw: 'Endelea'),
          onPressed: onUnitStep
              ? controller.saveFromUnitStep
              : controller.continueToUnitDetails,
          isLoading: onUnitStep && busy,
        );
      }),
    );
  }

}
