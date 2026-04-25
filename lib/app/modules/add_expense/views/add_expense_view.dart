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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _t(BuildContext context, {required String en, required String sw}) {
    final code =
        Get.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return code == 'sw' ? sw : en;
  }

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
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(context, en: 'Add Expense', sw: 'Ongeza Matumizi'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : AppColors.textColorPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                context,
                en: 'Track your property overhead and stay tax-ready.',
                sw: 'Fuatilia gharama za mali yako na uwe tayari kwa kodi.',
              ),
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.textColorSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _label(
              context,
              _t(context, en: 'EXPENSE CATEGORY', sw: 'KUNDI LA GHARAMA'),
            ),
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
                      _label(context, _t(context, en: 'AMOUNT', sw: 'KIASI')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(context, hint: '0.00')
                            .copyWith(
                              prefixText: 'TZS ',
                              prefixStyle: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? theme.colorScheme.onSurface
                                    : AppColors.textColorPrimary,
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
                      _label(context, _t(context, en: 'DATE', sw: 'TAREHE')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.dateController,
                        readOnly: true,
                        decoration:
                            _inputDecoration(
                              context,
                              hint: _t(
                                context,
                                en: 'mm/dd/yyyy',
                                sw: 'mm/dd/yyyy',
                              ),
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => controller.pickDate(context),
                                icon: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : AppColors.designPlaceholder,
                                ),
                              ),
                            ),
                        validator: (v) => controller.validateRequired(
                          v,
                          _t(context, en: 'Date', sw: 'Tarehe'),
                        ),
                        onTap: () => controller.pickDate(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label(
              context,
              _t(context, en: 'VENDOR NAME', sw: 'JINA LA MUUZAJI'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.vendorController,
              decoration: _inputDecoration(
                context,
                hint: _t(
                  context,
                  en: 'e.g. CleanCo Inc.',
                  sw: 'mf. CleanCo Inc.',
                ),
              ),
              validator: (v) => controller.validateRequired(
                v,
                _t(context, en: 'Vendor name', sw: 'Jina la muuzaji'),
              ),
            ),
            const SizedBox(height: 20),
            _label(
              context,
              _t(
                context,
                en: 'PROOF OF PURCHASE',
                sw: 'UTHIBITISHO WA MANUNUZI',
              ),
            ),
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
                    disabledBackgroundColor: AppColors.colorPrimary.withValues(
                      alpha: 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppValues.roundedButtonRadius,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textColorWhite,
                            ),
                          ),
                        )
                      : Text(
                          _t(context, en: 'Add Expense', sw: 'Ongeza Matumizi'),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: _isDark(context)
            ? Theme.of(context).colorScheme.onSurface
            : AppColors.textColorPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? theme.colorScheme.onSurfaceVariant
            : AppColors.designPlaceholder,
      ),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : AppColors.colorWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        borderSide: BorderSide(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.designInputBorder,
        ),
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
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue: controller.selectedCategory.value,
        decoration: _inputDecoration(
          context,
          hint: _t(context, en: 'Select Category', sw: 'Chagua Kundi'),
        ),
        hint: Text(
          _t(context, en: 'Select Category', sw: 'Chagua Kundi'),
          style: TextStyle(
            color: isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.designPlaceholder,
            fontSize: 16,
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: isDark
              ? theme.colorScheme.onSurfaceVariant
              : AppColors.designPlaceholder,
        ),
        items: controller.categories
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: controller.selectCategory,
        validator: (v) => controller.validateRequired(
          v ?? '',
          _t(context, en: 'Category', sw: 'Kundi'),
        ),
      ),
    );
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
              color: _isDark(context)
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : AppColors.colorWhite,
              borderRadius: BorderRadius.circular(AppValues.radius_12),
              border: Border.all(
                color: _isDark(context)
                    ? Theme.of(context).colorScheme.outlineVariant
                    : AppColors.designInputBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppValues.radius_12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: AppColors.colorPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _t(
                            context,
                            en: 'Receipt captured',
                            sw: 'Risiti imechukuliwa',
                          ),
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
                        label: Text(_t(context, en: 'Remove', sw: 'Ondoa')),
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
            color: AppColors.colorPrimaryLight.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppValues.radius_12),
            border: Border.all(
              color: AppColors.colorPrimary.withValues(alpha: 0.5),
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
                _t(
                  context,
                  en: 'Tap to capture receipt',
                  sw: 'Gusa kupiga picha ya risiti',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colorPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _t(
                  context,
                  en: 'Take a photo of your receipt',
                  sw: 'Piga picha ya risiti yako',
                ),
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
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHigh
              : AppColors.colorWhite,
          borderRadius: BorderRadius.circular(AppValues.radius_12),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outlineVariant
                : AppColors.designInputBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                    _t(
                      context,
                      en: 'Tax Deductible',
                      sw: 'Inakatwa Kwenye Kodi',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? theme.colorScheme.onSurface
                          : AppColors.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(
                      context,
                      en: 'This expense can be written off',
                      sw: 'Gharama hii inaweza kukatwa kwenye kodi',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.textColorSecondary,
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
                if (states.contains(WidgetState.selected)) {
                  return AppColors.colorPrimary;
                }
                return AppColors.designInputBorder;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
