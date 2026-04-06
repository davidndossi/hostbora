import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_tenant_local_data_source.dart';
import '../../../../routes/app_pages.dart';

/// Payment box state for M1…M6 ledger.
enum ResidencyMonthStatus {
  paid,
  partial,
  upcoming,
}

class TenantInsight {
  TenantInsight({
    required this.id,
    required this.name,
    required this.propertyLine,
    required this.totalStayLabel,
    required this.leasePeriodLabel,
    required this.leaseProgress,
    required this.monthStatuses,
    required this.onSchedule,
    required this.paidAmount,
    required this.totalAmount,
  });

  final String id;
  final String name;
  final String propertyLine;
  final String totalStayLabel;
  final String leasePeriodLabel;
  /// 0.0 – 1.0
  final double leaseProgress;
  final List<ResidencyMonthStatus> monthStatuses;
  final bool onSchedule;
  final double paidAmount;
  final double totalAmount;
}

class RentTenantResidencyPaymentTrackerController extends BaseController {
  RentTenantResidencyPaymentTrackerController()
      : _tenantLocal = Get.find<RentTenantLocalDataSource>();

  final RentTenantLocalDataSource _tenantLocal;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final tenants = <TenantInsight>[].obs;

  int get activeLeasesCount => tenants.length;
  double get collectionRatePct {
    if (tenants.isEmpty) return 0;
    final onScheduleCount = tenants.where((e) => e.onSchedule).length;
    return (onScheduleCount * 100 / tenants.length);
  }

  @override
  void onReady() {
    super.onReady();
    loadTenants();
  }

  List<TenantInsight> get filteredTenants {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return tenants.toList();
    return tenants
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.propertyLine.toLowerCase().contains(q),
        )
        .toList();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void onFilterPressed() {
    Get.snackbar('Filter', 'Filters coming soon');
  }

  void openTenantLedger(TenantInsight t) {
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'id': t.id,
        'name': t.name,
        'property': t.propertyLine,
      },
    );
  }

  Future<void> loadTenants() async {
    final rows = await _tenantLocal.getAllNewestFirst();
    final fmt = DateFormat('MMM yyyy');
    tenants.assignAll(rows.map((r) {
      final start = _parseDate(r.leaseStartIso) ?? DateTime.now();
      final end = _parseDate(r.leaseEndIso) ?? DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();
      final totalMonths = _monthsBetween(start, end).clamp(1, 240);
      final spentMonths = _monthsBetween(start, now).clamp(0, totalMonths);
      final progress = (spentMonths / totalMonths).clamp(0.0, 1.0);
      final totalAmount = r.rentAmountValue * totalMonths;
      final paidAmount = (r.rentAmountValue * spentMonths).clamp(0, totalAmount);
      return TenantInsight(
        id: '${r.id}',
        name: r.tenantName,
        propertyLine: r.propertyLabel,
        totalStayLabel: '$spentMonths Months',
        leasePeriodLabel: '${fmt.format(start).toUpperCase()} - ${fmt.format(end).toUpperCase()}',
        leaseProgress: progress,
        monthStatuses: List<ResidencyMonthStatus>.generate(
          6,
          (i) {
            if (i < spentMonths.clamp(0, 6)) return ResidencyMonthStatus.paid;
            return ResidencyMonthStatus.upcoming;
          },
        ),
        onSchedule: now.isBefore(end),
        paidAmount: paidAmount.toDouble(),
        totalAmount: totalAmount.toDouble(),
      );
    }));
  }

  DateTime? _parseDate(String v) {
    try {
      final d = DateTime.parse(v);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
