import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
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
        _currency = Get.find<CurrencyService>();

  final TenantLocalDataSource _tenantLocal;
  final CurrencyService _currency;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  final allItems = <TenantListItem>[].obs;
  final filteredItems = <TenantListItem>[].obs;
  final isLoading = false.obs;

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

  Future<void> loadTenants() async {
    isLoading.value = true;
    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final bnbTenants =
          await _tenantLocal.getAllNewestFirstByWorkspace('bnb');
      final rentTenants =
          await _tenantLocal.getAllNewestFirstByWorkspace('rent');

      TenantListItem _map(TenantRecord t, String cat) {
        final start = _parseDate(t.leaseStartIso);
        final end = _parseDate(t.leaseEndIso);
        final isActive = _computeActive(t, todayDate);
        return TenantListItem(
          id: t.id,
          name: t.tenantName.trim(),
          propertyLabel: t.propertyLabel.trim(),
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
        ...bnbTenants.map((t) => _map(t, 'bnb')),
        ...rentTenants.map((t) => _map(t, 'rent')),
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

  static bool _computeActive(TenantRecord t, DateTime todayDate) {
    final endRaw = t.leaseEndIso.trim();
    if (endRaw.isEmpty) return true;
    final end = DateTime.tryParse(endRaw);
    if (end == null) return true;
    return !DateTime(end.year, end.month, end.day).isBefore(todayDate);
  }

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}
