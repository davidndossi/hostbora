import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
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
      : _expenseLocal = Get.find<ExpenseLocalDataSource>();

  final ExpenseLocalDataSource _expenseLocal;
  final expenses = <ExpenseRecord>[].obs;

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
    expenses.value = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
  }

  double get targetProfit {
    final d = realData.value;
    if (d == null) return 0;
    return d.incomeTotal * 0.25;
  }

  double get actualProfit => realData.value?.netProfit ?? 0;

  double get deviationAmount => actualProfit - targetProfit;

  double get deviationPercentVsTarget {
    final target = targetProfit;
    if (target <= 0) return 0;
    return (deviationAmount.abs() / target) * 100;
  }

  List<double> targetTrendBars() {
    final t = targetProfit;
    if (t <= 0) return [0, 0, 0, 0, 0, 0];
    final m = t / 6;
    return [m * 0.92, m * 0.94, m * 0.98, m * 0.95, m * 1.00, m * 1.04];
  }

  List<double> actualTrendBars() {
    final a = actualProfit;
    if (a <= 0) return [0, 0, 0, 0, 0, 0];
    final m = a / 6;
    return [m * 0.76, m * 0.83, m * 0.88, m * 0.79, m * 0.91, m * 0.97];
  }

  List<RentProfitExpenseLine> get topExpenseLines {
    final rows = [...expenses];
    rows.sort((a, b) => b.amountValue.compareTo(a.amountValue));
    return rows.take(5).map((e) {
      final ratio = e.category.trim() == 'Maintenance' ? 0.84 : 0.9;
      return RentProfitExpenseLine(record: e, estimated: e.amountValue * ratio);
    }).toList();
  }

  int get revivingItemsCount => topExpenseLines.where((e) => e.variance > 0).length;

  double get maintenanceSharePercent {
    final total = realData.value?.expenseTotal ?? 0;
    if (total <= 0) return 0;
    final maintenance = expenses
        .where((e) => e.category.trim() == 'Maintenance')
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
