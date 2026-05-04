import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../routes/app_pages.dart';

class ContractCardVm {
  ContractCardVm({
    required this.tenantId,
    required this.propertyLineCaps,
    required this.propertySearchText,
    required this.tenantName,
    required this.leaseEnd,
    required this.daysUntilExpiry,
    required this.hasContractFile,
  });

  final int tenantId;
  /// e.g. "MASAKI 2BR • UNIT A" for display
  final String propertyLineCaps;
  final String propertySearchText;
  final String tenantName;
  final DateTime? leaseEnd;
  final int daysUntilExpiry;
  final bool hasContractFile;

  bool get isExpiredOrDue => daysUntilExpiry <= 0;

  /// Red / urgent row (design: expires in 14 days)
  bool get isUrgent => daysUntilExpiry > 0 && daysUntilExpiry <= 14;

  /// Light badge (e.g. 90 days left — show band 15–120 days, not urgent)
  bool get showDaysLeftBadge =>
      daysUntilExpiry > 14 && daysUntilExpiry <= 120;
}

class RentContractHubController extends BaseController {
  RentContractHubController() : _tenantLocal = Get.find<TenantLocalDataSource>();

  final TenantLocalDataSource _tenantLocal;

  final loading = true.obs;
  final searchQuery = ''.obs;
  /// When true, only tenants with lease ending within 30 days (or overdue).
  final filterExpiringSoon = false.obs;
  final contracts = <ContractCardVm>[].obs;

  final searchController = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    loadContracts();
  }

  Future<void> loadContracts() async {
    loading.value = true;
    try {
      final rows = await _tenantLocal.getAllNewestFirst();
      final today = DateTime.now();
      final d0 = DateTime(today.year, today.month, today.day);

      final vms = rows.map((r) {
        DateTime? end;
        var days = 9999;
        try {
          final parsed = DateTime.parse(r.leaseEndIso);
          end = DateTime(parsed.year, parsed.month, parsed.day);
          days = end.difference(d0).inDays;
        } catch (_) {
          end = null;
        }

        final loc = r.propertyLabel.trim();
        final unit = r.unitLabel.trim();
        final capsLine = _toCapsLine(loc, unit);
        final searchBlob = '${r.tenantName} $loc $unit'.toLowerCase();

        return ContractCardVm(
          tenantId: r.id,
          propertyLineCaps: capsLine,
          propertySearchText: searchBlob,
          tenantName: r.tenantName.trim().isNotEmpty ? r.tenantName.trim() : 'Tenant',
          leaseEnd: end,
          daysUntilExpiry: days,
          hasContractFile: r.contractFilePath.trim().isNotEmpty,
        );
      }).toList();

      vms.sort((a, b) {
        final da = a.daysUntilExpiry;
        final db = b.daysUntilExpiry;
        if (da != db) return da.compareTo(db);
        return a.tenantName.compareTo(b.tenantName);
      });

      contracts.assignAll(vms);
    } finally {
      loading.value = false;
    }
  }

  static String _toCapsLine(String loc, String unit) {
    final a = loc.toUpperCase();
    if (unit.isEmpty) return a.isEmpty ? 'PROPERTY' : a;
    final u = unit.toUpperCase();
    if (a.isEmpty) return u;
    return '$a • $u';
  }

  List<ContractCardVm> get filteredContracts {
    var list = contracts.toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (c) =>
                c.tenantName.toLowerCase().contains(q) ||
                c.propertyLineCaps.toLowerCase().contains(q) ||
                c.propertySearchText.contains(q),
          )
          .toList();
    }
    if (filterExpiringSoon.value) {
      list = list.where((c) => c.daysUntilExpiry <= 30).toList();
    }
    return list;
  }

  void setSearch(String v) => searchQuery.value = v;

  void setFilterExpiringSoon(bool v) => filterExpiringSoon.value = v;

  Future<void> onRefresh() => loadContracts();

  Future<void> onUploadSignedLease() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (r != null && r.files.isNotEmpty) {
      showSuccessMessage(
        Get.locale?.languageCode == 'sw'
            ? 'Faili imechaguliwa — uhifadhi wa vault unaendelea.'
            : 'File selected — vault sync coming soon.',
      );
    }
  }

  void onViewContract(ContractCardVm c) {
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'id': '${c.tenantId}',
        'name': c.tenantName,
        'property': c.propertyLineCaps,
      },
    );
  }

  void onRenewLease(ContractCardVm c) {
    Get.toNamed(
      Routes.RENT_LEASE_RENEWAL_FORM,
      parameters: {
        'tenantName': c.tenantName,
        'property': c.propertyLineCaps,
      },
    );
  }

  void openFiltersSheet() {
    final isSw = Get.locale?.languageCode == 'sw';
    Get.bottomSheet<void>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSw ? 'Vichujio' : 'Filters',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isSw ? 'Yanayoisha ndani ya siku 30' : 'Expiring within 30 days',
                ),
                value: filterExpiringSoon.value,
                onChanged: setFilterExpiringSoon,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void openNotifications() {
    Get.toNamed(Routes.NOTIFICATIONS);
  }

  String formatExpiry(ContractCardVm c, {required bool isSw}) {
    if (c.leaseEnd == null) {
      return isSw ? 'Tarehe haijulikani' : 'Date not set';
    }
    final loc = isSw ? 'sw' : 'en_US';
    try {
      return DateFormat.yMMMd(loc).format(c.leaseEnd!);
    } catch (_) {
      return DateFormat.yMMMd('en_US').format(c.leaseEnd!);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
