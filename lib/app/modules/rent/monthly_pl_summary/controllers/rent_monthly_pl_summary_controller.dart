import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../rent_real_data_controller_mixin.dart';

class PlExpenseLineVm {
  const PlExpenseLineVm({
    required this.labelKey,
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String labelKey;
  final String label;
  final double amount;
  final IconData icon;
}

class RentMonthlyPlSummaryController extends BaseController
    with RentRealDataControllerMixin {
  RentMonthlyPlSummaryController()
      : _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>();

  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;

  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final loadingMonth = true.obs;

  final totalRevenue = 0.0.obs;
  final totalExpenses = 0.0.obs;
  final rentIncome = 0.0.obs;
  final serviceIncome = 0.0.obs;
  final rentTransactionCount = 0.obs;
  final expenseStaff = 0.0.obs;
  final expenseMaint = 0.0.obs;
  final expenseUtil = 0.0.obs;
  final expenseTax = 0.0.obs;
  final netProfit = 0.0.obs;
  final profitMarginPct = 0.0.obs;
  final expenseRatioPct = 0.0.obs;
  final trendPctLabel = ''.obs;
  final insightLines = <String>[].obs;

  static final _money = NumberFormat('#,###', 'en_US');

  DateTime get _monthStart =>
      DateTime(selectedMonth.value.year, selectedMonth.value.month);
  DateTime get _nextMonthStart =>
      DateTime(selectedMonth.value.year, selectedMonth.value.month + 1);

  @override
  void onReady() {
    super.onReady();
    loadRealDataSnapshot();
    loadMonthData();
  }

  DateTime? _parseRecordDate(String iso, int createdAtMs) {
    try {
      final p = DateTime.parse(iso);
      return DateTime(p.year, p.month, p.day);
    } catch (_) {
      final f = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
      return DateTime(f.year, f.month, f.day);
    }
  }

  bool _inMonth(DateTime d) =>
      !d.isBefore(_monthStart) && d.isBefore(_nextMonthStart);

  static bool _isRentCategory(String category) {
    final x = category.toLowerCase().trim();
    return x.isEmpty || x.contains('rent');
  }

  static void _addToExpenseBucket(
    ExpenseRecord e,
    void Function(String bucket, double v) sink,
  ) {
    final v = e.amountValue;
    if (v <= 0) return;
    final c = e.category.toLowerCase();
    if (c.contains('staff') ||
        c.contains('salary') ||
        c.contains('payroll') ||
        c.contains('wage')) {
      sink('staff', v);
    } else if (c.contains('maint') ||
        c.contains('repair') ||
        c.contains('fix') ||
        c.contains('clean')) {
      sink('maint', v);
    } else if (c.contains('util') ||
        c.contains('luku') ||
        c.contains('electric') ||
        c.contains('water') ||
        c.contains('power')) {
      sink('util', v);
    } else if (c.contains('tax') ||
        c.contains('insur') ||
        c.contains('levy') ||
        c.contains('premium')) {
      sink('tax', v);
    } else {
      sink('maint', v);
    }
  }

  Future<void> loadMonthData() async {
    loadingMonth.value = true;
    try {
      final incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
      final expenses = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');

      double rent = 0, service = 0;
      var rentCount = 0;
      for (final r in incomes) {
        final d = _parseRecordDate(r.datePaidIso, r.createdAtMs);
        if (d == null || !_inMonth(d)) continue;
        if (_isRentCategory(r.category)) {
          rent += r.amountValue;
          if (r.amountValue > 0) rentCount++;
        } else {
          service += r.amountValue;
        }
      }

      double staff = 0, maint = 0, util = 0, tax = 0;
      for (final e in expenses) {
        final d = _parseRecordDate(e.datePaidIso, e.createdAtMs);
        if (d == null || !_inMonth(d)) continue;
        _addToExpenseBucket(e, (bucket, v) {
          switch (bucket) {
            case 'staff':
              staff += v;
            case 'maint':
              maint += v;
            case 'util':
              util += v;
            case 'tax':
              tax += v;
          }
        });
      }

      final rev = rent + service;
      final exp = staff + maint + util + tax;
      final net = rev - exp;

      rentIncome.value = rent;
      serviceIncome.value = service;
      rentTransactionCount.value = rentCount;
      expenseStaff.value = staff;
      expenseMaint.value = maint;
      expenseUtil.value = util;
      expenseTax.value = tax;
      totalRevenue.value = rev;
      totalExpenses.value = exp;
      netProfit.value = net;

      if (rev > 0.01) {
        profitMarginPct.value = ((net / rev) * 100).clamp(-999.0, 100.0);
        expenseRatioPct.value = ((exp / rev) * 100).clamp(0.0, 1000.0);
      } else {
        profitMarginPct.value = 0;
        expenseRatioPct.value = 0;
      }

      await _loadTrendAndInsights(util, incomes, expenses);
    } finally {
      loadingMonth.value = false;
    }
  }

  Future<void> _loadTrendAndInsights(
    double utilThisMonth,
    List<IncomeRecord> allIncome,
    List<ExpenseRecord> allExpense,
  ) async {
    final prevStart = DateTime(_monthStart.year, _monthStart.month - 1);
    final prevEnd = _monthStart;

    double prevNet = 0;
    double utilLast = 0;
    for (final r in allIncome) {
      final d = _parseRecordDate(r.datePaidIso, r.createdAtMs);
      if (d == null || d.isBefore(prevStart) || !d.isBefore(prevEnd)) continue;
      prevNet += r.amountValue;
    }
    for (final e in allExpense) {
      final d = _parseRecordDate(e.datePaidIso, e.createdAtMs);
      if (d == null || d.isBefore(prevStart) || !d.isBefore(prevEnd)) continue;
      prevNet -= e.amountValue;
      _addToExpenseBucket(e, (bucket, v) {
        if (bucket == 'util') utilLast += v;
      });
    }

    final thisNet = netProfit.value;
    if (prevNet.abs() < 1 && thisNet.abs() < 1) {
      trendPctLabel.value = '';
    } else if (prevNet.abs() < 1) {
      trendPctLabel.value = '+100%';
    } else {
      final pct = ((thisNet - prevNet) / prevNet.abs()) * 100;
      final sign = pct >= 0 ? '+ ' : '';
      trendPctLabel.value = '$sign${pct.round()}%';
    }

    final lines = <String>[];
    final isSw = Get.locale?.languageCode == 'sw';

    if (utilLast > 1) {
      final uPct = ((utilThisMonth - utilLast) / utilLast) * 100;
      if (uPct > 8) {
        lines.add(
          isSw
              ? 'Gharama za umeme/maji zimeongezeka kwa asilimia ${uPct.round()} ikilinganishwa na mwezi uliopita. Jaribu kuweka programu ya muda kwa AC katika vyumba vilivyo tupu.'
              : 'Your utility costs are ${uPct.round()}% higher than last month. Consider automating AC timers in empty units.',
        );
      } else if (uPct < -8) {
        lines.add(
          isSw
              ? 'Gharama za utilities zimepungua kwa asilimia ${(-uPct).round()} mwezi huu — endelea kufuatilia matumizi.'
              : 'Utility spending is down ${(-uPct).round()}% vs last month — keep tracking usage.',
        );
      }
    }

    final snap = realData.value;
    if (snap != null && snap.properties > 0) {
      final occ = ((snap.tenants / snap.properties) * 100).clamp(30.0, 98.0);
      final next = DateTime(_monthStart.year, _monthStart.month + 1);
      String nextM;
      try {
        nextM = DateFormat('MMMM', isSw ? 'sw' : 'en_US').format(next);
      } catch (_) {
        nextM = DateFormat('MMMM', 'en_US').format(next);
      }
      lines.add(
        isSw
            ? 'Uwiano wa upangaji unaelekea ${occ.round()}% kwa $nextM. Fikiria kuongeza bei za wikendi iwapo mahitaji ni ya juu.'
            : 'Occupancy is trending towards ${occ.round()}% for $nextM. Consider raising weekend rates when demand is strong.',
      );
    }

    if (lines.length < 2) {
      if (lines.isEmpty) {
        lines.add(
          isSw
              ? 'Ongeza mapato na gharama za mwezi huo hapa ili kupata muhtasari halisi wa faida.'
              : 'Record income and expenses for this month to sharpen your profit picture.',
        );
      }
      lines.add(
        isSw
            ? 'Angalia malipo yanayokaribia na mikataba inayoisha katika Kituo cha Rent.'
            : 'Review upcoming payments and lease expiries from the Rent hub.',
      );
    }

    insightLines.assignAll(lines.take(2).toList());
  }

  Future<void> pickMonth() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: selectedMonth.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: Get.locale?.languageCode == 'sw' ? 'Chagua mwezi' : 'Select month',
    );
    if (picked != null) {
      selectedMonth.value = DateTime(picked.year, picked.month);
      await loadMonthData();
    }
  }

  String formatTsh(double v) => 'Tsh ${_money.format(v.round())}';

  String monthTitle({required bool isSw}) {
    try {
      final loc = isSw ? 'sw' : 'en_US';
      return DateFormat('MMMM yyyy', loc).format(selectedMonth.value);
    } catch (_) {
      return DateFormat('MMMM yyyy', 'en_US').format(selectedMonth.value);
    }
  }

  String revenueRangeBadge({required bool isSw}) {
    try {
      final loc = isSw ? 'sw' : 'en_US';
      final start = DateFormat('MMM d', loc).format(_monthStart);
      final end = DateFormat('MMM d', loc).format(
        DateTime(_monthStart.year, _monthStart.month + 1, 0),
      );
      return '$start - $end';
    } catch (_) {
      final start = DateFormat('MMM d', 'en_US').format(_monthStart);
      final end = DateFormat('MMM d', 'en_US').format(
        DateTime(_monthStart.year, _monthStart.month + 1, 0),
      );
      return '$start - $end';
    }
  }

  List<PlExpenseLineVm> expenseLinesForUi({required bool isSw}) {
    return [
      PlExpenseLineVm(
        labelKey: 'staff',
        label: isSw ? 'Mishahara ya wafanyakazi' : 'Staff Salaries',
        amount: expenseStaff.value,
        icon: Icons.people_outline_rounded,
      ),
      PlExpenseLineVm(
        labelKey: 'maint',
        label: isSw ? 'Matengenezo' : 'Maintenance',
        amount: expenseMaint.value,
        icon: Icons.build_outlined,
      ),
      PlExpenseLineVm(
        labelKey: 'util',
        label: isSw ? 'Huduma za msingi' : 'Utilities',
        amount: expenseUtil.value,
        icon: Icons.bolt_outlined,
      ),
      PlExpenseLineVm(
        labelKey: 'tax',
        label: isSw ? 'Kodi na bima' : 'Taxes & Insurance',
        amount: expenseTax.value,
        icon: Icons.account_balance_outlined,
      ),
    ];
  }

  void onDownloadPdf() {
    showSuccessMessage(
      Get.locale?.languageCode == 'sw'
          ? 'Ripoti ya PDF — inakuja hivi karibuni'
          : 'PDF report — coming soon',
    );
  }

  Future<void> onShareWithAccountant() async {
    final isSw = Get.locale?.languageCode == 'sw';
    final title = monthTitle(isSw: isSw);
    final buf = StringBuffer()
      ..writeln(isSw ? 'Muhtasari wa P&L — $title' : 'P&L summary — $title')
      ..writeln('${isSw ? 'Mapato' : 'Revenue'}: ${formatTsh(totalRevenue.value)}')
      ..writeln('${isSw ? 'Gharama' : 'Expenses'}: ${formatTsh(totalExpenses.value)}')
      ..writeln('${isSw ? 'Faida halisi' : 'Net profit'}: ${formatTsh(netProfit.value)}');
    if (trendPctLabel.value.isNotEmpty) {
      buf.writeln(
        '${isSw ? 'Mwelekeo' : 'Trend'}: ${trendPctLabel.value}',
      );
    }
    await Share.share(
      buf.toString(),
      subject: isSw ? 'Muhtasari wa P&L' : 'Monthly P&L summary',
    );
  }
}
