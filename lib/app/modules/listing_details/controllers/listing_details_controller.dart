import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/property_members_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';

enum ListingUnitStatus { short, occupied, dueDate }

class ListingUnitRowVm {
  ListingUnitRowVm({
    required this.name,
    required this.subtitle,
    required this.status,
    this.tenantName = '',
    this.tenantId,
    this.unitId = '',
  });

  final String name;
  final String subtitle;
  final ListingUnitStatus status;
  final String tenantName;
  final int? tenantId;
  final String unitId;
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
        _propertyLocal = Get.find<PropertyLocalDataSource>(),
        _incomeLocal = Get.find<IncomeLocalDataSource>(),
        _expenseLocal = Get.find<ExpenseLocalDataSource>(),
        _staffLocal = Get.find<RentStaffLocalDataSource>(),
        _tenantLocal = Get.find<TenantLocalDataSource>(),
        _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
        _membersLocal = Get.find<PropertyMembersLocalDataSource>(),
        _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final RentStaffLocalDataSource _staffLocal;
  final TenantLocalDataSource _tenantLocal;
  final PropertyUnitLocalDataSource _unitLocal;
  final PropertyMembersLocalDataSource _membersLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;

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
      await _syncListingTitlesFromLocal();
    } finally {
      loadingListing.value = false;
    }
  }

  /// Refreshes app bar + hero from local [PropertyRecord] after edits or pull-to-refresh.
  Future<void> _syncListingTitlesFromLocal() async {
    final row = await _findLocalPropertyRowForListing();
    if (row == null) return;
    final name = row.propertyName.trim();
    final location = row.propertyLocation.trim();
    if (name.isEmpty && location.isEmpty) return;
    if (name.isNotEmpty) {
      listingTitle.value = name;
      heroOverlayTitle.value = location.isEmpty ? name : '$name • $location';
    } else {
      listingTitle.value = location;
      heroOverlayTitle.value = location;
    }
  }

  Future<void> _syncMonthlyRevenue(Map<String, dynamic>? remoteListing) async {
    final incomes = await _incomeLocal.getAllByPropertyRefAndWorkspace(
        propertyRef: _propertyId, workspaceType: 'bnb');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    double paymentTotal = 0;

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

    bool matchesListingScope(IncomeRecord row) {
      final pr = row.propertyRef.trim();
      if (pr.isNotEmpty && scopeRefs.isNotEmpty && scopeRefs.contains(pr)) {
        return true;
      }
      final apt = row.apartment.trim().toLowerCase();
      final unit = row.apartmentUnit.trim().toLowerCase();
      final notes = row.notes.trim().toLowerCase();
      final name = _propertyName.toLowerCase();
      final loc = _propertyLocation.toLowerCase();
      if (name.isEmpty && loc.isEmpty) return false;
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
      final d = row.paidLocalCalendarOrCreated();
      if (d.isBefore(start) || !d.isBefore(end)) continue;
      if (!matchesListingScope(row)) continue;
      paymentTotal += row.amountValue;
    }

    var spanningLeaseRent = 0.0;
    try {
      if (_propertyId.isNotEmpty ||
          _propertyName.isNotEmpty ||
          _propertyLocation.isNotEmpty) {
        final tenants = await _tenantLocal.getAllNewestFirst();
        for (final t in tenants) {
          if (!_tenantMatchesListingForMonthlyRevenue(t, scopeRefs)) continue;
          final ls = _parseTenantLeaseStartDate(t);
          final le = _parseTenantLeaseEndDate(t);
          if (ls == null || le == null) continue;
          if (_leaseBeganBeforeMonthAndEndsAfterFirstDayOfNextMonth(
                leaseStart: ls,
                leaseEnd: le,
                monthStart: start,
                nextMonthStart: end,
              )) {
            spanningLeaseRent += t.rentAmountValue;
          }
        }
      }
    } catch (_) {}

    final localTotal = paymentTotal + spanningLeaseRent;

    // Local rows (including newly saved income) are authoritative; use API
    // only when there is no matching local income for this month.
    final remoteMonthly =
        remoteListing != null ? _extractRemoteMonthlyIncome(remoteListing) : 0.0;
    final displayTotal = localTotal > 0 ? localTotal : remoteMonthly;

    monthlyRevenueLabel.value = _money.format(displayTotal.round());

    final expectedRemote =
        remoteListing != null ? _extractExpectedMonthlyIncome(remoteListing) : 0.0;
    final expectedLocal = await _expectedIncomeFromLocalUnits();
    final expected = expectedLocal > 0 ? expectedLocal : expectedRemote;
    monthlyRevenueProgress.value =
        expected <= 0 ? 0 : (displayTotal / expected).clamp(0, 1).toDouble();
  }

  /// Lease began strictly before [monthStart] and ends strictly after the first
  /// calendar day of the following month ([nextMonthStart]).
  static bool _leaseBeganBeforeMonthAndEndsAfterFirstDayOfNextMonth({
    required DateTime leaseStart,
    required DateTime leaseEnd,
    required DateTime monthStart,
    required DateTime nextMonthStart,
  }) {
    final ls = DateTime(leaseStart.year, leaseStart.month, leaseStart.day);
    final le = DateTime(leaseEnd.year, leaseEnd.month, leaseEnd.day);
    final ms = DateTime(monthStart.year, monthStart.month, monthStart.day);
    final nms =
        DateTime(nextMonthStart.year, nextMonthStart.month, nextMonthStart.day);
    return ls.isBefore(ms) && le.isAfter(nms);
  }

  DateTime? _parseTenantLeaseStartDate(TenantRecord t) {
    final raw = t.leaseStartIso.trim();
    try {
      if (raw.isEmpty) {
        return DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
      }
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
    }
  }

  DateTime? _parseTenantLeaseEndDate(TenantRecord t) {
    final raw = t.leaseEndIso.trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
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
    final scopeRefs = await _listingPropertyRefsForActivity();
    final candidates = <({int ts, ListingActivityVm vm})>[];

    try {
      final maintenanceRows = await _maintenanceLocal.getAllNewestFirst();
      for (final r in maintenanceRows) {
        if (!_maintenanceMatchesListing(r, scopeRefs)) continue;
        DateTime? scheduled;
        try {
          scheduled = DateTime.parse(r.scheduledDateIso.trim());
        } catch (_) {
          scheduled = null;
        }
        final scheduledLabel = scheduled != null
            ? DateFormat('MMM d, yyyy').format(scheduled)
            : '—';
        final cat = r.category.trim();
        final desc = r.description.trim();
        final subtitle = desc.isEmpty
            ? cat
            : (desc.length > 72 ? '${desc.substring(0, 69)}…' : '$cat · $desc');
        candidates.add((
          ts: r.createdAtMs,
          vm: ListingActivityVm(
            title: _isSw ? 'Matengenezo yalipangwa' : 'Maintenance scheduled',
            subtitle: subtitle,
            trailing: scheduledLabel,
            timeLabel: _relativeDateFromMs(r.createdAtMs),
            accentColor: const Color(0xFF6366F1),
          ),
        ));
      }
    } catch (_) {}

    final incomes = await _incomeLocal.getAllNewestFirst(workspaceType: 'bnb');
    final expenses = await _expenseLocal.getAllNewestFirst(workspaceType: 'bnb');
    final propNameLc = _propertyName.toLowerCase();

    bool matchProperty(String apartment, String notes) {
      if (propNameLc.isEmpty) return true;
      return apartment.toLowerCase().contains(propNameLc) ||
          notes.toLowerCase().contains(propNameLc);
    }

    for (final i in incomes) {
      if (!matchProperty(i.apartment, i.notes)) continue;
      candidates.add((
        ts: _activitySortTimestampIncome(i),
        vm: ListingActivityVm(
          title: _isSw ? 'Malipo yamepokelewa' : 'Payment received',
          subtitle: i.notes.isEmpty ? i.category : i.notes,
          trailing: '+ TZS ${_money.format(i.amountValue.round())}',
          timeLabel: _relativeDate(i.datePaidIso, i.createdAtMs),
          accentColor: const Color(0xFF0EA5A4),
        ),
      ));
    }
    for (final e in expenses) {
      if (!matchProperty(e.apartment, e.notes)) continue;
      candidates.add((
        ts: _activitySortTimestampExpense(e),
        vm: ListingActivityVm(
          title: _isSw ? 'Gharama imerekodiwa' : 'Expense logged',
          subtitle: e.notes.isEmpty ? e.category : e.notes,
          trailing: 'TZS ${_money.format(e.amountValue.round())}',
          timeLabel: _relativeDate(e.datePaidIso, e.createdAtMs),
          accentColor: const Color(0xFFF59E0B),
        ),
      ));
    }

    candidates.sort((a, b) => b.ts.compareTo(a.ts));
    return candidates.take(3).map((e) => e.vm).toList();
  }

  Future<Set<String>> _listingPropertyRefsForActivity() async {
    final refs = <String>{};
    if (_propertyId.isNotEmpty) refs.add(_propertyId);
    final row = await _findLocalPropertyRowForListing();
    if (row != null) {
      if (row.propertyRef.trim().isNotEmpty) refs.add(row.propertyRef.trim());
      refs.add('local_${row.id}');
      refs.add('legacy_${row.id}');
    }
    return refs;
  }

  bool _maintenanceMatchesListing(
    RentScheduledMaintenanceRecord r,
    Set<String> scopeRefs,
  ) {
    final pref = r.propertyRef.trim();
    if (pref.isNotEmpty && scopeRefs.contains(pref)) return true;
    final label = r.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final nameLc = _propertyName.toLowerCase();
    final locLc = _propertyLocation.toLowerCase();
    if (nameLc.isNotEmpty &&
        (label == nameLc || label.contains(nameLc) || nameLc.contains(label))) {
      return true;
    }
    if (locLc.isNotEmpty &&
        (label == locLc || label.contains(locLc) || locLc.contains(label))) {
      return true;
    }
    return false;
  }

  static int _activitySortTimestampIncome(IncomeRecord i) {
    final p = DateTime.tryParse(i.datePaidIso.trim());
    if (p != null) return p.millisecondsSinceEpoch;
    return i.createdAtMs;
  }

  static int _activitySortTimestampExpense(ExpenseRecord e) {
    final p = DateTime.tryParse(e.datePaidIso.trim());
    if (p != null) return p.millisecondsSinceEpoch;
    return e.createdAtMs;
  }

  String _relativeDateFromMs(int ms) {
    final iso = DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String();
    return _relativeDate(iso, ms);
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

      PropertyRecord? target;
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
      final tenants = await _tenantLocal.getAllNewestFirst();
      final listingRef = target.propertyRef.trim().isNotEmpty
          ? target.propertyRef.trim()
          : 'local_${target.id}';
      final listingName = target.apartmentSuite.trim().isNotEmpty
          ? target.apartmentSuite.trim()
          : target.propertyLocation.trim();
      final listingLoc = target.propertyLocation.trim();

      bool tenantMatchesListing(TenantRecord t) {
        final ref = t.propertyRef.trim();
        if (ref.isNotEmpty && ref == listingRef) return true;
        final label = t.propertyLabel.trim().toLowerCase();
        if (listingName.isNotEmpty &&
            label.contains(listingName.toLowerCase())) {
          return true;
        }
        if (listingLoc.isNotEmpty &&
            label.contains(listingLoc.toLowerCase())) {
          return true;
        }
        return false;
      }

      final listingTenants = tenants.where(tenantMatchesListing).toList();

      final unitsRaw = target.unitsJson.trim();
      if (unitsRaw.isEmpty) {
        final attachedTenant = listingTenants.isEmpty ? null : listingTenants.first;
        return [
          ListingUnitRowVm(
            name: target.apartmentSuite.trim().isNotEmpty
                ? target.apartmentSuite.trim()
                : target.propertyLocation.trim(),
            subtitle: _isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant',
            status: attachedTenant == null
                ? ListingUnitStatus.short
                : ListingUnitStatus.occupied,
            tenantName: attachedTenant?.tenantName ?? '',
            tenantId: attachedTenant?.id,
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
        final unitId = (m['unitId'] ?? m['id'] ?? '').toString().trim();
        TenantRecord? attachedTenant;
        for (final t in listingTenants) {
          final tid = t.apartmentUnitId.trim();
          final tName = t.unitLabel.trim();
          if (unitId.isNotEmpty && tid.isNotEmpty && tid == unitId) {
            attachedTenant = t;
            break;
          }
          if (unitName.isNotEmpty &&
              tName.isNotEmpty &&
              tName.toLowerCase() == unitName.toLowerCase()) {
            attachedTenant = t;
            break;
          }
        }
        final rent = (m['unitRent'] ?? m['rent'] ?? '').toString().trim();
        out.add(
          ListingUnitRowVm(
            name: unitName,
            subtitle: rent.isEmpty ? (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant') : 'Rent TZS $rent',
            status: attachedTenant == null
                ? ListingUnitStatus.short
                : ListingUnitStatus.occupied,
            tenantName: attachedTenant?.tenantName ?? '',
            tenantId: attachedTenant?.id,
            unitId: unitId,
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
      final tenantName = (m['tenantName'] ??
              m['occupantName'] ??
              m['guestName'] ??
              m['tenant'])
          ?.toString()
          .trim() ??
          '';
      final occupied =
          (m['occupied'] == true) ||
          (m['status']?.toString().toLowerCase() == 'occupied') ||
          tenantName.isNotEmpty;
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
          tenantName: tenantName,
          unitId: (m['unitId'] ?? m['id'] ?? '').toString().trim(),
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

  void onOpenUnitOccupancy() {
    Get.toNamed(
      Routes.LISTING_UNIT_OCCUPANCY,
      arguments: {
        'property_id': _propertyId,
        'property_name': _propertyName,
        'property_location': _propertyLocation,
      },
    );
  }

  void onOpenCalendarSync() {
    if (_propertyId.isEmpty) return;
    Get.toNamed(
      Routes.CALENDAR_SYNC,
      arguments: {
        'listing_id': _propertyId,
        'listing_name': listingTitle.value.isNotEmpty
            ? listingTitle.value
            : _propertyName,
      },
    );
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

  String _propertyLabelForEstimate() {
    final overlay = heroOverlayTitle.value.trim();
    if (overlay.isNotEmpty) return overlay;
    final title = listingTitle.value.trim();
    if (title.isNotEmpty) return title;
    if (_propertyName.isNotEmpty && _propertyLocation.isNotEmpty) {
      return '$_propertyName · $_propertyLocation';
    }
    return _propertyName.isNotEmpty ? _propertyName : 'Property';
  }

  Future<void> onAddPropertyEstimationCosts() async {
    var ref = _propertyId;
    if (ref.isEmpty) {
      final row = await _findLocalPropertyRowForListing();
      if (row != null) {
        ref = row.propertyRef.trim().isNotEmpty ? row.propertyRef.trim() : 'local_${row.id}';
      }
    }
    if (ref.isEmpty) {
      showErrorMessage(
        _isSw
            ? 'Hakuna kitambulisho cha mali kwa makadirio ya gharama.'
            : 'No property reference is available for cost estimates.',
      );
      return;
    }
    await Get.toNamed(
      Routes.RENT_PROPERTY_ROI_ESTIMATE_FORM,
      parameters: {
        'propertyRef': ref,
        'propertyLabel': _propertyLabelForEstimate(),
      },
    );
    await loadListingDetail();
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
    final ref = _propertyId;
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
      Routes.EDIT_LISTING,
      arguments: {'property_ref': propertyHubId},
    );
    if (result == true) {
      await loadListingDetail();
    }
  }

  Future<void> onEditUnitDetails(ListingUnitRowVm row) async {
    final propertyRef = _propertyId.trim();
    if (propertyRef.isEmpty) {
      showErrorMessage(
        _isSw
            ? 'Hakuna kitambulisho cha mali kuhariri unit.'
            : 'No property reference is available to edit this unit.',
      );
      return;
    }

    final result = await Get.toNamed(
      Routes.EDIT_UNIT,
      arguments: {
        'property_ref': propertyRef,
        'unit_name': row.name,
        if (row.unitId.trim().isNotEmpty) 'unit_id': row.unitId.trim(),
      },
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

    showLoading();
    try {
      await _purgeLocalPropertyRelations(row);
      await _propertyLocal.deleteById(row.id);
      Get.back();
      showSuccessMessage(_isSw ? 'Mali imefutwa' : 'Property removed');
    } catch (e, st) {
      logger.e('onDeleteProperty $e $st');
      showErrorMessage(
        _isSw ? 'Imeshindwa kufuta mali.' : 'Could not delete property.',
      );
    } finally {
      hideLoading();
    }
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

  void onViewAllLog() => showSuccessMessage(_isSw ? 'Kumbukumbu zote' : 'Viewing full activity log');

  void onManageStaff() => Get.toNamed(Routes.TEAM_AND_STAFF);

  void onQuickAction(int index) {
    switch (index) {
      case 0:
        Get.toNamed(
          Routes.ADD_NEW_TENANT,
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
          Routes.RECORD_PAYMENT,
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
      case 2:
        Get.toNamed(
          Routes.ADD_EXPENSE,
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
          Routes.ADD_NEW_TENANT,
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
