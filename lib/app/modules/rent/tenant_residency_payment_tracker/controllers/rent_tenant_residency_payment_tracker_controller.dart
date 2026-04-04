import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
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
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  /// Overview metrics (would come from API).
  final activeLeasesCount = 24;
  final collectionRatePct = 98.2;

  final tenants = <TenantInsight>[
    TenantInsight(
      id: '1',
      name: 'Julianne Moore',
      propertyLine: 'Sea View Apt 402',
      totalStayLabel: '14 Months',
      leasePeriodLabel: 'AUG 2023 - AUG 2024',
      leaseProgress: 0.75,
      monthStatuses: [
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.partial,
        ResidencyMonthStatus.upcoming,
        ResidencyMonthStatus.upcoming,
      ],
      onSchedule: true,
      paidAmount: 8400,
      totalAmount: 14400,
    ),
    TenantInsight(
      id: '2',
      name: 'David Chen',
      propertyLine: 'Harbor Loft 12',
      totalStayLabel: '8 Months',
      leasePeriodLabel: 'JAN 2024 - JAN 2025',
      leaseProgress: 0.42,
      monthStatuses: [
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.partial,
      ],
      onSchedule: false,
      paidAmount: 5200,
      totalAmount: 12000,
    ),
    TenantInsight(
      id: '3',
      name: 'Amara Okafor',
      propertyLine: 'The Azure Penthouse',
      totalStayLabel: '22 Months',
      leasePeriodLabel: 'MAR 2022 - MAR 2025',
      leaseProgress: 0.91,
      monthStatuses: [
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
        ResidencyMonthStatus.paid,
      ],
      onSchedule: true,
      paidAmount: 19200,
      totalAmount: 19200,
    ),
  ].obs;

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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
