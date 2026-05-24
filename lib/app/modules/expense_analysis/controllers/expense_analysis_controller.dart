import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../routes/app_pages.dart';

class ExpenseAnalysisController extends BaseController {
  ExpenseAnalysisController() : _expenseLocal = Get.find<ExpenseLocalDataSource>();

  final ExpenseLocalDataSource _expenseLocal;
  final selectedProperty = 'All Properties'.obs;
  final dateRangeLabel = 'Last 30 Days'.obs;
  final loading = false.obs;

  final totalAmountLabel = 'Tshs. 0'.obs;

  final expenseCategories = <ExpenseCategory>[].obs;
  final topExpenses = <TopExpenseItem>[].obs;
  static final _money = NumberFormat('#,###', 'en_US');

  @override
  void onReady() {
    super.onReady();
    loadRealExpenseData();
  }

  void goBack() => Get.back();

  void openMoreOptions() {
    // TODO: show menu
  }

  void selectPropertyFilter() {
    // TODO: show property dropdown
  }

  void selectDateRange() {
    // TODO: show date picker
  }

  void viewAllExpenses() {
    // TODO: navigate to full expenses list
  }

  Future<void> goToAddExpense() async {
    final saved = await Get.toNamed(Routes.ADD_EXPENSE);
    if (saved == true) {
      await loadRealExpenseData();
    }
  }

  void downloadReport() {
    // TODO: generate and download report
  }

  Future<void> loadRealExpenseData() async {
    loading.value = true;
    try {
      final rows = await _expenseLocal.getAllNewestFirst(workspaceType: 'bnb');
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));

      final inRange = rows.where((r) {
        final d = _parseExpenseDateOrCreated(r);
        return !d.isBefore(start) && !d.isAfter(now);
      }).toList();

      final total = inRange.fold<double>(0, (sum, e) => sum + e.amountValue);
      totalAmountLabel.value =
          Get.find<CurrencyService>().formatBase(total.round());

      final byCategory = <String, double>{};
      for (final row in inRange) {
        final key = _normalizedCategory(row.category);
        byCategory[key] = (byCategory[key] ?? 0) + row.amountValue;
      }

      final sortedCats = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      expenseCategories.assignAll(
        sortedCats.asMap().entries.map(
          (e) {
            return ExpenseCategory(
              name: e.value.key,
              value: e.value.value,
              colorIndex: e.key,
            );
          },
        ),
      );

      final currentMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final currentMonthByCategory = <String, double>{};
      final lastMonthByCategory = <String, double>{};
      for (final row in rows) {
        final key = _normalizedCategory(row.category);
        final d = _parseExpenseDateOrCreated(row);
        if (!d.isBefore(currentMonthStart)) {
          currentMonthByCategory[key] =
              (currentMonthByCategory[key] ?? 0) + row.amountValue;
        } else if (!d.isBefore(lastMonthStart) && d.isBefore(currentMonthStart)) {
          lastMonthByCategory[key] =
              (lastMonthByCategory[key] ?? 0) + row.amountValue;
        }
      }

      final maxMonthTotal = [
        ...currentMonthByCategory.values,
        ...lastMonthByCategory.values,
        1.0,
      ].reduce((a, b) => a > b ? a : b);

      topExpenses.assignAll(
        sortedCats.take(3).map((entry) {
          final current = currentMonthByCategory[entry.key] ?? 0;
          final previous = lastMonthByCategory[entry.key] ?? 0;
          final delta = current - previous;
          final pct = previous > 0
              ? (delta.abs() / previous) * 100
              : (current > 0 ? 100.0 : 0.0);
          return TopExpenseItem(
            category: entry.key,
            subtitle: _subtitleForCategory(entry.key),
            amount: Get.find<CurrencyService>().formatBase(entry.value.round()),
            changePercent: '${pct.toStringAsFixed(1)}%',
            changeUp: delta >= 0,
            thisMonthRatio: (current / maxMonthTotal).clamp(0.0, 1.0),
            lastMonthRatio: (previous / maxMonthTotal).clamp(0.0, 1.0),
            icon: _iconForCategory(entry.key),
          );
        }),
      );
    } finally {
      loading.value = false;
    }
  }

  static String _normalizedCategory(String raw) {
    final c = raw.trim();
    if (c.isEmpty) return 'Other';
    return c;
  }

  static DateTime _parseExpenseDateOrCreated(ExpenseRecord r) {
    final iso = r.datePaidIso.trim();
    if (iso.length >= 10 && iso[4] == '-' && iso[7] == '-') {
      final y = int.tryParse(iso.substring(0, 4));
      final m = int.tryParse(iso.substring(5, 7));
      final d = int.tryParse(iso.substring(8, 10));
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(r.createdAtMs);
    }
  }

  static String _subtitleForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('maint')) return 'Repairs, HVAC, Plumbing';
    if (c.contains('util')) return 'Electric, Water, Gas';
    if (c.contains('staff') || c.contains('salary')) return 'Wages, Contractors';
    if (c.contains('suppl')) return 'Procurement, Consumables';
    return 'Operational expenses';
  }

  static IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('maint')) return Icons.build_outlined;
    if (c.contains('util')) return Icons.bolt_outlined;
    if (c.contains('staff') || c.contains('salary')) return Icons.people_outline;
    if (c.contains('suppl')) return Icons.inventory_2_outlined;
    return Icons.receipt_long_outlined;
  }
}

class ExpenseCategory {
  final String name;
  final double value;
  final int colorIndex;

  ExpenseCategory({
    required this.name,
    required this.value,
    required this.colorIndex,
  });
}

class TopExpenseItem {
  final String category;
  final String subtitle;
  final String amount;
  final String changePercent;
  final bool changeUp;
  final double thisMonthRatio;
  final double lastMonthRatio;
  final IconData icon;

  TopExpenseItem({
    required this.category,
    required this.subtitle,
    required this.amount,
    required this.changePercent,
    required this.changeUp,
    required this.thisMonthRatio,
    required this.lastMonthRatio,
    required this.icon,
  });
}
