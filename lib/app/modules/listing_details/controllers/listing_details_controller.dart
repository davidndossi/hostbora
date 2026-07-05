import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../core/mixins/listing_financial_trends_mixin.dart';
import '../../../core/utils/property_listing_image_assigner.dart';
import '../../../data/local/db/property_local_data_source.dart';
import '../../../data/local/db/expense_local_data_source.dart';
import '../../../data/local/db/income_local_data_source.dart';
import '../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../data/local/db/property_members_local_data_source.dart';
import '../../../data/local/db/property_unit_local_data_source.dart';
import '../../../data/local/db/rent_payment_reminder_local_data_source.dart';
import '../../../data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '../../../data/local/db/rent_staff_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../core/utils/property_financial_time_series.dart';
import '../../../core/utils/property_listing_finance_scope.dart';
import '../../../data/model/general_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../rent/listing_activity_log/controllers/rent_listing_activity_log_controller.dart';
import '../../rent/staff_management/controllers/rent_staff_management_controller.dart';
import '../../rent/staff_payroll_details/controllers/rent_staff_payroll_details_controller.dart';
import '../models/listing_activity_vm.dart';
import '../models/listing_details_tab.dart';

enum ListingUnitStatus { short, occupied, dueDate }

class ListingUnitRowVm {
  ListingUnitRowVm({
    required this.name,
    required this.subtitle,
    required this.status,
    this.tenantName = '',
    this.tenantId,
    this.unitId = '',
    this.operationMode = 'bnb',
  });

  final String name;
  final String subtitle;
  final ListingUnitStatus status;
  final String tenantName;
  final int? tenantId;
  final String unitId;
  final String operationMode;
}

class ListingMaintenanceRowVm {
  const ListingMaintenanceRowVm({
    required this.id,
    required this.category,
    required this.description,
    required this.scheduledLabel,
    required this.priority,
  });

  final int id;
  final String category;
  final String description;
  final String scheduledLabel;
  final String priority;
}

class PaymentFollowUpBannerVm {
  const PaymentFollowUpBannerVm({
    required this.message,
    this.actionLabel,
    this.tenantName = '',
    this.phone = '',
    this.balanceTsh = 0,
  });

  final String message;
  final String? actionLabel;

  /// Pre-fill data forwarded to the schedule-payment-reminder screen.
  final String tenantName;
  final String phone;
  final int balanceTsh;
}

class ListingStaffVm {
  ListingStaffVm({required this.name, required this.jobTitle});

  final String name;
  final String jobTitle;
}

class ListingDetailsController extends BaseController
    with ListingFinancialTrendsMixin {
  ListingDetailsController()
    : _repository = Get.find<AppRepository>(tag: (AppRepository).toString()),
      _propertyLocal = Get.find<PropertyLocalDataSource>(),
      _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _expenseLocal = Get.find<ExpenseLocalDataSource>(),
      _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>(),
      _staffLocal = Get.find<RentStaffLocalDataSource>(),
      _tenantLocal = Get.find<TenantLocalDataSource>(),
      _unitLocal = Get.find<PropertyUnitLocalDataSource>(),
      _membersLocal = Get.find<PropertyMembersLocalDataSource>(),
      _maintenanceLocal = Get.find<RentScheduledMaintenanceLocalDataSource>(),
      _paymentReminderLocal = Get.find<RentPaymentReminderLocalDataSource>();

  final AppRepository _repository;
  final PropertyLocalDataSource _propertyLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final OfflineSyncQueueLocalDataSource _syncQueue;
  final RentStaffLocalDataSource _staffLocal;
  final TenantLocalDataSource _tenantLocal;
  final PropertyUnitLocalDataSource _unitLocal;
  final PropertyMembersLocalDataSource _membersLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;
  final RentPaymentReminderLocalDataSource _paymentReminderLocal;

  final loadingListing = true.obs;
  final selectedTab = ListingDetailsTab.overview.obs;
  final propertyWorkspaceMode = 'bnb'.obs;
  final paymentFollowUp = Rxn<PaymentFollowUpBannerVm>();
  final maintenanceRows = <ListingMaintenanceRowVm>[].obs;
  final selectedAssigneeStaffId = RxnString();
  final assigneeStaffOptions = <RentStaffRecord>[].obs;

  final listingTitle = ''.obs;
  final heroOverlayTitle = ''.obs;
  final heroImagePath = ''.obs;
  final occupancyPercent = 0.obs;
  final monthlyRevenueLabel = '0'.obs;
  final monthlyExpensesLabel = '0'.obs;
  final netIncomeLabel = '0'.obs;
  final monthlyRevenueProgress = 0.0.obs;

  /// All-time totals shown in the overview KPI cards.
  final totalIncomeLabel = '0'.obs;
  final totalExpensesLabel = '0'.obs;

  /// Expected monthly income based on current active tenant contracts (rent)
  /// or listed unit nightly rates (BnB).
  final expectedIncomeLabel = '0'.obs;

  /// Per-workspace breakdown for the income detail sheet.
  final rentIncomeTotalLabel = '0'.obs;
  final bnbIncomeTotalLabel = '0'.obs;

  final listingScrollController = ScrollController();

  final unitRows = <ListingUnitRowVm>[].obs;
  final recentActivity = <ListingActivityVm>[].obs;
  final staffPreview = <ListingStaffVm>[].obs;
  static final _money = NumberFormat('#,###', 'en_US');

  bool get _isSw => Get.locale?.languageCode == 'sw';

  List<String> get financeWorkspaceTypes {
    final mode = propertyWorkspaceMode.value;
    if (mode == 'both') return const ['bnb', 'rent'];
    if (mode == 'rent') return const ['rent'];
    return const ['bnb'];
  }

  List<ListingDetailsTab> get visibleTabs {
    final mode = propertyWorkspaceMode.value;
    final tabs = <ListingDetailsTab>[ListingDetailsTab.overview];
    if (mode == 'bnb' || mode == 'both') tabs.add(ListingDetailsTab.bnb);
    if (mode == 'rent' || mode == 'both') tabs.add(ListingDetailsTab.rent);
    tabs.addAll([
      ListingDetailsTab.finance,
      ListingDetailsTab.staff,
      ListingDetailsTab.maintenance,
    ]);
    return tabs;
  }

  List<ListingUnitRowVm> get bnbUnitRows {
    final mode = propertyWorkspaceMode.value;
    if (mode == 'rent') return const [];
    return unitRows.where((u) {
      final um = u.operationMode.trim().toLowerCase();
      if (mode == 'both') return um != 'rent';
      return um != 'rent';
    }).toList();
  }

  List<ListingUnitRowVm> get rentUnitRows {
    final mode = propertyWorkspaceMode.value;
    if (mode == 'bnb') return const [];
    if (mode == 'rent') return unitRows.toList();
    return unitRows
        .where((u) => u.operationMode.trim().toLowerCase() == 'rent')
        .toList();
  }

  void selectTab(ListingDetailsTab tab) {
    if (!visibleTabs.contains(tab)) return;
    selectedTab.value = tab;
    if (tab == ListingDetailsTab.staff ||
        tab == ListingDetailsTab.maintenance) {
      refreshStaffPanel();
    }
  }

  void ensureSelectedTabValid() {
    if (!visibleTabs.contains(selectedTab.value)) {
      selectedTab.value = ListingDetailsTab.overview;
    }
  }

  // Cached at init from route arguments so they remain stable even after
  // Get.arguments changes when child routes are pushed (e.g. edit screens).
  String _propertyId = '';
  String _propertyName = '';
  String _propertyLocation = '';

  @override
  void onInit() {
    super.onInit();
    _applyRouteArguments();
  }

  @override
  void onReady() {
    super.onReady();
    loadListingDetail().then((_) => refreshStaffPanel());
  }

  @override
  void onClose() {
    listingScrollController.dispose();
    super.onClose();
  }

  static Future<void> refreshIfRegistered() async {
    await RentListingActivityLogController.refreshIfRegistered();
    if (!Get.isRegistered<ListingDetailsController>()) return;
    await Get.find<ListingDetailsController>().refreshRecentActivityAndRevenue();
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

  Future<void> loadListingDetail() async {
    loadingListing.value = true;
    try {
      Map<String, dynamic>? remoteListing;
      if (_propertyId.isNotEmpty) {
        remoteListing = await _fetchListingMapFromRepository(_propertyId);
      }

      // Priority: repository listing detail -> local listing units_json -> fallback demo rows.
      var realRows = remoteListing == null
          ? <ListingUnitRowVm>[]
          : _unitRowsFromAnyMap(remoteListing);
      if (realRows.isEmpty) {
        realRows = await _loadUnitRowsFromLocal();
      }
      unitRows.assignAll(realRows.isEmpty ? [] : realRows);
      await _syncPropertyWorkspaceMode();
      ensureSelectedTabValid();
      await _syncOccupancyPercent(remoteListing);
      await _syncMonthlyRevenue(remoteListing);
      await _loadPropertyFinanceTrends();
      await _loadPaymentFollowUp();
      await _loadMaintenanceRows();
      await _loadAssigneeStaffOptions();

      var activities = remoteListing == null
          ? <ListingActivityVm>[]
          : _activityFromAnyMap(remoteListing);
      if (activities.isEmpty) {
        activities = await _loadActivityFromLocal();
      }
      recentActivity.assignAll(activities);

      var staff = remoteListing == null
          ? <ListingStaffVm>[]
          : _staffFromAnyMap(remoteListing);
      if (staff.isEmpty) {
        staff = await _loadStaffFromLocal();
      }
      staffPreview.assignAll(staff);
      await _syncListingTitlesFromLocal();
      await _syncHeroImage();
    } finally {
      loadingListing.value = false;
    }
  }

  /// Refreshes app bar + hero from local [PropertyRecord] after edits or pull-to-refresh.
  void _applyRouteArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    // Cache property identifiers immediately so they survive any subsequent
    // Get.toNamed() calls that overwrite Get.arguments.
    _propertyId = (args['property_id'] ?? '').toString().trim();
    _propertyName = (args['property_name'] ?? '').toString().trim();
    _propertyLocation = (args['property_location'] ?? '').toString().trim();

    final image = (args['property_image'] ?? '').toString().trim();
    if (_propertyName.isNotEmpty) {
      listingTitle.value = _propertyName;
      heroOverlayTitle.value = _propertyLocation.isEmpty
          ? _propertyName
          : '$_propertyName • $_propertyLocation';
    } else if (_propertyLocation.isNotEmpty) {
      listingTitle.value = _propertyLocation;
      heroOverlayTitle.value = _propertyLocation;
    }
    if (image.isNotEmpty) {
      heroImagePath.value = image;
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
    final incomes = <IncomeRecord>[];
    final expenses = <ExpenseRecord>[];
    for (final ws in financeWorkspaceTypes) {
      incomes.addAll(
        await _incomeLocal.getAllByPropertyRefAndWorkspace(
          propertyRef: _propertyId,
          workspaceType: ws,
        ),
      );
      expenses.addAll(await _expenseLocal.getAllNewestFirst(workspaceType: ws));
    }
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

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

    bool matchesListingScope({
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
      final rowNotes = notes.trim().toLowerCase();
      final name = _propertyName.toLowerCase();
      final loc = _propertyLocation.toLowerCase();
      if (name.isEmpty && loc.isEmpty) return false;
      if (name.isNotEmpty &&
          (apt.contains(name) ||
              unit.contains(name) ||
              rowNotes.contains(name))) {
        return true;
      }
      if (loc.isNotEmpty &&
          (apt.contains(loc) || unit.contains(loc) || rowNotes.contains(loc))) {
        return true;
      }
      return false;
    }

    // Monthly totals — for the revenue and expense labels.
    double monthlyIncomeTotal = 0;
    double monthlyExpenseTotal = 0;

    // All-time totals — used for net income (all units, entire tenancy history).
    double allTimeIncomeTotal = 0;
    double allTimeExpenseTotal = 0;

    for (final row in incomes) {
      if (!matchesListingScope(
        propertyRef: row.propertyRef,
        apartment: row.apartment,
        apartmentUnit: row.apartmentUnit,
        notes: row.notes,
      )) { continue; }
      allTimeIncomeTotal += row.amountValue;
      final d = row.paidLocalCalendarOrCreated();
      if (!d.isBefore(start) && d.isBefore(end)) {
        monthlyIncomeTotal += row.amountValue;
      }
    }

    for (final row in expenses) {
      // Expense table has no property_ref column; match by apartment name/notes.
      if (!matchesListingScope(
        propertyRef: '',
        apartment: row.apartment,
        apartmentUnit: row.apartmentUnit,
        notes: row.notes,
      )) { continue; }
      allTimeExpenseTotal += row.amountValue;
      final d = row.paidLocalCalendarOrCreated();
      if (!d.isBefore(start) && d.isBefore(end)) {
        monthlyExpenseTotal += row.amountValue;
      }
    }

    // Local rows (including newly saved income) are authoritative; fall back
    // to the remote monthly figure only when no local income exists yet.
    final remoteMonthly = remoteListing != null
        ? _extractRemoteMonthlyIncome(remoteListing)
        : 0.0;
    final displayMonthly =
        monthlyIncomeTotal > 0 ? monthlyIncomeTotal : remoteMonthly;

    monthlyRevenueLabel.value = _money.format(displayMonthly.round());
    monthlyExpensesLabel.value = _money.format(monthlyExpenseTotal.round());

    // All-time KPI labels.
    totalIncomeLabel.value = _money.format(allTimeIncomeTotal.round());
    totalExpensesLabel.value = _money.format(allTimeExpenseTotal.round());

    // Per-workspace income breakdown (from the already-loaded list).
    double rentTotal = 0;
    double bnbTotal = 0;
    for (final row in incomes) {
      final ws = row.workspaceType.trim().toLowerCase();
      if (ws == 'bnb') {
        bnbTotal += row.amountValue;
      } else {
        rentTotal += row.amountValue;
      }
    }
    rentIncomeTotalLabel.value = _money.format(rentTotal.round());
    bnbIncomeTotalLabel.value = _money.format(bnbTotal.round());

    // Net income = all-time income for all units − all-time expenses for all
    // units in this property.  When there is no local income at all, add the
    // remote monthly figure as the best available estimate.
    final netIncomeBase = allTimeIncomeTotal > 0
        ? allTimeIncomeTotal
        : (monthlyIncomeTotal > 0 ? monthlyIncomeTotal : remoteMonthly);
    netIncomeLabel.value =
        _money.format((netIncomeBase - allTimeExpenseTotal).round());

    final expectedRemote = remoteListing != null
        ? _extractExpectedMonthlyIncome(remoteListing)
        : 0.0;
    final expectedLocal = await _expectedIncomeFromLocalUnits();

    // For rent/both: active tenant contracted rents are more meaningful
    // than unit list prices.
    final tenantExpected = await _expectedIncomeFromTenants(scopeRefs);

    // Priority: active tenants > unit rates > remote estimate
    final expected = tenantExpected > 0
        ? tenantExpected
        : (expectedLocal > 0 ? expectedLocal : expectedRemote);

    expectedIncomeLabel.value = _money.format(expected.round());
    monthlyRevenueProgress.value = expected <= 0
        ? 0
        : (displayMonthly / expected).clamp(0, 1).toDouble();
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
      final target =
          rows.firstWhereOrNull((r) {
            final localId = 'local_${r.id}';
            return (_propertyId.isNotEmpty &&
                    (r.propertyRef.trim() == _propertyId ||
                        localId == _propertyId)) ||
                (_propertyName.isNotEmpty &&
                    (r.apartmentSuite.trim() == _propertyName ||
                        r.propertyLocation.trim() == _propertyName));
          }) ??
          rows.first;
      final decoded = jsonDecode(
        target.unitsJson.trim().isEmpty ? '[]' : target.unitsJson,
      );
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

  /// Computes the expected monthly income from active tenant contracts.
  ///
  /// Workspace type is inferred from [TenantRecord.rentFrequency]:
  /// - "per day" / "per night" / "nightly" → BnB (nightly × 30 as monthly proxy)
  /// - "per stay" → BnB one-off (counted as-is)
  /// - "per week" → monthly × 4.333
  /// - "per year" → monthly ÷ 12
  /// - "per quarter" → monthly ÷ 3
  /// - everything else → treat as monthly rent
  /// Formats [amount] in base currency, converting if [currency] != base.
  /// Appends "≈" prefix when conversion is applied.
  String _formatRentInBase(double amount, String currency) {
    final cs = Get.find<CurrencyService>();
    final base = cs.baseCurrency.value.trim().toUpperCase();
    final cur = currency.trim().toUpperCase();
    if (cur.isNotEmpty && cur != base) {
      final rate = cs.sellingRateFor(cur) ?? 0;
      if (rate > 0) {
        return '≈ ${cs.formatBase((amount * rate).round())}';
      }
    }
    return cs.formatBase(amount.round());
  }

  /// Returns the expected monthly income in base currency.
  /// If a tenant's [rentCurrency] differs from the base currency the amount is
  /// converted live using the latest selling rate.
  Future<double> _expectedIncomeFromTenants(Set<String> scopeRefs) async {
    try {
      final tenants = await _tenantLocal.getAllNewestFirst();
      final mode = propertyWorkspaceMode.value;
      final currencyService = Get.find<CurrencyService>();
      double total = 0;

      for (final t in tenants) {
        if (!_tenantMatchesListingForActivity(t, scopeRefs)) continue;
        var amount = t.rentAmountValue;
        if (amount <= 0) continue;

        // Convert contract amount to base currency if needed.
        final tenantCurrency = t.rentCurrency.trim().toUpperCase();
        final baseCurrency = currencyService.baseCurrency.value.trim().toUpperCase();
        if (tenantCurrency != baseCurrency && tenantCurrency.isNotEmpty) {
          final rate = currencyService.sellingRateFor(tenantCurrency) ?? 0;
          if (rate > 0) amount = amount * rate;
        }

        final freq = t.rentFrequency.trim().toLowerCase();
        final isBnb = freq.contains('day') ||
            freq.contains('night') ||
            freq.contains('stay');

        if (isBnb) {
          if (mode == 'bnb' || mode == 'both') {
            // "per stay" is a fixed amount; nightly → monthly via ×30.
            total += freq.contains('stay') ? amount : amount * 30;
          }
        } else {
          if (mode == 'rent' || mode == 'both') {
            final monthly = freq.contains('week')
                ? amount * 4.333
                : freq.contains('year')
                    ? amount / 12
                    : freq.contains('quarter')
                        ? amount / 3
                        : amount; // default: monthly
            total += monthly;
          }
        }
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _syncOccupancyPercent(
    Map<String, dynamic>? remoteListing,
  ) async {
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
          trailing: (m['amountLabel'] ?? m['amount'] ?? m['status'] ?? '')
              .toString()
              .trim(),
          timeLabel: (m['timeLabel'] ?? m['time'] ?? m['createdAt'] ?? '')
              .toString()
              .trim(),
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
    final unitActivityKeys = <String>{};

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
            activityType: ActivityType.maintenance,
            maintenanceId: r.id,
          ),
        ));
      }
    } catch (_) {}

    try {
      final units = await _unitLocal.getAllNewestFirst();
      for (final u in units) {
        if (!_unitMatchesListing(u, scopeRefs)) continue;
        final name = u.unitName.trim();
        if (name.isNotEmpty) unitActivityKeys.add(name.toLowerCase());
        candidates.add((
          ts: u.createdAtMs,
          vm: ListingActivityVm(
            title: _isSw ? 'Unit imeongezwa' : 'Property unit added',
            subtitle: name.isEmpty ? (_isSw ? 'Unit mpya' : 'New unit') : name,
            trailing: u.rentAmount > 0
                ? _formatRentInBase(u.rentAmount, u.rentCurrency)
                : '',
            timeLabel: _relativeDateFromMs(u.createdAtMs),
            accentColor: const Color(0xFF2563EB),
            activityType: ActivityType.unit,
            unitLocalId: u.id,
            unitLocalPropertyRef: u.propertyRef,
            unitLocalName: name,
          ),
        ));
      }
    } catch (_) {}

    try {
      final row = await _findLocalPropertyRowForListing();
      final decoded = jsonDecode(
        row?.unitsJson.trim().isEmpty ?? true ? '[]' : row!.unitsJson,
      );
      if (decoded is List && row != null) {
        for (final e in decoded.whereType<Map>()) {
          final m = Map<String, dynamic>.from(e);
          final name = (m['unitName'] ?? m['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final key = name.toLowerCase();
          if (unitActivityKeys.contains(key)) continue;
          unitActivityKeys.add(key);
          final rent = (m['unitRent'] ?? m['rent'] ?? '').toString().trim();
          candidates.add((
            ts: row.createdAtMs,
            vm: ListingActivityVm(
              title: _isSw ? 'Unit imeongezwa' : 'Property unit added',
              subtitle: name,
              trailing: rent.isEmpty ? '' : rent,
              timeLabel: _relativeDateFromMs(row.createdAtMs),
              accentColor: const Color(0xFF2563EB),
            ),
          ));
        }
      }
    } catch (_) {}

    try {
      final tenants = await _tenantLocal.getAllNewestFirst();
      for (final t in tenants) {
        if (!_tenantMatchesListingForActivity(t, scopeRefs)) continue;
        final unit = t.unitLabel.trim();
        candidates.add((
          ts: t.createdAtMs,
          vm: ListingActivityVm(
            title: _isSw ? 'Mpangaji ameongezwa' : 'Tenant added',
            subtitle: unit.isEmpty ? t.tenantName : '${t.tenantName} · $unit',
            trailing: t.rentAmountValue > 0
                ? _formatRentInBase(t.rentAmountValue, t.rentCurrency)
                : '',
            timeLabel: _relativeDateFromMs(t.createdAtMs),
            accentColor: const Color(0xFF16A34A),
            activityType: ActivityType.tenant,
            tenantId: t.id,
          ),
        ));
      }
    } catch (_) {}

    try {
      final staff = await _staffLocal.getAllNewestFirst();
      for (final s in staff) {
        candidates.add((
          ts: s.createdAtMs,
          vm: ListingActivityVm(
            title: _isSw ? 'Mfanyakazi ameongezwa' : 'Staff added',
            subtitle: s.jobTitle.trim().isEmpty
                ? s.name
                : '${s.name} · ${s.jobTitle}',
            trailing: s.displayAmountLine == '—' ? '' : s.displayAmountLine,
            timeLabel: _relativeDateFromMs(s.createdAtMs),
            accentColor: const Color(0xFF7C3AED),
            activityType: ActivityType.staff,
            staffId: s.id,
          ),
        ));
      }
    } catch (_) {}

    final incomes = <IncomeRecord>[];
    final expenses = <ExpenseRecord>[];
    for (final ws in financeWorkspaceTypes) {
      incomes.addAll(await _incomeLocal.getAllNewestFirst(workspaceType: ws));
      expenses.addAll(await _expenseLocal.getAllNewestFirst(workspaceType: ws));
    }
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
          trailing:
              '+ ${Get.find<CurrencyService>().formatBase(i.amountValue.round())}',
          timeLabel: _relativeDate(i.datePaidIso, i.createdAtMs),
          accentColor: const Color(0xFF0EA5A4),
          activityType: ActivityType.income,
          incomeId: i.id,
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
          trailing: Get.find<CurrencyService>().formatBase(
            e.amountValue.round(),
          ),
          timeLabel: _relativeDate(e.datePaidIso, e.createdAtMs),
          accentColor: const Color(0xFFF59E0B),
          activityType: ActivityType.expense,
          expenseId: e.id,
        ),
      ));
    }

    candidates.sort((a, b) => b.ts.compareTo(a.ts));
    return candidates.map((e) => e.vm).toList();
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

  bool _unitMatchesListing(PropertyUnitRecord r, Set<String> scopeRefs) {
    final ref = r.propertyRef.trim();
    return ref.isNotEmpty && scopeRefs.contains(ref);
  }

  bool _tenantMatchesListingForActivity(TenantRecord r, Set<String> scopeRefs) {
    final ref = r.propertyRef.trim();
    if (ref.isNotEmpty && scopeRefs.contains(ref)) return true;
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
    if (day == today.subtract(const Duration(days: 1))) {
      return _isSw ? 'Jana' : 'Yesterday';
    }
    return DateFormat('dd/MM').format(day);
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
        (r) =>
            _propertyName.isNotEmpty &&
            r.apartmentSuite.trim() == _propertyName,
      );
      target ??= rows.firstWhereOrNull(
        (r) =>
            _propertyName.isNotEmpty &&
            r.propertyLocation.trim() == _propertyName,
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
        if (listingLoc.isNotEmpty && label.contains(listingLoc.toLowerCase())) {
          return true;
        }
        return false;
      }

      final listingTenants = tenants.where(tenantMatchesListing).toList();

      final unitsRaw = target.unitsJson.trim();
      if (unitsRaw.isEmpty) {
        final attachedTenant = listingTenants.isEmpty
            ? null
            : listingTenants.first;
        final ws = target.workspaceType.trim().toLowerCase();
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
            operationMode: ws == 'rent' ? 'rent' : 'bnb',
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
        final mode = (m['operationMode'] ?? m['listingMode'] ?? m['workspaceType'])
            .toString()
            .trim()
            .toLowerCase();
        out.add(
          ListingUnitRowVm(
            name: unitName,
            subtitle: rent.isEmpty
                ? (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant')
                : 'Rent TZS $rent',
            status: attachedTenant == null
                ? ListingUnitStatus.short
                : ListingUnitStatus.occupied,
            tenantName: attachedTenant?.tenantName ?? '',
            tenantId: attachedTenant?.id,
            unitId: unitId,
            operationMode: mode == 'rent' ? 'rent' : 'bnb',
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
      final name = (m['unitName'] ?? m['name'] ?? m['label'] ?? '')
          .toString()
          .trim();
      if (name.isEmpty) continue;
      final rent = (m['unitRent'] ?? m['rent'] ?? m['price'] ?? '')
          .toString()
          .trim();
      final tenantName =
          (m['tenantName'] ??
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

  Future<void> loadRealDataSnapshot() async {
    await _loadPropertyFinanceTrends();
  }

  Future<void> _syncPropertyWorkspaceMode() async {
    final row = await _findLocalPropertyRowForListing();
    final raw = row?.workspaceType.trim().toLowerCase() ?? '';
    if (raw == 'rent' || raw == 'bnb' || raw == 'both') {
      propertyWorkspaceMode.value = raw;
      return;
    }
    propertyWorkspaceMode.value = 'bnb';
  }

  Future<void> _loadPropertyFinanceTrends() async {
    financialTrendsLoading.value = true;
    try {
      final scope = await PropertyListingFinanceScope.resolve(
        propertyId: _propertyId,
        propertyName: _propertyName,
        propertyLocation: _propertyLocation,
        propertyLocal: _propertyLocal,
      );
      final incomes = <IncomeRecord>[];
      final expenses = <ExpenseRecord>[];
      for (final ws in financeWorkspaceTypes) {
        incomes.addAll(await _incomeLocal.getAllNewestFirst(workspaceType: ws));
        expenses.addAll(await _expenseLocal.getAllNewestFirst(workspaceType: ws));
      }
      financialTrends.value = PropertyFinancialTimeSeriesBuilder.build(
        scope: scope,
        incomes: incomes,
        expenses: expenses,
      );
    } catch (_) {
      financialTrends.value = const PropertyFinancialTimeSeries(
        dateLabels: [],
        incomeByPeriod: [],
        costsByPeriod: [],
      );
    } finally {
      financialTrendsLoading.value = false;
    }
  }

  Future<void> _loadPaymentFollowUp() async {
    paymentFollowUp.value = null;
    final scopeRefs = await _listingPropertyRefsForActivity();
    final reminders = await _paymentReminderLocal.getAllNewestFirst();
    final now = DateTime.now();
    for (final r in reminders) {
      if (!_paymentReminderMatchesListing(r, scopeRefs)) continue;
      DateTime? at;
      try {
        at = DateTime.parse(r.reminderAtIso.trim());
      } catch (_) {
        continue;
      }
      if (at.isAfter(now.add(const Duration(days: 14)))) continue;
      final balance = NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0)
          .format(r.balanceTsh);
      paymentFollowUp.value = PaymentFollowUpBannerVm(
        message: _isSw
            ? 'Malipo ya ${r.tenantName.trim().isEmpty ? 'mpangaji' : r.tenantName} ($balance) yanahitaji ufuatiliaji.'
            : 'Payment for ${r.tenantName.trim().isEmpty ? 'tenant' : r.tenantName} ($balance) needs follow-up.',
        actionLabel: _isSw ? 'Tuma ukumbusho' : 'Send reminder',
        tenantName: r.tenantName.trim(),
        balanceTsh: r.balanceTsh,
      );
      return;
    }

    final tenants = await _tenantLocal.getAllNewestFirst();
    for (final t in tenants) {
      if (!_tenantMatchesListingForActivity(t, scopeRefs)) continue;
      final end = _tryParseDate(t.leaseEndIso);
      if (end == null) continue;
      if (end.isBefore(now) || end.isBefore(now.add(const Duration(days: 7)))) {
        paymentFollowUp.value = PaymentFollowUpBannerVm(
          message: _isSw
              ? 'Mkataba wa ${t.tenantName} unakaribia au umepita — angalia malipo.'
              : '${t.tenantName}\'s lease is ending or overdue — review payments.',
          actionLabel: _isSw ? 'Angalia mpangaji' : 'Review tenant',
          tenantName: t.tenantName.trim(),
          phone: t.phoneNumber.trim(),
        );
        return;
      }
    }
  }

  bool _paymentReminderMatchesListing(
    RentPaymentReminderRecord r,
    Set<String> scopeRefs,
  ) {
    final label = r.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final nameLc = _propertyName.toLowerCase();
    final locLc = _propertyLocation.toLowerCase();
    if (nameLc.isNotEmpty && label.contains(nameLc)) return true;
    if (locLc.isNotEmpty && label.contains(locLc)) return true;
    return scopeRefs.isNotEmpty && label.isNotEmpty;
  }

  DateTime? _tryParseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadMaintenanceRows() async {
    final scopeRefs = await _listingPropertyRefsForActivity();
    final rows = await _maintenanceLocal.getAllNewestFirst();
    final out = <ListingMaintenanceRowVm>[];
    for (final r in rows) {
      if (!_maintenanceMatchesListing(r, scopeRefs)) continue;
      DateTime? scheduled;
      try {
        scheduled = DateTime.parse(r.scheduledDateIso.trim());
      } catch (_) {
        scheduled = null;
      }
      out.add(
        ListingMaintenanceRowVm(
          id: r.id,
          category: r.category,
          description: r.description,
          scheduledLabel: scheduled != null
              ? DateFormat('MMM d, yyyy').format(scheduled)
              : '—',
          priority: r.priority,
        ),
      );
    }
    maintenanceRows.assignAll(out);
  }

  Future<void> _loadAssigneeStaffOptions() async {
    final rows = await _staffLocal.getAllNewestFirst();
    assigneeStaffOptions.assignAll(rows);
  }

  String? get selectedAssigneeStaffName {
    final id = selectedAssigneeStaffId.value;
    if (id == null || id.isEmpty) return null;
    final parsed = int.tryParse(id);
    if (parsed == null) return null;
    for (final s in assigneeStaffOptions) {
      if (s.id == parsed) return s.name.trim();
    }
    return null;
  }

  void updateAssigneeStaff(String? staffId) {
    selectedAssigneeStaffId.value =
        staffId == null || staffId.isEmpty ? null : staffId;
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

  void onShowIncomeBreakdown() {
    final isSw = _isSw;
    final currency = Get.find<CurrencyService>().baseCurrency.value;

    final workspaceMode = propertyWorkspaceMode.value;
    final showRent = workspaceMode == 'rent' || workspaceMode == 'both';
    final showBnb = workspaceMode == 'bnb' || workspaceMode == 'both';

    Get.bottomSheet(
      _IncomeBreakdownSheet(
        isSw: isSw,
        currency: currency,
        totalLabel: totalIncomeLabel.value,
        rentLabel: rentIncomeTotalLabel.value,
        bnbLabel: bnbIncomeTotalLabel.value,
        showRent: showRent,
        showBnb: showBnb,
      ),
      isScrollControlled: true,
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
        (r) =>
            _propertyName.isNotEmpty &&
            r.apartmentSuite.trim() == _propertyName,
      );
      target ??= rows.firstWhereOrNull(
        (r) =>
            _propertyName.isNotEmpty &&
            r.propertyLocation.trim() == _propertyName,
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

  Future<void> onOpenInventoryTracking() async {
    var ref = _propertyId;
    if (ref.isEmpty) {
      final row = await _findLocalPropertyRowForListing();
      if (row != null) {
        ref = row.propertyRef.trim().isNotEmpty
            ? row.propertyRef.trim()
            : 'local_${row.id}';
      }
    }
    if (ref.isEmpty) {
      showErrorMessage(
        _isSw
            ? 'Hakuna kitambulisho cha mali kwa ufuatiliaji wa vifaa.'
            : 'No property reference is available for inventory tracking.',
      );
      return;
    }
    final units = unitRows
        .map(
          (u) => {
            'unitId': u.unitId,
            'unitName': u.name,
          },
        )
        .toList();
    await Get.toNamed(
      Routes.INVENTORY_TRACKING,
      parameters: {
        'propertyRef': ref,
        'propertyName': _propertyLabelForEstimate(),
      },
      arguments: {'units': units},
    );
  }

  Future<void> onAddPropertyEstimationCosts() async {
    var ref = _propertyId;
    if (ref.isEmpty) {
      final row = await _findLocalPropertyRowForListing();
      if (row != null) {
        ref = row.propertyRef.trim().isNotEmpty
            ? row.propertyRef.trim()
            : 'local_${row.id}';
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
    await Get.toNamed(Routes.EDIT_LISTING, arguments: {'property_ref': ref});
    await loadListingDetail();
  }

  Future<void> onAddNewUnit(String workspace) async {
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

    await Get.toNamed(
      Routes.EDIT_LISTING,
      arguments: {
        'property_ref': propertyHubId,
        'default_unit_mode': workspace == 'rent' ? 'rent' : 'bnb',
      },
    );
    await loadListingDetail();
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

    await Get.toNamed(
      Routes.EDIT_UNIT,
      arguments: {
        'property_ref': propertyRef,
        'unit_name': row.name,
        if (row.unitId.trim().isNotEmpty) 'unit_id': row.unitId.trim(),
      },
    );
    await loadListingDetail();
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
            child: Text(
              _isSw ? 'Ghairi' : 'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              _isSw ? 'Futa' : 'Delete',
              style: TextStyle(fontSize: 16),
            ),
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

  void onViewAllLog() => showSuccessMessage(
    _isSw ? 'Kumbukumbu zote' : 'Viewing full activity log',
  );

  Future<void> onManageStaff() async {
    await Get.toNamed(Routes.TEAM_AND_STAFF);
    await loadListingDetail();
  }

  Future<void> onEditActivity(ListingActivityVm activity) async {
    switch (activity.activityType) {
      case ActivityType.expense:
        final id = activity.expenseId;
        if (id == null) return;
        await Get.toNamed(
          Routes.ADD_EXPENSE,
          arguments: {'mode': 'edit', 'expenseId': id},
        );

      case ActivityType.income:
        await Get.toNamed(
          Routes.RECORD_PAYMENT,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            'workspaceType': _workspaceParamForMode(propertyWorkspaceMode.value),
          },
        );

      case ActivityType.tenant:
        final id = activity.tenantId;
        if (id == null) return;
        await Get.toNamed(
          Routes.RENT_TENANT_LEDGER_OCCUPANCY,
          parameters: {'tenantId': id.toString()},
        );

      case ActivityType.maintenance:
        await Get.toNamed(
          Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            'workspaceType': propertyWorkspaceMode.value,
          },
        );

      case ActivityType.staff:
        await Get.toNamed(Routes.RENT_STAFF_MANAGEMENT);

      case ActivityType.unit:
        final ref = activity.unitLocalPropertyRef ?? _propertyId;
        final name = activity.unitLocalName ?? '';
        await Get.toNamed(
          Routes.EDIT_UNIT,
          arguments: {
            'property_ref': ref,
            'unit_name': name,
          },
        );

      case ActivityType.remote:
        return;
    }
    await loadListingDetail();
  }

  Future<void> onDeleteActivity(ListingActivityVm activity) async {
    if (!activity.canDelete) return;

    final (deleteTitle, deleteMsg) = switch (activity.activityType) {
      ActivityType.expense => (
          _isSw ? 'Futa gharama?' : 'Delete expense?',
          _isSw
              ? 'Gharama hii itaondolewa kwenye shughuli na hesabu za mali.'
              : 'This expense will be removed from activity and property totals.',
        ),
      ActivityType.income => (
          _isSw ? 'Futa malipo?' : 'Delete payment?',
          _isSw
              ? 'Malipo haya yatafutwa kwenye shughuli na hesabu.'
              : 'This payment record will be permanently removed.',
        ),
      ActivityType.tenant => (
          _isSw ? 'Futa mpangaji?' : 'Delete tenant?',
          _isSw
              ? 'Rekodi ya mpangaji itafutwa. Hii haitabatilisha mkataba.'
              : 'The tenant record will be deleted. This does not cancel any contract.',
        ),
      ActivityType.maintenance => (
          _isSw ? 'Futa matengenezo?' : 'Delete maintenance?',
          _isSw
              ? 'Rekodi hii ya matengenezo itafutwa.'
              : 'This scheduled maintenance record will be deleted.',
        ),
      ActivityType.staff => (
          _isSw ? 'Futa mfanyakazi?' : 'Remove staff member?',
          _isSw
              ? 'Rekodi ya mfanyakazi itafutwa.'
              : 'This staff record will be permanently removed.',
        ),
      ActivityType.unit => (
          _isSw ? 'Futa unit?' : 'Delete unit?',
          _isSw
              ? 'Unit hii itafutwa kwenye orodha ya mali.'
              : 'This unit will be removed from the property.',
        ),
      ActivityType.remote => ('', ''),
    };

    if (deleteTitle.isEmpty) return;

    final confirmed = await confirmDestructive(
      title: deleteTitle,
      message: deleteMsg,
      confirmLabel: _isSw ? 'Futa' : 'Delete',
      cancelLabel: _isSw ? 'Ghairi' : 'Cancel',
    );
    if (!confirmed) return;

    switch (activity.activityType) {
      case ActivityType.expense:
        final id = activity.expenseId!;
        await _expenseLocal.deleteById(id);
        await _syncQueue.deleteByDedupeKey('expense:create:$id');
        unawaited(_remoteDeleteExpense(id));

      case ActivityType.income:
        final incomeId = activity.incomeId!;
        final record = await _incomeLocal.getById(incomeId);
        await _incomeLocal.deleteById(incomeId);
        if (record != null && record.backendPaymentId.isNotEmpty) {
          unawaited(_remoteDeletePayment(record.backendPaymentId));
        }

      case ActivityType.tenant:
        final tenantId = activity.tenantId!;
        final tenantRec = await _tenantLocal.findById(tenantId);
        await _tenantLocal.deleteById(tenantId);
        if (tenantRec != null && tenantRec.backendTenantId.isNotEmpty) {
          unawaited(_remoteDeleteTenant(tenantRec.backendTenantId));
        }

      case ActivityType.maintenance:
        final maintenanceId = activity.maintenanceId!;
        final maintenanceRec = await _maintenanceLocal.getById(maintenanceId);
        await _maintenanceLocal.deleteById(maintenanceId);
        if (maintenanceRec != null && maintenanceRec.backendTaskId.isNotEmpty) {
          unawaited(_remoteDeleteTask(maintenanceRec.backendTaskId));
        }

      case ActivityType.staff:
        await _staffLocal.deleteById(activity.staffId!);

      case ActivityType.unit:
        await _unitLocal.deleteById(activity.unitLocalId!);

      case ActivityType.remote:
        return;
    }

    final successMsg = switch (activity.activityType) {
      ActivityType.expense =>
        _isSw ? 'Gharama imefutwa' : 'Expense deleted',
      ActivityType.income =>
        _isSw ? 'Malipo yamefutwa' : 'Payment deleted',
      ActivityType.tenant =>
        _isSw ? 'Mpangaji amefutwa' : 'Tenant deleted',
      ActivityType.maintenance =>
        _isSw ? 'Matengenezo yamefutwa' : 'Maintenance deleted',
      ActivityType.staff =>
        _isSw ? 'Mfanyakazi amefutwa' : 'Staff member removed',
      ActivityType.unit =>
        _isSw ? 'Unit imefutwa' : 'Unit deleted',
      ActivityType.remote => '',
    };
    if (successMsg.isNotEmpty) {
      showSuccessWithHaptic(successMsg);
    }
    await loadListingDetail();
  }

  // ── Remote delete helpers (fire-and-forget with offline queue fallback) ──

  Future<void> _remoteDeleteExpense(int localId) async {
    final backendId = await _expenseLocal.getBackendExpenseId(localId);
    if (backendId == null || backendId.isEmpty) return;
    await _tryOrQueue(
      remoteCall: () => _repository.deleteExpense(backendId),
      entityType: 'expense',
      operation: 'delete',
      payload: {'backendExpenseId': backendId},
      dedupeKey: 'expense:delete:$backendId',
    );
  }

  Future<void> _remoteDeletePayment(String backendPaymentId) async {
    await _tryOrQueue(
      remoteCall: () => _repository.deletePayment(backendPaymentId),
      entityType: 'payment',
      operation: 'delete',
      payload: {'paymentId': backendPaymentId},
      dedupeKey: 'payment:delete:$backendPaymentId',
    );
  }

  Future<void> _remoteDeleteTenant(String backendTenantId) async {
    await _tryOrQueue(
      remoteCall: () => _repository.deleteTenant(backendTenantId),
      entityType: 'tenant',
      operation: 'delete',
      payload: {'id': backendTenantId},
      dedupeKey: 'tenant:delete:$backendTenantId',
    );
  }

  Future<void> _remoteDeleteTask(String backendTaskId) async {
    await _tryOrQueue(
      remoteCall: () => _repository.deleteTask(backendTaskId),
      entityType: 'task',
      operation: 'delete',
      payload: {'taskId': backendTaskId},
      dedupeKey: 'task:delete:$backendTaskId',
    );
  }

  Future<void> _tryOrQueue({
    required Future<GeneralResponse> Function() remoteCall,
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
    required String dedupeKey,
  }) async {
    try {
      final res = await remoteCall();
      final ok = res.responseCode == null ||
          res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201';
      if (!ok) throw Exception(res.message ?? 'Remote $entityType:$operation failed');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: entityType,
        operation: operation,
        payloadJson: jsonEncode(payload),
        dedupeKey: dedupeKey,
      );
    }
  }

  String _workspaceParamForMode(String mode) =>
      mode.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb';

  void onAddTenantForWorkspace(String workspace) {
    Get.toNamed(
      Routes.ADD_NEW_TENANT,
      parameters: {
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        'workspaceType': _workspaceParamForMode(workspace),
      },
      arguments: {
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        if (_propertyName.isNotEmpty) 'property': _propertyName,
      },
    )?.then((_) => loadListingDetail());
  }

  void onAddIncomeForWorkspace(String workspace) {
    Get.toNamed(
      Routes.RECORD_PAYMENT,
      parameters: {
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        'workspaceType': _workspaceParamForMode(workspace),
      },
      arguments: {
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        if (_propertyName.isNotEmpty) 'property': _propertyName,
      },
    )?.then((_) => loadListingDetail());
  }

  void onScheduleMaintenance() {
    final assignee = selectedAssigneeStaffName;
    Get.toNamed(
      Routes.RENT_SCHEDULE_MAINTENANCE_FORM,
      parameters: {
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        'workspaceType': propertyWorkspaceMode.value,
        if (assignee != null && assignee.isNotEmpty) 'description': 'Assigned to: $assignee',
      },
    )?.then((_) => loadListingDetail());
  }

  void onAddMaintenanceTask() {
    final assignee = selectedAssigneeStaffName;
    Get.toNamed(
      Routes.ADD_TASK,
      parameters: {
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
      },
      arguments: {
        if (assignee != null && assignee.isNotEmpty)
          'description': 'Assigned to: $assignee',
      },
    )?.then((_) => loadListingDetail());
  }

  void onPaymentFollowUpTap() {
    final banner = paymentFollowUp.value;
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        if (banner != null && banner.tenantName.isNotEmpty)
          'name': banner.tenantName,
        if (banner != null && banner.phone.isNotEmpty)
          'phone': banner.phone,
        if (banner != null && banner.balanceTsh > 0)
          'balance': banner.balanceTsh.toString(),
      },
    )?.then((_) => loadListingDetail());
  }

  void onQuickAction(int index) {
    switch (index) {
      case 0:
        onAddTenantForWorkspace(
          propertyWorkspaceMode.value == 'rent' ? 'rent' : 'bnb',
        );
        break;
      case 1:
        onAddIncomeForWorkspace(
          propertyWorkspaceMode.value == 'rent' ? 'rent' : 'bnb',
        );
        break;
      case 2:
        Get.toNamed(
          Routes.ADD_EXPENSE,
          parameters: {
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
          },
        )?.then((_) => loadListingDetail());
        break;
      case 3:
        onScheduleMaintenance();
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

  void onUnitPrimaryActionForWorkspace(
    ListingUnitRowVm row,
    String workspace,
  ) {
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
            'workspaceType': _workspaceParamForMode(workspace),
          },
        )?.then((_) => loadListingDetail());
        break;
    }
  }

  void onAnalyticsQuickAction(int index) {
    if (index == 1) {
      Get.toNamed(Routes.RENT_MONTHLY_PL_SUMMARY);
    }
  }

  void onUnitPrimaryAction(ListingUnitRowVm row) {
    final ws = row.operationMode.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb';
    onUnitPrimaryActionForWorkspace(row, ws);
  }

  Future<void> onAddStaff() async {
    await Get.toNamed(
      Routes.RENT_STAFF_MANAGEMENT,
      arguments: {
        'property_ref': _propertyId,
        'property_name': _propertyName,
      },
    );
    await _loadAssigneeStaffOptions();
    await loadListingDetail();
  }

  Future<void> refreshStaffPanel() async {
    if (Get.isRegistered<RentStaffManagementController>()) {
      await Get.find<RentStaffManagementController>().loadStaff();
    }
    if (Get.isRegistered<RentStaffPayrollDetailsController>()) {
      await Get.find<RentStaffPayrollDetailsController>().loadPayroll();
    }
    await _loadAssigneeStaffOptions();
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

/// ─── Income breakdown bottom sheet ──────────────────────────────────────────

class _IncomeBreakdownSheet extends StatelessWidget {
  const _IncomeBreakdownSheet({
    required this.isSw,
    required this.currency,
    required this.totalLabel,
    required this.rentLabel,
    required this.bnbLabel,
    required this.showRent,
    required this.showBnb,
  });

  final bool isSw;
  final String currency;
  final String totalLabel;
  final String rentLabel;
  final String bnbLabel;
  final bool showRent;
  final bool showBnb;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final line = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? const Color(0xFFF2F2F7) : const Color(0xFF111827);
    final textMuted = isDark ? const Color(0xFFAEAEB2) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isSw ? 'Mgawanyo wa Mapato' : 'Income Breakdown',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSw
                ? 'Mapato yote kulingana na aina ya mali'
                : 'All-time income by property mode',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 20),
          if (showRent)
            _row(
              icon: Icons.home_work_outlined,
              iconColor: const Color(0xFF2563EB),
              label: isSw ? 'Kodi (Rent)' : 'Rent',
              value: '$currency $rentLabel',
              textPrimary: textPrimary,
              textMuted: textMuted,
              line: line,
            ),
          if (showRent && showBnb) const SizedBox(height: 2),
          if (showBnb)
            _row(
              icon: Icons.bed_outlined,
              iconColor: const Color(0xFF0EA5A4),
              label: isSw ? 'BnB (Usiku)' : 'BnB',
              value: '$currency $bnbLabel',
              textPrimary: textPrimary,
              textMuted: textMuted,
              line: line,
            ),
          if (showRent || showBnb) ...[
            const SizedBox(height: 12),
            Divider(color: line),
            const SizedBox(height: 8),
          ],
          _row(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: scheme.primary,
            label: isSw ? 'Jumla' : 'Total',
            value: '$currency $totalLabel',
            textPrimary: textPrimary,
            textMuted: textMuted,
            line: line,
            isBold: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textMuted,
    required Color line,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(14),
        color: isBold ? iconColor.withValues(alpha: 0.08) : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
