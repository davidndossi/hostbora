import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/thousand_separator.dart';
import '../../../core/widget/currency_dropdown_field.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
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
      locale: const Locale('en', 'GB'),
    );
    
    if (picked == null) return;
    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    final year = picked.year.toString();
    controller.datePaidController.text = '$day/$month/$year';
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: controller.isEditMode
          ? (_isSw ? 'Hariri Gharama' : 'Edit Expense')
          : (_isSw ? 'Ongeza Gharama' : 'Add Expense'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final sectionTitleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: c.headline,
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
              colors: c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _isSw ? 'Chagua Mjengo' : 'Select Property',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final hasProperties = controller.hasProperties;
                    final hintColor = c.hint;
                    final textColor = c.headline;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue:
                              controller.propertyOptions.contains(
                                controller.selectedProperty.value,
                              )
                              ? controller.selectedProperty.value
                              : null,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          dropdownColor: c.dropdownBg,
                          icon: Icon(
                            Icons.expand_more_rounded,
                            color: c.secondary,
                          ),
                          decoration: InputDecoration(
                            hintText: _isSw
                                ? 'Chagua mjengo'
                                : 'Choose property',
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 16,
                            ),
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
                          onChanged: hasProperties
                              ? controller.updateSelectedProperty
                              : null,
                        ),
                        if (!hasProperties)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 2),
                            child: Text(
                              _isSw
                                  ? 'Bado hakuna mjengo - ongeza mjengo kwanza.'
                                  : 'No properties yet - add property first.',
                              style: TextStyle(fontSize: 12, color: hintColor),
                            ),
                          ),
                      ],
                    );
                  }),
                  Obx(() {
                    if (!controller.showExpenseUnitPicker) {
                      return const SizedBox.shrink();
                    }
                    final units = controller.expenseUnitsForSelectedProperty;
                    if (units.isEmpty) return const SizedBox.shrink();

                    final hintColor = c.hint;
                    final textColor = c.headline;
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
                            dropdownColor: c.dropdownBg,
                            icon: Icon(
                              Icons.expand_more_rounded,
                              color: c.secondary,
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
                                      ? 'Sio lazima — jengo lote'
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
              colors: c,
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
                          colors: c,
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
              colors: c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(_isSw ? 'Kiasi' : 'Amount', style: sectionTitleStyle),
                  const SizedBox(height: 7),
                  Obx(
                    () => _field(
                      c,
                      controller.amountController,
                      hint: '0.00',
                      prefixText: '${controller.selectedCurrency.value} ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: controller.validateAmount,
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_isSw ? 'Sarafu' : 'Currency', style: sectionTitleStyle),
                  const SizedBox(height: 7),
                  CurrencyDropdownField(
                    selectedCurrency: controller.selectedCurrency,
                    label: _isSw ? 'Sarafu' : 'Currency',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSw ? 'Tarehe ya Muamala' : 'Transaction Date',
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
                  _field(
                    c,
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
                    c,
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
            Obx(
              () => LoadingButton(
                label: controller.isEditMode
                    ? (_isSw ? 'Sasisha Gharama' : 'Update Expense')
                    : (_isSw ? 'Rekodi Muamala' : 'Record Transaction'),
                icon: Icons.receipt_long_outlined,
                onPressed: controller.saveExpenseOffline,
                isLoading: controller.isBusy.value,
              ),
            ),
            const SizedBox(height: 14),
            _expenseCard(
              colors: c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSw ? 'Muktadha wa Mwezi' : 'Monthly Context',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: c.headline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          colors: c,
                          label: _isSw ? 'BAJETI ILIYOTUMIKA' : 'BUDGET USED',
                          value: '0%',
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          colors: c,
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
          ],
        ),
      ),
    );
  }

  Widget _expenseCard({
    required FormSurfaceColors colors,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: colors.isDark ? Border.all(color: colors.border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.22 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _field(
    FormSurfaceColors colors,
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
    String prefixText = '',
  }) {
    // final textColor = colors.secondary;
    final hintStyle = TextStyle(
      fontSize: 14,
      color: colors.hint,
      height: isMultiline ? 1.35 : 1.2,
    );
    final suffixIconColor = colors.secondary;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.fill : Colors.transparent,
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
          // color: textColor,
          height: isMultiline ? 1.35 : 1.25,
        ),
        decoration: InputDecoration(
          isDense: false,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: hintStyle,
          prefixText: prefixText.isEmpty ? null : prefixText,
          prefixStyle: TextStyle(
            fontSize: 14,
            // color: textColor,
            fontWeight: FontWeight.w700,
          ),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: 8, top: isMultiline ? 12 : 0),
                  child: Icon(suffix, size: 20, color: suffixIconColor),
                ),
          suffixIconConstraints: BoxConstraints(
            minWidth: suffix != null ? 40 : 0,
            minHeight: suffix != null ? (isMultiline ? 52 : 40) : 0,
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.colors,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final FormSurfaceColors colors;
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final labelColor = colors.hint;
    final valueMuted = colors.headline;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
                ? colors.tokens.accent
                : valueMuted,
          ),
        ),
      ],
    );
  }
}

class _ExpenseChip extends StatelessWidget {
  const _ExpenseChip({
    required this.colors,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final FormSurfaceColors colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // final bg = selected
    //     ? colors.tokens.accent
    //     : (colors.isDark ? colors.fill : const Color(0xFFF1F1EE));
    final bg = selected ? colors.tokens.accent : colors.chipUnselectedBg;
    final fg = selected ? Colors.white : colors.headline;
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
