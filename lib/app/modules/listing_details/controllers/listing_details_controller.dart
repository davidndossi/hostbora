import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/rent_expense_local_data_source.dart';
import '../../../data/local/db/rent_income_local_data_source.dart';
import '../../../data/local/db/rent_property_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/db/rent_tenant_local_data_source.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

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

class ListingActivityVm {
  ListingActivityVm({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.timeLabel,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String timeLabel;
  final Color accentColor;
}

class ListingStaffVm {
  ListingStaffVm({required this.name, required this.jobTitle});

  final String name;
  final String jobTitle;
}

class ListingDetailsController extends BaseController {
  ListingDetailsController()
      : _repository =
            Get.find<AppRepository>(tag: (AppRepository).toString()),
        _propertyLocal = Get.find<RentPropertyLocalDataSource>(),
        _incomeLocal = Get.find<RentIncomeLocalDataSource>(),
        _expenseLocal = Get.find<RentExpenseLocalDataSource>(),
        _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _tenantLocal = Get.find<RentTenantLocalDataSource>();

  final AppRepository _repository;
  final RentPropertyLocalDataSource _propertyLocal;
  final RentIncomeLocalDataSource _incomeLocal;
  final RentExpenseLocalDataSource _expenseLocal;
  final RentStaffLocalDataSource _staffLocal;
  final RentTenantLocalDataSource _tenantLocal;

  final loadingListing = true.obs;
  final listingTitle = ''.obs;
  final heroOverlayTitle = ''.obs;
  final occupancyPercent = 0.obs;
  final monthlyRevenueLabel = '0'.obs;
  final monthlyRevenueProgress = 0.0.obs;

  final listingScrollController = ScrollController();

  final unitRows = <ListingUnitRowVm>[].obs;
  final recentActivity = <ListingActivityVm>[].obs;
  final staffPreview = <ListingStaffVm>[].obs;
  static final _money = NumberFormat('#,###', 'en_US');

  bool get _isSw => Get.locale?.languageCode == 'sw';
  String get _propertyId =>
      (Get.arguments is Map)
          ? ((Get.arguments as Map)['property_id'] ?? '').toString().trim()
          : '';
  String get _propertyName =>
      (Get.arguments is Map)
          ? ((Get.arguments as Map)['property_name'] ?? '').toString().trim()
          : '';
  String get _propertyLocation =>
      (Get.arguments is Map)
          ? ((Get.arguments as Map)['property_location'] ?? '').toString().trim()
          : '';

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
      unitRows.assignAll(realRows.isEmpty ? [] : realRows);
      await _syncOccupancyPercent(remoteListing);
      await _syncMonthlyRevenue(remoteListing);

      var activities = remoteListing == null ? <ListingActivityVm>[] : _activityFromAnyMap(remoteListing);
      if (activities.isEmpty) {
        activities = await _loadActivityFromLocal();
      }
      recentActivity.assignAll(activities);

      var staff = remoteListing == null ? <ListingStaffVm>[] : _staffFromAnyMap(remoteListing);
      if (staff.isEmpty) {
        staff = await _loadStaffFromLocal();
      }
      staffPreview.assignAll(staff);
    } finally {
      loadingListing.value = false;
    }
  }

  Future<void> _syncMonthlyRevenue(Map<String, dynamic>? remoteListing) async {
    // Prefer explicit monthly income from API if present.
    if (remoteListing != null) {
      final remote = _extractRemoteMonthlyIncome(remoteListing);
      if (remote > 0) {
        monthlyRevenueLabel.value = _money.format(remote.round());
        final expected = _extractExpectedMonthlyIncome(remoteListing);
        monthlyRevenueProgress.value =
            expected <= 0 ? 0 : (remote / expected).clamp(0, 1).toDouble();
        return;
      }
    }

    final incomes = await _incomeLocal.getAllNewestFirst();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    double total = 0;

    bool matchesListingScope(RentIncomeRecord row) {
      final apt = row.apartment.trim().toLowerCase();
      final unit = row.apartmentUnit.trim().toLowerCase();
      final notes = row.notes.trim().toLowerCase();
      final name = _propertyName.toLowerCase();
      final loc = _propertyLocation.toLowerCase();
      if (name.isEmpty && loc.isEmpty) return true;
      if (name.isNotEmpty &&
          (apt.contains(name) || unit.contains(name) || notes.contains(name))) {
        return true;
      }
      if (loc.isNotEmpty &&
          (apt.contains(loc) || unit.contains(loc) || notes.contains(loc))) {
        return true;
      }
      return false;
    }

    for (final row in incomes) {
      DateTime d;
      try {
        d = DateTime.parse(row.datePaidIso);
      } catch (_) {
        d = DateTime.fromMillisecondsSinceEpoch(row.createdAtMs);
      }
      if (d.isBefore(start) || !d.isBefore(end)) continue;
      if (!matchesListingScope(row)) continue;
      total += row.amountValue;
    }

    monthlyRevenueLabel.value = _money.format(total.round());
    final expected = await _expectedIncomeFromLocalUnits();
    monthlyRevenueProgress.value =
        expected <= 0 ? 0 : (total / expected).clamp(0, 1).toDouble();
  }

  double _extractRemoteMonthlyIncome(Map<String, dynamic> listing) {
    final candidates = <dynamic>[
      listing['monthlyRevenue'],
      listing['monthlyIncome'],
      listing['currentMonthIncome'],
      listing['thisMonthIncome'],
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
            return (_propertyId.isNotEmpty &&
                    (r.propertyRef.trim() == _propertyId || localId == _propertyId)) ||
                (_propertyName.isNotEmpty &&
                    (r.apartmentSuite.trim() == _propertyName ||
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

    bool matchesListing(RentTenantRecord t) {
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

  Future<Map<String, dynamic>?> _fetchListingMapFromRepository(
    String listingId,
  ) async {
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
    final out = <ListingActivityVm>[];
    final incomes = await _incomeLocal.getAllNewestFirst();
    final expenses = await _expenseLocal.getAllNewestFirst();
    final propNameLc = _propertyName.toLowerCase();

    bool matchProperty(String apartment, String notes) {
      if (propNameLc.isEmpty) return true;
      return apartment.toLowerCase().contains(propNameLc) ||
          notes.toLowerCase().contains(propNameLc);
    }

    for (final i in incomes.take(8)) {
      if (!matchProperty(i.apartment, i.notes)) continue;
      out.add(
        ListingActivityVm(
          title: _isSw ? 'Malipo yamepokelewa' : 'Payment received',
          subtitle: i.notes.isEmpty ? i.category : i.notes,
          trailing: '+ TZS ${_money.format(i.amountValue.round())}',
          timeLabel: _relativeDate(i.datePaidIso, i.createdAtMs),
          accentColor: const Color(0xFF0EA5A4),
        ),
      );
      if (out.length >= 3) return out;
    }
    for (final e in expenses.take(8)) {
      if (!matchProperty(e.apartment, e.notes)) continue;
      out.add(
        ListingActivityVm(
          title: _isSw ? 'Gharama imerekodiwa' : 'Expense logged',
          subtitle: e.notes.isEmpty ? e.category : e.notes,
          trailing: 'TZS ${_money.format(e.amountValue.round())}',
          timeLabel: _relativeDate(e.datePaidIso, e.createdAtMs),
          accentColor: const Color(0xFFF59E0B),
        ),
      );
      if (out.length >= 3) return out;
    }
    return out;
  }

  String _relativeDate(String iso, int ms) {
    DateTime d;
    try {
      d = DateTime.parse(iso);
    } catch (_) {
      d = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final day = DateTime(d.year, d.month, d.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return _isSw ? 'Leo' : 'Today';
    if (day == today.subtract(const Duration(days: 1))) return _isSw ? 'Jana' : 'Yesterday';
    return DateFormat('MMM d').format(day);
  }

  Future<List<ListingUnitRowVm>> _loadUnitRowsFromLocal() async {
    try {
      final rows = await _propertyLocal.getAllNewestFirst();
      if (rows.isEmpty) return const [];

      RentPropertyRecord? target;
      if (_propertyId.isNotEmpty) {
        for (final r in rows) {
          final localId = 'local_${r.id}';
          if (r.propertyRef.trim() == _propertyId || localId == _propertyId) {
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
      target ??= rows.first;

      final unitsRaw = target.unitsJson.trim();
      if (unitsRaw.isEmpty) {
        return [
          ListingUnitRowVm(
            name: target.apartmentSuite.trim().isNotEmpty
                ? target.apartmentSuite.trim()
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

  void _applyRouteArguments() {
    final args = Get.arguments;
    if (args is! Map) return;
    final map = Map<String, dynamic>.from(args);
    final name = (map['property_name'] ?? '').toString().trim();
    final location = (map['property_location'] ?? '').toString().trim();
    if (name.isNotEmpty) {
      listingTitle.value = name;
      heroOverlayTitle.value = location.isEmpty ? name : '$name • $location';
    }
  }

  Future<void> loadRealDataSnapshot() async {
    // Kept for refresh compatibility with the view.
  }

  Future<void> onEditListing() async {
    await Get.toNamed(
      Routes.ADD_LISTING,
      arguments: {
        'isEditMode': true,
        if (_propertyId.isNotEmpty) 'listing_id': _propertyId,
        if (_propertyName.isNotEmpty)
          'listing_data': {
            'propertyName': _propertyName,
            'streetAddress': _propertyLocation,
          },
      },
    );
  }

  Future<void> onAddNewUnit() async {
    await Get.toNamed(
      Routes.ADD_LISTING,
      arguments: {
        'isEditMode': true,
        if (_propertyId.isNotEmpty) 'listing_id': _propertyId,
        'listing_data': {
          if (_propertyName.isNotEmpty) 'propertyName': _propertyName,
          if (_propertyLocation.isNotEmpty) 'streetAddress': _propertyLocation,
          // Force apartment context so user can add apartment units.
          'propertyType': 'Apartment',
        },
      },
    );
  }

  void onViewAllLog() => showSuccessMessage(_isSw ? 'Kumbukumbu zote' : 'Viewing full activity log');

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
        );
        break;
      case 1:
        Get.toNamed(
          Routes.RENT_ADD_INCOME_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
        );
        break;
      case 2:
        Get.toNamed(
          Routes.RENT_ADD_NEW_EXPENSE,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
        );
        break;
      case 3:
        Get.toNamed(
          Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
          },
        );
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
      case ListingUnitStatus.short:
        showSuccessMessage(_isSw ? 'Angalia maelezo' : 'View details');
        break;
    }
  }

  String primaryButtonLabel(ListingUnitRowVm row, bool isSw) {
    if (row.status == ListingUnitStatus.dueDate) {
      return isSw ? 'Send Invoice' : 'Send Invoice';
    }
    if (row.status == ListingUnitStatus.occupied) {
      return isSw ? 'View Details' : 'View Details';
    }
    return isSw ? 'Add Tenant' : 'Add Tenant';
  }
}
