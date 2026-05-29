import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';
import '../../../core/theme/form_surface_colors.dart';

import 'package:paa_yangu/app/core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
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

  

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return CustomAppBar(
      appBarTitleText: appLocalization.expenseAnalysis,
      isCentered: true,
      actions: [
        IconButton(
          onPressed: controller.openMoreOptions,
          icon: const Icon(Icons.more_vert),
          color: c.isDark ? Colors.white : AppColors.appBarIconColor,
        ),
      ],
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
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
    });
  }

  List<Color> _chartColors(int count) {
    final palette = <Color>[
      _expenseChartCyan,
      _expenseChartPurple,
      _expenseChartGreen,
      _expenseChartOrange,
      Colors.indigo,
      Colors.teal,
    ];
    if (count <= palette.length) return palette;
    return List<Color>.generate(count, (i) => palette[i % palette.length]);
  }

  Widget _emptyStateCard(BuildContext context, {required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).inputFill,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: context.tokens.textSecondary,
        ),
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
    final colors = _chartColors(categories.length);
    final hasData = categories.isNotEmpty;

    final sections = hasData
        ? categories.asMap().entries.map((e) {
            final c = e.value;
            return PieChartSectionData(
              value: c.value,
              color: colors[c.colorIndex % colors.length],
              radius: 48,
              showTitle: false,
            );
          }).toList()
        : [
            PieChartSectionData(
              value: 1,
              color: Colors.grey.withValues(alpha: 0.3),
              radius: 48,
              showTitle: false,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FormSurfaceColors.of(context).isDark
            ? const Color(0xFF1F1F1F)
            : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: FormSurfaceColors.of(context).isDark ? 0.28 : 0.06,
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
                        color: context.tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.totalAmountLabel.value,
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
          if (hasData)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: categories.map((c) {
                return _LegendDot(colors[c.colorIndex % colors.length], c.name);
              }).toList(),
            )
          else
            Text(
              _t(context, en: 'No expenses in selected period', sw: 'Hakuna matumizi kwa kipindi hiki'),
              style: TextStyle(
                fontSize: 13,
                color: context.tokens.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopExpenses(BuildContext context) {
    if (controller.loading.value) {
      return const DefaultScreenSkeleton();
    }
    if (controller.topExpenses.isEmpty) {
      return _emptyStateCard(
        context,
        message: _t(
          context,
          en: 'No expense records available yet.',
          sw: 'Bado hakuna rekodi za matumizi.',
        ),
      );
    }
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
            .take(3)
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
    final c = FormSurfaceColors.of(context);
    return Material(
      color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
      borderRadius: BorderRadius.circular(AppValues.radius_6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius_6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radius_6),
            border: Border.all(
              color: c.isDark
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
                color: c.secondary,
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
            color: context.tokens.textSecondary,
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
    final c = FormSurfaceColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1F1F1F) : AppColors.colorWhite,
        borderRadius: BorderRadius.circular(AppValues.radius_12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.28 : 0.06),
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
                        color: c.isDark
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
              color: c.secondary,
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
              color: c.secondary,
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
