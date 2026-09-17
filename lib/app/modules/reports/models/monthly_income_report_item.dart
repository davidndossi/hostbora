/// One calendar month of rolled-up income for the monthly reports index.
class MonthlyIncomeReportItem {
  const MonthlyIncomeReportItem({
    required this.month,
    required this.paidAmount,
    this.upcomingAmount = 0,
  });

  /// First day of the month (local).
  final DateTime month;

  /// Income recorded as paid in this calendar month.
  final double paidAmount;

  /// Expected payments still due in this month (current/future months).
  final double upcomingAmount;

  /// Paid + upcoming — headline total for the month card.
  double get totalIncome => paidAmount + upcomingAmount;

  int get year => month.year;
  int get monthNumber => month.month;
}
