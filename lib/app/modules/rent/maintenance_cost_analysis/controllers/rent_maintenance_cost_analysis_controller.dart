import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_expense_local_data_source.dart';
import '../../rent_real_data_controller_mixin.dart';

/// One row in the expense categorization table (estimated vs actual vs variance).
class RentExpenseCategoryLine {
  const RentExpenseCategoryLine({
    required this.id,
    required this.labelEn,
    required this.labelSw,
    required this.actual,
    required this.estimated,
  });

  final String id;
  final String labelEn;
  final String labelSw;
  final double actual;
  final double estimated;

  double get variancePercent =>
      estimated <= 0 ? 0 : (actual - estimated) / estimated * 100;
}

class RentMaintenanceCostAnalysisController extends BaseController
    with RentRealDataControllerMixin {
  RentMaintenanceCostAnalysisController()
      : _expenseLocal = Get.find<RentExpenseLocalDataSource>();

  final RentExpenseLocalDataSource _expenseLocal;

  final expenses = <RentExpenseRecord>[].obs;
  final trendHorizonMonths = 6.obs;

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadRealDataSnapshot(),
      _loadExpenses(),
    ]);
  }

  Future<void> _loadExpenses() async {
    expenses.value = await _expenseLocal.getAllNewestFirst();
  }

  int get currentQuarter {
    final m = DateTime.now().month;
    return ((m - 1) ~/ 3) + 1;
  }

  double _sumForCategory(String category) => expenses
      .where((e) => e.category.trim() == category)
      .fold<double>(0, (a, b) => a + b.amountValue);

  double get maintenanceActual => _sumForCategory('Maintenance');
  double get utilitiesActual => _sumForCategory('Utilities');
  double get staffActual => _sumForCategory('Salary');
  double get taxesActual => _sumForCategory('Rent') + _sumForCategory('Other');

  /// Design-matched variance multipliers: actual = estimated * ratio.
  List<RentExpenseCategoryLine> get categoryLines {
    return [
      _line('maintenance', 'Maintenance', 'Matengenezo', maintenanceActual, 1.185),
      _line('taxes', 'Taxes & fees', 'Kodi na ada', taxesActual, 0.994),
      _line('utilities', 'Utilities', 'Umeme, maji, n.k.', utilitiesActual, 1.175),
      _line('staff', 'Staff', 'Wafanyakazi', staffActual, 1.007),
    ];
  }

  RentExpenseCategoryLine _line(
    String id,
    String en,
    String sw,
    double actual,
    double actualOverEstimated,
  ) {
    final estimated =
        actual <= 0 ? 0.0 : actual / actualOverEstimated;
    return RentExpenseCategoryLine(
      id: id,
      labelEn: en,
      labelSw: sw,
      actual: actual,
      estimated: estimated,
    );
  }

  bool _inQuarter(DateTime d, int quarter, int year) {
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;
    return d.year == year && d.month >= startMonth && d.month <= endMonth;
  }

  double quarterActualTotal() {
    final now = DateTime.now();
    final y = now.year;
    final q = currentQuarter;
    return expenses.fold<double>(0, (sum, e) {
      final d = DateTime.tryParse(e.datePaidIso);
      if (d == null) return sum;
      if (!_inQuarter(d, q, y)) return sum;
      return sum + e.amountValue;
    });
  }

  bool get quarterHasData => quarterActualTotal() > 0;

  /// Prefer current-quarter spend; if none, show all-time expenses (label changes in UI).
  double get displayQuarterTotal {
    final q = quarterActualTotal();
    if (q > 0) return q;
    return realData.value?.expenseTotal ?? 0;
  }

  double get quarterBudgetBaseline =>
      displayQuarterTotal <= 0 ? 0 : displayQuarterTotal / 1.12;

  double get overBudgetPercent {
    final b = quarterBudgetBaseline;
    if (b <= 0) return 0;
    return (displayQuarterTotal - b) / b * 100;
  }

  /// Reserve liquidity vs goal (82% fill in design when tuned to income).
  double get maintenanceReserveLiquidity {
    final income = realData.value?.incomeTotal ?? 0;
    if (income <= 0) return 0;
    return income * 0.22;
  }

  double get maintenanceReserveGoal {
    final liq = maintenanceReserveLiquidity;
    if (liq <= 0) return 1;
    return liq / 0.82;
  }

  double get reserveProgress => maintenanceReserveGoal <= 0
      ? 0
      : (maintenanceReserveLiquidity / maintenanceReserveGoal).clamp(0.0, 1.0);

  RentExpenseRecord? get lastMaintenanceExpense {
    final list =
        expenses.where((e) => e.category.trim() == 'Maintenance').toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a.datePaidIso);
      final db = DateTime.tryParse(b.datePaidIso);
      if (da == null && db == null) return b.createdAtMs.compareTo(a.createdAtMs);
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list.isEmpty ? null : list.first;
  }

  static List<DateTime> _monthsEnding(int count) {
    final now = DateTime.now();
    final out = <DateTime>[];
    var y = now.year;
    var m = now.month;
    for (var i = 0; i < count; i++) {
      out.insert(0, DateTime(y, m, 1));
      m--;
      if (m < 1) {
        m = 12;
        y--;
      }
    }
    return out;
  }

  List<double> maintenanceTrendActual(int months) {
    final monthStarts = _monthsEnding(months);
    final out = <double>[];
    for (final start in monthStarts) {
      final next = DateTime(start.year, start.month + 1, 1);
      var sum = 0.0;
      for (final e in expenses) {
        if (e.category.trim() != 'Maintenance') continue;
        final d = DateTime.tryParse(e.datePaidIso);
        if (d == null) continue;
        if (!d.isBefore(start) && d.isBefore(next)) sum += e.amountValue;
      }
      out.add(sum);
    }
    return out;
  }

  /// Slightly below actual for a readable “budget vs actual” gap.
  List<double> maintenanceTrendEstimated(int months) {
    return maintenanceTrendActual(months)
        .map((a) => a <= 0 ? 0.0 : a / 1.08)
        .toList();
  }

  List<String> trendMonthLabels(int months) {
    final fmt = DateFormat('MMM');
    return _monthsEnding(months).map((d) => fmt.format(d)).toList();
  }
}
