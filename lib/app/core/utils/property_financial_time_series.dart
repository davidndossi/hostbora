import 'package:intl/intl.dart';

import '../../data/local/db/expense_local_data_source.dart';
import '../../data/local/db/income_local_data_source.dart';
import 'property_listing_finance_scope.dart';

/// Monthly income and cost totals for one property, ordered oldest → newest.
class PropertyFinancialTimeSeries {
  const PropertyFinancialTimeSeries({
    required this.dateLabels,
    required this.incomeByPeriod,
    required this.costsByPeriod,
  });

  final List<String> dateLabels;
  final List<double> incomeByPeriod;
  final List<double> costsByPeriod;

  bool get isEmpty {
    final inc = incomeByPeriod.fold<double>(0, (a, b) => a + b);
    final cost = costsByPeriod.fold<double>(0, (a, b) => a + b);
    return inc <= 0 && cost <= 0;
  }
}

class PropertyFinancialTimeSeriesBuilder {
  const PropertyFinancialTimeSeriesBuilder._();

  static const _monthCount = 12;

  static PropertyFinancialTimeSeries build({
    required PropertyListingFinanceScope scope,
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
    DateTime? anchor,
  }) {
    final now = anchor ?? DateTime.now();
    final labels = <String>[];
    final incomeY = <double>[];
    final costY = <double>[];

    for (var i = _monthCount - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      labels.add(DateFormat('MMM yy').format(monthStart));
      incomeY.add(_sumIncome(incomes, scope, monthStart, monthEnd));
      costY.add(_sumExpense(expenses, scope, monthStart, monthEnd));
    }

    return PropertyFinancialTimeSeries(
      dateLabels: labels,
      incomeByPeriod: incomeY,
      costsByPeriod: costY,
    );
  }

  static double _sumIncome(
    List<IncomeRecord> rows,
    PropertyListingFinanceScope scope,
    DateTime start,
    DateTime end,
  ) {
    var sum = 0.0;
    for (final row in rows) {
      if (!scope.matchesIncome(row)) continue;
      final d = row.paidLocalCalendarOrCreated();
      if (!d.isBefore(start) && d.isBefore(end)) {
        sum += row.amountValue;
      }
    }
    return sum;
  }

  static double _sumExpense(
    List<ExpenseRecord> rows,
    PropertyListingFinanceScope scope,
    DateTime start,
    DateTime end,
  ) {
    var sum = 0.0;
    for (final row in rows) {
      if (!scope.matchesExpense(row)) continue;
      final d = row.paidLocalCalendarOrCreated();
      if (!d.isBefore(start) && d.isBefore(end)) {
        sum += row.amountValue;
      }
    }
    return sum;
  }
}
