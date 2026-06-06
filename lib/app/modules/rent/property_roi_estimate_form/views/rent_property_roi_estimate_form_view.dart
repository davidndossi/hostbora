import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/app/core/base/rent_base_view.dart';
import '/app/core/utils/thousand_separator.dart';
import '/app/core/widget/loading_button.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_estimate_form_controller.dart';

class _RoiUi {
  _RoiUi(this.context);

  final BuildContext context;

  ThemeData get _t => Theme.of(context);
  bool get dark => _t.brightness == Brightness.dark;

  Color get text => _t.colorScheme.onSurface;
  Color get muted => _t.hintColor;
  Color get card => _t.cardColor;
  Color get border =>
      dark ? const Color(0xFF4A4A4C) : const Color(0xFFE0E0E0);
  Color get inputFill =>
      dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2);
  Color get soft =>
      dark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F5);
  Color get teal =>
      dark ? const Color(0xFF4DB6AC) : const Color(0xFF0A5C5C);
  Color get greenBg =>
      dark ? const Color(0xFF1A2E2A) : const Color(0xFFECFDF5);
  Color get greenText =>
      dark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
  Color get amberBg =>
      dark ? const Color(0xFF2C2210) : const Color(0xFFFFFBEB);
  Color get amberText =>
      dark ? const Color(0xFFFCD34D) : const Color(0xFF78350F);

  InputDecoration fieldDeco({
    String? label,
    String? hint,
    String? prefix,
    Widget? prefixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      );
}

class RentPropertyRoiEstimateFormView
    extends RentBaseView<RentPropertyRoiEstimateFormController> {
  RentPropertyRoiEstimateFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';
  static final _money = NumberFormat('#,###', 'en_US');

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Makadirio' : 'Estimates');

  @override
  Widget body(BuildContext context) {
    final u = _RoiUi(context);
    return Form(
      key: controller.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          rentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Text(
                  controller.propertyLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: u.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSw
                      ? 'Ongeza makadirio ya gharama za mjengo na mgawanyo wa matumizi'
                      : 'Add Estimates of property costs & Expense Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, color: u.text),
                ),
                const SizedBox(height: 14),
                Text(
                  _isSw
                      ? 'Makadirio haya yatatumika kupima faida ya uwekezaji na kufuatilia hela ya uwekezaji kurudi.'
                      : 'This estimate will be used to determine return on investment and track break even.',
                  style: TextStyle(fontSize: 12, color: u.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Center(
                    child: SegmentedButton<EstimateInputMode>(
                      segments: [
                        ButtonSegment(
                          value: EstimateInputMode.approximate,
                          label: Text(
                            _isSw ? 'Makisio ya jumla' : 'Approximate total',
                            style: const TextStyle(fontSize: 13),
                          ),
                          icon: const Icon(Icons.functions, size: 18),
                        ),
                        ButtonSegment(
                          value: EstimateInputMode.itemized,
                          label: Text(
                            _isSw ? 'Gharama za vipengele' : 'Individual items',
                            style: const TextStyle(fontSize: 13),
                          ),
                          icon: const Icon(Icons.list_alt_outlined, size: 18),
                        ),
                      ],
                      selected: {controller.mode.value},
                      onSelectionChanged: (v) => controller.setMode(v.first),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => controller.mode.value == EstimateInputMode.approximate
                      ? _approximateSection(u)
                      : _itemizedSection(context, u),
                ),
                const SizedBox(height: 14),
                _field(u, _isSw ? 'Mapato ya mwezi yanayotarajiwa' : 'Expected Monthly Income', controller.expectedMonthlyIncomeController),
                const SizedBox(height: 10),
                _field(u, _isSw ? 'Matengenezo / matumizi ya mwezi (makadirio)' : 'Expected Monthly Maintenance / Expense', controller.expectedMonthlyExpenseController),
                const SizedBox(height: 10),
                _field(u, _isSw ? 'Lengo la ukaaji (%)' : 'Target Occupancy (%)', controller.targetOccupancyController, validator: controller.validatePercent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    _RoiUi u,
    String label,
    TextEditingController textController, {
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: textController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ThousandsSeparatorInputFormatter()],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: u.fieldDeco(label: label, prefix: prefixText),
      ),
    );
  }

  Widget _approximateSection(_RoiUi u) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field(
          u,
          _isSw ? 'Makadirio ya jumla ya gharama za mali' : 'Approximate estimate of whole property',
          controller.approximateTotalController,
          validator: controller.validateRequiredAmount,
          prefixText: 'Tshs ',
        ),
        const SizedBox(height: 14),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: LoadingButton(
              label: controller.saving.value
                  ? (_isSw ? 'Inahifadhi...' : 'Saving...')
                  : (_isSw ? 'Hifadhi makadirio' : 'Save estimate'),
              onPressed: controller.save,
              isLoading: controller.saving.value,
              icon: Icons.save_outlined,
            ),
          ),
        ),
      ],
    );
  }

  // ── shared section header ─────────────────────────────────────────────────
  Widget _sectionLabel(_RoiUi u, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: u.muted,
          ),
        ),
      );

  Widget _itemizedSection(BuildContext context, _RoiUi u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Intro ────────────────────────────────────────────────────────
        Text(
          _isSw
              ? 'Ongeza gharama za kila kipengele kuanzia mwanzo hadi mwisho wa mradi.'
              : 'Add individual costs from start to finish of the project.',
          style: TextStyle(fontSize: 12.5, color: u.muted, height: 1.4),
        ),
        const SizedBox(height: 16),

        // ── Project dates ────────────────────────────────────────────────
        _sectionLabel(u, _isSw ? 'Muda wa mradi' : 'Project timeline'),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _dateTile(
                  u,
                  label: _isSw ? 'Tarehe ya kuanza' : 'Start date',
                  value: controller.startDate.value,
                  onTap: () => controller.pickStartDate(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTile(
                  u,
                  label: _isSw ? 'Tarehe ya kukamilika' : 'Completion date',
                  value: controller.completionDate.value,
                  onTap: () => controller.pickCompletionDate(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Item entry form card ─────────────────────────────────────────
        _sectionLabel(u, _isSw ? 'Ongeza kipengele' : 'Add cost item'),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: u.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: u.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedCategory.value,
                  decoration: u.fieldDeco(
                    label: _isSw ? 'Aina ya gharama' : 'Expense category',
                  ),
                  items: controller.expenseCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => controller.selectedCategory.value =
                      v ?? controller.selectedCategory.value,
                ),
              ),
              const SizedBox(height: 16),

              // Material name
              TextFormField(
                controller: controller.materialNameController,
                decoration: u.fieldDeco(
                  label: _isSw ? 'Jina la bidhaa/kipengele' : 'Material / item name',
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 2,
                decoration: u.fieldDeco(
                  label: _isSw ? 'Maelezo (si lazima)' : 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Quantity + Unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: controller.quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      validator: controller.validateRequiredAmount,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: u.fieldDeco(
                        label: _isSw ? 'Idadi' : 'Quantity',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.selectedUnit.value,
                        decoration: u.fieldDeco(
                          label: _isSw ? 'Kipimo' : 'Unit',
                        ),
                        items: RentPropertyRoiEstimateFormController.unitOptions
                            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => controller.selectedUnit.value =
                            v ?? controller.selectedUnit.value,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unit cost
              TextFormField(
                controller: controller.unitCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: controller.validateRequiredAmount,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: u.fieldDeco(
                  label: _isSw ? 'Gharama kwa kipimo' : 'Unit cost',
                  prefix: 'TZS ',
                ),
              ),
              const SizedBox(height: 20),

              // Total cost preview — reactive
              Obx(
                () {
                  final total = controller.draftTotal.value;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: u.greenBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: u.greenText.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 16,
                          color: u.greenText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSw ? 'Jumla ya kipengele: ' : 'Item total: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: u.greenText,
                          ),
                        ),
                        Text(
                          'TZS ${_money.format(total.round())}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: u.greenText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Supplier
              TextFormField(
                controller: controller.supplierController,
                decoration: u.fieldDeco(
                  label: _isSw ? 'Msambazaji (si lazima)' : 'Supplier / vendor (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Payment method
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedPaymentMethod.value,
                  decoration: u.fieldDeco(
                    label: _isSw ? 'Njia ya malipo (si lazima)' : 'Payment method (optional)',
                  ),
                  items: RentPropertyRoiEstimateFormController.paymentMethodOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => controller.selectedPaymentMethod.value =
                      v ?? controller.selectedPaymentMethod.value,
                ),
              ),
              const SizedBox(height: 16),

              // Receipt
              TextFormField(
                controller: controller.receiptPathController,
                decoration: u.fieldDeco(
                  label: _isSw ? 'Risiti (si lazima)' : 'Receipt upload (optional)',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Add item button ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: controller.addItemCost,
            style: FilledButton.styleFrom(
              backgroundColor: u.teal,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              _isSw ? 'Ongeza kipengele' : 'Add cost item',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // ── Filters ───────────────────────────────────────────────────────
        _filters(context, u),
        const SizedBox(height: 12),

        // ── Entries list ──────────────────────────────────────────────────
        _entriesList(u),
        const SizedBox(height: 16),

        // ── Summary ───────────────────────────────────────────────────────
        _summarySection(u),
      ],
    );
  }

  Widget _dateTile(
    _RoiUi u, {
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: u.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: u.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasValue ? u.teal : u.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: u.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue
                        ? DateFormat('dd MMM yyyy').format(value)
                        : (_isSw ? 'Chagua tarehe' : 'Select date'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: hasValue ? u.text : u.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: u.muted, size: 20),
          ],
        ),
      ),
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
              decoration: u.fieldDeco(
                hint: _isSw ? 'Tafuta bidhaa...' : 'Search materials...',
                prefixIcon: Icon(Icons.search, size: 20, color: u.muted),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: controller.filterCategory.value,
              decoration: u.fieldDeco(
                label: _isSw ? 'Aina ya gharama' : 'Category filter',
              ),
              items: controller.filterCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => controller.filterCategory.value = v ?? 'All',
            ),
            const SizedBox(height: 16),
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                          '${e.quantity} ${e.unit}  ×  TZS ${_money.format(e.unitCost.round())}',
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
                        'TZS ${_money.format(e.totalCost.round())}',
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
          // ── Total project cost hero ─────────────────────────────────
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
                  'TZS ${_money.format(totalProject.round())}',
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

          // ── Category breakdown ──────────────────────────────────────
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
                        'TZS ${_money.format(e.value.round())}',
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

          // ── Highest cost callout ────────────────────────────────────
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

          // ── Charts ──────────────────────────────────────────────────
          _chartCard(u, _isSw ? 'Mgawanyo wa pai' : 'Pie breakdown', SizedBox(height: 220, child: _pieChart(totals))),
          const SizedBox(height: 12),
          _chartCard(u, _isSw ? 'Mchoro wa mstari' : 'Bar comparison', SizedBox(height: 220, child: _barChart(totals))),

          const SizedBox(height: 16),

          // ── Export buttons ──────────────────────────────────────────
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

          // ── Save estimate ───────────────────────────────────────────
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: LoadingButton(
                label: controller.saving.value
                    ? (_isSw ? 'Inahifadhi...' : 'Saving...')
                    : (_isSw ? 'Hifadhi makadirio' : 'Save estimate'),
                onPressed: controller.save,
                isLoading: controller.saving.value,
                icon: Icons.save_outlined,
              ),
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
          final p = total <= 0 ? 0 : (e.value / total * 100);
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: e.value,
            title: '${p.toStringAsFixed(0)}%',
            radius: 56,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
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
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
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
