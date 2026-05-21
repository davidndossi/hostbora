import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/edit_listing_controller.dart';

class EditListingView extends BaseView<EditListingController> {
  EditListingView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, sw: 'Hariri Mali', en: 'Edit Property'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
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
                color: _isDark(context) ? Colors.white70 : AppColors.textColorSecondary,
              ),
            ),
          ),
        );
      }
      final dividerColor = _isDark(context) ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED);
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
                        color: _isDark(context) ? Colors.white : const Color(0xFF2E2E2E),
                      ),
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return _t(
                            context,
                            en: 'Property name is required',
                            sw: 'Jina la mali linahitajika',
                          );
                        }
                        return null;
                      },
                    ),
                    if (controller.showUnitsEditor)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Divider(height: 1, color: dividerColor),
                          const SizedBox(height: 18),
                          _buildUnitsSection(context, isDark: _isDark(context)),
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

  Widget _buildUnitsSection(BuildContext context, {required bool isDark}) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    final labelColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);
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
                child: _addedUnitTile(context, i, isDark: isDark),
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
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(context, en: 'UNIT NAME', sw: 'JINA LA UNITI'),
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
                hint: _t(context, en: 'e.g. 4B or Unit 1', sw: 'mf. 4B au Unit 1'),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.unitFloorLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => _unitFloorDropdown(
                  context: context,
                  isDark: isDark,
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
                  color: labelColor,
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
                  filled: true,
                  fillColor: fill,
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
                  color: labelColor,
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
                  color: isDark ? Colors.white : const Color(0xFF2E2E2E),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fill,
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
                    color: isDark ? const Color(0xFF5EC9C3) : null,
                  ),
                  label: Text(
                    _t(context, en: 'Add unit', sw: 'Ongeza uniti'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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
          ),
        ),
      ],
    );
  }

  Widget _unitFloorDropdown({
    required BuildContext context,
    required bool isDark,
    required AppLocalizations l10n,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    final fill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1F1);
    final textColor = isDark ? Colors.white : const Color(0xFF2E2E2E);
    final floor = PropertyUnitFloor.indices.contains(value)
        ? value
        : PropertyUnitFloor.defaultIndex;
    return DropdownButtonFormField<int>(
      initialValue: floor,
      isExpanded: true,
      icon: Icon(
        Icons.expand_more,
        color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3D3D3D),
      ),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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

  Widget _addedUnitTile(BuildContext context, int index, {required bool isDark}) {
    final u = controller.apartmentUnits[index];
    final l10n = AppLocalizations.of(context)!;
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
                  '${PropertyUnitFloor.label(l10n, u.unitFloor)} · Tshs ${u.unitRent} · ${u.unitRentFrequency}',
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
            tooltip: _t(context, en: 'Remove unit', sw: 'Ondoa uniti'),
            visualDensity: VisualDensity.compact,
          ),
        ],
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

  Widget _buildLabel(BuildContext context, String text) {
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

  InputDecoration _inputDecoration(BuildContext context, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _isDark(context) ? Colors.white70 : AppColors.designPlaceholder,
      ),
      filled: true,
      fillColor: _isDark(context) ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
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
}
