import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/theme/form_surface_colors.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../controllers/monthly_income_reports_controller.dart';
import '../models/monthly_income_report_item.dart';

class MonthlyIncomeReportsView extends BaseView<MonthlyIncomeReportsController> {
  MonthlyIncomeReportsView({super.key});

  String _t({required String en, required String sw}) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(en: 'Reports', sw: 'Ripoti'),
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Obx(() {
      if (controller.isLoading.value && controller.months.isEmpty) {
        return const DefaultScreenSkeleton();
      }
      return Column(
        children: [
          _yearSelector(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshYear,
              child: controller.months.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Center(
                            child: Text(
                              _t(
                                en: 'No income recorded for this year',
                                sw: 'Hakuna mapato yaliyorekodiwa mwaka huu',
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: c.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        if (controller.featured != null) ...[
                          _FeaturedMonthCard(
                            item: controller.featured!,
                            title: controller.monthTitle(controller.featured!),
                            amount: controller.formatAmount(
                              controller.featured!.totalIncome,
                              includeCode: true,
                            ),
                            paidLabel: controller.formatAmount(
                              controller.featured!.paidAmount,
                            ),
                            upcomingLabel: controller.formatAmount(
                              controller.featured!.upcomingAmount,
                              includeCode: true,
                            ),
                            paidCaption: _t(en: 'Paid', sw: 'Imelipwa'),
                            upcomingCaption:
                                _t(en: 'Upcoming', sw: 'Inayokuja'),
                            viewLabel: _t(
                              en: 'View report',
                              sw: 'Angalia ripoti',
                            ),
                            onView: () => controller
                                .openMonthReport(controller.featured!),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _MonthGrid(
                          items: controller.gridMonths,
                          titleFor: controller.monthTitle,
                          amountFor: (item) =>
                              controller.formatAmount(item.totalIncome),
                          onTap: controller.openMonthReport,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: controller.openAnalyticsHub,
                          child: Text(
                            _t(
                              en: 'Detailed analytics',
                              sw: 'Uchambuzi wa kina',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _yearSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: controller.canGoPrevYear ? controller.prevYear : null,
              icon: const Icon(Icons.chevron_left),
              color: scheme.onSurface,
            ),
            Text(
              '${controller.selectedYear.value}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: controller.canGoNextYear ? controller.nextYear : null,
              icon: const Icon(Icons.chevron_right),
              color: scheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedMonthCard extends StatelessWidget {
  const _FeaturedMonthCard({
    required this.item,
    required this.title,
    required this.amount,
    required this.paidLabel,
    required this.upcomingLabel,
    required this.paidCaption,
    required this.upcomingCaption,
    required this.viewLabel,
    required this.onView,
  });

  final MonthlyIncomeReportItem item;
  final String title;
  final String amount;
  final String paidLabel;
  final String upcomingLabel;
  final String paidCaption;
  final String upcomingCaption;
  final String viewLabel;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = c.isDark ? scheme.primary : AppColors.colorPrimary;
    return Material(
      color: c.card,
      elevation: c.isDark ? 0 : 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: c.secondary,
                ),
              ),
              const SizedBox(height: 22),
              _MonthPerformanceBars(
                paid: item.paidAmount,
                upcoming: item.upcomingAmount,
                accent: accent,
              ),
              const SizedBox(height: 20),
              _AmountBreakdownRow(
                filled: true,
                caption: paidCaption,
                value: paidLabel,
                accent: accent,
                secondary: c.secondary,
                onSurface: scheme.onSurface,
              ),
              const SizedBox(height: 12),
              _AmountBreakdownRow(
                filled: false,
                caption: upcomingCaption,
                value: upcomingLabel,
                accent: accent,
                secondary: c.secondary,
                onSurface: scheme.onSurface,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: onView,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.isDark
                        ? scheme.surfaceContainerHighest
                        : const Color(0xFFE8E8E8),
                    foregroundColor: scheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    viewLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPerformanceBars extends StatelessWidget {
  const _MonthPerformanceBars({
    required this.paid,
    required this.upcoming,
    required this.accent,
  });

  final double paid;
  final double upcoming;
  final Color accent;

  static const double _maxHeight = 120;
  static const double _barWidth = 56;
  static const double _minVisible = 6;

  @override
  Widget build(BuildContext context) {
    final maxVal = [paid, upcoming, 1.0].reduce((a, b) => a > b ? a : b);
    final paidH = paid <= 0
        ? _minVisible
        : (_minVisible + (paid / maxVal) * (_maxHeight - _minVisible))
            .clamp(_minVisible, _maxHeight);
    final upcomingH = upcoming <= 0
        ? _minVisible
        : (_minVisible + (upcoming / maxVal) * (_maxHeight - _minVisible))
            .clamp(_minVisible, _maxHeight);
    final lightAccent = Color.lerp(accent, Colors.white, 0.72) ??
        accent.withValues(alpha: 0.28);

    return SizedBox(
      height: _maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PerformanceBar(
            height: paidH,
            width: _barWidth,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(accent, Colors.white, 0.25) ?? accent,
                accent,
                Color.lerp(accent, Colors.black, 0.18) ?? accent,
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PerformanceBar(
            height: upcomingH,
            width: _barWidth * 0.55,
            color: lightAccent,
          ),
        ],
      ),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  const _PerformanceBar({
    required this.height,
    required this.width,
    this.color,
    this.gradient,
  });

  final double height;
  final double width;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _AmountBreakdownRow extends StatelessWidget {
  const _AmountBreakdownRow({
    required this.filled,
    required this.caption,
    required this.value,
    required this.accent,
    required this.secondary,
    required this.onSurface,
  });

  final bool filled;
  final String caption;
  final String value;
  final Color accent;
  final Color secondary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? accent : Colors.transparent,
            border: Border.all(color: accent, width: 2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            caption,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: secondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.items,
    required this.titleFor,
    required this.amountFor,
    required this.onTap,
  });

  final List<MonthlyIncomeReportItem> items;
  final String Function(MonthlyIncomeReportItem) titleFor;
  final String Function(MonthlyIncomeReportItem) amountFor;
  final ValueChanged<MonthlyIncomeReportItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _MonthTile(
          title: titleFor(item),
          amount: amountFor(item),
          onTap: () => onTap(item),
        );
      },
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.title,
    required this.amount,
    required this.onTap,
  });

  final String title;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: c.card,
      elevation: c.isDark ? 0 : 1.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppValues.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
