import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/local/db/expense_local_data_source.dart';

class ManageExpensesRowUi {
  const ManageExpensesRowUi({
    required this.tenantName,
    required this.apartmentLine,
    required this.paidDate,
    required this.categoryLabel,
    required this.notes,
    required this.amountTsh,
  });

  final String tenantName;
  final String apartmentLine;
  final DateTime paidDate;
  final String categoryLabel;
  final String notes;
  final double amountTsh;
}

class ManageExpensesController extends BaseController {
  ManageExpensesController()
      : _expenseLocal = Get.find<ExpenseLocalDataSource>();

  final ExpenseLocalDataSource _expenseLocal;

  static final NumberFormat moneyFormat = NumberFormat('#,###', 'en_US');
  static final DateFormat monthFormat = DateFormat('MMM yyyy');

  late final List<DateTime> monthChoices;

  final selectedMonthIndex = 0.obs;
  final apartmentKeys = <String>[''].obs;
  final selectedApartmentKey = ''.obs;
  final categoryKeys = <String>[''].obs;
  final selectedCategoryKey = ''.obs;
  final filterStart = Rxn<DateTime>();
  final filterEnd = Rxn<DateTime>();
  final rows = <ManageExpensesRowUi>[].obs;
  final totalTsh = 0.0.obs;
  final loading = false.obs;

  DateTime get selectedMonth =>
      monthChoices[selectedMonthIndex.value.clamp(0, monthChoices.length - 1)];

  String get totalLabel =>
      Get.find<CurrencyService>().formatBase(totalTsh.value.round());

  @override
  void onInit() {
    super.onInit();
    monthChoices = _buildMonthChoices();
    final now = DateTime.now();
    final cur = DateTime(now.year, now.month, 1);
    var idx = monthChoices.indexWhere((e) => e.year == cur.year && e.month == cur.month);
    if (idx < 0) idx = monthChoices.length ~/ 2;
    selectedMonthIndex.value = idx;
  }

  @override
  void onReady() {
    super.onReady();
    refreshRows();
  }

  List<DateTime> _buildMonthChoices() {
    final now = DateTime.now();
    final start = DateTime(now.year - 2, now.month, 1);
    final end = DateTime(now.year + 2, now.month, 1);
    final out = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month + 1, 1)) {
      out.add(d);
    }
    return out;
  }

  void setMonthIndex(int? i) {
    if (i == null) return;
    if (i < 0 || i >= monthChoices.length) return;
    selectedMonthIndex.value = i;
    refreshRows();
  }

  void setApartmentFilter(String? key) {
    selectedApartmentKey.value = key ?? '';
    refreshRows();
  }

  void setCategoryFilter(String? key) {
    selectedCategoryKey.value = key ?? '';
    refreshRows();
  }

  Future<void> pickFilterStart() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final initial = filterStart.value ?? selectedMonth;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2018),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      filterStart.value = DateTime(picked.year, picked.month, picked.day);
      refreshRows();
    }
  }

  Future<void> pickFilterEnd() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final initial = filterEnd.value ?? selectedMonth;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2018),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      filterEnd.value = DateTime(picked.year, picked.month, picked.day);
      refreshRows();
    }
  }

  Future<void> refreshRows() async {
    loading.value = true;
    var ws = 'rent';
    if (Get.arguments != null && Get.arguments['ws'] != null) {
      ws = Get.arguments['ws'];
    }
    try {
      final expenses =
          await _expenseLocal.getAllNewestFirst(workspaceType: ws);

      final y = selectedMonth.year;
      final m = selectedMonth.month;

      final aptKeys = <String>{''};
      final catKeys = <String>{''};
      for (final r in expenses) {
        aptKeys.add(_apartmentKeyFromExpense(r));
        final cat = r.category.trim();
        if (cat.isNotEmpty) catKeys.add(cat);
      }
      final sortedApt = aptKeys.where((k) => k.isNotEmpty).toList()..sort();
      apartmentKeys.assignAll(['', ...sortedApt]);
      final sortedCat = catKeys.where((k) => k.isNotEmpty).toList()..sort();
      categoryKeys.assignAll(['', ...sortedCat]);

      final built = <ManageExpensesRowUi>[];
      for (final r in expenses) {
        final paid = r.paidLocalCalendarOrCreated();
        if (paid.year != y || paid.month != m) continue;
        if (!_inDateRange(paid)) continue;
        final line = _apartmentKeyFromExpense(r);
        if (!_apartmentFilterMatches(line)) continue;
        final cat = r.category.trim();
        if (!_categoryFilterMatches(cat)) continue;

        built.add(
          ManageExpensesRowUi(
            tenantName: r.tenantName.trim(),
            apartmentLine: line,
            paidDate: paid,
            categoryLabel: cat,
            notes: r.notes.trim(),
            amountTsh: r.amountValue,
          ),
        );
      }
      built.sort((a, b) => b.paidDate.compareTo(a.paidDate));

      rows.assignAll(built);
      totalTsh.value = built.fold<double>(0, (s, e) => s + e.amountTsh);
    } finally {
      loading.value = false;
    }
  }

  bool _inDateRange(DateTime paidDay) {
    final s = filterStart.value;
    final e = filterEnd.value;
    if (s != null && paidDay.isBefore(s)) return false;
    if (e != null && paidDay.isAfter(e)) return false;
    return true;
  }

  bool _apartmentFilterMatches(String line) {
    final sel = selectedApartmentKey.value.trim();
    if (sel.isEmpty) return true;
    return line.trim() == sel;
  }

  bool _categoryFilterMatches(String category) {
    final sel = selectedCategoryKey.value.trim();
    if (sel.isEmpty) return true;
    return category == sel;
  }

  static String _apartmentKeyFromExpense(ExpenseRecord r) {
    final a = r.apartment.trim();
    final u = r.apartmentUnit.trim();
    if (u.isEmpty) return a;
    if (a.isEmpty) return u;
    return '$a · $u';
  }
}
