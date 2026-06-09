import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../routes/app_pages.dart';

class ExpenseAnalysisController extends BaseController {
  ExpenseAnalysisController() : _expenseLocal = Get.find<ExpenseLocalDataSource>();

  final ExpenseLocalDataSource _expenseLocal;
  final selectedPropertyKey = ''.obs;
  final selectedProperty = 'All Properties'.obs;
  final dateRangeLabel = ''.obs;
  final loading = false.obs;

  final totalAmountLabel = 'Tshs. 0'.obs;

  final expenseCategories = <ExpenseCategory>[].obs;
  final topExpenses = <TopExpenseItem>[].obs;

  /// Inclusive calendar-day range (date-only).
  final rangeStart = _calendarToday().subtract(const Duration(days: 29)).obs;
  final rangeEnd = _calendarToday().obs;

  static DateTime _calendarToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _t(String en, String sw) =>
      Get.locale?.languageCode == 'sw' ? sw : en;

  String get _allPropertiesLabel =>
      _t('All Properties', 'Mali zote');

  @override
  void onInit() {
    super.onInit();
    _syncFilterLabels();
  }

  @override
  void onReady() {
    super.onReady();
    loadRealExpenseData();
  }

  void goBack() => Get.back();

  void openMoreOptions() {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(_t('Refresh', 'Sasisha')),
              onTap: () {
                Get.back();
                loadRealExpenseData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(_t('Download report', 'Pakua ripoti')),
              onTap: () {
                Get.back();
                downloadReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(_t('Add expense', 'Ongeza matumizi')),
              onTap: () {
                Get.back();
                goToAddExpense();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(appLocalization.cancel),
              onTap: Get.back,
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> selectPropertyFilter() async {
    final rows = await _expenseLocal.getAllNewestFirst(workspaceType: '');
    final keys = <String>{};
    for (final r in rows) {
      final k = _apartmentLine(r).trim();
      if (k.isNotEmpty) keys.add(k);
    }
    final sorted = keys.toList()..sort();

    Get.bottomSheet(
      SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: Get.height * 0.65),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _t('Property', 'Mali'),
                    style: Get.textTheme.titleSmall,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: Text(_allPropertiesLabel),
                  trailing: selectedPropertyKey.value.isEmpty
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                  onTap: () {
                    selectedPropertyKey.value = '';
                    selectedProperty.value = _allPropertiesLabel;
                    Get.back();
                    loadRealExpenseData();
                  },
                ),
                ...sorted.map((key) {
                  final sel = selectedPropertyKey.value == key;
                  return ListTile(
                    title: Text(key, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing:
                        sel ? const Icon(Icons.check, color: Colors.teal) : null,
                    onTap: () {
                      selectedPropertyKey.value = key;
                      selectedProperty.value = key;
                      Get.back();
                      loadRealExpenseData();
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> selectDateRange() async {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _t('Date range', 'Kipindi cha tarehe'),
                style: Get.textTheme.titleSmall,
              ),
            ),
            ListTile(
              title: Text(_t('Last 7 days', 'Siku 7 zilizopita')),
              onTap: () {
                final end = _calendarToday();
                Get.back();
                _setRange(end.subtract(const Duration(days: 6)), end);
              },
            ),
            ListTile(
              title: Text(_t('Last 30 days', 'Siku 30 zilizopita')),
              onTap: () {
                final end = _calendarToday();
                Get.back();
                _setRange(end.subtract(const Duration(days: 29)), end);
              },
            ),
            ListTile(
              title: Text(_t('Last 90 days', 'Siku 90 zilizopita')),
              onTap: () {
                final end = _calendarToday();
                Get.back();
                _setRange(end.subtract(const Duration(days: 89)), end);
              },
            ),
            ListTile(
              title: Text(_t('This month', 'Mwezi huu')),
              onTap: () {
                final n = DateTime.now();
                Get.back();
                _setRange(DateTime(n.year, n.month, 1), _calendarToday());
              },
            ),
            ListTile(
              title: Text(_t('Last month', 'Mwezi uliopita')),
              onTap: () {
                final n = DateTime.now();
                final thisMonth = DateTime(n.year, n.month, 1);
                final lastEnd = thisMonth.subtract(const Duration(days: 1));
                Get.back();
                _setRange(
                  DateTime(lastEnd.year, lastEnd.month, 1),
                  DateTime(lastEnd.year, lastEnd.month, lastEnd.day),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(_t('Custom range…', 'Kipindi maalum…')),
              onTap: () async {
                Get.back();
                await _pickCustomDateRange();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(appLocalization.cancel),
              onTap: Get.back,
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void _setRange(DateTime start, DateTime end) {
    rangeStart.value = DateTime(start.year, start.month, start.day);
    rangeEnd.value = DateTime(end.year, end.month, end.day);
    loadRealExpenseData();
  }

  Future<void> _pickCustomDateRange() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final initial = DateTimeRange(
      start: rangeStart.value,
      end: rangeEnd.value,
    );
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initial,
      locale: const Locale('en', 'GB'),
    );
    if (picked != null) {
      _setRange(picked.start, picked.end);
    }
  }

  void viewAllExpenses() {
    Get.toNamed(
      Routes.RENT_MANAGE_EXPENSES,
      arguments: {'ws': ''},
    )?.then((_) => loadRealExpenseData());
  }

  Future<void> goToAddExpense() async {
    final saved = await Get.toNamed(Routes.ADD_EXPENSE);
    if (saved == true) {
      await loadRealExpenseData();
    }
  }

  Future<void> downloadReport() async {
    final rows = await _filteredBnbRows();
    if (rows.isEmpty) {
      showErrorMessage(
        _t('No expenses in the selected filters.', 'Hakuna matumizi kwa vigezo ulivyochagua.'),
      );
      return;
    }
    final fx = Get.find<CurrencyService>();
    final buf = StringBuffer('\uFEFF');
    buf.writeln(
      [
        _csvEscape(_t('Date', 'Tarehe')),
        _csvEscape(_t('Category', 'Aina')),
        _csvEscape(_t('Amount (base)', 'Kiasi (msingi)')),
        _csvEscape(_t('Property / unit', 'Mali / kitengo')),
        _csvEscape(_t('Notes', 'Maelezo')),
      ].join(','),
    );
    for (final r in rows) {
      final d = _parseExpenseDateOrCreated(r);
      buf.writeln(
        [
          _csvEscape(DateFormat('dd/MM/yyyy').format(d)),
          _csvEscape(_normalizedCategory(r.category)),
          _csvEscape(fx.formatBase(r.amountValue.round())),
          _csvEscape(_apartmentLine(r)),
          _csvEscape(r.notes.trim()),
        ].join(','),
      );
    }
    try {
      final dir = await getTemporaryDirectory();
      final name =
          'expense_analysis_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$name');
      await file.writeAsString(buf.toString(), flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')]);
      showSuccessMessage(
        _t('Report ready to share.', 'Ripoti iko tayari kushirikiwa.'),
      );
    } catch (e) {
      showErrorMessage(e.toString());
    }
  }

  void _syncFilterLabels() {
    final start = rangeStart.value;
    final end = rangeEnd.value;
    dateRangeLabel.value =
        '${DateFormat('dd/MM').format(start)} – ${DateFormat('dd/MM/yyyy').format(end)}';
    selectedProperty.value = selectedPropertyKey.value.trim().isEmpty
        ? _allPropertiesLabel
        : selectedPropertyKey.value.trim();
  }

  Future<List<ExpenseRecord>> _filteredBnbRows() async {
    final rows = await _expenseLocal.getAllNewestFirst(workspaceType: 'bnb');
    final key = selectedPropertyKey.value.trim();
    final propFiltered = key.isEmpty
        ? rows
        : rows.where((r) => _apartmentLine(r) == key).toList();

    final start = DateTime(
      rangeStart.value.year,
      rangeStart.value.month,
      rangeStart.value.day,
    );
    final end = DateTime(
      rangeEnd.value.year,
      rangeEnd.value.month,
      rangeEnd.value.day,
    );

    return propFiltered.where((r) {
      final d = _parseExpenseDateOrCreated(r);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  static String _csvEscape(String s) {
    final t = s.replaceAll('"', '""');
    if (t.contains(',') || t.contains('\n') || t.contains('"')) {
      return '"$t"';
    }
    return t;
  }

  static String _apartmentLine(ExpenseRecord r) {
    final a = r.apartment.trim();
    final u = r.apartmentUnit.trim();
    if (u.isEmpty) return a;
    if (a.isEmpty) return u;
    return '$a · $u';
  }

  Future<void> loadRealExpenseData() async {
    loading.value = true;
    try {
      _syncFilterLabels();
      final rows = await _expenseLocal.getAllNewestFirst(workspaceType: '');
      final key = selectedPropertyKey.value.trim();
      final rowsForProperty = key.isEmpty
          ? rows
          : rows.where((r) => _apartmentLine(r) == key).toList();

      final start = DateTime(
        rangeStart.value.year,
        rangeStart.value.month,
        rangeStart.value.day,
      );
      final end = DateTime(
        rangeEnd.value.year,
        rangeEnd.value.month,
        rangeEnd.value.day,
      );

      final inRange = rowsForProperty.where((r) {
        final d = _parseExpenseDateOrCreated(r);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();

      final total = inRange.fold<double>(0, (sum, e) => sum + e.amountValue);
      totalAmountLabel.value =
          Get.find<CurrencyService>().formatBase(total.round());

      final byCategory = <String, double>{};
      for (final row in inRange) {
        final cat = _normalizedCategory(row.category);
        byCategory[cat] = (byCategory[cat] ?? 0) + row.amountValue;
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

      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final currentMonthByCategory = <String, double>{};
      final lastMonthByCategory = <String, double>{};
      for (final row in rowsForProperty) {
        final cat = _normalizedCategory(row.category);
        final d = _parseExpenseDateOrCreated(row);
        if (!d.isBefore(currentMonthStart)) {
          currentMonthByCategory[cat] =
              (currentMonthByCategory[cat] ?? 0) + row.amountValue;
        } else if (!d.isBefore(lastMonthStart) && d.isBefore(currentMonthStart)) {
          lastMonthByCategory[cat] =
              (lastMonthByCategory[cat] ?? 0) + row.amountValue;
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
