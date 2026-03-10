import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/widget/custom_app_bar.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/add_expense_controller.dart';

class AddExpenseView extends BaseView<AddExpenseController> {
  AddExpenseView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.addExpense,
      isCentered: true,
    );
    // return AppBar(
    //   backgroundColor: AppColors.pageBackground,
    //   elevation: 0,
    //   scrolledUnderElevation: 0,
    //   leading: IconButton(
    //     onPressed: () => Get.back(),
    //     icon: const Icon(Icons.chevron_left, size: 28),
    //     style: IconButton.styleFrom(
    //       backgroundColor: AppColors.colorWhite,
    //       foregroundColor: AppColors.textColorPrimary,
    //       shape: const CircleBorder(),
    //     ),
    //   ),
    //   title: Text(
    //     'NEW ENTRY',
    //     style: TextStyle(
    //       fontSize: 14,
    //       fontWeight: FontWeight.w700,
    //       color: AppColors.colorPrimary,
    //       letterSpacing: 0.8,
    //     ),
    //   ),
    //   centerTitle: true,
    // );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Expense',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your property overhead and stay tax-ready.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textColorSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _label('EXPENSE CATEGORY'),
            const SizedBox(height: 8),
            _buildCategoryField(context),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('AMOUNT'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(hint: '0.00').copyWith(
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            color: AppColors.textColorPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        validator: controller.validateAmount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('DATE'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.dateController,
                        readOnly: true,
                        decoration: _inputDecoration(hint: 'mm/dd/yyyy').copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => controller.pickDate(context),
                            icon: Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.designPlaceholder),
                          ),
                        ),
                        validator: (v) => controller.validateRequired(v, 'Date'),
                        onTap: () => controller.pickDate(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label('VENDOR NAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.vendorController,
              decoration: _inputDecoration(hint: 'e.g. CleanCo Inc.'),
              validator: (v) => controller.validateRequired(v, 'Vendor name'),
            ),
            const SizedBox(height: 20),
            _label('PROOF OF PURCHASE'),
            const SizedBox(height: 8),
            _buildUploadArea(context),
            const SizedBox(height: 20),
            _buildTaxDeductibleCard(context),
            const SizedBox(height: 28),
            Obx(() {
              final saving = controller.saving.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : controller.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: AppColors.textColorWhite,
                    disabledBackgroundColor: AppColors.colorPrimary.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppValues.roundedButtonRadius),
                    ),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColorWhite),
                          ),
                        )
                      : const Text('Add Expense'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.designPlaceholder),
      filled: true,
      fillColor: AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: const BorderSide(color: AppColors.designInputBorder),
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

  Widget _buildCategoryField(BuildContext context) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedCategory.value,
          decoration: _inputDecoration(hint: 'Select Category'),
          hint: Text(
            'Select Category',
            style: TextStyle(
              color: AppColors.designPlaceholder,
              fontSize: 16,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.designPlaceholder),
          items: controller.categories
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: controller.selectCategory,
          validator: (v) => controller.validateRequired(v ?? '', 'Category'),
        ));
  }

  Widget _buildUploadArea(BuildContext context) {
    return Obx(() {
      final path = controller.receiptFilePath.value;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.colorWhite,
              borderRadius: BorderRadius.circular(AppValues.radius_12),
              border: Border.all(color: AppColors.designInputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppValues.radius_12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 20, color: AppColors.colorPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Receipt captured',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: controller.clearReceipt,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      }
      return GestureDetector(
        onTap: controller.uploadReceipt,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.colorPrimaryLight.withOpacity(0.25),
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: AppColors.colorPrimary.withOpacity(0.5),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: AppColors.colorPrimary,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to capture receipt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colorPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a photo of your receipt',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textColorSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTaxDeductibleCard(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.colorWhite,
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(color: AppColors.designInputBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tax Deductible',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This expense can be written off',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: controller.taxDeductible.value,
                onChanged: controller.setTaxDeductible,
                activeTrackColor: AppColors.colorPrimaryLight,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return AppColors.colorPrimary;
                  return AppColors.designInputBorder;
                }),
              ),
            ],
          ),
        ));
  }
}
