import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Colors from the "Fedha" dashboard design (light and night variants).
class FinancePalette {
  const FinancePalette({
    required this.panel,
    required this.page,
    required this.text,
    required this.sub,
    required this.edge,
    required this.mint,
    required this.soft,
    required this.night,
  });

  final Color panel;
  final Color page;
  final Color text;
  final Color sub;
  final Color edge;
  final Color mint;
  final Color soft;
  final bool night;

  static const _light = FinancePalette(
    panel: Colors.white,
    page: Color(0xFFF7F9F8),
    text: Color(0xFF233D38),
    sub: Color(0xFF60716B),
    edge: Color(0xFFE8EEEB),
    mint: Color(0xFF207568),
    soft: Color(0xFFEDF5F1),
    night: false,
  );

  static const _night = FinancePalette(
    panel: Color(0xFF192C27),
    page: Color(0xFF10211D),
    text: Color(0xFFE2EEE8),
    sub: Color(0xFF9CAFA6),
    edge: Color(0xFF2D4239),
    mint: Color(0xFF72BBAA),
    soft: Color(0xFF233D33),
    night: true,
  );

  static FinancePalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _night : _light;
}

/// Page heading and one-line intro.
class FinanceHeading extends StatelessWidget {
  const FinanceHeading({super.key, required this.title, required this.intro});

  final String title;
  final String intro;

  @override
  Widget build(BuildContext context) {
    final p = FinancePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: -1.15,
            color: p.text,
          ),
        ),
        const SizedBox(height: 5),
        Text(intro, style: TextStyle(fontSize: 13, color: p.sub)),
      ],
    );
  }
}

/// Net profit hero with the income / expenses split underneath.
class FinanceHeroCard extends StatelessWidget {
  const FinanceHeroCard({
    super.key,
    required this.period,
    required this.profitLabel,
    required this.currency,
    required this.profitAmount,
    required this.incomeLabel,
    required this.incomeValue,
    required this.expenseLabel,
    required this.expenseValue,
  });

  final String period;
  final String profitLabel;
  final String currency;
  final String profitAmount;
  final String incomeLabel;
  final String incomeValue;
  final String expenseLabel;
  final String expenseValue;

  static const _hero = Color(0xFF1D6C60);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _hero,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10164F40),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.4, 2.2),
            radius: 1.7,
            colors: [Color(0xFF388676), Color(0x00388676)],
            stops: [0, 0.65],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: Color(0xFFDFEFE3),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    profitLabel,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$currency ',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              color: Color(0xFFDDF0E5),
                            ),
                          ),
                          TextSpan(text: profitAmount),
                        ],
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                        letterSpacing: -1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: const BoxDecoration(
                color: Color(0x660B473B),
                border: Border(top: BorderSide(color: Color(0x24FFFFFF))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SplitCell(
                      icon: Icons.north_east_rounded,
                      label: incomeLabel,
                      value: incomeValue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0x38FFFFFF)),
                        ),
                      ),
                      child: _SplitCell(
                        icon: Icons.south_east_rounded,
                        label: expenseLabel,
                        value: expenseValue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitCell extends StatelessWidget {
  const _SplitCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFFE1EEE6)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE1EEE6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Add income (filled) and add expense (outlined).
class FinanceActions extends StatelessWidget {
  const FinanceActions({
    super.key,
    required this.addIncomeLabel,
    required this.addExpenseLabel,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  final String addIncomeLabel;
  final String addExpenseLabel;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final p = FinancePalette.of(context);
    Widget button({
      required String label,
      required VoidCallback onTap,
      required bool filled,
    }) {
      return Expanded(
        child: Material(
          color: filled ? p.mint : p.panel,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: filled ? Colors.transparent : p.edge),
              ),
              child: Text(
                '＋ $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? p.panel : p.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        button(label: addIncomeLabel, onTap: onAddIncome, filled: true),
        const SizedBox(width: 10),
        button(label: addExpenseLabel, onTap: onAddExpense, filled: false),
      ],
    );
  }
}

/// White bordered card used by the lower panels.
class FinancePanel extends StatelessWidget {
  const FinancePanel({super.key, required this.child, this.padding = 18});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final p = FinancePalette.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.edge),
      ),
      child: child,
    );
  }
}

/// Income trend: weekly (this month vs last) or monthly bars with a segmented
/// control.
class IncomeTrendPanel extends StatelessWidget {
  const IncomeTrendPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.weeklyTab,
    required this.monthlyTab,
    required this.monthly,
    required this.onSelect,
    required this.current,
    required this.previous,
    required this.labels,
    required this.currentLegend,
    required this.previousLegend,
    this.padding = 18,
  });

  final String title;
  final String subtitle;
  final String weeklyTab;
  final String monthlyTab;
  final bool monthly;
  final ValueChanged<bool> onSelect;
  final List<double> current;

  /// Null on the monthly view, which has no comparison series.
  final List<double>? previous;
  final List<String> labels;
  final String currentLegend;
  final String? previousLegend;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final p = FinancePalette.of(context);
    final prev = previous;
    var maxV = 0.0;
    for (final v in current) {
      if (v > maxV) maxV = v;
    }
    if (prev != null) {
      for (final v in prev) {
        if (v > maxV) maxV = v;
      }
    }
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.04;
    final prevColor = p.sub.withValues(alpha: 0.65);

    final groups = [
      for (var i = 0; i < current.length; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 3,
          barRods: [
            BarChartRodData(
              toY: current[i],
              width: 16,
              color: p.mint,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
            if (prev != null)
              BarChartRodData(
                toY: i < prev.length ? prev[i] : 0,
                width: 16,
                color: prevColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
          ],
        ),
    ];

    return FinancePanel(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: p.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 12, color: p.sub)),
          const SizedBox(height: 14),
          _Tabs(
            p: p,
            weeklyTab: weeklyTab,
            monthlyTab: monthlyTab,
            monthly: monthly,
            onSelect: onSelect,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: p.edge, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(bottom: BorderSide(color: p.edge)),
                ),
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
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: TextStyle(fontSize: 11, color: p.sub),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: groups,
              ),
              duration: const Duration(milliseconds: 150),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legend(color: p.mint, label: currentLegend, sub: p.sub),
              if (previousLegend != null)
                _Legend(color: prevColor, label: previousLegend!, sub: p.sub),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.p,
    required this.weeklyTab,
    required this.monthlyTab,
    required this.monthly,
    required this.onSelect,
  });

  final FinancePalette p;
  final String weeklyTab;
  final String monthlyTab;
  final bool monthly;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, bool toMonthly) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? p.soft : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () => onSelect(toMonthly),
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? p.mint : p.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.page,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          tab(weeklyTab, !monthly, false),
          const SizedBox(width: 3),
          tab(monthlyTab, monthly, true),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.sub});

  final Color color;
  final String label;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: sub)),
      ],
    );
  }
}

/// Month summary: total income, average per day, and how the average is
/// measured.
class MonthSummaryPanel extends StatelessWidget {
  const MonthSummaryPanel({
    super.key,
    required this.title,
    required this.totalLabel,
    required this.totalValue,
    required this.avgLabel,
    required this.avgValue,
    required this.note,
    this.padding = 18,
  });

  final String title;
  final String totalLabel;
  final String totalValue;
  final String avgLabel;
  final String avgValue;
  final String note;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final p = FinancePalette.of(context);
    Widget line(String label, String value, {bool last = false}) {
      return Container(
        padding: EdgeInsets.fromLTRB(0, 12, 0, last ? 0 : 12),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: p.edge)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 14, color: p.text)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FinancePanel(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: p.text,
            ),
          ),
          const SizedBox(height: 2),
          line(totalLabel, totalValue),
          line(avgLabel, avgValue, last: true),
          const SizedBox(height: 3),
          Text(note, style: TextStyle(fontSize: 12, color: p.sub)),
        ],
      ),
    );
  }
}
