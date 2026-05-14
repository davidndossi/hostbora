import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';

/// Filters the payment list by how a row compares to the tenant's configured rent.
enum ManagePaymentStatusFilter { all, full, partial }

/// One row for the Manage payments list (actual income or projected rent).
class ManagePaymentsRowUi {
  const ManagePaymentsRowUi({
    required this.isExpected,
    required this.tenantName,
    required this.apartmentLine,
    required this.paidDate,
    required this.categoryLabel,
    required this.amountTsh,
    required this.isFullPayment,
    required this.hasRentComparableStatus,
  });

  final bool isExpected;
  final String tenantName;
  final String apartmentLine;
  final DateTime? paidDate;
  final String categoryLabel;
  final double amountTsh;
  /// For rent-like categories: paid >= one-period rent. For expected rows, always true.
  final bool isFullPayment;
  /// When false, status chip shows em dash (non-rent income).
  final bool hasRentComparableStatus;
}

class ManagePaymentsController extends BaseController {
  ManagePaymentsController()
      : _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>();

  final IncomeLocalDataSource _incomeLocal;
  final TenantLocalDataSource _tenantLocal;

  static final NumberFormat moneyFormat = NumberFormat('#,###', 'en_US');
  static final DateFormat monthFormat = DateFormat('MMM yyyy');

  /// Calendar months from [onInit] (past → future) for the month dropdown.
  late final List<DateTime> monthChoices;

  final selectedMonthIndex = 0.obs;
  final apartmentKeys = <String>[''].obs;
  final selectedApartmentKey = ''.obs;
  final statusFilter = ManagePaymentStatusFilter.all.obs;
  final filterStart = Rxn<DateTime>();
  final filterEnd = Rxn<DateTime>();
  final rows = <ManagePaymentsRowUi>[].obs;
  final totalTsh = 0.0.obs;
  final loading = false.obs;

  DateTime get selectedMonth =>
      monthChoices[selectedMonthIndex.value.clamp(0, monthChoices.length - 1)];

  bool get isFutureMonth {
    final m = selectedMonth;
    final now = DateTime.now();
    final cur = DateTime(now.year, now.month, 1);
    return m.isAfter(cur);
  }

  String get totalLabel => 'Tsh ${moneyFormat.format(totalTsh.value.round())}';

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

  void setStatusFilter(ManagePaymentStatusFilter f) {
    statusFilter.value = f;
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

  void clearDateFilters() {
    filterStart.value = null;
    filterEnd.value = null;
    refreshRows();
  }

  Future<void> refreshRows() async {
    loading.value = true;
    try {
      final income = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
      final tenants = await _tenantLocal.getAllNewestFirstByWorkspace('rent');

      final y = selectedMonth.year;
      final m = selectedMonth.month;

      final keys = <String>{''};
      for (final r in income) {
        keys.add(_apartmentKeyFromIncome(r));
      }
      for (final t in tenants) {
        keys.add(_apartmentKeyFromTenant(t));
      }
      final sortedKeys = keys.where((k) => k.isNotEmpty).toList()..sort();
      apartmentKeys.assignAll(['', ...sortedKeys]);

      final built = <ManagePaymentsRowUi>[];

      if (isFutureMonth) {
        /// **Expected rent for a future calendar month** uses [TenantRecord] lease overlap
        /// with that month and `rent_amount_value` + `rent_frequency` only (no separate
        /// schedule table in local DB). Assumptions documented on [_expectedRentForTenantMonth].
        for (final t in tenants) {
          final expected = _expectedRentForTenantMonth(t, y, m);
          if (expected <= 0) continue;
          final line = _apartmentKeyFromTenant(t);
          if (!_apartmentFilterMatches(line)) continue;
          if (statusFilter.value == ManagePaymentStatusFilter.partial) {
            continue;
          }
          built.add(
            ManagePaymentsRowUi(
              isExpected: true,
              tenantName: t.tenantName.trim(),
              apartmentLine: line,
              paidDate: null,
              categoryLabel: '',
              amountTsh: expected,
              isFullPayment: true,
              hasRentComparableStatus: true,
            ),
          );
        }
        built.sort((a, b) => a.tenantName.toLowerCase().compareTo(b.tenantName.toLowerCase()));
      } else {
        for (final r in income) {
          final paid = r.paidLocalCalendarOrCreated();
          if (paid.year != y || paid.month != m) continue;
          if (!_inDateRange(paid)) continue;
          final line = _apartmentKeyFromIncome(r);
          if (!_apartmentFilterMatches(line)) continue;

          final tenant = _findTenantForIncome(r, tenants);
          final rentComparable = _isRentCategory(r.category);
          var full = true;
          var hasStatus = false;
          if (rentComparable && tenant != null && tenant.rentAmountValue > 0) {
            hasStatus = true;
            final expected = tenant.rentAmountValue;
            full = r.amountValue + 0.5 >= expected;
          }

          if (statusFilter.value == ManagePaymentStatusFilter.full &&
              (!hasStatus || !full)) {
            continue;
          }
          if (statusFilter.value == ManagePaymentStatusFilter.partial &&
              (!hasStatus || full)) {
            continue;
          }

          built.add(
            ManagePaymentsRowUi(
              isExpected: false,
              tenantName: r.tenantName.trim(),
              apartmentLine: line,
              paidDate: paid,
              categoryLabel: r.category.trim(),
              amountTsh: r.amountValue,
              isFullPayment: full,
              hasRentComparableStatus: hasStatus,
            ),
          );
        }
        built.sort((a, b) {
          final da = a.paidDate;
          final db = b.paidDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
      }

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

  static String _apartmentKeyFromIncome(IncomeRecord r) {
    final a = r.apartment.trim();
    final u = r.apartmentUnit.trim();
    if (u.isEmpty) return a;
    if (a.isEmpty) return u;
    return '$a · $u';
  }

  static String _apartmentKeyFromTenant(TenantRecord t) {
    final pl = t.propertyLabel.trim();
    final u = t.unitLabel.trim();
    if (u.isEmpty) return pl;
    if (pl.isEmpty) return u;
    return '$pl · $u';
  }

  static bool _isRentCategory(String category) {
    final c = category.trim().toLowerCase();
    return c == 'rent' || c == 'lease';
  }

  /// Same name + property blob idea as [RentTenantLedgerOccupancyController._incomeRowMatchesTenant].
  TenantRecord? _findTenantForIncome(IncomeRecord r, List<TenantRecord> tenants) {
    for (final t in tenants) {
      if (_incomeRowMatchesTenant(r, t)) return t;
    }
    return null;
  }

  static bool _incomeRowMatchesTenant(IncomeRecord r, TenantRecord t) {
    if (r.tenantName.trim().toLowerCase() != t.tenantName.trim().toLowerCase()) {
      return false;
    }
    final pl = t.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return true;
    final ap = r.apartment.trim().toLowerCase();
    final unit = r.apartmentUnit.trim().toLowerCase();
    final blob = '$ap $unit'.trim();
    return blob.contains(pl) || pl.contains(ap);
  }

  static DateTime? _parseIsoDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  static bool _leaseIntersectsMonth(TenantRecord t, int year, int month) {
    final start = _parseIsoDate(t.leaseStartIso);
    final end = _parseIsoDate(t.leaseEndIso);
    final ms = DateTime(year, month, 1);
    final me = DateTime(year, month + 1, 0);
    if (start == null || end == null) {
      return true;
    }
    return !end.isBefore(ms) && !start.isAfter(me);
  }

  /// Expected rent for one calendar month from tenant terms (no proration table).
  ///
  /// - **Per Month** (default): one [TenantRecord.rentAmountValue] if the lease intersects the month.
  /// - **Per Week**: `ceil(overlapDays / 7) * rentAmountValue`.
  /// - **Per Day**: `overlapDays * rentAmountValue`.
  /// - **Per Year**: `rentAmountValue / 12` for any intersecting month (simple monthly spread;
  ///   there is no stored annual payment calendar).
  static double _expectedRentForTenantMonth(TenantRecord t, int year, int month) {
    if (!_leaseIntersectsMonth(t, year, month)) return 0;
    final start = _parseIsoDate(t.leaseStartIso);
    final end = _parseIsoDate(t.leaseEndIso);
    final ms = DateTime(year, month, 1);
    final me = DateTime(year, month + 1, 0);
    if (start == null || end == null) {
      return t.rentAmountValue <= 0 ? 0 : t.rentAmountValue;
    }
    DateTime ovStart = start.isAfter(ms) ? start : ms;
    DateTime ovEnd = end.isBefore(me) ? end : me;
    if (ovEnd.isBefore(ovStart)) return 0;
    final overlapDays = ovEnd.difference(ovStart).inDays + 1;
    final freq = t.rentFrequency.trim().toLowerCase();
    final r = t.rentAmountValue;
    if (r <= 0) return 0;
    switch (freq) {
      case 'per day':
        return r * overlapDays;
      case 'per week':
        return r * (overlapDays / 7).ceil();
      case 'per year':
        return r / 12;
      case 'per month':
      default:
        return r;
    }
  }
}
