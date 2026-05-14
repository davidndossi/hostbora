import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/core/widget/custom_app_bar.dart';

import '../../../core/base/base_view.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../controllers/add_expense_controller.dart';

class AddExpenseView extends BaseView<AddExpenseController> {
  AddExpenseView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  DateTime _parseExistingDate(String raw) {
    final parts = raw.trim().split('/');
    if (parts.length != 3) return DateTime.now();
    final day = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
      return DateTime.now();
    }
    return DateTime(year, month, day);
  }

  Future<void> _pickTransactionDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.datePaidController.text.trim().isEmpty
        ? now
        : _parseExistingDate(controller.datePaidController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    final year = picked.year.toString();
    controller.datePaidController.text = '$day/$month/$year';
  }

  // bool _isDark(BuildContext context) =>
  //     Theme.of(context).brightness == Brightness.dark;

  // String _t(BuildContext context, {required String en, required String sw}) {
  //   final code =
  //       Get.locale?.languageCode ??
  //       Localizations.localeOf(context).languageCode;
  //   return code == 'sw' ? sw : en;
  // }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.addExpense,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : const Color(0xFF1F2937),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            _expenseCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _isSw ? 'Chagua Mjengo' : 'Select Property',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 10),
                  Obx(
                        () {
                      final hasProperties = controller.hasProperties;
                      final hintColor =
                      isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8A);
                      final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: controller.propertyOptions.contains(controller.selectedProperty.value)
                                ? controller.selectedProperty.value
                                : null,
                            isExpanded: true,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            dropdownColor:
                            isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            icon: Icon(
                              Icons.expand_more_rounded,
                              color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF3D3D3D),
                            ),
                            decoration: InputDecoration(
                              hintText: _isSw ? 'Chagua mjengo' : 'Choose property',
                              hintStyle: TextStyle(color: hintColor, fontSize: 16),
                              border: InputBorder.none,
                            ),
                            validator: controller.validateSelectedProperty,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            items: controller.propertyOptions
                                .map(
                                  (p) => DropdownMenuItem<String>(
                                value: p,
                                child: Text(
                                  p,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: hasProperties ? controller.updateSelectedProperty : null,
                          ),
                          if (!hasProperties)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 2),
                              child: Text(
                                _isSw ? 'Bado hakuna mjengo - ongeza mjengo kwanza.' : 'No properties yet - add property first.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hintColor,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  Obx(() {
                    if (!controller.showExpenseUnitPicker) {
                      return const SizedBox.shrink();
                    }
                    final units = controller.expenseUnitsForSelectedProperty;
                    if (units.isEmpty) return const SizedBox.shrink();

                    final hintColor =
                    isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8A);
                    final textColor =
                    isDark ? Colors.white : const Color(0xFF1F2937);
                    final sel = controller.selectedExpenseUnitKey.value;
                    final valid =
                        sel != null && units.any((u) => u.selectionKey == sel);
                    final value = valid ? sel : null;

                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSw ? 'KITENGO (si lazima)' : 'UNIT (optional)',
                            style: sectionTitleStyle.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String?>(
                            initialValue: value,
                            isExpanded: true,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            dropdownColor:
                            isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            icon: Icon(
                              Icons.expand_more_rounded,
                              color: isDark
                                  ? const Color(0xFFAEAEB2)
                                  : const Color(0xFF3D3D3D),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  _isSw
                                      ? 'Sio lazima — gharama ya jumla'
                                      : 'Optional — whole property',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ...units.map(
                                    (u) => DropdownMenuItem<String?>(
                                  value: u.selectionKey,
                                  child: Text(
                                    u.unitName,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: controller.updateSelectedExpenseUnit,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _expenseCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _isSw ? 'Chagua Kategoria' : 'Select Category',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 10),
                  Obx(
                        () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        controller.expenses.length,
                            (i) => _ExpenseChip(
                          isDark: isDark,
                          label: controller.expenses[i],
                          selected: controller.selectedExpenseIndex.value == i,
                          onTap: () => controller.selectExpense(i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _expenseCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    _isSw ? 'Kiasi (Tsh)' : 'Amount (Tsh)',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
                  _field(
                    isDark,
                    controller.amountController,
                    hint: 'Tsh 0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: controller.validateAmount,
                    inputFormatters: [
                      ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSw ? 'Tarehe ya Muamala' : 'Transaction Date',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
                  _field(
                    isDark,
                    controller.datePaidController,
                    hint: 'dd/MM/yyyy',
                    keyboardType: TextInputType.datetime,
                    suffix: Icons.calendar_month_rounded,
                    readOnly: true,
                    onTap: () => _pickTransactionDate(context),
                    validator: controller.validateDatePaid,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSw ? 'Maelezo' : 'Description',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
                  _field(
                    isDark,
                    controller.notesController,
                    hint: _isSw
                        ? 'Andika maelezo ya gharama (si lazima)'
                        : 'Add expense description (optional)',
                    isMultiline: true,
                    minHeight: 92,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.saveExpenseOffline,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 20),
                label: Text(_isSw ? 'Rekodi Muamala' : 'Record Transaction',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            // const Text(
            //   'By recording this expense, you update the monthly operational report for The Concierge',
            //   style: TextStyle(fontSize: 9, height: 1.3, color: Color(0xFF8A8A8A)),
            // ),
            const SizedBox(height: 14),
            _expenseCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'Muktadha wa Mwezi' : 'Monthly Context',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          isDark: isDark,
                          label: _isSw ? 'BAJETI ILIYOTUMIKA' : 'BUDGET USED',
                          value: '0%',
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          isDark: isDark,
                          label: _isSw ? 'HALI' : 'STATUS',
                          value: _isSw ? 'Nzuri' : 'Healthy',
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(12),
            //   child: SizedBox(
            //     width: double.infinity,
            //     height: 210,
            //     child: Stack(
            //       fit: StackFit.expand,
            //       children: [
            //         Image.asset('images/luxury_room_view.png',
            //             fit: BoxFit.cover,
            //             errorBuilder: (context, error, stackTrace) =>
            //                 Container(color: const Color(0xFF334444))),
            //         Container(
            //           decoration: BoxDecoration(
            //             gradient: LinearGradient(
            //               begin: Alignment.topCenter,
            //               end: Alignment.bottomCenter,
            //               colors: [
            //                 Colors.black.withValues(alpha: 0.05),
            //                 Colors.black.withValues(alpha: 0.6),
            //               ],
            //             ),
            //           ),
            //         ),
            //         const Positioned(
            //           left: 12,
            //           right: 12,
            //           bottom: 12,
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text('OPERATIONAL EXCELLENCE',
            //                   style: TextStyle(
            //                       color: Colors.white,
            //                       fontSize: 8,
            //                       letterSpacing: 1.8,
            //                       fontWeight: FontWeight.w700)),
            //               SizedBox(height: 4),
            //               Text(
            //                 'Invest in quality maintenance to preserve\nasset value.',
            //                 style: TextStyle(
            //                     color: Colors.white,
            //                     fontSize: 13,
            //                     height: 1.3,
            //                     fontWeight: FontWeight.w500),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 86),
          ],
        ),
      ),
    );
  }

  Widget _expenseCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: const Color(0xFF3A3A3C)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _field(
      bool isDark,
      TextEditingController fieldController, {
        required String hint,
        IconData? suffix,
        bool isMultiline = false,
        double minHeight = 48,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        List<TextInputFormatter>? inputFormatters,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    final textColor = isDark ? const Color(0xFFE8E8ED) : const Color(0xFF5B5B5B);
    final hintColor =
    isDark ? const Color(0xFF8E8E93) : const Color(0xFF5B5B5B).withValues(alpha: 0.72);
    final hintStyle = TextStyle(
      fontSize: 14,
      color: hintColor,
      height: isMultiline ? 1.35 : 1.2,
    );
    final suffixIconColor =
    isDark ? const Color(0xFFAEAEB2) : const Color(0xFF2D2D2D);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: fieldController,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType ?? TextInputType.text,
        inputFormatters: inputFormatters,
        maxLines: isMultiline ? null : 1,
        minLines: isMultiline ? 3 : 1,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.sentences,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          height: isMultiline ? 1.35 : 1.25,
        ),
        decoration: InputDecoration(
          isDense: false,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: hintStyle,
          suffixIcon: suffix == null
              ? null
              : Padding(
            padding: EdgeInsets.only(left: 8, top: isMultiline ? 12 : 0),
            child: Icon(
              suffix,
              size: 20,
              color: suffixIconColor,
            ),
          ),
          suffixIconConstraints: BoxConstraints(
            minWidth: suffix != null ? 40 : 0,
            minHeight: suffix != null ? (isMultiline ? 52 : 40) : 0,
          ),
        ),
      ),
    );
  }

  // @override
  // Widget body(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final isDark = _isDark(context);
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
  //     child: Form(
  //       key: controller.formKey,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             _t(context, en: 'Add Expense', sw: 'Ongeza Matumizi'),
  //             style: TextStyle(
  //               fontSize: 28,
  //               fontWeight: FontWeight.w700,
  //               color: isDark
  //                   ? theme.colorScheme.onSurface
  //                   : AppColors.textColorPrimary,
  //               letterSpacing: -0.5,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             _t(
  //               context,
  //               en: 'Track your property overhead and stay tax-ready.',
  //               sw: 'Fuatilia gharama za mali yako na uwe tayari kwa kodi.',
  //             ),
  //             style: TextStyle(
  //               fontSize: 15,
  //               color: isDark
  //                   ? theme.colorScheme.onSurfaceVariant
  //                   : AppColors.textColorSecondary,
  //               height: 1.4,
  //             ),
  //           ),
  //           const SizedBox(height: 24),
  //           _label(
  //             context,
  //             _t(context, en: 'EXPENSE CATEGORY', sw: 'KUNDI LA GHARAMA'),
  //           ),
  //           const SizedBox(height: 8),
  //           _buildCategoryField(context),
  //           const SizedBox(height: 20),
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     _label(context, _t(context, en: 'AMOUNT', sw: 'KIASI')),
  //                     const SizedBox(height: 8),
  //                     TextFormField(
  //                       controller: controller.amountController,
  //                       keyboardType: const TextInputType.numberWithOptions(
  //                         decimal: true,
  //                       ),
  //                       decoration: _inputDecoration(context, hint: '0.00')
  //                           .copyWith(
  //                             prefixText: 'TZS ',
  //                             prefixStyle: TextStyle(
  //                               fontSize: 16,
  //                               color: isDark
  //                                   ? theme.colorScheme.onSurface
  //                                   : AppColors.textColorPrimary,
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                       validator: controller.validateAmount,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     _label(context, _t(context, en: 'DATE', sw: 'TAREHE')),
  //                     const SizedBox(height: 8),
  //                     TextFormField(
  //                       controller: controller.dateController,
  //                       readOnly: true,
  //                       decoration:
  //                           _inputDecoration(
  //                             context,
  //                             hint: _t(
  //                               context,
  //                               en: 'mm/dd/yyyy',
  //                               sw: 'mm/dd/yyyy',
  //                             ),
  //                           ).copyWith(
  //                             suffixIcon: IconButton(
  //                               onPressed: () => controller.pickDate(context),
  //                               icon: Icon(
  //                                 Icons.calendar_today_outlined,
  //                                 size: 20,
  //                                 color: isDark
  //                                     ? theme.colorScheme.onSurfaceVariant
  //                                     : AppColors.designPlaceholder,
  //                               ),
  //                             ),
  //                           ),
  //                       validator: (v) => controller.validateRequired(
  //                         v,
  //                         _t(context, en: 'Date', sw: 'Tarehe'),
  //                       ),
  //                       onTap: () => controller.pickDate(context),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 20),
  //           _label(
  //             context,
  //             _t(context, en: 'VENDOR NAME', sw: 'JINA LA MUUZAJI'),
  //           ),
  //           const SizedBox(height: 8),
  //           TextFormField(
  //             controller: controller.vendorController,
  //             decoration: _inputDecoration(
  //               context,
  //               hint: _t(
  //                 context,
  //                 en: 'e.g. CleanCo Inc.',
  //                 sw: 'mf. CleanCo Inc.',
  //               ),
  //             ),
  //             validator: (v) => controller.validateRequired(
  //               v,
  //               _t(context, en: 'Vendor name', sw: 'Jina la muuzaji'),
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           _label(
  //             context,
  //             _t(
  //               context,
  //               en: 'PROOF OF PURCHASE',
  //               sw: 'UTHIBITISHO WA MANUNUZI',
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           _buildUploadArea(context),
  //           const SizedBox(height: 20),
  //           _buildTaxDeductibleCard(context),
  //           const SizedBox(height: 28),
  //           Obx(() {
  //             final saving = controller.saving.value;
  //             return SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton(
  //                 onPressed: saving ? null : controller.submit,
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: AppColors.colorPrimary,
  //                   foregroundColor: AppColors.textColorWhite,
  //                   disabledBackgroundColor: AppColors.colorPrimary.withValues(
  //                     alpha: 0.6,
  //                   ),
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(
  //                       AppValues.roundedButtonRadius,
  //                     ),
  //                   ),
  //                   elevation: 0,
  //                 ),
  //                 child: saving
  //                     ? const SizedBox(
  //                         height: 22,
  //                         width: 22,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           valueColor: AlwaysStoppedAnimation<Color>(
  //                             AppColors.textColorWhite,
  //                           ),
  //                         ),
  //                       )
  //                     : Text(
  //                         _t(context, en: 'Add Expense', sw: 'Ongeza Matumizi'),
  //                       ),
  //               ),
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _label(BuildContext context, String text) {
  //   return Text(
  //     text,
  //     style: TextStyle(
  //       fontSize: 12,
  //       fontWeight: FontWeight.w600,
  //       letterSpacing: 0.5,
  //       color: _isDark(context)
  //           ? Theme.of(context).colorScheme.onSurface
  //           : AppColors.textColorPrimary,
  //     ),
  //   );
  // }

  // InputDecoration _inputDecoration(
  //   BuildContext context, {
  //   required String hint,
  // }) {
  //   final theme = Theme.of(context);
  //   final isDark = _isDark(context);
  //   return InputDecoration(
  //     hintText: hint,
  //     hintStyle: TextStyle(
  //       color: isDark
  //           ? theme.colorScheme.onSurfaceVariant
  //           : AppColors.designPlaceholder,
  //     ),
  //     filled: true,
  //     fillColor: isDark
  //         ? theme.colorScheme.surfaceContainerHigh
  //         : AppColors.colorWhite,
  //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //     border: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: BorderSide(
  //         color: isDark
  //             ? theme.colorScheme.outlineVariant
  //             : AppColors.designInputBorder,
  //       ),
  //     ),
  //     enabledBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: BorderSide(
  //         color: isDark
  //             ? theme.colorScheme.outlineVariant
  //             : AppColors.designInputBorder,
  //       ),
  //     ),
  //     focusedBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.5),
  //     ),
  //     errorBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppValues.radius_6),
  //       borderSide: const BorderSide(color: AppColors.errorColor),
  //     ),
  //   );
  // }

  // Widget _buildCategoryField(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final isDark = _isDark(context);
  //   return Obx(
  //     () => DropdownButtonFormField<String>(
  //       initialValue: controller.selectedCategory.value,
  //       decoration: _inputDecoration(
  //         context,
  //         hint: _t(context, en: 'Select Category', sw: 'Chagua Kundi'),
  //       ),
  //       hint: Text(
  //         _t(context, en: 'Select Category', sw: 'Chagua Kundi'),
  //         style: TextStyle(
  //           color: isDark
  //               ? theme.colorScheme.onSurfaceVariant
  //               : AppColors.designPlaceholder,
  //           fontSize: 16,
  //         ),
  //       ),
  //       icon: Icon(
  //         Icons.keyboard_arrow_down,
  //         color: isDark
  //             ? theme.colorScheme.onSurfaceVariant
  //             : AppColors.designPlaceholder,
  //       ),
  //       items: controller.categories
  //           .map((e) => DropdownMenuItem(value: e, child: Text(e)))
  //           .toList(),
  //       onChanged: controller.selectCategory,
  //       validator: (v) => controller.validateRequired(
  //         v ?? '',
  //         _t(context, en: 'Category', sw: 'Kundi'),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildUploadArea(BuildContext context) {
  //   return Obx(() {
  //     final path = controller.receiptFilePath.value;
  //     if (path != null && path.isNotEmpty) {
  //       final file = File(path);
  //       if (file.existsSync()) {
  //         return Container(
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             color: _isDark(context)
  //                 ? Theme.of(context).colorScheme.surfaceContainerHigh
  //                 : AppColors.colorWhite,
  //             borderRadius: BorderRadius.circular(AppValues.radius_12),
  //             border: Border.all(
  //               color: _isDark(context)
  //                   ? Theme.of(context).colorScheme.outlineVariant
  //                   : AppColors.designInputBorder,
  //             ),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               ClipRRect(
  //                 borderRadius: const BorderRadius.vertical(
  //                   top: Radius.circular(AppValues.radius_12),
  //                 ),
  //                 child: AspectRatio(
  //                   aspectRatio: 16 / 10,
  //                   child: Image.file(file, fit: BoxFit.cover),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 8,
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.receipt_long,
  //                       size: 20,
  //                       color: AppColors.colorPrimary,
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: Text(
  //                         _t(
  //                           context,
  //                           en: 'Receipt captured',
  //                           sw: 'Risiti imechukuliwa',
  //                         ),
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.w600,
  //                           color: AppColors.textColorPrimary,
  //                         ),
  //                       ),
  //                     ),
  //                     TextButton.icon(
  //                       onPressed: controller.clearReceipt,
  //                       icon: const Icon(Icons.close, size: 18),
  //                       label: Text(_t(context, en: 'Remove', sw: 'Ondoa')),
  //                       style: TextButton.styleFrom(
  //                         foregroundColor: AppColors.textColorSecondary,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       }
  //     }
  //     return GestureDetector(
  //       onTap: controller.uploadReceipt,
  //       child: Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.symmetric(vertical: 32),
  //         decoration: BoxDecoration(
  //           color: AppColors.colorPrimaryLight.withValues(alpha: 0.25),
  //           borderRadius: BorderRadius.circular(AppValues.radius_12),
  //           border: Border.all(
  //             color: AppColors.colorPrimary.withValues(alpha: 0.5),
  //             width: 2,
  //             strokeAlign: BorderSide.strokeAlignInside,
  //           ),
  //         ),
  //         child: Column(
  //           children: [
  //             Icon(
  //               Icons.camera_alt_outlined,
  //               size: 48,
  //               color: AppColors.colorPrimary,
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               _t(
  //                 context,
  //                 en: 'Tap to capture receipt',
  //                 sw: 'Gusa kupiga picha ya risiti',
  //               ),
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.colorPrimary,
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               _t(
  //                 context,
  //                 en: 'Take a photo of your receipt',
  //                 sw: 'Piga picha ya risiti yako',
  //               ),
  //               style: TextStyle(
  //                 fontSize: 12,
  //                 color: AppColors.textColorSecondary,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   });
  // }

  // Widget _buildTaxDeductibleCard(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final isDark = _isDark(context);
  //   return Obx(
  //     () => Container(
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: isDark
  //             ? theme.colorScheme.surfaceContainerHigh
  //             : AppColors.colorWhite,
  //         borderRadius: BorderRadius.circular(AppValues.radius_12),
  //         border: Border.all(
  //           color: isDark
  //               ? theme.colorScheme.outlineVariant
  //               : AppColors.designInputBorder,
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.04),
  //             blurRadius: 6,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   _t(
  //                     context,
  //                     en: 'Tax Deductible',
  //                     sw: 'Inakatwa Kwenye Kodi',
  //                   ),
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                     color: isDark
  //                         ? theme.colorScheme.onSurface
  //                         : AppColors.textColorPrimary,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   _t(
  //                     context,
  //                     en: 'This expense can be written off',
  //                     sw: 'Gharama hii inaweza kukatwa kwenye kodi',
  //                   ),
  //                   style: TextStyle(
  //                     fontSize: 13,
  //                     color: isDark
  //                         ? theme.colorScheme.onSurfaceVariant
  //                         : AppColors.textColorSecondary,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Switch(
  //             value: controller.taxDeductible.value,
  //             onChanged: controller.setTaxDeductible,
  //             activeTrackColor: AppColors.colorPrimaryLight,
  //             thumbColor: WidgetStateProperty.resolveWith((states) {
  //               if (states.contains(WidgetState.selected)) {
  //                 return AppColors.colorPrimary;
  //               }
  //               return AppColors.designInputBorder;
  //             }),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.isDark,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final bool isDark;
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final labelColor =
    isDark ? const Color(0xFF8E8E93) : const Color(0xFF8B8B8B);
    final valueMuted = isDark ? Colors.white : const Color(0xFF111111);

    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 8,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: (value == 'Healthy' || value == 'Nzuri')
                ? const Color(0xFF006D73)
                : valueMuted,
          ),
        ),
      ],
    );
  }
}

class _ExpenseChip extends StatelessWidget {
  const _ExpenseChip({
    required this.isDark,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final bool isDark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF006D73)
        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F1EE));
    final fg = selected
        ? Colors.white
        : (isDark ? const Color(0xFFE8E8ED) : const Color(0xFF1E1E1E));
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        splashColor: selected ? Colors.white24 : Colors.black12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
