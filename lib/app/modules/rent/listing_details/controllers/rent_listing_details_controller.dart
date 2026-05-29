import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/base/feedback_extensions.dart';
import '../../../../core/mixins/listing_financial_trends_mixin.dart';
import '../../../../core/utils/property_listing_image_assigner.dart';
import '../../../../core/utils/tenant_rent_billing.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/property_members_local_data_source.dart';
import '../../../../data/local/db/property_unit_local_data_source.dart';
import '../../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../../routes/app_pages.dart';
import '../../listing_activity_log/controllers/rent_listing_activity_log_controller.dart';
import '../../tenant_residency_payment_tracker/controllers/rent_tenant_residency_payment_tracker_controller.dart';
import '../models/listing_activity_vm.dart';
import '../services/rent_listing_activity_loader.dart';

enum ListingUnitStatus { short, occupied, dueDate }

class ListingUnitRowVm {
  ListingUnitRowVm({
    required this.name,
    required this.subtitle,
    required this.status,
  });

  final String name;
  final String subtitle;
  final ListingUnitStatus status;
}

class ListingStaffVm {
  ListingStaffVm({required this.name, required this.jobTitle});

  final String name;
  final String jobTitle;
}

class RentListingDetailsController extends BaseController
    with ListingFinancialTrendsMixin {
  RentListingDetailsController()
      : _repository =
  Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _membersLocal = Get.find<PropertyMembersLocalDataSource>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final RentStaffLocalDataSource _staffLocal;
  final TenantLocalDataSource _tenantLocal;
  final PropertyUnitLocalDataSource _unitLocal;
  final PropertyMembersLocalDataSource _membersLocal;

  final loadingListing = true.obs;
  final listingTitle = ''.obs;
  final heroOverlayTitle = ''.obs;
  final heroImagePath = ''.obs;
  final occupancyPercent = 0.obs;
  final expectedMonthlyIncomeLabel = '0'.obs;
  final monthlyIncomeLabel = '—'.obs;
  final hasRecordedMonthlyIncome = false.obs;
  final monthlyRevenueProgress = 0.0.obs;

  final listingScrollController = ScrollController();

  final unitRows = <ListingUnitRowVm>[].obs;
  final recentActivity = <ListingActivityVm>[].obs;
  final staffPreview = <ListingStaffVm>[].obs;
  static final _money = NumberFormat('#,###', 'en_US');
  final _activityLoader = RentListingActivityLoader();

  RentListingActivityScope get _activityScope => RentListingActivityScope(
        propertyId: _propertyId,
        propertyName: _propertyName,
        propertyLocation: _propertyLocation,
        isSw: _isSw,
      );

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String get _propertyId {
    final args = Get.arguments;
    if (args is Map) {
      final id = (args['property_id'] ?? args['id'] ?? '').toString().trim();
      if (id.isNotEmpty) return id;
    }
    return Get.parameters['id']?.trim() ?? '';
  }

  String get _propertyName {
    final args = Get.arguments;
    if (args is Map) {
      final n = (args['property_name'] ?? '').toString().trim();
      if (n.isNotEmpty) return n;
    }
    return Get.parameters['title']?.trim() ?? '';
  }

  String get _propertyLocation {
    final args = Get.arguments;
    if (args is Map) {
      return (args['property_location'] ?? '').toString().trim();
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    _applyRouteArguments();
  }

  @override
  void onReady() {
    super.onReady();
    loadListingDetail();
  }

  @override
  void onClose() {
    listingScrollController.dispose();
    super.onClose();
  }

  Future<void> loadListingDetail() async {
    loadingListing.value = true;
    try {
      Map<String, dynamic>? remoteListing;
      if (_propertyId.isNotEmpty) {
        remoteListing = await _fetchListingMapFromRepository(_propertyId);
      }

      // Priority: repository listing detail -> local listing units_json -> fallback demo rows.
      var realRows = remoteListing == null ? <ListingUnitRowVm>[] : _unitRowsFromAnyMap(remoteListing);
      if (realRows.isEmpty) {
        realRows = await _loadUnitRowsFromLocal();
      }
      unitRows.assignAll(realRows.isEmpty ? _fallbackUnitRows() : realRows);
      await _syncOccupancyPercent(remoteListing);
      await _syncMonthlyRevenue(remoteListing);
      await loadListingFinancialTrends(
        workspaceType: 'rent',
        propertyId: _propertyId,
        propertyName: _propertyName,
        propertyLocation: _propertyLocation,
      );

      recentActivity.assignAll(await _resolveRecentActivity(remoteListing));

      var staff = remoteListing == null ? <ListingStaffVm>[] : _staffFromAnyMap(remoteListing);
      if (staff.isEmpty) {
        staff = await _loadStaffFromLocal();
      }
      staffPreview.assignAll(staff);
      await _syncHeroImage();
    } finally {
      loadingListing.value = false;
    }
  }

  Future<void> _syncHeroImage() async {
    if (heroImagePath.value.trim().isNotEmpty &&
        PropertyListingImageAssigner.isNetworkPath(heroImagePath.value)) {
      return;
    }
    final row = await _findLocalPropertyRowForListing();
    if (row != null) {
      heroImagePath.value = PropertyListingImageAssigner.resolveDisplayPath(
        storedPath: row.coverPhotoPath,
        propertyRef: row.propertyRef,
        localPropertyId: row.id,
        propertyName: row.propertyName,
      );
      return;
    }
    if (heroImagePath.value.trim().isNotEmpty) return;
    heroImagePath.value = PropertyListingImageAssigner.resolveDisplayPath(
      storedPath: null,
      propertyRef: _propertyId,
      propertyName: _propertyName,
    );
  }

  /// Refreshes recent activity and monthly revenue without reloading units/staff.
  Future<void> refreshRecentActivityAndRevenue() async {
    Map<String, dynamic>? remoteListing;
    if (_propertyId.isNotEmpty) {
      remoteListing = await _fetchListingMapFromRepository(_propertyId);
    }
    recentActivity.assignAll(await _resolveRecentActivity(remoteListing));
    await _syncMonthlyRevenue(remoteListing);
    await loadListingFinancialTrends(
      workspaceType: 'rent',
      propertyId: _propertyId,
      propertyName: _propertyName,
      propertyLocation: _propertyLocation,
    );
  }

  /// Local income/expense rows win so new entries show immediately after add forms.
  Future<List<ListingActivityVm>> _resolveRecentActivity(
    Map<String, dynamic>? remoteListing,
  ) async {
    final local = await _loadActivityFromLocal();
    if (local.isNotEmpty) return local;
    if (remoteListing == null) return const [];
    return _activityFromAnyMap(remoteListing);
  }

  /// Called when income or expense is saved elsewhere while this screen is open.
  static Future<void> refreshIfRegistered() async {
    await RentListingActivityLogController.refreshIfRegistered();
    if (!Get.isRegistered<RentListingDetailsController>()) return;
    await Get.find<RentListingDetailsController>().refreshRecentActivityAndRevenue();
  }

  Future<void> _syncMonthlyRevenue(Map<String, dynamic>? remoteListing) async {
    final incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final expenses = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    double paymentTotal = 0;
    double expenseTotal = 0;

    final scopeRefs = await _listingScopeRefsForRevenue();

    for (final row in incomes) {
      final d = row.paidLocalCalendarOrCreated();
      if (d.isBefore(start) || !d.isBefore(end)) continue;
      if (!_rowMatchesListingRevenueScope(
        scopeRefs: scopeRefs,
        propertyRef: row.propertyRef,
        apartment: row.apartment,
        apartmentUnit: row.apartmentUnit,
        notes: row.notes,
      )) {
        continue;
      }
      paymentTotal += row.amountValue;
    }

    for (final row in expenses) {
      final d = row.paidLocalCalendarOrCreated();
      if (d.isBefore(start) || !d.isBefore(end)) continue;
      if (!_rowMatchesListingRevenueScope(
        scopeRefs: scopeRefs,
        propertyRef: '',
        apartment: row.apartment,
        apartmentUnit: row.apartmentUnit,
        notes: row.notes,
      )) {
        continue;
      }
      expenseTotal += row.amountValue;
    }

    var tenantMonthRevenue = 0.0;
    try {
      if (_propertyId.isNotEmpty ||
          _propertyName.isNotEmpty ||
          _propertyLocation.isNotEmpty) {
        final tenants = await _tenantLocal.getAllNewestFirst();
        for (final t in tenants) {
          if (!_tenantMatchesListingForMonthlyRevenue(t, scopeRefs)) continue;
          tenantMonthRevenue += TenantRentBilling.revenueInCalendarMonth(
            rentAmountValue: t.rentAmountValue,
            rentFrequency: t.rentFrequency,
            leaseStartIso: t.leaseStartIso,
            leaseEndIso: t.leaseEndIso,
            monthStart: start,
            nextMonthStart: end,
          );
        }
      }
    } catch (_) {}

    final expectedFromUnits = await _expectedIncomeFromLocalUnits();
    final expectedRemote =
        remoteListing != null ? _extractExpectedMonthlyIncome(remoteListing) : 0.0;
    final expectedLocal =
        tenantMonthRevenue > 0 ? tenantMonthRevenue : expectedFromUnits;
    final expected = expectedLocal > 0 ? expectedLocal : expectedRemote;

    final fx = Get.find<CurrencyService>();
    expectedMonthlyIncomeLabel.value = fx.formatBase(expected.round());

    final hasIncome = paymentTotal > 0;
    hasRecordedMonthlyIncome.value = hasIncome;
    if (hasIncome) {
      final netIncome = paymentTotal - expenseTotal;
      monthlyIncomeLabel.value = fx.formatBase(netIncome.round());
      monthlyRevenueProgress.value = expected <= 0
          ? 0
          : (netIncome / expected).clamp(0, 1).toDouble();
    } else {
      monthlyIncomeLabel.value = '—';
      monthlyRevenueProgress.value = 0;
    }
  }

  Future<Set<String>> _listingScopeRefsForRevenue() async {
    final scopeRefs = <String>{};
    if (_propertyId.isNotEmpty) {
      scopeRefs.add(_propertyId);
      final local = await _findLocalPropertyRowForListing();
      if (local != null) {
        if (local.propertyRef.trim().isNotEmpty) {
          scopeRefs.add(local.propertyRef.trim());
        }
        scopeRefs.add('local_${local.id}');
        scopeRefs.add('legacy_${local.id}');
      }
    }
    return scopeRefs;
  }

  bool _rowMatchesListingRevenueScope({
    required Set<String> scopeRefs,
    required String propertyRef,
    required String apartment,
    required String apartmentUnit,
    required String notes,
  }) {
    final pr = propertyRef.trim();
    if (pr.isNotEmpty && scopeRefs.isNotEmpty && scopeRefs.contains(pr)) {
      return true;
    }
    final apt = apartment.trim().toLowerCase();
    final unit = apartmentUnit.trim().toLowerCase();
    final notesLc = notes.trim().toLowerCase();
    final name = _propertyName.toLowerCase();
    final loc = _propertyLocation.toLowerCase();
    if (name.isEmpty && loc.isEmpty) return false;
    if (name.isNotEmpty &&
        (apt.contains(name) || unit.contains(name) || notesLc.contains(name))) {
      return true;
    }
    if (loc.isNotEmpty &&
        (apt.contains(loc) || unit.contains(loc) || notesLc.contains(loc))) {
      return true;
    }
    return false;
  }

  bool _tenantMatchesListingForMonthlyRevenue(
    TenantRecord t,
    Set<String> scopeRefs,
  ) {
    final ref = t.propertyRef.trim();
    if (ref.isNotEmpty && scopeRefs.isNotEmpty && scopeRefs.contains(ref)) {
      return true;
    }
    final labelLc = t.propertyLabel.trim().toLowerCase();
    if (_propertyName.isNotEmpty &&
        labelLc.contains(_propertyName.toLowerCase())) {
      return true;
    }
    if (_propertyLocation.isNotEmpty &&
        labelLc.contains(_propertyLocation.toLowerCase())) {
      return true;
    }
    return false;
  }

  Future<PropertyRecord?> _findLocalPropertyRowForListing() async {
    try {
      final rows = await _propertyLocal.getAllNewestFirst();
      if (rows.isEmpty) return null;
      PropertyRecord? target;
      if (_propertyId.isNotEmpty) {
        for (final r in rows) {
          final localId = 'local_${r.id}';
          final legacyId = 'legacy_${r.id}';
          if (r.propertyRef.trim() == _propertyId ||
              localId == _propertyId ||
              legacyId == _propertyId) {
            target = r;
            break;
          }
        }
      }
      target ??= rows.firstWhereOrNull(
        (r) => _propertyName.isNotEmpty && r.apartmentSuite.trim() == _propertyName,
      );
      target ??= rows.firstWhereOrNull(
        (r) => _propertyName.isNotEmpty && r.propertyLocation.trim() == _propertyName,
      );
      return target;
    } catch (_) {
      return null;
    }
  }

  double _extractExpectedMonthlyIncome(Map<String, dynamic> listing) {
    final candidates = <dynamic>[
      listing['expectedMonthlyIncome'],
      listing['targetMonthlyIncome'],
      listing['monthlyIncomeTarget'],
      listing['expectedIncome'],
    ];
    for (final c in candidates) {
      if (c is num) return c.toDouble();
      if (c is String) {
        final n = double.tryParse(c.replaceAll(',', '').trim());
        if (n != null) return n;
      }
    }
    return 0;
  }

  Future<double> _expectedIncomeFromLocalUnits() async {
    try {
      final rows = await _propertyLocal.getAllNewestFirst();
      if (rows.isEmpty) return 0;
      final target = rows.firstWhereOrNull((r) {
        final localId = 'local_${r.id}';
        final legacyId = 'legacy_${r.id}';
        return (_propertyId.isNotEmpty &&
                (r.propertyRef.trim() == _propertyId ||
                    localId == _propertyId ||
                    legacyId == _propertyId)) ||
            (_propertyName.isNotEmpty &&
                (r.propertyName.trim() == _propertyName ||
                    r.propertyLocation.trim() == _propertyName));
      }) ??
          rows.first;
      final decoded = jsonDecode(target.unitsJson.trim().isEmpty ? '[]' : target.unitsJson);
      if (decoded is! List) return 0;
      double total = 0;
      for (final e in decoded.whereType<Map>()) {
        final m = Map<String, dynamic>.from(e);
        final raw = (m['unitRent'] ?? m['rent'] ?? m['price'] ?? '').toString();
        final n = double.tryParse(raw.replaceAll(',', '').trim());
        if (n != null && n > 0) total += n;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _syncOccupancyPercent(Map<String, dynamic>? remoteListing) async {
    final totalUnits = unitRows.length;
    if (totalUnits <= 0) {
      occupancyPercent.value = 0;
      return;
    }

    var tenantsCount = 0;
    if (remoteListing != null) {
      tenantsCount = _extractTenantCountFromRemote(remoteListing);
    }
    if (tenantsCount <= 0) {
      tenantsCount = await _extractTenantCountFromLocal();
    }
    final pct = ((tenantsCount / totalUnits) * 100).round();
    occupancyPercent.value = pct.clamp(0, 100);
  }

  int _extractTenantCountFromRemote(Map<String, dynamic> listing) {
    final tenantLists = <dynamic>[
      listing['tenants'],
      listing['tenantList'],
      listing['activeTenants'],
      listing['occupants'],
    ];
    for (final t in tenantLists) {
      if (t is List) return t.length;
    }
    final numeric = <dynamic>[
      listing['tenantsCount'],
      listing['tenantCount'],
      listing['activeTenantsCount'],
      listing['occupiedUnits'],
    ];
    for (final n in numeric) {
      if (n is num) return n.toInt();
    }
    return 0;
  }

  Future<int> _extractTenantCountFromLocal() async {
    final tenants = await _tenantLocal.getAllNewestFirst();
    if (tenants.isEmpty) return 0;

    bool matchesListing(TenantRecord t) {
      final ref = t.propertyRef.trim();
      if (_propertyId.isNotEmpty && ref.isNotEmpty) {
        if (ref == _propertyId) return true;
      }
      final labelLc = t.propertyLabel.trim().toLowerCase();
      if (_propertyName.isNotEmpty &&
          labelLc.contains(_propertyName.toLowerCase())) {
        return true;
      }
      if (_propertyLocation.isNotEmpty &&
          labelLc.contains(_propertyLocation.toLowerCase())) {
        return true;
      }
      return false;
    }

    if (_propertyId.isEmpty &&
        _propertyName.isEmpty &&
        _propertyLocation.isEmpty) {
      // No listing scope available in args; avoid inflating occupancy.
      return 0;
    }
    return tenants.where(matchesListing).length;
  }

  Future<Map<String, dynamic>?> _fetchListingMapFromRepository(String listingId) async {
    try {
      final res = await _repository.getListing(listingId);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      if (data is Map && data['listing'] is Map<String, dynamic>) {
        return data['listing'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  List<ListingActivityVm> _activityFromAnyMap(Map<String, dynamic> listing) {
    final candidates = <dynamic>[
      listing['recentActivity'],
      listing['activity'],
      listing['activities'],
      listing['timeline'],
      listing['logs'],
    ];
    List<dynamic> rows = const [];
    for (final c in candidates) {
      if (c is List) {
        rows = c;
        break;
      }
    }
    if (rows.isEmpty) return const [];
    final out = <ListingActivityVm>[];
    for (final e in rows.whereType<Map>()) {
      final m = Map<String, dynamic>.from(e);
      final title = (m['title'] ?? m['name'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      out.add(
        ListingActivityVm(
          title: title,
          subtitle: (m['subtitle'] ?? m['description'] ?? '').toString().trim(),
          trailing: (m['amountLabel'] ?? m['amount'] ?? m['status'] ?? '').toString().trim(),
          timeLabel: (m['timeLabel'] ?? m['time'] ?? m['createdAt'] ?? '').toString().trim(),
          accentColor: const Color(0xFF0EA5A4),
        ),
      );
    }
    return out;
  }

  List<ListingStaffVm> _staffFromAnyMap(Map<String, dynamic> listing) {
    final candidates = <dynamic>[
      listing['staffAssigned'],
      listing['staff'],
      listing['assignedStaff'],
      listing['team'],
    ];
    List<dynamic> rows = const [];
    for (final c in candidates) {
      if (c is List) {
        rows = c;
        break;
      }
    }
    if (rows.isEmpty) return const [];
    final out = <ListingStaffVm>[];
    for (final e in rows.whereType<Map>()) {
      final m = Map<String, dynamic>.from(e);
      final name = (m['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      out.add(
        ListingStaffVm(
          name: name,
          jobTitle: (m['jobTitle'] ?? m['role'] ?? '').toString().trim(),
        ),
      );
    }
    return out;
  }

  Future<List<ListingStaffVm>> _loadStaffFromLocal() async {
    final rows = await _staffLocal.getAllNewestFirst();
    return rows
        .map((s) => ListingStaffVm(name: s.name, jobTitle: s.jobTitle))
        .toList();
  }

  Future<List<ListingActivityVm>> _loadActivityFromLocal() async {
    return _activityLoader.load(scope: _activityScope, limit: 3);
  }

  Future<List<ListingUnitRowVm>> _loadUnitRowsFromLocal() async {
    try {
      final rows = await _propertyLocal.getAllNewestFirst();
      if (rows.isEmpty) return const [];

      PropertyRecord? target;
      if (_propertyId.isNotEmpty) {
        for (final r in rows) {
          final localId = 'local_${r.id}';
          final legacyId = 'legacy_${r.id}';
          if (r.propertyRef.trim() == _propertyId ||
              localId == _propertyId ||
              legacyId == _propertyId) {
            target = r;
            break;
          }
        }
      }
      target ??= rows.firstWhereOrNull(
            (r) => _propertyName.isNotEmpty && r.propertyName.trim() == _propertyName,
      );
      target ??= rows.firstWhereOrNull(
            (r) => _propertyName.isNotEmpty && r.propertyLocation.trim() == _propertyName,
      );
      target ??= rows.first;

      final unitsRaw = target.unitsJson.trim();
      if (unitsRaw.isEmpty) {
        return [
          ListingUnitRowVm(
            name: target.propertyName.trim().isNotEmpty
                ? target.propertyName.trim()
                : target.propertyLocation.trim(),
            subtitle: _isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant',
            status: ListingUnitStatus.short,
          ),
        ];
      }
      final decoded = jsonDecode(unitsRaw);
      if (decoded is! List) return const [];
      final out = <ListingUnitRowVm>[];
      for (final e in decoded.whereType<Map>()) {
        final m = Map<String, dynamic>.from(e);
        final unitName = (m['unitName'] ?? m['name'] ?? '').toString().trim();
        if (unitName.isEmpty) continue;
        final rent = (m['unitRent'] ?? m['rent'] ?? '').toString().trim();
        out.add(
          ListingUnitRowVm(
            name: unitName,
            subtitle: rent.isEmpty ? (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant') : 'Rent TZS $rent',
            status: ListingUnitStatus.short,
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  List<ListingUnitRowVm> _unitRowsFromAnyMap(Map<String, dynamic> listing) {
    final candidates = <dynamic>[
      listing['units'],
      listing['unitList'],
      listing['apartmentUnits'],
      listing['rooms'],
      listing['apartment_units'],
    ];
    List<dynamic> units = const [];
    for (final c in candidates) {
      if (c is List) {
        units = c;
        break;
      }
    }
    if (units.isEmpty) return const [];

    final out = <ListingUnitRowVm>[];
    for (final e in units.whereType<Map>()) {
      final m = Map<String, dynamic>.from(e);
      final name = (m['unitName'] ?? m['name'] ?? m['label'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final rent = (m['unitRent'] ?? m['rent'] ?? m['price'] ?? '').toString().trim();
      final occupied =
          (m['occupied'] == true) || (m['status']?.toString().toLowerCase() == 'occupied');
      final dueDate =
          m['status']?.toString().toLowerCase() == 'due_date' ||
              m['status']?.toString().toLowerCase() == 'overdue';
      final status = dueDate
          ? ListingUnitStatus.dueDate
          : (occupied ? ListingUnitStatus.occupied : ListingUnitStatus.short);

      out.add(
        ListingUnitRowVm(
          name: name,
          subtitle: rent.isNotEmpty
              ? 'Rent TZS $rent'
              : (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant'),
          status: status,
        ),
      );
    }
    return out;
  }

  List<ListingUnitRowVm> _fallbackUnitRows() {
    return [
      ListingUnitRowVm(
        name: 'Unit 401',
        subtitle: _isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant',
        status: ListingUnitStatus.short,
      ),
      ListingUnitRowVm(
        name: 'Unit 402',
        subtitle: _isSw ? 'Kodi imelipwa' : 'Rent fully paid',
        status: ListingUnitStatus.occupied,
      ),
      ListingUnitRowVm(
        name: 'Unit 403',
        subtitle: _isSw ? 'Malipo yamechelewa' : 'Payment overdue',
        status: ListingUnitStatus.dueDate,
      ),
    ];
  }

  void _applyRouteArguments() {
    final args = Get.arguments;
    if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      final name = (map['property_name'] ?? '').toString().trim();
      final location = (map['property_location'] ?? '').toString().trim();
      final image = (map['property_image'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        listingTitle.value = name;
        heroOverlayTitle.value = location.isEmpty ? name : '$name • $location';
      } else if (location.isNotEmpty) {
        listingTitle.value = location;
        heroOverlayTitle.value = location;
      }
      if (image.isNotEmpty) {
        heroImagePath.value = image;
        return;
      }
    }
    final title = Get.parameters['title']?.trim() ?? '';
    if (title.isNotEmpty) {
      listingTitle.value = title;
      heroOverlayTitle.value = title;
    }
  }

  Future<void> loadRealDataSnapshot() async {
    // Kept for refresh compatibility with the view.
  }

  Future<void> onEditListing() async {
    if (_propertyId.isEmpty) {
      Get.snackbar(
        _isSw ? 'Haiwezekani' : 'Unavailable',
        _isSw
            ? 'Hakuna kitambulisho cha mali cha kuhariri.'
            : 'No property id is available to edit.',
      );
      return;
    }
    final localRow = await _findLocalPropertyRowForListing();
    final ref = (localRow?.propertyRef.trim().isNotEmpty == true)
        ? localRow!.propertyRef.trim()
        : _propertyId;
    await Get.toNamed(
      Routes.EDIT_LISTING,
      arguments: {'property_ref': ref},
    );
    await loadListingDetail();
  }

  Future<void> onAddNewUnit() async {
    final propertyHubId = _propertyId.trim();

    if (propertyHubId.isEmpty) {
      Get.snackbar(
        _isSw ? 'Haiwezekani' : 'Unavailable',
        _isSw
            ? 'Hakuna mali iliyohifadhiwa kwenye kifaa hiki kuongeza kitengo.'
            : 'No on-device property record found to add a unit.',
      );
      return;
    }

    final result = await Get.toNamed(
      Routes.RENT_ADD_NEW_LISTING,
      parameters: {'propertyRef': propertyHubId},
    );
    if (result == true) {
      await loadListingDetail();
    }
  }

  Future<void> onDeleteProperty() async {
    final row = await _findLocalPropertyRowForListing();
    if (row == null) {
      showErrorMessage(
        _isSw
            ? 'Haiwezi kufuta: hakuna rekodi ya mali kwenye kifaa.'
            : 'Cannot delete: no on-device property record for this listing.',
      );
      return;
    }

    final title = listingTitle.value.trim();
    final label = title.isNotEmpty
        ? title
        : (row.propertyName.trim().isNotEmpty
            ? row.propertyName.trim()
            : row.propertyLocation.trim());

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_isSw ? 'Futa mali?' : 'Delete property?'),
        content: Text(
          _isSw
              ? 'Hii itafuta "$label" na rekodi zake kwenye kifaa hiki. Hatua hii haiwezi kutenduliwa.'
              : 'This will remove "$label" and its saved details from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_isSw ? 'Ghairi' : 'Cancel', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(_isSw ? 'Futa' : 'Delete', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    await runBusy(() async {
      try {
        await _purgeLocalPropertyRelations(row);
        await _propertyLocal.deleteById(row.id);
        Get.back();
        showSuccessWithHaptic(_isSw ? 'Mali imefutwa' : 'Property removed');
      } catch (e, st) {
        logger.e('onDeleteProperty $e $st');
        showErrorMessage(
          _isSw ? 'Imeshindwa kufuta mali.' : 'Could not delete property.',
        );
      }
    });
  }

  Future<void> _purgeLocalPropertyRelations(PropertyRecord row) async {
    final refs = <String>{
      if (row.propertyRef.trim().isNotEmpty) row.propertyRef.trim(),
      'local_${row.id}',
      'legacy_${row.id}',
    };
    for (final r in refs) {
      await _unitLocal.deleteByPropertyRef(r);
      await _tenantLocal.deleteByPropertyRef(r);
      await _membersLocal.deleteAllForPropertyRef(r);
    }
  }

  void onViewAllLog() {
    Get.toNamed(
      Routes.RENT_LISTING_ACTIVITY_LOG,
      parameters: {
        if (_propertyId.isNotEmpty) 'id': _propertyId,
        if (_propertyName.isNotEmpty) 'title': _propertyName,
      },
      arguments: {
        if (_propertyId.isNotEmpty) 'property_id': _propertyId,
        if (_propertyName.isNotEmpty) 'property_name': _propertyName,
        if (_propertyLocation.isNotEmpty) 'property_location': _propertyLocation,
      },
    );
  }

  void onManageStaff() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void onQuickAction(int index) {
    switch (index) {
      case 0:
        Get.toNamed(
          Routes.RENT_ADD_TENANT_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
          arguments: {
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            if (_propertyName.isNotEmpty) 'property': _propertyName,
          },
        )?.then((result) {
          if (result == true) {
            loadListingDetail();
          }
        });
        break;
      case 1:
        Get.toNamed(
          Routes.RENT_ADD_INCOME_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
          arguments: {
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            if (_propertyName.isNotEmpty) 'property': _propertyName,
          },
        )?.then((result) async {
          if (result == true) {
            await RentTenantResidencyPaymentTrackerController.refreshIfRegistered();
            await refreshRecentActivityAndRevenue();
          }
        });
        break;
      case 2:
        Get.toNamed(
          Routes.RENT_ADD_NEW_EXPENSE,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
          arguments: {
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            if (_propertyName.isNotEmpty) 'property': _propertyName,
          },
        )?.then((result) async {
          if (result == true) {
            await refreshRecentActivityAndRevenue();
          }
        });
        break;
      case 3:
        Get.toNamed(
          Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
        )?.then((result) {
          if (result == true) {
            loadListingDetail();
          }
        });
        break;
      case 4:
        showSuccessMessage(_isSw ? 'Udhibiti wa lock' : 'Unit lock control');
        break;
      case 5:
        Get.toNamed(Routes.RENT_SMART_UTILITY_DASHBOARD);
        break;
      default:
        break;
    }
  }

  void onAnalyticsQuickAction(int index) {
    if (index == 1) {
      Get.toNamed(Routes.RENT_MONTHLY_PL_SUMMARY);
    }
  }

  void onUnitPrimaryAction(ListingUnitRowVm row) {
    switch (row.status) {
      case ListingUnitStatus.dueDate:
        showSuccessMessage(_isSw ? 'Tuma ankara' : 'Send invoice');
        break;
      case ListingUnitStatus.occupied:
        showSuccessMessage(_isSw ? 'Angalia maelezo' : 'View details');
        break;
      case ListingUnitStatus.short:
        Get.toNamed(
          Routes.RENT_ADD_TENANT_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            'unitName': row.name,
          },
        )?.then((result) {
          if (result == true) {
            loadListingDetail();
          }
        });
        break;
    }
  }

  String primaryButtonLabel(ListingUnitRowVm row, bool isSw) {
    if (row.status == ListingUnitStatus.dueDate) {
      return isSw ? 'Tuma Ankara' : 'Send Invoice';
    }
    if (row.status == ListingUnitStatus.occupied) {
      return isSw ? 'Angalia Maelezo' : 'View Details';
    }
    return isSw ? 'Ongeza Mpangaji' : 'Add Tenant';
  }
}
