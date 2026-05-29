import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/values/property_unit_floor.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../controllers/edit_unit_controller.dart';

class EditUnitView extends BaseView<EditUnitController> {
  EditUnitView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
        appBarTitleText: _isSw ? 'Hariri Uniti' : 'Edit Unit',
        isCentered: true,
      );

  @override
  Widget body(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      if (controller.loading.value) {
        return const DefaultScreenSkeleton();
      }
      if (controller.loadError.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              controller.loadError.value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: dark ? Colors.white70 : AppColors.textColorSecondary),
            ),
          ),
        );
      }

      final l10n = AppLocalizations.of(context)!;
      return Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          children: [
            _label(dark, _isSw ? 'JINA LA UNITI' : 'UNIT NAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.unitNameController,
              textCapitalization: TextCapitalization.words,
              decoration: _input(dark, _isSw ? 'mf. Unit 4B' : 'e.g. Unit 4B'),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return _isSw ? 'Jina la uniti linahitajika' : 'Unit name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _label(dark, l10n.unitFloorLabel.toUpperCase()),
            const SizedBox(height: 8),
            Obx(
              () {
                final floor = PropertyUnitFloor.indices.contains(controller.unitFloor.value)
                    ? controller.unitFloor.value
                    : PropertyUnitFloor.defaultIndex;
                return DropdownButtonFormField<int>(
                  initialValue: floor,
                  decoration: _input(dark, ''),
                  items: PropertyUnitFloor.indices
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(PropertyUnitFloor.label(l10n, f)),
                        ),
                      )
                      .toList(),
                  onChanged: controller.updateUnitFloor,
                );
              },
            ),
            const SizedBox(height: 14),
            _label(dark, _isSw ? 'KODI YA UNITI' : 'UNIT RENT'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.unitRentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: _input(dark, '0.00').copyWith(prefixText: 'Tshs '),
              validator: (v) {
                final raw = (v ?? '').trim().replaceAll(',', '');
                final n = double.tryParse(raw);
                if (raw.isEmpty || n == null || n <= 0) {
                  return _isSw ? 'Weka kodi sahihi' : 'Enter a valid rent amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _label(dark, _isSw ? 'MZUNGUKO WA KODI' : 'RENT FREQUENCY'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.unitRentFrequency.value,
                decoration: _input(dark, ''),
                items: EditUnitController.rentFrequencyOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: controller.updateRentFrequency,
              ),
            ),
            const SizedBox(height: 14),
            _label(dark, _isSw ? 'MAELEZO (hiari)' : 'DESCRIPTION (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.unitDescriptionController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: _input(
                dark,
                _isSw ? 'Andika maelezo ya uniti' : 'Write unit notes',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(AppValues.padding),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isSw ? 'Hifadhi Mabadiliko' : 'Save Changes',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _label(bool dark, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
          color: dark ? Colors.white70 : AppColors.textColorSecondary,
        ),
      );

  InputDecoration _input(bool dark, String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: dark ? const Color(0xFF1F1F1F) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? Colors.white24 : AppColors.designInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? Colors.white24 : AppColors.designInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.designAccent, width: 1.4),
        ),
      );
}
