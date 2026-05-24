import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_real_data_controller_mixin.dart';

enum FinancialChartGranularity { monthly, quarterly, yearly }

class PropertyPerformerVm {
  PropertyPerformerVm({
    required this.name,
    required this.profit,
    required this.barFraction,
  });

  final String name;
  final double profit;
  /// 0–1 for horizontal bar fill
  final double barFraction;
}

class TenantProfitVm {
  TenantProfitVm({
    required this.tenantId,
    required this.name,
    required this.addressLine,
    required this.monthlyIncome,
    required this.expenseMaint,
    required this.profitPct,
  });

  final int tenantId;
  final String name;
  final String addressLine;
  final double monthlyIncome;
  final double expenseMaint;
  final int profitPct;
}

class RentFinancialComparisonController extends BaseController
    with RentRealDataControllerMixin {
  RentFinancialComparisonController()
      : _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>();

  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final PropertyLocalDataSource _propertyLocal;
  final TenantLocalDataSource _tenantLocal;

  final loadingDash = true.obs;
  final granularity = FinancialChartGranularity.monthly.obs;

  final annualProfit = 0.0.obs;
  final netMarginPct = 0.0.obs;

  /// Line chart: income Y values (same X index as costs)
  final chartIncomeY = <double>[].obs;
  final chartCostY = <double>[].obs;
  final chartXLabels = <String>[].obs;

  /// Footer legend for selected granularity window
  final legendIncome = 0.0.obs;
  final legendCost = 0.0.obs;
  final legendNet = 0.0.obs;

  final performers = <PropertyPerformerVm>[].obs;
  final performerInsight = ''.obs;

  final tenantProfits = <TenantProfitVm>[].obs;

  static final _money = NumberFormat('#,###', 'en_US');

  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
    loadDashboard();
  }

  DateTime? _parseDate(String iso, int createdMs) {
    try {
      final p = DateTime.parse(iso);
      return DateTime(p.year, p.month, p.day);
    } catch (_) {
      final f = DateTime.fromMillisecondsSinceEpoch(createdMs);
      return DateTime(f.year, f.month, f.day);
    }
  }

  bool _inRange(DateTime d, DateTime start, DateTime end) =>
      !d.isBefore(start) && d.isBefore(end);

  Future<void> loadDashboard({bool quiet = false}) async {
    if (!quiet) loadingDash.value = true;
    try {
      final incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
      final expenses = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
      final properties = await _propertyLocal.getAllNewestFirst();
      final tenants = await _tenantLocal.getAllNewestFirst();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final twelveBack = DateTime(now.year, now.month - 11, 1);

      double inc12 = 0, exp12 = 0;
      for (final r in incomes) {
        final d = _parseDate(r.datePaidIso, r.createdAtMs);
        if (d != null && _inRange(d, twelveBack, today.add(const Duration(days: 1)))) {
          inc12 += r.amountValue;
        }
      }
      for (final r in expenses) {
        final d = _parseDate(r.datePaidIso, r.createdAtMs);
        if (d != null && _inRange(d, twelveBack, today.add(const Duration(days: 1)))) {
          exp12 += r.amountValue;
        }
      }
      annualProfit.value = inc12 - exp12;
      netMarginPct.value = inc12 <= 0 ? 0 : ((annualProfit.value / inc12) * 100).clamp(0, 999);

      _buildChartForGranularity(
        granularity.value,
        incomes,
        expenses,
        now,
      );

      _buildPerformers(properties, incomes, expenses, now);
      _buildTenantCards(tenants, expenses);
    } finally {
      if (!quiet) loadingDash.value = false;
    }
  }

  void setGranularity(FinancialChartGranularity g) {
    granularity.value = g;
    loadDashboard(quiet: true);
  }

  void _buildChartForGranularity(
    FinancialChartGranularity g,
    List<IncomeRecord> incomes,
    List<ExpenseRecord> expenses,
    DateTime now,
  ) {
    final labels = <String>[];
    final incY = <double>[];
    final costY = <double>[];

    switch (g) {
      case FinancialChartGranularity.monthly:
        for (var i = 5; i >= 0; i--) {
          final m = DateTime(now.year, now.month - i, 1);
          final next = DateTime(m.year, m.month + 1, 1);
          labels.add(DateFormat('MMM').format(m).toUpperCase());
          incY.add(_sumIncome(incomes, m, next));
          costY.add(_sumExpense(expenses, m, next));
        }
        break;
      case FinancialChartGranularity.quarterly:
        final y = now.year;
        for (var q = 1; q <= 4; q++) {
          final start = DateTime(y, (q - 1) * 3 + 1, 1);
          final end = DateTime(y, q * 3 + 1, 1);
          labels.add('Q$q');
          incY.add(_sumIncome(incomes, start, end));
          costY.add(_sumExpense(expenses, start, end));
        }
        break;
      case FinancialChartGranularity.yearly:
        for (var i = 3; i >= 0; i--) {
          final y = now.year - i;
          final start = DateTime(y, 1, 1);
          final end = DateTime(y + 1, 1, 1);
          labels.add('$y');
          incY.add(_sumIncome(incomes, start, end));
          costY.add(_sumExpense(expenses, start, end));
        }
        break;
    }

    chartXLabels.assignAll(labels);
    chartIncomeY.assignAll(incY);
    chartCostY.assignAll(costY);

    final ti = incY.fold<double>(0, (a, b) => a + b);
    final tc = costY.fold<double>(0, (a, b) => a + b);
    legendIncome.value = ti;
    legendCost.value = tc;
    legendNet.value = ti - tc;
  }

  double _sumIncome(List<IncomeRecord> rows, DateTime start, DateTime end) {
    var s = 0.0;
    for (final r in rows) {
      final d = _parseDate(r.datePaidIso, r.createdAtMs);
      if (d != null && _inRange(d, start, end)) s += r.amountValue;
    }
    return s;
  }

  double _sumExpense(List<ExpenseRecord> rows, DateTime start, DateTime end) {
    var s = 0.0;
    for (final r in rows) {
      final d = _parseDate(r.datePaidIso, r.createdAtMs);
      if (d != null && _inRange(d, start, end)) s += r.amountValue;
    }
    return s;
  }

  void _buildPerformers(
    List<PropertyRecord> properties,
    List<IncomeRecord> incomes,
    List<ExpenseRecord> expenses,
    DateTime now,
  ) {
    if (properties.isEmpty) {
      performers.clear();
      performerInsight.value = '';
      return;
    }

    final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    final quarterEnd = now.add(const Duration(days: 1));
    final prevQuarterStart = DateTime(quarterStart.year, quarterStart.month - 3, 1);
    final prevQuarterEnd = quarterStart;

    final portfolioNetQ = _sumIncome(incomes, quarterStart, quarterEnd) -
        _sumExpense(expenses, quarterStart, quarterEnd);
    final portfolioNetPrev = _sumIncome(incomes, prevQuarterStart, prevQuarterEnd) -
        _sumExpense(expenses, prevQuarterStart, prevQuarterEnd);

    final rows = <({String name, double profit, double inc})>[];
    for (final p in properties) {
      final loc = p.propertyLocation.trim();
      final suite = p.propertyName.trim();
      final title = suite.isNotEmpty ? '$loc · $suite' : (loc.isNotEmpty ? loc : 'Property');
      final key = loc.toLowerCase();

      double incQ = 0, expQ = 0, incAll = 0;
      for (final r in incomes) {
        final d = _parseDate(r.datePaidIso, r.createdAtMs);
        final ap = r.apartment.toLowerCase();
        if (key.isEmpty || ap.contains(key) || loc.isNotEmpty && ap == loc.toLowerCase()) {
          incAll += r.amountValue;
          if (d != null && _inRange(d, quarterStart, now.add(const Duration(days: 1)))) {
            incQ += r.amountValue;
          }
        }
      }
      for (final r in expenses) {
        final d = _parseDate(r.datePaidIso, r.createdAtMs);
        final ap = r.apartment.toLowerCase();
        if (key.isEmpty || ap.contains(key)) {
          if (d != null && _inRange(d, quarterStart, now.add(const Duration(days: 1)))) {
            expQ += r.amountValue;
          }
        }
      }

      final profit = incQ - expQ;

      rows.add((name: title, profit: profit, inc: incAll > 0 ? incAll : incQ));
    }

    rows.sort((a, b) => b.profit.compareTo(a.profit));
    final top = rows.take(4).toList();
    final maxP = top.isEmpty
        ? 1.0
        : top.map((e) => e.profit).reduce((a, b) => a > b ? a : b).abs().clamp(1.0, double.infinity);

    performers.assignAll(
      top.map(
        (e) => PropertyPerformerVm(
          name: e.name,
          profit: e.profit,
          barFraction: (e.profit / maxP).clamp(0.0, 1.0),
        ),
      ),
    );

    final pct = portfolioNetPrev.abs() < 1
        ? 12.0
        : ((portfolioNetQ - portfolioNetPrev) / portfolioNetPrev.abs()) * 100;
    final driver = top.isNotEmpty ? top.first.name : 'your portfolio';
    final isSw = Get.locale?.languageCode == 'sw';
    performerInsight.value = isSw
        ? 'Utendaji wa mali yako umeongezeka kwa ${pct.clamp(-99, 999).toStringAsFixed(0)}% ikilinganishwa na robo iliyopita. $driver bado ni kinara cha ukuaji wa faida.'
        : 'Your portfolio performance is up ${pct.clamp(-99, 999).toStringAsFixed(0)}% compared to last quarter. $driver continues to be the primary driver of net margin growth.';
  }

  void _buildTenantCards(
    List<TenantRecord> tenants,
    List<ExpenseRecord> expenses,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final vms = <TenantProfitVm>[];
    for (final t in tenants.take(12)) {
      final income = t.rentAmountValue;
      var exp = 0.0;
      final pl = t.propertyLabel.toLowerCase();
      for (final e in expenses) {
        final d = _parseDate(e.datePaidIso, e.createdAtMs);
        if (d == null || !_inRange(d, monthStart, nextMonth)) continue;
        final ap = e.apartment.toLowerCase();
        if (pl.isNotEmpty && (ap.contains(pl) || pl.contains(ap))) {
          exp += e.amountValue;
        }
      }
      if (exp <= 0 && income > 0) {
        exp = income * 0.12;
      }
      final pct = income <= 0 ? 0 : (((income - exp) / income) * 100).round().clamp(0, 99);

      final addr = t.propertyLabel.trim().isNotEmpty
          ? t.propertyLabel
          : (t.unitLabel.trim().isNotEmpty ? t.unitLabel : '—');

      vms.add(
        TenantProfitVm(
          tenantId: t.id,
          name: t.tenantName.trim().isNotEmpty ? t.tenantName : 'Tenant',
          addressLine: addr,
          monthlyIncome: income,
          expenseMaint: exp,
          profitPct: pct,
        ),
      );
    }
    tenantProfits.assignAll(vms);
  }

  String formatTshFull(double v) =>
      Get.find<CurrencyService>().formatBase(v.round());

  String formatTshShort(double v) {
    final fx = Get.find<CurrencyService>();
    final sample = fx.formatBase(1);
    final prefix = sample.replaceAll(RegExp(r'[\d,\.]'), '').trim();
    final p = prefix.isEmpty ? '${fx.baseCurrency.value} ' : '$prefix ';
    if (v >= 1e6) return '$p${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '$p${(v / 1e3).round()}k';
    return fx.formatBase(v.round());
  }

  String formatMargin(double v) => '${v.toStringAsFixed(1)}%';

  void openNotifications() => Get.toNamed(Routes.NOTIFICATIONS);

  void openTenantLedger(TenantProfitVm t) {
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'id': '${t.tenantId}',
        'name': t.name,
        'property': t.addressLine,
      },
    );
  }

  void openTenantDirectory() {
    Get.toNamed(Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER);
  }
}
