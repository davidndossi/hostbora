import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/base/feedback_extensions.dart';
import '../../../core/mixins/listing_financial_trends_mixin.dart';
import '../../../core/utils/auth_messages.dart';
import '../../../core/utils/expected_month_rent.dart';
import '../../../core/utils/property_listing_image_assigner.dart';
import '../../../core/utils/property_remote_rent.dart';
import '../../../data/local/db/property_listing_units_sync.dart';
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
import '../../../data/local/deleted_properties_store.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/local/service/offline_sync_worker_service.dart';
import '../../add_listing/models/apartment_unit_draft.dart';
import '../../../data/local/service/lease_income_extension.dart';
import '../../../core/utils/property_financial_time_series.dart';
import '../../../core/utils/property_listing_finance_scope.dart';
import '../../../data/model/general_response.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';
import '../../my_properties/controllers/my_properties_controller.dart';
import '../../all_tenants/controllers/all_tenants_controller.dart';
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

  String _formatRentLabel(String raw, {String currency = ''}) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', ''));
    if (parsed == null) return raw.trim();
    final cs = Get.find<CurrencyService>();
    final cur = currency.trim().toUpperCase();
    final base = cs.baseCurrency.value.trim().toUpperCase();
    if (cur.isNotEmpty && cur != base) {
      final rate = cs.sellingRateFor(cur);
      if (rate != null && rate > 0) {
        final converted =
            cs.toBaseAmount(inputAmount: parsed, inputCurrency: cur);
        return '≈ ${cs.formatBase(converted.round())}';
      }
      // FX rate not ready — show contract currency, never mislabel as base.
      final n = NumberFormat('#,###', 'en_US').format(parsed.round());
      return '$cur $n';
    }
    return cs.formatBase(parsed.round());
  }

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
    await Get.find<ListingDetailsController>().loadListingDetail();
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
  /// Remote activity is only used when this listing has no local rows yet.
  Future<List<ListingActivityVm>> _resolveRecentActivity(
      Map<String, dynamic>? remoteListing,
      ) async {
    final local = await _loadActivityFromLocal();
    if (local.isNotEmpty) return local;
    if (remoteListing == null) return const [];
    // New / unmatched listings often get empty remote payloads — never fall
    // through to another listing's activity via a loose local filter.
    return _activityFromAnyMap(remoteListing);
  }

  Future<void> loadListingDetail() async {
    loadingListing.value = true;
    try {
      Map<String, dynamic>? remoteListing;
      if (_propertyId.isNotEmpty) {
        remoteListing = await _fetchListingMapFromRepository(_propertyId);
      }

      // FX rates must be ready before unit rent labels / expected income convert.
      await _ensureCurrencyRatesLoaded();
      await LeaseIncomeExtension.applyMissed();

      // Priority: local units + tenants (immediate after add/delete) -> remote -> empty.
      var realRows = await _loadUnitRowsFromLocal();
      if (realRows.isEmpty && remoteListing != null) {
        realRows = _unitRowsFromAnyMap(remoteListing);
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

      recentActivity.assignAll(await _resolveRecentActivity(remoteListing));

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

  Future<void> _ensureCurrencyRatesLoaded() async {
    if (!Get.isRegistered<CurrencyService>()) return;
    final cs = Get.find<CurrencyService>();
    if (cs.rates.length <= 1 || cs.sellingRateFor('USD') == null) {
      await CurrencyService.refreshIfRegistered();
    }
    if (cs.sellingRateFor('USD') == null) {
      try {
        await cs.refreshRatesFromRemote();
      } catch (_) {}
    }
  }

  Future<void> _syncMonthlyRevenue(Map<String, dynamic>? remoteListing) async {
    await _ensureCurrencyRatesLoaded();
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

    final expected = await _expectedIncomeFromTenants(scopeRefs);

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

  String _formatRentInBase(double amount, String currency) {
    final cs = Get.find<CurrencyService>();
    final base = cs.baseCurrency.value.trim().toUpperCase();
    final cur = currency.trim().toUpperCase();
    if (cur.isNotEmpty && cur != base) {
      final converted = cs.toBaseAmount(inputAmount: amount, inputCurrency: cur);
      if (converted > 0 && (converted - amount).abs() > 0.0001) {
        return '≈ ${cs.formatBase(converted.round())}';
      }
    }
    return cs.formatBase(amount.round());
  }

  /// This property's expected income for the current month. BnB units use the
  /// nightly rate in base currency times the days in the month. Rent tenants
  /// use this month's contract rent.
  Future<double> _expectedIncomeFromTenants(Set<String> scopeRefs) async {
    try {
      await _ensureCurrencyRatesLoaded();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);
      final currencyService = Get.find<CurrencyService>();
      final byId = <int, TenantRecord>{};
      for (final ref in scopeRefs) {
        for (final tenant in await _tenantLocal.listByPropertyRef(ref)) {
          byId[tenant.id] = tenant;
        }
      }

      final property = await _findLocalPropertyRowForListing();
      final days = ExpectedMonthRent.daysInMonth(monthStart);
      final bnbUnits = property == null
          ? const <BnbUnitRate>[]
          : ExpectedMonthRent.bnbUnitsOf(property, daysInMonth: days);
      final coverAll = property != null &&
          bnbUnits.isNotEmpty &&
          ExpectedMonthRent.bnbUnitsCoverAllTenants(property);
      var total = 0.0;
      final coveredTenantIds = <int>{};
      for (final unit in bnbUnits) {
        var nightly = unit.nightlyAmount;
        var currency = unit.currency;
        for (final tenant in byId.values) {
          if (property != null &&
              !ExpectedMonthRent.tenantOnProperty(tenant, property)) {
            continue;
          }
          final onThisUnit = unit.matchesTenant(tenant) ||
              (bnbUnits.length == 1 && unit.unitId == 'main');
          if (onThisUnit || coverAll) coveredTenantIds.add(tenant.id);
          if (!onThisUnit || nightly > 0 || tenant.rentAmountValue <= 0) {
            continue;
          }
          nightly = ExpectedMonthRent.nightlyFrom(
                tenant.rentAmountValue,
                tenant.rentFrequency,
                days,
              ) ??
              tenant.rentAmountValue;
          currency = tenant.rentCurrency;
        }
        if (nightly <= 0) continue;
        final nightlyBase = currencyService.toBaseAmount(
          inputAmount: nightly,
          inputCurrency: currency.trim().isEmpty
              ? currencyService.baseCurrency.value
              : currency,
        );
        total += nightlyBase * days;
      }
      for (final tenant in byId.values) {
        if (coveredTenantIds.contains(tenant.id)) continue;
        var amount = ExpectedMonthRent.of(
          tenant,
          monthStart: monthStart,
          nextMonthStart: nextMonthStart,
        );
        if (amount <= 0 && property != null) {
          amount = _unitRentOnProperty(tenant, property);
        }
        final tenantCurrency = tenant.rentCurrency.trim().toUpperCase();
        total += currencyService.toBaseAmount(
          inputAmount: amount,
          inputCurrency: tenantCurrency.isEmpty
              ? currencyService.baseCurrency.value
              : tenantCurrency,
        );
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  double _unitRentOnProperty(TenantRecord tenant, PropertyRecord property) {
    final raw = property.unitsJson.trim();
    if (raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return 0;
      for (final entry in decoded.whereType<Map>()) {
        final unitId = (entry['unitId'] ?? entry['id'] ?? '').toString().trim();
        final unitName =
            (entry['unitName'] ?? entry['name'] ?? '').toString().trim();
        final tenantUnitId = tenant.apartmentUnitId.trim();
        final tenantUnitName = tenant.unitLabel.trim();
        final idMatches = tenantUnitId.isNotEmpty &&
            unitId.isNotEmpty &&
            tenantUnitId == unitId;
        final nameMatches = tenantUnitName.isNotEmpty &&
            unitName.isNotEmpty &&
            tenantUnitName.toLowerCase() == unitName.toLowerCase();
        if (!idMatches && !nameMatches) continue;
        final rent = double.tryParse(
          (entry['unitRent'] ?? entry['rent'] ?? '')
              .toString()
              .replaceAll(',', '')
              .trim(),
        );
        if (rent != null && rent > 0) return rent;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _syncOccupancyPercent(
    Map<String, dynamic>? remoteListing,
  ) async {
    final totalUnits = unitRows.length;
    if (totalUnits <= 0) {
      occupancyPercent.value = 0;
      return;
    }

    // Local DB is source of truth after add/delete tenant (remote lags).
    var tenantsCount = await _extractTenantCountFromLocal();
    if (tenantsCount <= 0 && remoteListing != null) {
      tenantsCount = _extractTenantCountFromRemote(remoteListing);
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
    if (_propertyId.isNotEmpty) {
      // Trust ref-based count even when 0 (e.g. just deleted last tenant).
      return _tenantLocal.countByPropertyRef(_propertyId);
    }

    final tenants = await _tenantLocal.getAllNewestFirst();
    if (tenants.isEmpty) return 0;

    bool matchesListing(TenantRecord t) {
      final ref = t.propertyRef.trim();
      if (_propertyId.isNotEmpty && ref.isNotEmpty && ref == _propertyId) {
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
      final res = await _repository.getProperty(listingId);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      if (data is Map && data['property'] is Map<String, dynamic>) {
        return data['property'] as Map<String, dynamic>;
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
    // Local staff rows are account-scoped (no property_ref). Never attach the
    // whole roster to a single listing — especially a brand-new empty one.
    return const [];
  }

  Future<List<ListingActivityVm>> _loadActivityFromLocal() async {
    final scopeRefs = await _listingPropertyRefsForActivity();
    // Without a property identity we cannot safely attribute any local rows.
    if (scopeRefs.isEmpty &&
        _propertyName.trim().isEmpty &&
        _propertyLocation.trim().isEmpty) {
      return const [];
    }

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
            unitPropertyUnitRef: u.propertyUnitRef.trim().isEmpty
                ? null
                : u.propertyUnitRef.trim(),
          ),
        ));
      }
    } catch (_) {}

    // Do not synthesize "unit added" rows from unitsJson — those are created
    // with the property itself and look like prior activity on a new listing.

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

    // Staff is account-scoped in local DB — omit from per-property activity.

    final incomes = <IncomeRecord>[];
    final expenses = <ExpenseRecord>[];
    for (final ws in financeWorkspaceTypes) {
      incomes.addAll(await _incomeLocal.getAllNewestFirst(workspaceType: ws));
      expenses.addAll(await _expenseLocal.getAllNewestFirst(workspaceType: ws));
    }

    for (final i in incomes) {
      if (!_financeRowMatchesListing(
        scopeRefs: scopeRefs,
        propertyRef: i.propertyRef,
        apartment: i.apartment,
        apartmentUnit: i.apartmentUnit,
        notes: i.notes,
      )) {
        continue;
      }
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
      if (!_financeRowMatchesListing(
        scopeRefs: scopeRefs,
        propertyRef: '',
        apartment: e.apartment,
        apartmentUnit: e.apartmentUnit,
        notes: e.notes,
      )) {
        continue;
      }
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

  /// True when a finance row belongs to this listing (never "match all").
  bool _financeRowMatchesListing({
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
    final name = _propertyName.trim().toLowerCase();
    final loc = _propertyLocation.trim().toLowerCase();
    if (name.isEmpty && loc.isEmpty) return false;

    final apt = apartment.trim().toLowerCase();
    final unit = apartmentUnit.trim().toLowerCase();
    final notesLc = notes.trim().toLowerCase();

    if (name.isNotEmpty && (apt == name || unit == name)) return true;
    if (loc.isNotEmpty && (apt == loc || unit == loc)) return true;

    // Containment only for reasonably specific names (avoids short false hits).
    if (name.length >= 4 &&
        (apt.contains(name) || unit.contains(name) || notesLc.contains(name))) {
      return true;
    }
    if (loc.length >= 4 &&
        (apt.contains(loc) || unit.contains(loc) || notesLc.contains(loc))) {
      return true;
    }
    return false;
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
    final nameLc = _propertyName.trim().toLowerCase();
    final locLc = _propertyLocation.trim().toLowerCase();
    // Exact label match only — substring matching pulls in other properties.
    if (nameLc.isNotEmpty && label == nameLc) return true;
    if (locLc.isNotEmpty && label == locLc) return true;
    return false;
  }

  bool _unitMatchesListing(PropertyUnitRecord r, Set<String> scopeRefs) {
    if (scopeRefs.isEmpty) return false;
    final ref = r.propertyRef.trim();
    return ref.isNotEmpty && scopeRefs.contains(ref);
  }

  bool _tenantMatchesListingForActivity(TenantRecord r, Set<String> scopeRefs) {
    final ref = r.propertyRef.trim();
    if (ref.isNotEmpty && scopeRefs.contains(ref)) return true;
    final label = r.propertyLabel.trim().toLowerCase();
    if (label.isEmpty) return false;
    final nameLc = _propertyName.trim().toLowerCase();
    final locLc = _propertyLocation.trim().toLowerCase();
    if (nameLc.isNotEmpty && label == nameLc) return true;
    if (locLc.isNotEmpty && label == locLc) return true;
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

  /// Resolves BnB vs Rent for a unit row from JSON + frequency fallback.
  String _resolveUnitOperationMode(Map<String, dynamic> m) {
    final raw = (m['operationMode'] ?? '').toString().trim().toLowerCase();
    if (raw == 'rent' || raw == 'bnb') return raw;
    final freq = (m['unitRentFrequency'] ?? '').toString().trim().toLowerCase();
    if (freq.contains('day') ||
        freq.contains('night') ||
        freq.contains('stay')) {
      return 'bnb';
    }
    if (freq.contains('month') ||
        freq.contains('week') ||
        freq.contains('year') ||
        freq.contains('quarter')) {
      return 'rent';
    }
    return 'bnb';
  }

  Future<List<ListingUnitRowVm>> _loadUnitRowsFromLocal() async {
    try {
      await _ensureCurrencyRatesLoaded();
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
        (r) =>
            _propertyName.isNotEmpty &&
            r.apartmentSuite.trim() == _propertyName,
      );
      target ??= rows.firstWhereOrNull(
        (r) =>
            _propertyName.isNotEmpty &&
            r.propertyLocation.trim() == _propertyName,
      );
      if (target == null) return const [];
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
        if (ref.isNotEmpty) {
          if (ref == listingRef) return true;
          if (ref == 'local_${target?.id}' || ref == 'legacy_${target?.id}') {
            return true;
          }
          final hub = target?.propertyRef.trim();
          if (hub != null && hub.isNotEmpty && ref == hub) return true;
        }
        final label = t.propertyLabel.trim().toLowerCase();
        if (listingName.isNotEmpty && label == listingName.toLowerCase()) {
          return true;
        }
        if (listingLoc.isNotEmpty && label == listingLoc.toLowerCase()) {
          return true;
        }
        if (listingName.isNotEmpty &&
            listingLoc.isNotEmpty &&
            (label == '${listingName.toLowerCase()} · ${listingLoc.toLowerCase()}' ||
                label ==
                    '${listingLoc.toLowerCase()} · ${listingName.toLowerCase()}')) {
          return true;
        }
        return false;
      }

      final listingTenants = tenants.where(tenantMatchesListing).toList();

      // Local property_units can hold currency when unitsJson is stale/missing it.
      final localUnitCurrencyByKey = <String, String>{};
      try {
        final refs = <String>{
          listingRef,
          'local_${target.id}',
          'legacy_${target.id}',
          if (target.propertyRef.trim().isNotEmpty) target.propertyRef.trim(),
        };
        for (final ref in refs) {
          final unitRows = await _unitLocal.getAllByPropertyRefNewestFirstChunked(
            propertyRef: ref,
          );
          for (final u in unitRows) {
            final cur = u.rentCurrency.trim().toUpperCase();
            if (cur.isEmpty) continue;
            final idKey = u.propertyUnitRef.trim().toLowerCase();
            final nameKey = u.unitName.trim().toLowerCase();
            if (idKey.isNotEmpty) localUnitCurrencyByKey['id:$idKey'] = cur;
            if (nameKey.isNotEmpty) localUnitCurrencyByKey['name:$nameKey'] = cur;
          }
        }
      } catch (_) {}

      String resolveUnitCurrency(Map<String, dynamic> m) {
        final fromJson = (m['unitRentCurrency'] ??
                m['rentCurrency'] ??
                m['currency'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();
        if (fromJson.isNotEmpty && fromJson != 'TZS') return fromJson;
        final unitId = (m['unitId'] ?? m['id'] ?? '').toString().trim().toLowerCase();
        final unitName = (m['unitName'] ?? m['name'] ?? '').toString().trim().toLowerCase();
        final fromLocal = (unitId.isNotEmpty
                ? localUnitCurrencyByKey['id:$unitId']
                : null) ??
            (unitName.isNotEmpty ? localUnitCurrencyByKey['name:$unitName'] : null);
        if (fromLocal != null && fromLocal.isNotEmpty) return fromLocal;
        return fromJson.isNotEmpty ? fromJson : '';
      }

      final unitsRaw = target.unitsJson.trim();
      if (unitsRaw.isEmpty) {
        // Prefer structured property_units rows (survive remote sync that
        // clears unitsJson) over a synthetic single placeholder.
        final fromUnitTable = await _unitRowsFromPropertyUnitsTable(
          listingRefs: <String>{
            listingRef,
            'local_${target.id}',
            'legacy_${target.id}',
            if (target.propertyRef.trim().isNotEmpty) target.propertyRef.trim(),
          },
          listingTenants: listingTenants,
        );
        if (fromUnitTable.isNotEmpty) return fromUnitTable;

        final attachedTenant =
            listingTenants.isEmpty ? null : listingTenants.first;
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
        final rentCurrency = resolveUnitCurrency(m);
        final mode = _resolveUnitOperationMode(m);
        out.add(
          ListingUnitRowVm(
            name: unitName,
            subtitle: rent.isEmpty
                ? (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant')
                : 'Rent ${_formatRentLabel(rent, currency: rentCurrency)}',
            status: attachedTenant == null
                ? ListingUnitStatus.short
                : ListingUnitStatus.occupied,
            tenantName: attachedTenant?.tenantName ?? '',
            tenantId: attachedTenant?.id,
            unitId: unitId,
            operationMode: mode,
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Builds unit rows from the local `property_units` table when unitsJson is empty.
  Future<List<ListingUnitRowVm>> _unitRowsFromPropertyUnitsTable({
    required Set<String> listingRefs,
    required List<TenantRecord> listingTenants,
  }) async {
    final seen = <String>{};
    final records = <PropertyUnitRecord>[];
    for (final ref in listingRefs) {
      if (ref.trim().isEmpty) continue;
      final rows = await _unitLocal.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
      );
      for (final u in rows) {
        final key = u.propertyUnitRef.trim().isNotEmpty
            ? 'id:${u.propertyUnitRef.trim().toLowerCase()}'
            : 'name:${u.unitName.trim().toLowerCase()}';
        if (key == 'id:' || key == 'name:') continue;
        if (!seen.add(key)) continue;
        records.add(u);
      }
    }
    if (records.isEmpty) return const [];

    final out = <ListingUnitRowVm>[];
    for (final u in records) {
      final unitName = u.unitName.trim();
      if (unitName.isEmpty) continue;
      final unitId = u.propertyUnitRef.trim();
      TenantRecord? attachedTenant;
      for (final t in listingTenants) {
        final tid = t.apartmentUnitId.trim();
        final tName = t.unitLabel.trim();
        if (unitId.isNotEmpty && tid.isNotEmpty && tid == unitId) {
          attachedTenant = t;
          break;
        }
        if (tName.isNotEmpty && tName.toLowerCase() == unitName.toLowerCase()) {
          attachedTenant = t;
          break;
        }
      }
      final rent = u.rentAmount > 0 ? u.rentAmount.toString() : '';
      final mode = u.operationMode.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb';
      out.add(
        ListingUnitRowVm(
          name: unitName,
          subtitle: rent.isEmpty
              ? (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant')
              : 'Rent ${_formatRentLabel(rent, currency: u.rentCurrency)}',
          status: attachedTenant == null
              ? ListingUnitStatus.short
              : ListingUnitStatus.occupied,
          tenantName: attachedTenant?.tenantName ?? '',
          tenantId: attachedTenant?.id,
          unitId: unitId,
          operationMode: mode,
        ),
      );
    }
    return out;
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
      final rentCurrency = (m['unitRentCurrency'] ??
              m['rentCurrency'] ??
              m['currency'] ??
              '')
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
              ? 'Rent ${_formatRentLabel(rent, currency: rentCurrency)}'
              : (_isSw ? 'Inasubiri mpangaji' : 'Awaiting tenant'),
          status: status,
          tenantName: tenantName,
          unitId: (m['unitId'] ?? m['id'] ?? '').toString().trim(),
          operationMode: _resolveUnitOperationMode(m),
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
      final balance = Get.find<CurrencyService>().formatBase(r.balanceTsh);
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

  Future<String> _resolvePropertyRefForFinanceTools() async {
    var ref = _propertyId.trim();
    if (ref.isNotEmpty) return ref;
    final row = await _findLocalPropertyRowForListing();
    if (row == null) return '';
    return row.propertyRef.trim().isNotEmpty
        ? row.propertyRef.trim()
        : 'local_${row.id}';
  }

  /// Property ROI Analysis (principal vs income charts) for this listing.
  Future<void> onOpenPropertyRoiAnalysis() async {
    final ref = await _resolvePropertyRefForFinanceTools();
    if (ref.isEmpty) {
      showErrorMessage(
        _isSw
            ? 'Hakuna kitambulisho cha mali kwa uchambuzi wa ROI.'
            : 'No property reference is available for ROI analysis.',
      );
      return;
    }
    await Get.toNamed(
      Routes.RENT_PROPERTY_ROI_ANALYSIS,
      parameters: {
        'propertyRef': ref,
        'propertyLabel': _propertyLabelForEstimate(),
      },
    );
    await loadListingDetail();
  }

  /// Tenancy Insights scoped to this listing (rent tenants, exports, charts).
  Future<void> onOpenTenancyInsights() async {
    final ref = await _resolvePropertyRefForFinanceTools();
    final title = _propertyLabelForEstimate();
    await Get.toNamed(
      Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER,
      parameters: {
        'ws': 'rent',
        if (ref.isNotEmpty) 'propertyRef': ref,
        if (title.isNotEmpty) 'propertyTitle': title,
        if (_propertyLocation.isNotEmpty) 'propertyLoc': _propertyLocation,
        if (_propertyName.isNotEmpty) 'propertySuite': _propertyName,
      },
      arguments: {
        'ws': 'rent',
        if (ref.isNotEmpty) 'propertyRef': ref,
        if (title.isNotEmpty) 'propertyTitle': title,
        if (_propertyLocation.isNotEmpty) 'propertyLoc': _propertyLocation,
        if (_propertyName.isNotEmpty) 'propertySuite': _propertyName,
      },
    );
    await loadListingDetail();
  }

  /// Define tenant charges for this listing.
  Future<void> onOpenTenantCharges() async {
    final ref = await _resolvePropertyRefForFinanceTools();
    final title = _propertyLabelForEstimate();
    await Get.toNamed(
      Routes.RENT_DEFINE_TENANT_CHARGES,
      parameters: {
        if (ref.isNotEmpty) 'propertyRef': ref,
        if (title.isNotEmpty) 'propertyLabel': title,
        if (title.isNotEmpty) 'propertyTitle': title,
      },
      arguments: {
        if (ref.isNotEmpty) 'propertyRef': ref,
        if (title.isNotEmpty) 'propertyLabel': title,
        if (title.isNotEmpty) 'propertyTitle': title,
      },
    );
    await loadListingDetail();
  }

  /// Apartment rent / service charge PDF reports for this listing.
  Future<void> onOpenApartmentReports() async {
    final ref = await _resolvePropertyRefForFinanceTools();
    final title = _propertyLabelForEstimate();
    await Get.toNamed(
      Routes.RENT_APARTMENT_REPORTS,
      parameters: {
        if (ref.isNotEmpty) 'propertyRef': ref,
        if (title.isNotEmpty) 'propertyTitle': title,
        if (title.isNotEmpty) 'propertyLabel': title,
      },
      arguments: {
        if (ref.isNotEmpty) 'propertyRef': ref,
        if (title.isNotEmpty) 'propertyTitle': title,
        if (title.isNotEmpty) 'propertyLabel': title,
      },
    );
  }

  Future<void> onAddPropertyEstimationCosts() async {
    final ref = await _resolvePropertyRefForFinanceTools();
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
        if (_propertyName.isNotEmpty) 'propertyName': _propertyName,
        if (_propertyLocation.isNotEmpty) 'propertyLocation': _propertyLocation,
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
    var propertyHubId = _propertyId.trim();
    final local = await _findLocalPropertyRowForListing();
    if (local != null) {
      final stored = local.propertyRef.trim();
      propertyHubId = stored.isNotEmpty ? stored : 'local_${local.id}';
    }

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
    // Route `property_id` may be a remote listing id that does not equal the
    // local `property_ref`. Resolve the on-device row the same way the rest of
    // listing details does (ref / local_ / name).
    var propertyRef = _propertyId.trim();
    int? propertyLocalId;
    final local = await _findLocalPropertyRowForListing();
    if (local != null) {
      propertyLocalId = local.id;
      final stored = local.propertyRef.trim();
      propertyRef = stored.isNotEmpty ? stored : 'local_${local.id}';
    }
    if (propertyRef.isEmpty && propertyLocalId == null) {
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
        if (propertyRef.isNotEmpty) 'property_ref': propertyRef,
        if (propertyLocalId != null) 'property_local_id': propertyLocalId,
        if (_propertyId.trim().isNotEmpty) 'listing_id': _propertyId.trim(),
        'unit_name': row.name,
        if (row.unitId.trim().isNotEmpty) 'unit_id': row.unitId.trim(),
      },
    );
    await loadListingDetail();
  }

  Future<void> onDeleteUnit(ListingUnitRowVm row) async {
    final occupied = row.tenantName.trim().isNotEmpty;
    final confirmed = await confirmDestructive(
      title: _isSw ? 'Futa unit?' : 'Delete unit?',
      message: occupied
          ? (_isSw
              ? 'Unit "${row.name}" itafutwa. Rekodi ya mpangaji ${row.tenantName} itabaki.'
              : '"${row.name}" will be removed. ${row.tenantName}\'s tenant record will stay.')
          : (_isSw
              ? 'Unit "${row.name}" itafutwa kwenye mali hii.'
              : '"${row.name}" will be removed from this property.'),
      confirmLabel: _isSw ? 'Futa' : 'Delete',
      cancelLabel: _isSw ? 'Ghairi' : 'Cancel',
    );
    if (!confirmed) return;
    final removed = await _removeUnitFromProperty(
      unitId: row.unitId,
      unitName: row.name,
    );
    if (!removed) return;
    showSuccessWithHaptic(_isSw ? 'Unit imefutwa' : 'Unit deleted');
    await loadListingDetail();
    unawaited(MyPropertiesController.refreshIfRegistered());
    unawaited(HomeController.refreshIfRegistered());
  }

  /// Removes one unit from `units_json` and `property_units`, then updates the
  /// remote property. An empty `units_json` string is a missing list and would
  /// show a placeholder unit again, so a property with no units stores `[]`.
  Future<bool> _removeUnitFromProperty({
    required String unitId,
    required String unitName,
    int? localRowId,
  }) async {
    final property = await _findLocalPropertyRowForListing();
    if (property == null) {
      showErrorMessage(
        _isSw
            ? 'Hakuna mali iliyohifadhiwa kwenye kifaa hiki.'
            : 'No on-device property record found.',
      );
      return false;
    }

    var id = unitId.trim();
    var name = unitName.trim();
    if (localRowId != null && (id.isEmpty || name.isEmpty)) {
      final row = await _unitLocal.getById(localRowId);
      if (row != null) {
        if (id.isEmpty) id = row.propertyUnitRef.trim();
        if (name.isEmpty) name = row.unitName.trim();
      }
    }

    final ref = property.propertyRef.trim().isNotEmpty
        ? property.propertyRef.trim()
        : 'local_${property.id}';
    final aliases = <String>{
      ref,
      'local_${property.id}',
      'legacy_${property.id}',
      if (property.propertyRef.trim().isNotEmpty) property.propertyRef.trim(),
    };

    var drafts = _draftsFromUnitsJson(property.unitsJson);
    if (drafts.isEmpty) {
      drafts = await _draftsFromUnitTable(aliases);
    }
    var remaining = drafts
        .where((d) => !_draftIsUnit(d, unitId: id, unitName: name))
        .toList();
    if (remaining.length == drafts.length) {
      if (localRowId == null) {
        showErrorMessage(
          _isSw
              ? 'Unit hii haijahifadhiwa kama kitengo tofauti.'
              : 'This unit is not stored as a separate unit.',
        );
        return false;
      }
      await _unitLocal.deleteById(localRowId);
      remaining = await _draftsFromUnitTable(aliases);
    }

    final unitsJson = jsonEncode(remaining.map((d) => d.toJson()).toList());
    final listingRent = remaining.length == 1
        ? remaining.first.unitRent
        : property.rentAmount;
    final rentAmount = remaining.isEmpty
        ? ''
        : PropertyRemoteRent.amount(
            unitCount: remaining.length,
            listingRentAmount: listingRent,
            unitsJson: unitsJson,
          );
    final rentFrequency = remaining.isEmpty
        ? property.rentFrequency
        : PropertyRemoteRent.frequency(
            unitCount: remaining.length,
            listingRentFrequency: remaining.length == 1
                ? remaining.first.unitRentFrequency
                : property.rentFrequency,
            unitsJson: unitsJson,
            rentAmount: rentAmount,
          );
    final updated = property.copyWith(
      units: remaining.length,
      unitsJson: unitsJson,
      rentAmount: rentAmount,
      rentFrequency: rentFrequency,
    );
    await _propertyLocal.update(updated);

    for (final alias in aliases) {
      if (alias != ref) {
        await _unitLocal.deleteByPropertyRef(alias);
      }
    }
    await syncPropertyUnitsForListingSave(
      unitLocal: _unitLocal,
      propertyRef: ref,
      isApartment: true,
      apartmentUnitMaps: remaining.map((d) => d.toJson()).toList(),
      minRentalDuration: property.minRentalDuration,
      listingRentFrequency: rentFrequency,
      listingRentRaw: rentAmount,
      singleUnitName: property.propertyName,
      rooms: 0,
      maxGuests: 0,
      listingMode: property.workspaceType,
    );
    unawaited(_pushUnitsToRemote(updated, deletedUnitId: id));
    return true;
  }

  List<ApartmentUnitDraft> _draftsFromUnitsJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => ApartmentUnitDraft.fromJson(Map<String, dynamic>.from(m)))
          .where((d) => d.unitName.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ApartmentUnitDraft>> _draftsFromUnitTable(Set<String> refs) async {
    final seen = <String>{};
    final out = <ApartmentUnitDraft>[];
    for (final ref in refs) {
      if (ref.trim().isEmpty) continue;
      final rows = await _unitLocal.getAllByPropertyRefNewestFirstChunked(
        propertyRef: ref,
      );
      for (final u in rows) {
        final key = u.propertyUnitRef.trim().isNotEmpty
            ? 'id:${u.propertyUnitRef.trim().toLowerCase()}'
            : 'name:${u.unitName.trim().toLowerCase()}';
        if (key == 'id:' || key == 'name:' || !seen.add(key)) continue;
        if (u.unitName.trim().isEmpty) continue;
        out.add(
          ApartmentUnitDraft(
            unitId: u.propertyUnitRef,
            unitName: u.unitName,
            unitRent: u.rentAmount > 0
                ? u.rentAmount.toString()
                : '',
            unitRentFrequency: u.rentFrequency,
            unitFloor: u.floor,
            operationMode: u.operationMode,
            unitDescription: u.notes,
            unitRentCurrency: u.rentCurrency,
          ),
        );
      }
    }
    return out;
  }

  bool _draftIsUnit(
    ApartmentUnitDraft draft, {
    required String unitId,
    required String unitName,
  }) {
    final id = draft.unitId.trim();
    if (unitId.isNotEmpty) return id.isNotEmpty && id == unitId;
    final name = draft.unitName.trim().toLowerCase();
    final wanted = unitName.trim().toLowerCase();
    return wanted.isNotEmpty && name == wanted;
  }

  Future<void> _pushUnitsToRemote(
    PropertyRecord property, {
    String deletedUnitId = '',
  }) async {
    final ref = property.propertyRef.trim();
    if (ref.isEmpty) return;
    final unitKey = deletedUnitId.trim();
    if (unitKey.isNotEmpty) {
      try {
        await _repository.deletePropertyUnit(ref, unitKey);
      } catch (_) {}
    }
    final payload = <String, dynamic>{
      'property_ref': ref,
      'location': property.propertyLocation,
      'name': property.propertyName,
      'type': property.propertyType,
      'units': property.units,
      'tenants': property.tenants,
      'workspace_type': property.workspaceType,
      'rent_amount': property.rentAmount,
      'rent_frequency': property.rentFrequency,
      'min_rental_duration': property.minRentalDuration,
      'units_json': property.unitsJson,
      'floor_count': property.floorCount,
      'cover_photo_path': property.coverPhotoPath,
    };
    try {
      final res = await _repository.updatePropertyByRef(ref, payload);
      final ok = res.responseCode == '0' ||
          res.responseCode == '200' ||
          res.responseCode == '201' ||
          (res.responseCode ?? '').trim().isEmpty;
      if (!ok) throw Exception(res.message ?? 'updatePropertyByRef failed');
    } catch (_) {
      try {
        await _syncQueue.enqueue(
          entityType: 'property',
          operation: 'update',
          payloadJson: jsonEncode(payload),
          dedupeKey: 'property:update:$ref',
        );
        if (Get.isRegistered<OfflineSyncWorkerService>()) {
          await Get.find<OfflineSyncWorkerService>().runNow(maxItems: 5);
        }
      } catch (_) {}
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
        final listIds = <String>{
          if (_propertyId.isNotEmpty) _propertyId,
          if (row.propertyRef.trim().isNotEmpty) row.propertyRef.trim(),
          'local_${row.id}',
          'legacy_${row.id}',
        };
        await DeletedPropertiesStore().markDeleted(listIds);
        await _purgeLocalPropertyRelations(row);
        await _propertyLocal.deleteById(row.id);
        // Drop from the open My Properties list immediately (don't wait for reload).
        MyPropertiesController.removeIfRegistered(listIds);
        unawaited(_bestEffortRemotePropertyDelete(listIds));
        Get.back(result: true);
        showSuccessWithHaptic(_isSw ? 'Mali imefutwa' : 'Property removed');
        unawaited(MyPropertiesController.refreshIfRegistered());
        unawaited(HomeController.refreshIfRegistered());
      } catch (e, st) {
        logger.e('onDeleteProperty $e $st');
        showErrorMessage(
          _isSw ? 'Imeshindwa kufuta mali.' : 'Could not delete property.',
        );
      }
    });
  }

  /// Best-effort server delete so sync does not resurrect the property.
  Future<void> _bestEffortRemotePropertyDelete(Set<String> refs) async {
    try {
      final res = await _repository.getMyProperties();
      final data = res.data;
      List<dynamic> rows = const [];
      if (data is Map && data['properties'] is List) {
        rows = data['properties'] as List;
      } else if (data is List) {
        rows = data;
      }
      for (final raw in rows.whereType<Map>()) {
        final map = Map<String, dynamic>.from(raw);
        final ref = (map['property_ref'] ??
                map['propertyRef'] ??
                map['id'] ??
                '')
            .toString()
            .trim();
        if (ref.isEmpty || !refs.contains(ref)) continue;
        final remoteId = int.tryParse((map['id'] ?? '').toString());
        if (remoteId == null) continue;
        try {
          await _repository.deleteProperty(remoteId);
        } catch (_) {}
      }
    } catch (_) {
      // Offline / API error — tombstone keeps it hidden until next successful delete.
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
          parameters: {
            'id': id.toString(),
            'name': activity.subtitle,
            if (_propertyName.isNotEmpty) 'property': _propertyName,
            'ws': _workspaceParamForMode(propertyWorkspaceMode.value),
            if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
            if (_propertyName.isNotEmpty) 'propertyTitle': _propertyName,
            if (_propertyLocation.isNotEmpty) 'propertyLoc': _propertyLocation,
          },
          arguments: {
            'ws': _workspaceParamForMode(propertyWorkspaceMode.value),
          },
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
        final ref = (activity.unitLocalPropertyRef ?? _propertyId).trim();
        final name = (activity.unitLocalName ?? '').trim();
        final unitId = (activity.unitPropertyUnitRef ?? '').trim();
        if (ref.isEmpty && activity.unitLocalId == null) {
          showErrorMessage(
            _isSw
                ? 'Hakuna kitambulisho cha mali kuhariri unit hii.'
                : 'No property reference is available to edit this unit.',
          );
          return;
        }
        await Get.toNamed(
          Routes.EDIT_UNIT,
          arguments: {
            if (ref.isNotEmpty) 'property_ref': ref,
            if (_propertyId.trim().isNotEmpty) 'listing_id': _propertyId.trim(),
            if (name.isNotEmpty) 'unit_name': name,
            if (unitId.isNotEmpty) 'unit_id': unitId,
            if (activity.unitLocalId != null)
              'unit_local_id': activity.unitLocalId,
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
        final staffId = activity.staffId!;
        final staffRec = await _staffLocal.getById(staffId);
        if (staffRec != null) {
          await RemovedStaffPhones.remember(staffRec.phone);
        }
        final backendStaffId = await _staffLocal.backendIdForLocal(staffId);
        await _staffLocal.deleteById(staffId);
        if (backendStaffId != null && backendStaffId.isNotEmpty) {
          unawaited(_remoteDeleteStaff(backendStaffId));
        }

      case ActivityType.unit:
        final removed = await _removeUnitFromProperty(
          unitId: activity.unitPropertyUnitRef ?? '',
          unitName: activity.unitLocalName ?? activity.subtitle,
          localRowId: activity.unitLocalId,
        );
        if (!removed) return;

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
    if (activity.activityType == ActivityType.tenant ||
        activity.activityType == ActivityType.unit) {
      unawaited(MyPropertiesController.refreshIfRegistered());
      unawaited(HomeController.refreshIfRegistered());
      if (activity.activityType == ActivityType.tenant) {
        unawaited(AllTenantsController.refreshIfRegistered());
      }
    }
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

  Future<void> _remoteDeleteStaff(String backendStaffId) async {
    await _tryOrQueue(
      remoteCall: () => _repository.deleteStaff(backendStaffId),
      entityType: 'staff',
      operation: 'delete',
      payload: {'id': backendStaffId},
      dedupeKey: 'staff:delete:$backendStaffId',
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

  /// True when every unit in [workspace] already has a tenant.
  bool allUnitsOccupiedFor(String workspace) {
    final rows = _workspaceParamForMode(workspace) == 'rent'
        ? rentUnitRows
        : bnbUnitRows;
    if (rows.isEmpty) return false;
    return rows.every((row) => row.status == ListingUnitStatus.occupied);
  }

  void _openAddTenant({
    String unitId = '',
    String unitName = '',
    String workspace = '',
    bool showAllUnits = false,
  }) {
    final ws = workspace.trim().toLowerCase();
    final explicitWorkspace = !showAllUnits && (ws == 'rent' || ws == 'bnb');
    Get.toNamed(
      Routes.ADD_NEW_TENANT,
      parameters: {
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        if (unitId.trim().isNotEmpty) 'unitId': unitId.trim(),
        if (unitName.trim().isNotEmpty) 'unitName': unitName.trim(),
      },
      arguments: {
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (unitId.trim().isNotEmpty) 'unitId': unitId.trim(),
        if (unitName.trim().isNotEmpty) 'unitName': unitName.trim(),
        // Quick Management is not a BnB or Rent tab, so both unit types stay
        // selectable even if an earlier screen left workspaceType as bnb.
        if (showAllUnits) 'showAllUnits': 'true',
        if (explicitWorkspace) 'workspaceType': ws,
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
        if (_propertyName.isNotEmpty) 'property': _propertyName,
        if (_propertyId.isNotEmpty) 'propertyRef': _propertyId,
        if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
      },
    )?.then((_) async {
      await loadListingDetail();
    });
  }

  void onPaymentFollowUpTap() {
    final banner = paymentFollowUp.value;
    Get.toNamed(
      Routes.RENT_RECURRING_REMINDERS,
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
        _openAddTenant(showAllUnits: true);
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
      case 6:
        onOpenTenancyInsights();
        break;
      case 7:
        onOpenPropertyRoiAnalysis();
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
        if (allUnitsOccupiedFor(workspace)) {
          _openAddTenant(
            unitId: row.unitId,
            unitName: row.name,
            workspace: workspace,
          );
          break;
        }
        showSuccessMessage(_isSw ? 'Angalia maelezo' : 'View details');
        break;
      case ListingUnitStatus.short:
        _openAddTenant(
          unitId: row.unitId,
          unitName: row.name,
          workspace: workspace,
        );
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
    _bindStaffPropertyContext();
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
    _bindStaffPropertyContext();
    if (Get.isRegistered<RentStaffManagementController>()) {
      await Get.find<RentStaffManagementController>().loadStaff();
    }
    if (Get.isRegistered<RentStaffPayrollDetailsController>()) {
      await Get.find<RentStaffPayrollDetailsController>().loadPayroll();
    }
    await _loadAssigneeStaffOptions();
  }

  void _bindStaffPropertyContext() {
    if (!Get.isRegistered<RentStaffManagementController>()) return;
    Get.find<RentStaffManagementController>().bindPropertyContext(
      propertyRef: _propertyId,
      propertyName: _propertyName,
    );
  }

  String primaryButtonLabel(ListingUnitRowVm row, bool isSw) {
    if (row.status == ListingUnitStatus.dueDate) {
      return isSw ? 'Tuma Ankara' : 'Send Invoice';
    }
    if (row.status == ListingUnitStatus.occupied) {
      final workspace =
          row.operationMode.trim().toLowerCase() == 'rent' ? 'rent' : 'bnb';
      if (allUnitsOccupiedFor(workspace)) {
        return isSw ? 'Ongeza Mpangaji' : 'Add Tenant';
      }
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
              fontWeight: FontWeight.w700,
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
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
