import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../rent_real_data_controller_mixin.dart';

class RentProfitExpenseLine {
  const RentProfitExpenseLine({
    required this.record,
    required this.estimated,
  });

  final ExpenseRecord record;
  final double estimated;

  double get variance => record.amountValue - estimated;
}

class RentProfitAnalysisDashboardController extends BaseController
    with RentRealDataControllerMixin {
  RentProfitAnalysisDashboardController()
      : _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>();

  final ExpenseLocalDataSource _expenseLocal;
  final IncomeLocalDataSource _incomeLocal;
  final expenses = <ExpenseRecord>[].obs;
  final incomes = <IncomeRecord>[].obs;

  /// Calendar year used for the Target/Actual monthly chart.
  int get chartYear => DateTime.now().year;

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadRealDataSnapshot(),
      _loadExpenses(),
      _loadIncomes(),
    ]);
  }

  Future<void> _loadExpenses() async {
    final rent = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
    final bnb = await _expenseLocal.getAllNewestFirst(workspaceType: 'bnb');
    expenses.value = [...rent, ...bnb];
  }

  Future<void> _loadIncomes() async {
    final rent = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final bnb = await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb');
    incomes.value = [...rent, ...bnb];
  }

  bool _isSuddenCost(ExpenseRecord e) {
    final c = e.category.trim().toLowerCase();
    return c == 'maintenance' ||
        c.contains('repair') ||
        c.contains('emergency') ||
        c.contains('sudden');
  }

  /// Profit if income is kept and sudden maintenance/costs are excluded.
  double get targetProfit {
    final income = incomes.fold<double>(0, (a, b) => a + b.amountValue);
    final planned = expenses
        .where((e) => !_isSuddenCost(e))
        .fold<double>(0, (a, b) => a + b.amountValue);
    return income - planned;
  }

  /// Profit after deducting all expenses.
  double get actualProfit {
    final income = incomes.fold<double>(0, (a, b) => a + b.amountValue);
    final all = expenses.fold<double>(0, (a, b) => a + b.amountValue);
    return income - all;
  }

  double get deviationAmount => actualProfit - targetProfit;

  double get deviationPercentVsTarget {
    final target = targetProfit.abs();
    if (target <= 0) return 0;
    return (deviationAmount.abs() / target) * 100;
  }

  List<double> _monthlyIncomeForYear(int year) {
    final out = List<double>.filled(12, 0);
    for (final r in incomes) {
      final d = r.paidLocalCalendarOrCreated();
      if (d.year != year) continue;
      out[d.month - 1] += r.amountValue;
    }
    return out;
  }

  List<double> _monthlyExpenseForYear(int year, {required bool suddenOnly}) {
    final out = List<double>.filled(12, 0);
    for (final e in expenses) {
      final d = e.paidLocalCalendarOrCreated();
      if (d.year != year) continue;
      final sudden = _isSuddenCost(e);
      if (suddenOnly && !sudden) continue;
      if (!suddenOnly && sudden) continue;
      out[d.month - 1] += e.amountValue;
    }
    return out;
  }

  List<double> _monthlyAllExpenseForYear(int year) {
    final out = List<double>.filled(12, 0);
    for (final e in expenses) {
      final d = e.paidLocalCalendarOrCreated();
      if (d.year != year) continue;
      out[d.month - 1] += e.amountValue;
    }
    return out;
  }

  /// Target profit per month for [chartYear] (income − planned costs).
  List<double> targetTrendBars() {
    final year = chartYear;
    final income = _monthlyIncomeForYear(year);
    final planned = _monthlyExpenseForYear(year, suddenOnly: false);
    return List.generate(12, (i) => income[i] - planned[i]);
  }

  /// Actual profit per month for [chartYear] (income − all expenses).
  List<double> actualTrendBars() {
    final year = chartYear;
    final income = _monthlyIncomeForYear(year);
    final all = _monthlyAllExpenseForYear(year);
    return List.generate(12, (i) => income[i] - all[i]);
  }

  List<RentProfitExpenseLine> get topExpenseLines {
    final rows = [...expenses];
    rows.sort((a, b) => b.amountValue.compareTo(a.amountValue));
    return rows.take(5).map((e) {
      final ratio = _isSuddenCost(e) ? 0.5 : 0.9;
      return RentProfitExpenseLine(record: e, estimated: e.amountValue * ratio);
    }).toList();
  }

  int get revivingItemsCount => topExpenseLines.where((e) => e.variance > 0).length;

  double get maintenanceSharePercent {
    final total = expenses.fold<double>(0, (a, b) => a + b.amountValue);
    if (total <= 0) return 0;
    final maintenance = expenses
        .where(_isSuddenCost)
        .fold<double>(0, (a, b) => a + b.amountValue);
    return (maintenance / total) * 100;
  }

  String insightMessage(bool isSw) {
    final share = maintenanceSharePercent;
    if (isSw) {
      if (share >= 45) {
        return 'Gharama za matengenezo ziko juu (takriban ${share.toStringAsFixed(0)}%). '
            'Weka kikomo cha dharura kwa kila mali na panga matengenezo ya kinga kila mwezi.';
      }
      if (share >= 25) {
        return 'Matengenezo yanaongoza gharama kwa ${share.toStringAsFixed(0)}%. '
            'Wekeza kwenye ukaguzi wa mara kwa mara ili kupunguza kazi za ghafla.';
      }
      return 'Uwiano wa matengenezo uko salama kwa sasa. Endelea kufuatilia tofauti za gharama kwa kila mali.';
    }
    if (share >= 45) {
      return 'Maintenance costs are consuming about ${share.toStringAsFixed(0)}% of spend. '
          'Set emergency caps per property and schedule proactive monthly servicing.';
    }
    if (share >= 25) {
      return 'Maintenance is driving ${share.toStringAsFixed(0)}% of expenses. '
          'Invest in preventive checks to reduce unplanned repairs.';
    }
    return 'Maintenance share is currently manageable. Keep tracking variance by property.';
  }

  void onApplyStrategy() {
    showSuccessMessage('Strategy applied');
  }
}
