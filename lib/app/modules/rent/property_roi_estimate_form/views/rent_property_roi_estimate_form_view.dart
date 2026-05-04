import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/app/core/base/base_view.dart';
import '/app/core/utils/thousand_separator.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_property_roi_estimate_form_controller.dart';

class RentPropertyRoiEstimateFormView
    extends BaseView<RentPropertyRoiEstimateFormController> {
  RentPropertyRoiEstimateFormView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';
  static final _money = NumberFormat('#,###', 'en_US');

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Makadirio' : 'Estimates');

  @override
  Widget body(BuildContext context) {
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSw
                      ? 'Ongeza makadirio ya gharama za mjengo na mgawanyo wa matumizi'
                      : 'Add Estimates of property costs & Expense Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isSw
                      ? 'Makadirio haya yatatumika kupima faida ya uwekezaji na kufuatilia hela ya uwekezaji kurudi.'
                      : 'This estimate will be used to determine return on investment and track break even.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => SegmentedButton<EstimateInputMode>(
                    segments: [
                      ButtonSegment(
                        value: EstimateInputMode.approximate,
                        label: Text(_isSw ? 'Makisio ya jumla' : 'Approximate total', style: const TextStyle(fontSize: 14)),
                        icon: const Icon(Icons.functions),
                      ),
                      ButtonSegment(
                        value: EstimateInputMode.itemized,
                        label: Text(_isSw ? 'Gharama za vipengele' : 'Individual items', style: const TextStyle(fontSize: 14),),
                        icon: const Icon(Icons.list_alt_outlined),
                      ),
                    ],
                    selected: {controller.mode.value},
                    onSelectionChanged: (v) => controller.setMode(v.first),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => controller.mode.value == EstimateInputMode.approximate
                      ? _approximateSection()
                      : _itemizedSection(context),
                ),
                // const SizedBox(height: 14),
                // _field(
                //   _isSw ? 'Mapato ya mwezi yanayotarajiwa' : 'Expected Monthly Income',
                //   controller.expectedMonthlyIncomeController,
                // ),
                // _field(
                //   _isSw ? 'Matumizi ya mwezi yanayotarajiwa' : 'Expected Monthly Expense',
                //   controller.expectedMonthlyExpenseController,
                // ),
                // _field(
                //   _isSw ? 'Lengo la ukaaji (%)' : 'Target Occupancy (%)',
                //   controller.targetOccupancyController,
                //   validator: controller.validatePercent,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
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
        inputFormatters: [
          ThousandsSeparatorInputFormatter(),
        ],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
        ),
      ),
    );
  }

  Widget _approximateSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field(
          _isSw ? 'Makadirio ya jumla ya gharama za mali' : 'Approximate estimate of whole property',
          controller.approximateTotalController,
          validator: controller.validateRequiredAmount,
          prefixText: 'Tshs ',
        ),
        const SizedBox(height: 14),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.saving.value ? null : controller.save,
              child: Text(
                controller.saving.value
                    ? (_isSw ? 'Inahifadhi...' : 'Saving...')
                    : (_isSw ? 'Hifadhi makadirio' : 'Save estimate'),
                style: TextStyle(
                    fontSize: 16
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemizedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSw
              ? 'Ongeza gharama za kila kipengele kuanzia mwanzo hadi mwisho wa mradi.'
              : 'Add individual costs from start to finish property.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _dateTile(
                  label: _isSw ? 'Start Date' : 'Start Date',
                  value: controller.startDate.value,
                  onTap: () => controller.pickStartDate(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateTile(
                  label: _isSw ? 'Completion Date' : 'Completion Date',
                  value: controller.completionDate.value,
                  onTap: () => controller.pickCompletionDate(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedCategory.value,
            items: controller.expenseCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => controller.selectedCategory.value = v ?? controller.selectedCategory.value,
            decoration: InputDecoration(
              labelText: _isSw ? 'Expense Category' : 'Expense Category',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _field(_isSw ? 'Material/Item Name' : 'Material/Item Name', controller.materialNameController),
        _textField(_isSw ? 'Description (optional)' : 'Description (optional)', controller.descriptionController),
        Row(
          children: [
            Expanded(
              child: _field(
                _isSw ? 'Quantity' : 'Quantity',
                controller.quantityController,
                validator: controller.validateRequiredAmount,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedUnit.value,
                  items: RentPropertyRoiEstimateFormController.unitOptions
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => controller.selectedUnit.value = v ?? controller.selectedUnit.value,
                  decoration: InputDecoration(
                    labelText: _isSw ? 'Unit' : 'Unit',
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3),
                  ),
                ),
              ),
            ),
          ],
        ),
        _field(
          _isSw ? 'Unit Cost' : 'Unit Cost',
          controller.unitCostController,
          validator: controller.validateRequiredAmount,
        ),
        // Obx(
        //   () =>
              Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_isSw ? 'Total Cost' : 'Total Cost'}: TZS ${_money.format(controller.draftTotalCost.round())}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        // ),
        _textField(_isSw ? 'Supplier/Vendor (optional)' : 'Supplier/Vendor (optional)', controller.supplierController),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedPaymentMethod.value,
            items: RentPropertyRoiEstimateFormController.paymentMethodOptions
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => controller.selectedPaymentMethod.value = v ?? controller.selectedPaymentMethod.value,
            decoration: InputDecoration(
              labelText: _isSw ? 'Payment Method (optional)' : 'Payment Method (optional)',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _textField(_isSw ? 'Receipt Upload (optional)' : 'Receipt Upload (optional)', controller.receiptPathController),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.addItemCost,
            icon: const Icon(Icons.add),
            label: Text(
              _isSw ? 'Ongeza kipengele' : 'Add item cost',
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14)
            ),
          ),
        ),
        const SizedBox(height: 16),
        _filters(context),
        const SizedBox(height: 10),
        _entriesList(),
        const SizedBox(height: 10),
        _summarySection(),
      ],
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF3F3F3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value == null ? '-' : DateFormat('dd MMM yyyy').format(value)),
          ],
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: const Color(0xFFF3F3F3)),
      ),
    );
  }

  Widget _filters(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller.searchController,
            onChanged: (_) => controller.entries.refresh(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: _isSw ? 'Search materials' : 'Search materials',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: controller.filterCategory.value,
            items: controller.filterCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => controller.filterCategory.value = v ?? 'All',
            decoration: InputDecoration(
              labelText: _isSw ? 'Category filter' : 'Category filter',
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.pickFilterRange(context),
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(
                      _isSw ? 'Date filter' : 'Date filter',
                      style: const TextStyle(fontSize: 14)
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: controller.clearFilters,
                child: Text(
                    _isSw ? 'Clear filters' : 'Clear filters',
                    style: const TextStyle(fontSize: 14)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entriesList() {
    return Obx(() {
      final rows = controller.filteredEntries;
      if (rows.isEmpty) {
        return Text(
          _isSw ? 'Hakuna vipengele vilivyoongezwa.' : 'No item costs added yet.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        );
      }
      return Column(
        children: List.generate(rows.length, (i) {
          final e = rows[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF9F9F9),
              border: Border.all(color: const Color(0xFFE3E3E3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.materialName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(e.category, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(
                        '${e.quantity} ${e.unit} x ${_money.format(e.unitCost.round())} = ${_money.format(e.totalCost.round())}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.removeEntry(i),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _summarySection() {
    return Obx(() {
      final totals = controller.categoryTotals;
      final totalProject = controller.totalProjectCost;
      final highest = controller.highestCostCategory;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSw ? 'Muhtasari wa gharama' : 'Summary',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...totals.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    Text('${_money.format(e.value.round())} (${controller.categoryPercent(e.key).toStringAsFixed(1)}%)'),
                  ],
                ),
              )),
          if (highest.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_isSw ? 'Kundi lenye gharama kubwa zaidi' : 'Highest Cost Category'}: $highest',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${_isSw ? 'Jumla ya gharama za mradi' : 'Total Project Cost'}: TZS ${_money.format(totalProject.round())}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: _pieChart(totals)),
          const SizedBox(height: 10),
          SizedBox(height: 220, child: _barChart(totals)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.exportExcel,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text(
                    'Export Excel',
                    style: TextStyle(fontSize: 14)
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text(
                    'Export PDF',
                    style: TextStyle(fontSize: 14)
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
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
