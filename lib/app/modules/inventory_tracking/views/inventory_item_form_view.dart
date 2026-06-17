import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/widget/custom_app_bar.dart';
import '../controllers/inventory_item_form_controller.dart';
import 'inventory_barcode_scanner_view.dart';

class InventoryItemFormView extends BaseView<InventoryItemFormController> {
  InventoryItemFormView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: controller.isEditing
          ? (_isSw ? 'Hariri kipengele' : 'Edit item')
          : (_isSw ? 'Ongeza kipengele' : 'Add item'),
      showLanguageToggle: false,
      showThemeToggle: false,
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Form(
      key: controller.formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _isSw ? 'Jina' : 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? (_isSw ? 'Jina linahitajika' : 'Name is required')
                          : null,
                ),
              ),
              const SizedBox(width: 8),
              // QR / Barcode scan button
              Container(
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.colorPrimary,
                  ),
                  tooltip: _isSw ? 'Changanua' : 'Scan QR / Barcode',
                  onPressed: () async {
                    final result = await Get.to<String>(
                      () => const InventoryBarcodeScannerView(),
                    );
                    if (result != null && result.trim().isNotEmpty) {
                      controller.nameController.text = result.trim();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.selectedCategory.value,
              decoration: InputDecoration(
                labelText: _isSw ? 'Aina' : 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: InventoryItemFormController.categories
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.selectedCategory.value = v;
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isSw ? 'Idadi' : 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 0) {
                      return _isSw ? 'Idadi halali' : 'Valid quantity required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller.reorderLevelController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isSw ? 'Kiwango cha chini' : 'Reorder level',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.selectedCondition.value,
              decoration: InputDecoration(
                labelText: _isSw ? 'Hali' : 'Condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: InventoryItemFormController.conditions
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.selectedCondition.value = v;
              },
            ),
          ),
          const SizedBox(height: 12),
          // Room-level location picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSw ? 'Chumba / Mahali' : 'Room / Location',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.hint,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Obx(() {
                final selected = controller.selectedRoom.value;
                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: InventoryItemFormController.rooms.map((room) {
                    final isSelected = selected == room;
                    return ChoiceChip(
                      label: Text(room,
                          style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) {
                        if (isSelected) {
                          controller.selectedRoom.value = '';
                          controller.locationNoteController.text = '';
                        } else {
                          controller.selectedRoom.value = room;
                          controller.locationNoteController.text = room;
                        }
                      },
                      selectedColor:
                          AppColors.colorPrimary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.colorPrimary
                            : c.headline,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.locationNoteController,
                decoration: InputDecoration(
                  labelText: _isSw
                      ? 'Maelezo ya mahali (si lazima)'
                      : 'Location detail (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: _isSw ? 'k.m. Kabati la jikoni' : 'e.g. Kitchen cupboard',
                  hintStyle: TextStyle(fontSize: 14, color: c.hint),
                ),
                onChanged: (v) {
                  // If user types something not matching a room, clear chip
                  if (!InventoryItemFormController.rooms.contains(v.trim())) {
                    controller.selectedRoom.value = '';
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: CurrencyDropdownField(
                  selectedCurrency: controller.selectedCurrency,
                  label: 'Currency',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller.purchaseValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: controller.validatePurchaseValue,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  style: TextStyle(fontSize: 16, color: c.headline),
                  decoration: InputDecoration(
                    labelText: _isSw ? 'Thamani ya ununuzi' : 'Purchase value',
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
                )
              )
            ],
          ),
          const SizedBox(height: 24),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    controller.saving.value ? null : controller.save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: controller.saving.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        controller.isEditing
                            ? (_isSw ? 'Hifadhi mabadiliko' : 'Save changes')
                            : (_isSw ? 'Ongeza kipengele' : 'Add item'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
