import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '../controllers/add_listing_controller.dart';

String _t(BuildContext context, {required String en, required String sw}) {
  return Get.locale?.languageCode == 'sw' ? sw : en;
}

/// Shared "Add Unit" section for apartment-type properties: lists added units
/// and an inline draft form to add more. Used by both the full Add Listing
/// screen and the condensed quick-add wizard so the two flows stay in sync.
Widget buildAddUnitsSection(BuildContext context, AddListingController controller) {
  final c = FormSurfaceColors.of(context);
  final l10n = AppLocalizations.of(context)!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'ADD UNIT',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: c.headline,
        ),
      ),
      const SizedBox(height: 8),
      Obx(
        () => Column(
          children: List.generate(
            controller.apartmentUnits.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _addedUnitTile(context, controller, i),
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
            hint: _t(context, en: 'e.g. 4B or Unit 1', sw: 'mf. 4B au Unit 1'),
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
          Obx(
            () => TextFormField(
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
          const SizedBox(height: 12),
          Text(
            'CURRENCY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: c.hint,
            ),
          ),
          const SizedBox(height: 8),
          CurrencyDropdownField(
            selectedCurrency: controller.selectedCurrency,
            label: 'Currency',
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
                  color: c.hint,
                ),
                children: [
                  const TextSpan(text: 'UNIT DESCRIPTION'),
                  TextSpan(
                    text: _t(context, en: ' (optional)', sw: ' (hiari)'),
                    style: TextStyle(fontWeight: FontWeight.w600, color: c.hint),
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

Widget _addedUnitTile(
  BuildContext context,
  AddListingController controller,
  int index,
) {
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
                '${PropertyUnitFloor.label(l10n, u.unitFloor)} · ${u.unitRentCurrency} ${u.unitRent} · ${u.unitRentFrequency}${controller.listingMode.value == 'both' ? ' · ${_unitModeLabel(context, u.operationMode)}' : ''}',
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
      contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
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

Widget _formCard({required BuildContext context, required List<Widget> children}) {
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}
