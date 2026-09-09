import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/property_name_rules.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../data/local/service/currency_service.dart';
import '../controllers/edit_listing_controller.dart';

class EditListingView extends BaseView<EditListingController> {
  EditListingView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  String _formatUnitRent(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', ''));
    if (parsed != null) {
      return Get.find<CurrencyService>().formatBase(parsed.round());
    }
    return raw.trim();
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, sw: 'Hariri Mali', en: 'Edit Property'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.loadError.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              controller.loadError.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: c.secondary,
              ),
            ),
          ),
        );
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
                      _t(context, en: 'PROPERTY LOCATION', sw: 'MAHALI ILIPO JENGO'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.propertyLocationController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 16,
                        color: c.headline,
                      ),
                      decoration: _inputDecoration(
                        context,
                        hint: _t(
                          context,
                          en: 'Enter street address or area',
                          sw: 'Weka anwani kamili ya mtaa au eneo',
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return _t(
                            context,
                            en: 'Location is required',
                            sw: 'Mahali yanahitajika',
                          );
                        }
                        return null;
                      },
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
                    if (controller.showUnitsEditor)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Divider(height: 1, color: c.divider),
                          const SizedBox(height: 18),
                          _buildUnitsSection(context),
                        ],
                      ),
                    const SizedBox(height: 28),
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

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppValues.largePadding),
      child: FilledButton(
        onPressed: controller.save,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _t(context, en: 'Save changes', sw: 'Hifadhi mabadiliko'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildUnitsSection(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, _t(context, en: 'APARTMENT UNITS', sw: 'VYUMBA / UNITI')),
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
        const SizedBox(height: 8),
        Text(
          _t(context, en: 'ADD UNIT', sw: 'ONGEZA UNITI'),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: c.hint,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.tileBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, en: 'UNIT MODE', sw: 'AINA YA UNITI'),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: c.hint,
                ),
              ),
              const SizedBox(height: 8),
              _unitModeToggle(context),
              const SizedBox(height: 12),
              Text(
                _t(context, en: 'UNIT NAME', sw: 'JINA LA UNITI'),
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
                hint: _t(context, en: 'e.g. 4B or Unit 1', sw: 'mf. 4B au Unit 1'),
              ),
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
                _t(context, en: 'UNIT RENT', sw: 'KODI YA UNITI'),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: c.hint,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.draftUnitRentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: controller.validateDraftUnitRent,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: TextStyle(
                  fontSize: 16,
                  color: c.headline,
                ),
                decoration: InputDecoration(
                  prefix: Text(
                    Get.find<CurrencyService>().inputPrefix,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.secondary,
                    ),
                  ),
                  hintText: '0.00',
                  filled: true,
                  fillColor: c.fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.only(left: 12, right: 8, top: 4, bottom: 4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _t(context, en: 'DESCRIPTION (optional)', sw: 'MAELEZO (hiari)'),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: c.hint,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.draftUnitDescriptionController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 16,
                  color: c.headline,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
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
                    _t(context, en: 'Add unit', sw: 'Ongeza uniti'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        c.isDark ? c.tokens.accent : c.headline,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.headline),
      decoration: InputDecoration(
        filled: true,
        fillColor: c.fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              child: Text(PropertyUnitFloor.label(l10n, f)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _addedUnitTile(BuildContext context, int index) {
    final c = FormSurfaceColors.of(context);
    final u = controller.apartmentUnits[index];
    final l10n = AppLocalizations.of(context)!;
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
                  '${PropertyUnitFloor.label(l10n, u.unitFloor)} · ${_formatUnitRent(u.unitRent)} · ${u.unitRentFrequency}',
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
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: c.hint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => controller.removeApartmentUnit(index),
            icon: Icon(Icons.close_rounded, color: c.hint),
            tooltip: _t(context, en: 'Remove unit', sw: 'Ondoa uniti'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _unitModeToggle(BuildContext context) {
    final cs = FormSurfaceColors.of(context);
    const opts = [('bnb', 'BnB'), ('rent', 'Rent')];
    return Obx(() {
      final current = controller.draftUnitMode.value;
      return Row(
        children: opts.map((opt) {
          final selected = current == opt.$1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt.$1 == 'bnb' ? 6 : 0),
              child: GestureDetector(
                onTap: () => controller.updateDraftUnitMode(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : cs.fill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : cs.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : cs.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
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
      style: TextStyle(
        fontSize: 14,
        color: c.headline,
      ),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        filled: true,
        fillColor: c.fill,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: c.hint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      ),
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

  InputDecoration _inputDecoration(BuildContext context, {required String hint}) {
    final c = FormSurfaceColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint),
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
}
