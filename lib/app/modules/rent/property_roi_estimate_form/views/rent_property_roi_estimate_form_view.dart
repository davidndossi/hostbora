import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '/app/core/base/rent_base_view.dart';
import '/app/core/utils/thousand_separator.dart';
import '/app/core/values/app_colors.dart';
import '/app/core/widget/loading_button.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_estimate_form_controller.dart';

class _RoiUi {
  _RoiUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  Color get text => _t.colorScheme.onSurface;
  Color get muted => dark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);
  Color get label => dark ? const Color(0xFFB0B3BA) : const Color(0xFF4B5563);
  Color get card => _t.cardColor;
  Color get scaffold =>
      dark ? const Color(0xFF1C1C1E) : const Color(0xFFF8FAFC);
  Color get border =>
      dark ? const Color(0xFF3A3A3C) : const Color(0xFFF1F5F9);
  Color get softBorder =>
      dark ? const Color(0xFF3A3A3C) : const Color(0xFFEAF6F6);
  Color get segmentTrack =>
      dark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9);
  Color get placeholder =>
      dark ? const Color(0xFF8E8E93) : const Color(0xFFCBD5E1);
  Color get teal => AppColors.colorPrimary;
  Color get soft =>
      dark ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC);
  Color get greenBg =>
      dark ? const Color(0xFF1A2E2A) : const Color(0xFFECFDF5);
  Color get greenText =>
      dark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
  Color get amberBg =>
      dark ? const Color(0xFF2C2210) : const Color(0xFFFFFBEB);
  Color get amberText =>
      dark ? const Color(0xFFFCD34D) : const Color(0xFF78350F);
}

class RentPropertyRoiEstimateFormView
    extends RentBaseView<RentPropertyRoiEstimateFormController> {
  RentPropertyRoiEstimateFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _formatMoney(num amount) =>
      Get.find<CurrencyService>().formatBase(amount.round());

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Makadirio' : 'Estimates');

  @override
  Color pageBackgroundColor(BuildContext context) => _RoiUi(context).scaffold;

  @override
  Widget body(BuildContext context) {
    final u = _RoiUi(context);
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: u.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(u),
                      const SizedBox(height: 16),
                      _modeSwitch(u),
                      const SizedBox(height: 16),
                      Obx(
                        () => controller.mode.value ==
                                EstimateInputMode.approximate
                            ? _approximateSection(u)
                            : _itemizedForm(context, u),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  if (controller.mode.value != EstimateInputMode.itemized) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      _filters(context, u),
                      const SizedBox(height: 12),
                      _entriesList(u),
                      const SizedBox(height: 16),
                      _summarySection(u),
                    ],
                  );
                }),
              ],
            ),
          ),
          _bottomBar(u),
        ],
      ),
    );
  }

  Widget _header(_RoiUi u) {
    final address = controller.propertyAddress;
    final name = controller.propertyName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address.isNotEmpty) ...[
          Text(
            address,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.28,
              color: u.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 0.95,
            color: u.teal,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isSw
              ? 'Makadirio haya yatatumika kupima faida ya uwekezaji na kufuatilia kufikia faida.'
              : 'This estimate will be used to determine return on investment and track break even',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            height: 1.4,
            color: u.muted,
          ),
        ),
      ],
    );
  }

  Widget _modeSwitch(_RoiUi u) {
    return Obx(() {
      final approximate =
          controller.mode.value == EstimateInputMode.approximate;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: u.segmentTrack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _segmentTab(
                u,
                label: _isSw ? 'Makisio ya jumla' : 'Approximate Total',
                selected: approximate,
                onTap: () =>
                    controller.setMode(EstimateInputMode.approximate),
              ),
            ),
            Expanded(
              child: _segmentTab(
                u,
                label: _isSw ? 'Vipengele' : 'Individual Items',
                selected: !approximate,
                onTap: () => controller.setMode(EstimateInputMode.itemized),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _segmentTab(
    _RoiUi u, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? u.card : Colors.transparent,
      elevation: selected ? 1.5 : 0,
      shadowColor: const Color(0x14718096),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.28,
                color: selected ? u.teal : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(_RoiUi u, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.4,
          color: u.label,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
    _RoiUi u, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: u.placeholder,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: u.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: u.teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _amountWithCurrency(
    _RoiUi u, {
    required String label,
    required TextEditingController textController,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(u, label),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: textController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: validator,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(color: u.text, fontSize: 14),
                decoration: _inputDeco(u, hint: '0.00'),
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 92,
              child: Obx(() {
                final codes = Get.find<CurrencyService>().currencyCodes;
                final value = codes.contains(controller.selectedCurrency.value)
                    ? controller.selectedCurrency.value
                    : Get.find<CurrencyService>().baseCurrency.value;
                return DropdownButtonFormField<String>(
                  initialValue: value,
                  isExpanded: true,
                  decoration: _inputDeco(u),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: u.label,
                    size: 18,
                  ),
                  items: codes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: TextStyle(fontSize: 14, color: u.text)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.selectedCurrency.value = v;
                  },
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _approximateSection(_RoiUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _amountWithCurrency(
          u,
          label: _isSw
              ? 'Makadirio ya jumla ya mali'
              : 'Approximate estimate of whole property',
          textController: controller.approximateTotalController,
          validator: controller.validateRequiredAmount,
        ),
        const SizedBox(height: 14),
        _amountWithCurrency(
          u,
          label: _isSw
              ? 'Mapato ya mwezi yanayotarajiwa'
              : 'Expected Monthly Income',
          textController: controller.expectedMonthlyIncomeController,
        ),
        const SizedBox(height: 14),
        _amountWithCurrency(
          u,
          label: _isSw
              ? 'Matengenezo / matumizi ya mwezi'
              : 'Expected Monthly Maintenance / Expenses',
          textController: controller.expectedMonthlyExpenseController,
        ),
        const SizedBox(height: 14),
        _fieldLabel(
          u,
          _isSw ? 'Lengo la ukaaji (%)' : 'Target Occupancy (%)',
        ),
        TextFormField(
          controller: controller.targetOccupancyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: controller.validatePercent,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(color: u.text, fontSize: 14),
          decoration: _inputDeco(u, hint: _isSw ? 'Mf. 90%' : 'Ex: 90%'),
        ),
      ],
    );
  }

  Widget _itemizedForm(BuildContext context, _RoiUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw
              ? 'Ongeza gharama za kila kipengele kuanzia mwanzo hadi mwisho wa mradi'
              : 'Add individual cost form start to finish of the project',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            height: 1.4,
            color: u.muted,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _dateField(
                  u,
                  label: _isSw ? 'Tarehe ya kuanza' : 'Start Date',
                  value: controller.startDate.value,
                  placeholder: _isSw ? 'Chagua tarehe' : 'Select Date',
                  onTap: () => controller.pickStartDate(context),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Obx(
                () => _dateField(
                  u,
                  label: _isSw ? 'Tarehe ya mwisho' : 'End Date',
                  value: controller.completionDate.value,
                  placeholder: _isSw ? 'Chagua tarehe' : 'Select Date',
                  onTap: () => controller.pickCompletionDate(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _fieldLabel(u, _isSw ? 'Aina ya gharama' : 'Expense Category'),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedCategory.value,
            isExpanded: true,
            decoration: _inputDeco(u).copyWith(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: u.softBorder, width: 1.5),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: u.label),
            items: controller.expenseCategories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: TextStyle(fontSize: 12, color: u.text),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => controller.selectedCategory.value =
                v ?? controller.selectedCategory.value,
          ),
        ),
        const SizedBox(height: 14),
        _fieldLabel(u, _isSw ? 'Jina la bidhaa/kipengele' : 'Material/Item name'),
        TextFormField(
          controller: controller.materialNameController,
          style: TextStyle(color: u.text, fontSize: 14),
          decoration: _inputDeco(u, hint: _isSw ? 'Mf. Saruji' : 'Ex: Cement'),
        ),
        const SizedBox(height: 14),
        _fieldLabel(
          u,
          _isSw ? 'Maelezo (si lazima)' : 'Description (Optional)',
        ),
        TextFormField(
          controller: controller.descriptionController,
          maxLines: 3,
          style: TextStyle(color: u.text, fontSize: 14),
          decoration: _inputDeco(u, hint: _isSw ? 'Ongeza maelezo' : 'Add Details'),
        ),
        const SizedBox(height: 14),
        _fieldLabel(u, _isSw ? 'Idadi' : 'Quantity'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: TextStyle(color: u.text, fontSize: 14),
                decoration: _inputDeco(u, hint: '2'),
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 100,
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedUnit.value,
                  isExpanded: true,
                  decoration: _inputDeco(u),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: u.label,
                    size: 18,
                  ),
                  items: RentPropertyRoiEstimateFormController.unitOptions
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v,
                            style: TextStyle(fontSize: 14, color: u.text),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => controller.selectedUnit.value =
                      v ?? controller.selectedUnit.value,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _fieldLabel(u, _isSw ? 'Gharama kwa kipimo' : 'Unit Cost'),
        TextFormField(
          controller: controller.unitCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          style: TextStyle(color: u.text, fontSize: 14),
          decoration: _inputDeco(
            u,
            hint: _isSw ? 'Mf: TZS 200K' : 'Ex: TZS 200K',
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final total = controller.draftTotal.value;
          return RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.28,
                color: u.text,
              ),
              children: [
                TextSpan(
                  text: _isSw ? 'Jumla ya kipengele: ' : 'Item total Cost: ',
                ),
                TextSpan(
                  text: _formatMoney(total),
                  style: TextStyle(
                    color: u.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        _fieldLabel(
          u,
          _isSw ? 'Msambazaji (si lazima)' : 'Supplier/Vendor (Optional)',
        ),
        TextFormField(
          controller: controller.supplierController,
          style: TextStyle(color: u.text, fontSize: 14),
          decoration: _inputDeco(
            u,
            hint: _isSw ? 'Mf: Jina la muuzaji' : 'Ex: Vendor name',
          ),
        ),
        const SizedBox(height: 14),
        _fieldLabel(
          u,
          _isSw ? 'Njia ya malipo (si lazima)' : 'Payment method (optional)',
        ),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedPaymentMethod.value.isEmpty
                ? 'Cash'
                : controller.selectedPaymentMethod.value,
            isExpanded: true,
            decoration: _inputDeco(u).copyWith(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: u.softBorder, width: 1.5),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: u.label),
            items: RentPropertyRoiEstimateFormController.paymentMethodOptions
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      m,
                      style: TextStyle(fontSize: 12, color: u.text),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => controller.selectedPaymentMethod.value =
                v ?? controller.selectedPaymentMethod.value,
          ),
        ),
        const SizedBox(height: 14),
        _receiptUpload(u),
      ],
    );
  }

  Widget _dateField(
    _RoiUi u, {
    required String label,
    required DateTime? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(u, label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: u.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: u.softBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: u.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValue
                        ? DateFormat('dd MMM yyyy').format(value)
                        : placeholder,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                      color: hasValue ? u.text : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _receiptUpload(_RoiUi u) {
    return Obx(() {
      // Touch Rx so receipt path updates re-render.
      controller.entries.length;
      final path = controller.receiptPathController.text.trim();
      final hasFile = path.isNotEmpty;
      return InkWell(
        onTap: controller.pickReceipt,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: u.soft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: u.softBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: u.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 14, color: u.teal),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      hasFile
                          ? p.basename(path)
                          : (_isSw
                              ? 'Pakia risiti (si lazima)'
                              : 'Upload Receipt (Optional)'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.28,
                        color: u.text,
                      ),
                    ),
                  ),
                  if (hasFile) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: controller.clearReceipt,
                      child: Icon(Icons.close, size: 16, color: u.muted),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isSw
                    ? 'Ukubwa wa juu: 10MB (Jpg, Png, heic)'
                    : 'Maximum File Size: 10MB (Jpg,Png,heic)',
                style: TextStyle(
                  fontSize: 10,
                  color: u.muted,
                  height: 1.2,
                ),
              ),
              if (hasFile && File(path).existsSync()) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(path),
                    height: 72,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _bottomBar(_RoiUi u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: u.card,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            u.teal.withValues(alpha: 0),
            u.teal.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Obx(() {
        final approximate =
            controller.mode.value == EstimateInputMode.approximate;
        if (approximate) {
          return LoadingButton(
            label: controller.saving.value
                ? (_isSw ? 'Inahifadhi...' : 'Saving...')
                : (_isSw ? 'Hifadhi makadirio' : 'Save estimate'),
            onPressed: controller.save,
            isLoading: controller.saving.value,
          );
        }
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: controller.addItemCost,
            style: FilledButton.styleFrom(
              backgroundColor: u.teal,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text(
              _isSw ? 'Ongeza kipengele' : 'Add Cost Item',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _filters(BuildContext context, _RoiUi u) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: u.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: u.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 16, color: u.muted),
                const SizedBox(width: 6),
                Text(
                  _isSw ? 'Chuja vipengele' : 'Filter items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: u.text,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: controller.clearFilters,
                  child: Text(
                    _isSw ? 'Futa vichujio' : 'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: u.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.searchController,
              onChanged: (_) => controller.entries.refresh(),
              decoration: _inputDeco(
                u,
                hint: _isSw ? 'Tafuta bidhaa...' : 'Search materials...',
              ).copyWith(
                prefixIcon: Icon(Icons.search, size: 20, color: u.muted),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: controller.filterCategory.value,
              decoration: _inputDeco(
                u,
                hint: _isSw ? 'Aina ya gharama' : 'Category filter',
              ),
              items: controller.filterCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => controller.filterCategory.value = v ?? 'All',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => controller.pickFilterRange(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: u.teal,
                  side: BorderSide(color: u.teal.withValues(alpha: 0.5)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(
                  _isSw ? 'Chuja kwa tarehe' : 'Filter by date range',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entriesList(_RoiUi u) {
    return Obx(() {
      final rows = controller.filteredEntries;
      if (rows.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: u.soft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: u.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: u.muted, size: 20),
              const SizedBox(width: 8),
              Text(
                _isSw
                    ? 'Hakuna vipengele vilivyoongezwa bado.'
                    : 'No cost items added yet.',
                style: TextStyle(fontSize: 13, color: u.muted),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? '${rows.length} vipengele' : '${rows.length} items',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: u.muted,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(rows.length, (i) {
            final e = rows[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                color: u.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: u.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.materialName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: u.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: u.teal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            e.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: u.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${e.quantity} ${e.unit}  ×  ${_formatMoney(e.unitCost)}',
                          style: TextStyle(fontSize: 12.5, color: u.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMoney(e.totalCost),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: u.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => controller.removeEntry(i),
                        child: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: u.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _summarySection(_RoiUi u) {
    return Obx(() {
      final totals = controller.categoryTotals;
      final totalProject = controller.totalProjectCost;
      final highest = controller.highestCostCategory;

      if (totals.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: u.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_isSw
                          ? 'JUMLA YA GHARAMA ZA MRADI'
                          : 'TOTAL PROJECT COST')
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(totalProject),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isSw ? 'Mgawanyo wa gharama' : 'Cost breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: u.text,
            ),
          ),
          const SizedBox(height: 10),
          ...totals.entries.map((e) {
            final pct = controller.categoryPercent(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: u.text,
                          ),
                        ),
                      ),
                      Text(
                        _formatMoney(e.value),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: u.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, color: u.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: u.soft,
                      color: u.teal,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (highest.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: u.amberBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: u.amberText.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 18,
                    color: u.amberText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_isSw ? 'Gharama kubwa zaidi' : 'Highest cost category'}: $highest',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: u.amberText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _chartCard(
            u,
            _isSw ? 'Mgawanyo wa pai' : 'Pie breakdown',
            SizedBox(height: 220, child: _pieChart(totals)),
          ),
          const SizedBox(height: 12),
          _chartCard(
            u,
            _isSw ? 'Mchoro wa mstari' : 'Bar comparison',
            SizedBox(height: 220, child: _barChart(totals)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: controller.exportExcel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: u.text,
                      side: BorderSide(color: u.border),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: Text(
                      'Excel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: u.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: controller.exportPdf,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: u.text,
                      side: BorderSide(color: u.border),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: u.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => LoadingButton(
              label: controller.saving.value
                  ? (_isSw ? 'Inahifadhi...' : 'Saving...')
                  : (_isSw ? 'Hifadhi makadirio' : 'Save estimate'),
              onPressed: controller.save,
              isLoading: controller.saving.value,
              icon: Icons.save_outlined,
            ),
          ),
        ],
      );
    });
  }

  Widget _chartCard(_RoiUi u, String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: u.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: u.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: u.text,
            ),
          ),
          const SizedBox(height: 12),
          chart,
        ],
      ),
    );
  }

  Widget _pieChart(Map<String, double> totals) {
    final entries = totals.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final colors = [
      const Color(0xFF0EA5A4),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];
    final total = entries.fold<double>(0, (a, b) => a + b.value);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 34,
        sections: List.generate(entries.length, (i) {
          final e = entries[i];
          final pct = total <= 0 ? 0 : (e.value / total * 100);
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: e.value,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 56,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          );
        }),
      ),
    );
  }

  Widget _barChart(Map<String, double> totals) {
    final entries = totals.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 10 : maxY * 1.2,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox.shrink();
                }
                final text = entries[i].key.split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                width: 18,
                borderRadius: BorderRadius.circular(5),
                color: const Color(0xFF0EA5A4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
