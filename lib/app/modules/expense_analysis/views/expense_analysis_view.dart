import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/expense_analysis_controller.dart';

const _expenseChartCyan = Color(0xFF00BCD4);
const _expenseChartPurple = Color(0xFF9C27B0);
const _expenseChartGreen = Color(0xFF4CAF50);
const _expenseChartOrange = Color(0xFFFF9800);
const _expenseAnalysisBlue = Color(0xFF2196F3);

class ExpenseAnalysisView extends BaseView<ExpenseAnalysisController> {
  ExpenseAnalysisView({super.key});

  String _t(BuildContext context, {required String en, required String sw}) {
    return Get.locale?.languageCode == 'sw' ? sw : en;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.expenseAnalysis,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(Routes.SETTINGS),
          icon: const Icon(Icons.more_vert_outlined),
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(context),
          const SizedBox(height: 24),
          _buildDonutChart(context),
          const SizedBox(height: 24),
          _buildTopExpenses(context),
          const SizedBox(height: 16),
          _buildDownloadButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget? floatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: controller.goToAddExpense,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        _t(Get.context!, en: 'Add Expense', sw: 'Ongeza Matumizi'),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: controller.selectedProperty.value,
            icon: Icons.keyboard_arrow_down,
            onTap: controller.selectPropertyFilter,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterChip(
            label: controller.dateRangeLabel.value,
            icon: Icons.calendar_today_outlined,
            onTap: controller.selectDateRange,
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart(BuildContext context) {
    final categories = controller.expenseCategories;
    final colors = [
      _expenseChartCyan,
      _expenseChartPurple,
      _expenseChartGreen,
      _expenseChartOrange,
    ];

    final sections = categories.asMap().entries.map((e) {
      final c = e.value;
      return PieChartSectionData(
        value: c.value,
        color: colors[c.colorIndex % colors.length],
        radius: 48,
        showTitle: false,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark(context)
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _isDark(context) ? 0.28 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 56,
                    sectionsSpace: 2,
                  ),
                  duration: const Duration(milliseconds: 150),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(context, en: 'TOTAL', sw: 'JUMLA'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: _isDark(context)
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ExpenseAnalysisController.totalAmount,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendDot(
                _expenseChartCyan,
                _t(context, en: 'Maintenance', sw: 'Matengenezo'),
              ),
              _LegendDot(
                _expenseChartPurple,
                _t(context, en: 'Utilities', sw: 'Huduma'),
              ),
              _LegendDot(
                _expenseChartGreen,
                _t(context, en: 'Staffing', sw: 'Wafanyakazi'),
              ),
              _LegendDot(
                _expenseChartOrange,
                _t(context, en: 'Supplies', sw: 'Vifaa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpenses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t(context, en: 'Top Expenses', sw: 'Matumizi Makuu'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: controller.viewAllExpenses,
              child: Text(
                _t(context, en: 'View All', sw: 'Ona Yote'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _expenseAnalysisBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...controller.topExpenses
            .take(2)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TopExpenseCard(item: e),
              ),
            ),
      ],
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.downloadReport,
        icon: const Icon(Icons.download_rounded, size: 22),
        label: Text(
          _t(
            context,
            en: 'Download Detailed Report',
            sw: 'Pakua Ripoti ya Kina',
          ),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radius_12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.designInputBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white70 : AppColors.textColorSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textColorSecondary,
          ),
        ),
      ],
    );
  }
}

class _TopExpenseCard extends StatelessWidget {
  final TopExpenseItem item;

  const _TopExpenseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _expenseChartCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 22, color: _expenseChartCyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.changeUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: AppColors.colorSuccessGreen,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.changePercent,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.colorSuccessGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Get.locale?.languageCode == 'sw' ? 'MWEZI HUU' : 'THIS MO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.thisMonthRatio,
              minHeight: 6,
              backgroundColor: AppColors.lightGreyColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                _expenseChartCyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Get.locale?.languageCode == 'sw' ? 'MWEZI ULIOPITA' : 'LAST MO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.lastMonthRatio,
              minHeight: 6,
              backgroundColor: AppColors.lightGreyColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.textColorSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
