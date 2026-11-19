import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/base/base_view.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/skeleton_presets.dart';
import '../../../data/local/service/currency_service.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/finance_dashboard_widgets.dart';

class DashboardView extends BaseView<DashboardController> {
  DashboardView({super.key});

  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsSw = [
    'Januari',
    'Februari',
    'Machi',
    'Aprili',
    'Mei',
    'Juni',
    'Julai',
    'Agosti',
    'Septemba',
    'Oktoba',
    'Novemba',
    'Desemba',
  ];
  static const _shortEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _shortSw = [
    'Jan',
    'Feb',
    'Mac',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  bool _sw(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'sw';

  String _t(BuildContext context, String en, String sw) =>
      _sw(context) ? sw : en;

  String _month(BuildContext context, DateTime d) =>
      (_sw(context) ? _monthsSw : _monthsEn)[d.month - 1];

  String _short(BuildContext context, DateTime d) =>
      (_sw(context) ? _shortSw : _shortEn)[d.month - 1];

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: appLocalization.dashboard,
      isCentered: true,
    );
  }

  @override
  Widget body(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        final showSkeleton =
            controller.isLoading.value && !controller.hasLoadedOnce.value;
        if (showSkeleton) {
          return const DefaultScreenSkeleton();
        }
        return Column(
          children: [
            if (controller.refreshing.value)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: _content(context),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _content(BuildContext context) {
    final cs = Get.find<CurrencyService>();
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);

    final net = controller.monthNetValue.value;
    final income = controller.monthIncomeValue.value;
    final expenses = controller.monthExpenseValue.value;
    final daysElapsed = now.day;
    final perDay = daysElapsed > 0 ? income / daysElapsed : 0.0;
    final monthly = controller.trendMonthly.value;

    final monthName = _month(context, now);
    final period = '$monthName ${now.year}';

    final firstOfSpan = DateTime(now.year, now.month - 4, 1);
    final monthlySub = firstOfSpan.year == now.year
        ? '${_month(context, firstOfSpan)} ${_t(context, 'to', 'hadi')} '
              '$monthName ${now.year}'
        : '${_month(context, firstOfSpan)} ${firstOfSpan.year} '
              '${_t(context, 'to', 'hadi')} $monthName ${now.year}';

    final weekLabel = _t(context, 'Week', 'Wiki');
    final trendPanel = IncomeTrendPanel(
      title: _t(context, 'Income trend', 'Mwenendo wa mapato'),
      subtitle: monthly
          ? monthlySub
          : _t(
              context,
              '$monthName compared with ${_month(context, prev)}',
              '$monthName ikilinganishwa na ${_month(context, prev)}',
            ),
      weeklyTab: _t(context, 'By week', 'Kwa wiki'),
      monthlyTab: _t(context, 'By month', 'Kwa mwezi'),
      monthly: monthly,
      onSelect: (v) => controller.trendMonthly.value = v,
      current: monthly
          ? controller.monthlyValuesA.toList()
          : controller.weeklyIncomeCurrent.toList(),
      previous: monthly ? null : controller.weeklyIncomePrevious.toList(),
      labels: monthly
          ? [
              for (var i = 4; i >= 0; i--)
                _short(context, DateTime(now.year, now.month - i, 1)),
            ]
          : [for (var i = 1; i <= 4; i++) '$weekLabel $i'],
      currentLegend: monthly
          ? _t(context, 'Monthly income', 'Mapato ya mwezi')
          : monthName,
      previousLegend: monthly ? null : _month(context, prev),
    );

    final summaryPanel = MonthSummaryPanel(
      title: _t(context, 'Month summary', 'Muhtasari wa mwezi'),
      totalLabel: _t(context, 'Total income', 'Jumla ya mapato'),
      totalValue: cs.formatBase(income.round()),
      avgLabel: _t(context, 'Average per day', 'Wastani kwa siku'),
      avgValue: cs.formatBase(perDay.round()),
      note: _t(
        context,
        'Average over $daysElapsed days of $monthName.',
        'Wastani wa siku $daysElapsed za $monthName.',
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinanceHeading(
              title: _t(context, 'Finance dashboard', 'Dashibodi ya fedha'),
              intro: _t(
                context,
                'Your income, expenses and profit for this month.',
                'Mapato, matumizi na faida yako kwa mwezi huu.',
              ),
            ),
            const SizedBox(height: 18),
            FinanceHeroCard(
              period: period,
              profitLabel: _t(context, 'Net profit', 'Faida halisi'),
              currency: CurrencyService.symbolFor(cs.baseCurrency.value).trim(),
              profitAmount:
                  '${net < 0 ? '-' : ''}${cs.formatNumber(net.abs().round())}',
              incomeLabel: _t(context, 'Income', 'Mapato'),
              incomeValue: cs.formatBase(income.round()),
              expenseLabel: _t(context, 'Expenses', 'Matumizi'),
              expenseValue: cs.formatBase(expenses.round()),
            ),
            const SizedBox(height: 12),
            FinanceActions(
              addIncomeLabel: _t(context, 'Add income', 'Ongeza mapato'),
              addExpenseLabel: _t(context, 'Add expense', 'Ingiza gharama'),
              onAddIncome: controller.openAddIncome,
              onAddExpense: controller.openAddExpense,
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 12, child: trendPanel),
                  const SizedBox(width: 20),
                  Expanded(flex: 10, child: summaryPanel),
                ],
              )
            else ...[
              trendPanel,
              const SizedBox(height: 16),
              summaryPanel,
            ],
          ],
        );
      },
    );
  }
}
