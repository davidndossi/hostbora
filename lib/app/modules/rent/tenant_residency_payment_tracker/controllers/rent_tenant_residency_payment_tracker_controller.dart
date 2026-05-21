import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
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
    required this.phoneNumber,
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
  final String phoneNumber;
}

class RentTenantResidencyPaymentTrackerController extends BaseController {
  RentTenantResidencyPaymentTrackerController()
      : _tenantLocal = Get.find<TenantLocalDataSource>();

  final TenantLocalDataSource _tenantLocal;
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
    final base = tenants.toList();
    final searched = q.isEmpty
        ? base
        : base
            .where(
              (t) =>
                  t.name.toLowerCase().contains(q) ||
                  t.propertyLine.toLowerCase().contains(q),
            )
            .toList();
    return searched;
  }

  /// App bar label; includes listing name when opened with `propertyTitle` from listing details.
  String get tenantsScreenTitle {
    final isSw = Get.locale?.languageCode == 'sw';
    final t = Get.parameters['propertyTitle']?.trim() ?? '';
    if (t.isEmpty) return isSw ? 'Maarifa ya Upangaji' : 'Tenancy Insights';
    return isSw ? 'Wapangaji — $t' : 'Tenants — $t';
  }

  static bool _recordMatchesListingFilter(TenantRecord t) {
    final ref = Get.parameters['propertyRef']?.trim() ?? '';
    final title = Get.parameters['propertyTitle']?.trim() ?? '';
    final loc = Get.parameters['propertyLoc']?.trim() ?? '';
    final suite = Get.parameters['propertySuite']?.trim() ?? '';
    final hasFilter = ref.isNotEmpty || title.isNotEmpty || loc.isNotEmpty;
    if (!hasFilter) return true;

    final r = t.propertyRef.trim();
    if (ref.isNotEmpty && r.isNotEmpty && r == ref) return true;

    final pl = t.propertyLabel.trim();
    if (ref.isNotEmpty && r.isEmpty) {
      if (title.isNotEmpty && pl == title) return true;
      if (loc.isNotEmpty && pl == loc) return true;
      if (loc.isNotEmpty && suite.isNotEmpty && pl == '$loc · $suite') return true;
    }
    if (ref.isEmpty) {
      if (title.isNotEmpty && pl == title) return true;
      if (loc.isNotEmpty && pl == loc) return true;
      if (loc.isNotEmpty && suite.isNotEmpty && pl == '$loc · $suite') return true;
    }
    return false;
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

  void openSendSmsForFilteredTenants() {
    final scoped = filteredTenants;
    final phones = scoped
        .map((e) => e.phoneNumber.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (phones.isEmpty) {
      showErrorMessage('No tenant phone numbers available');
      return;
    }
    final contextTitle = Get.parameters['propertyTitle']?.trim() ?? '';
    Get.toNamed(
      Routes.SEND_SMS,
      arguments: {
        'phones': phones,
        'propertyRef': Get.parameters['propertyRef'] ?? '',
        'contextLabel': contextTitle.isEmpty
            ? 'Tenancy insights recipients'
            : 'Tenants in $contextTitle',
      },
    );
  }

  Future<void> loadTenants() async {
    String ws = 'rent';
    if (Get.arguments != null && Get.arguments['ws'] != null) {
      ws = Get.arguments['ws'];
    }
    final rows = await _tenantLocal.getAllNewestFirstByWorkspace(ws);
    final scoped = rows.where(_recordMatchesListingFilter).toList();
    final fmt = DateFormat('MMM yyyy');
    tenants.assignAll(scoped.map((r) {
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
        phoneNumber: r.phoneNumber,
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
