import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/utils/getx_instance_probe.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';

enum TenantCategoryFilter { all, bnb, rent }

enum TenantStatusFilter { all, active, past }

class TenantListItem {
  const TenantListItem({
    required this.id,
    required this.name,
    required this.propertyLabel,
    required this.unitLabel,
    required this.leaseStartIso,
    required this.leaseEndIso,
    required this.leaseStartDisplay,
    required this.leaseEndDisplay,
    required this.category,
    required this.isActive,
    required this.phoneNumber,
    required this.rentAmountValue,
    required this.rentFrequency,
    required this.propertyRef,
    required this.apartmentUnitId,
  });

  final int id;
  final String name;
  final String propertyLabel;
  final String unitLabel;
  final String leaseStartIso;
  final String leaseEndIso;
  final String leaseStartDisplay;
  final String leaseEndDisplay;

  /// 'bnb' or 'rent'
  final String category;
  final bool isActive;
  final String phoneNumber;
  final double rentAmountValue;
  final String rentFrequency;
  final String propertyRef;
  final String apartmentUnitId;

  bool get isBnb => category == 'bnb';
}

class AllTenantsController extends BaseController {
  AllTenantsController()
      : _tenantLocal = Get.find<TenantLocalDataSource>(),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _currency = Get.find<CurrencyService>();

  final TenantLocalDataSource _tenantLocal;
  final PropertyLocalDataSource _propertyLocal;
  final CurrencyService _currency;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  final allItems = <TenantListItem>[].obs;
  final filteredItems = <TenantListItem>[].obs;
  final isLoading = false.obs;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final categoryFilter = TenantCategoryFilter.all.obs;
  final statusFilter = TenantStatusFilter.all.obs;

  int get bnbCount =>
      allItems.where((t) => t.isBnb).length;

  int get rentCount =>
      allItems.where((t) => !t.isBnb).length;

  @override
  void onInit() {
    super.onInit();
    loadTenants();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  static Future<void> refreshIfRegistered() async {
    if (!GetxInstanceProbe.isAlive<AllTenantsController>()) return;
    await Get.find<AllTenantsController>().loadTenants();
  }

  Future<void> loadTenants() async {
    isLoading.value = true;
    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final bnbTenants =
          await _tenantLocal.getAllNewestFirstByWorkspace('bnb');
      final rentTenants =
          await _tenantLocal.getAllNewestFirstByWorkspace('rent');

      final names = await _propertyNamesByRef();

      TenantListItem mapTenant(TenantRecord t, String cat) {
        final start = _parseDate(t.leaseStartIso);
        final end = _parseDate(t.leaseEndIso);
        final isActive = _computeActive(t, todayDate);
        return TenantListItem(
          id: t.id,
          name: t.tenantName.trim(),
          propertyLabel: _propertyNameFor(t, names),
          unitLabel: t.unitLabel.trim(),
          leaseStartIso: t.leaseStartIso,
          leaseEndIso: t.leaseEndIso,
          leaseStartDisplay: start != null ? _dateFmt.format(start) : '—',
          leaseEndDisplay: end != null ? _dateFmt.format(end) : 'Ongoing',
          category: cat,
          isActive: isActive,
          phoneNumber: t.phoneNumber,
          rentAmountValue: t.rentAmountValue,
          rentFrequency: t.rentFrequency,
          propertyRef: t.propertyRef,
          apartmentUnitId: t.apartmentUnitId,
        );
      }

      final combined = [
        ...bnbTenants.map((t) => mapTenant(t, 'bnb')),
        ...rentTenants.map((t) => mapTenant(t, 'rent')),
      ];

      // Sort: active first, then by name
      combined.sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      allItems.assignAll(combined);
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    _applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilters();
  }

  void setCategoryFilter(TenantCategoryFilter filter) {
    categoryFilter.value = filter;
    _applyFilters();
  }

  void setStatusFilter(TenantStatusFilter filter) {
    statusFilter.value = filter;
    _applyFilters();
  }

  void _applyFilters() {
    var result = allItems.toList();

    // Category filter
    switch (categoryFilter.value) {
      case TenantCategoryFilter.bnb:
        result = result.where((t) => t.isBnb).toList();
        break;
      case TenantCategoryFilter.rent:
        result = result.where((t) => !t.isBnb).toList();
        break;
      case TenantCategoryFilter.all:
        break;
    }

    // Status filter
    switch (statusFilter.value) {
      case TenantStatusFilter.active:
        result = result.where((t) => t.isActive).toList();
        break;
      case TenantStatusFilter.past:
        result = result.where((t) => !t.isActive).toList();
        break;
      case TenantStatusFilter.all:
        break;
    }

    // Search filter
    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (t) =>
                t.name.toLowerCase().contains(q) ||
                t.propertyLabel.toLowerCase().contains(q) ||
                t.unitLabel.toLowerCase().contains(q) ||
                t.phoneNumber.contains(q),
          )
          .toList();
    }

    filteredItems.assignAll(result);
  }

  String formatAmount(double amount) =>
      _currency.formatBase(amount.round());

  Future<Map<String, String>> _propertyNamesByRef() async {
    final names = <String, String>{};
    final rows = await _propertyLocal.getAllNewestFirst();
    for (final row in rows) {
      final name = row.propertyName.trim().isNotEmpty
          ? row.propertyName.trim()
          : row.propertyLocation.trim();
      if (name.isEmpty) continue;
      final ref = row.propertyRef.trim();
      if (ref.isNotEmpty) names[ref] = name;
      names['local_${row.id}'] = name;
      names['legacy_${row.id}'] = name;
    }
    return names;
  }

  String _propertyNameFor(TenantRecord tenant, Map<String, String> names) {
    final ref = tenant.propertyRef.trim();
    final fromRef = ref.isEmpty ? null : names[ref];
    if (fromRef != null && fromRef.isNotEmpty) return fromRef;
    final label = tenant.propertyLabel.trim();
    final fromLabel = label.isEmpty ? null : names[label];
    if (fromLabel != null && fromLabel.isNotEmpty) return fromLabel;
    if (_looksLikePropertyRef(label)) return '';
    return label;
  }

  static bool _looksLikePropertyRef(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    if (v.startsWith('local_') ||
        v.startsWith('legacy_') ||
        v.startsWith('remote_')) {
      return true;
    }
    return RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(v);
  }

  static bool _computeActive(TenantRecord t, DateTime todayDate) {
    final end = _parseDate(t.leaseEndIso);
    if (end == null) return true;
    return !DateTime(end.year, end.month, end.day).isBefore(todayDate);
  }

  /// Date-only values stay on that calendar day. [DateTime.parse] treats
  /// `yyyy-MM-dd` as UTC, which shows the previous day in East Africa.
  static DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.length >= 10 && t[4] == '-' && t[7] == '-') {
      final y = int.tryParse(t.substring(0, 4));
      final m = int.tryParse(t.substring(5, 7));
      final d = int.tryParse(t.substring(8, 10));
      if (y != null &&
          m != null &&
          m >= 1 &&
          m <= 12 &&
          d != null &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(t);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
