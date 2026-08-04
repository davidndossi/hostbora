import 'dart:async';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../../core/base/base_controller.dart';
import '../../../../core/constants/ui_preference_keys.dart';
import '../../../../core/utils/getx_instance_probe.dart';
import '../../../../core/utils/property_break_even_metrics.dart';
import '../../../../data/local/db/expense_local_data_source.dart';
import '../../../../data/local/db/income_local_data_source.dart';
import '../../../../data/local/db/rent_property_estimate_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/currency_service.dart';
import '../../../../data/local/service/local_notification_scheduler_service.dart';
import '../../../../routes/app_pages.dart';

/// Payment box state for M1…M6 ledger.
enum ResidencyMonthStatus { paid, partial, upcoming }

enum TenancyExcelTemplate { customerRentDetails, customerRentTenantSummary }

enum TenantReportFrequency { weekly, monthly }

enum TenantFinanceWindow { tenure, allTime }

class PropertyPrincipalSnapshot {
  const PropertyPrincipalSnapshot({
    required this.principalCost,
    required this.maintenanceCost,
    required this.incomeGenerated,
    required this.monthlyNet,
    required this.breakEvenLabel,
  });

  final double principalCost;
  final double maintenanceCost;
  final double incomeGenerated;
  final double monthlyNet;
  final String breakEvenLabel;

  bool get hasChartData => principalCost > 0 || maintenanceCost > 0;
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
    required this.leaseStart,
    required this.leaseEnd,
    required this.monthlyRent,
    required this.arrearsAmount,
    required this.isLeaseEndingSoon,
    required this.incomeForTenure,
    required this.expenseForTenure,
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
  final DateTime leaseStart;
  final DateTime leaseEnd;
  final double monthlyRent;
  final double arrearsAmount;
  final bool isLeaseEndingSoon;
  final double incomeForTenure;
  final double expenseForTenure;
}

class RentTenantResidencyPaymentTrackerController extends BaseController {
  RentTenantResidencyPaymentTrackerController()
    : _tenantLocal = Get.find<TenantLocalDataSource>(),
      _incomeLocal = Get.find<IncomeLocalDataSource>(),
      _expenseLocal = Get.find<ExpenseLocalDataSource>(),
      _estimateLocal = Get.find<RentPropertyEstimateLocalDataSource>(),
      _preferenceManager = Get.find<PreferenceManager>(
        tag: (PreferenceManager).toString(),
      ),
      _notificationScheduler = Get.find<LocalNotificationSchedulerService>();

  final TenantLocalDataSource _tenantLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final RentPropertyEstimateLocalDataSource _estimateLocal;
  final PreferenceManager _preferenceManager;
  final LocalNotificationSchedulerService _notificationScheduler;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final tenants = <TenantInsight>[].obs;

  /// Skeleton on first load when [tenants] is still empty.
  final tenantsInitialLoading = true.obs;
  final financeWindow = TenantFinanceWindow.tenure.obs;
  final selectedTenantIdsForCompare = <String>{}.obs;
  final expandedTenantCardIds = <String>{}.obs;
  final compareRangeStart = Rxn<DateTime>();
  final compareRangeEnd = Rxn<DateTime>();
  final whatsappScheduleEnabled = false.obs;
  final whatsappScheduleFrequency = TenantReportFrequency.weekly.obs;
  final whatsappScheduleTemplate = TenancyExcelTemplate.customerRentDetails.obs;
  final nextWhatsappScheduleAt = Rxn<DateTime>();
  final propertyPrincipal = Rxn<PropertyPrincipalSnapshot>();

  static const _waScheduleEnabledKey = 'tenant_report_wa_schedule_enabled';
  static const _waScheduleFrequencyKey = 'tenant_report_wa_schedule_frequency';
  static const _waScheduleTemplateKey = 'tenant_report_wa_schedule_template';
  static const _waScheduleNextMsKey = 'tenant_report_wa_schedule_next_ms';

  String _formatAmount(num amount) =>
      Get.find<CurrencyService>().formatBase(amount.round());
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  final _tenantRecordsById = <String, TenantRecord>{};
  List<IncomeRecord> _incomeRowsCache = const [];
  List<ExpenseRecord> _expenseRowsCache = const [];
  bool _routeContextCaptured = false;
  String _workspaceType = 'rent';
  String _filterPropertyRef = '';
  String _filterPropertyTitle = '';
  String _filterPropertyLoc = '';
  String _filterPropertySuite = '';

  int get activeLeasesCount => tenants.length;
  double get collectionRatePct {
    if (tenants.isEmpty) return 0;
    final onScheduleCount = tenants.where((e) => e.onSchedule).length;
    return (onScheduleCount * 100 / tenants.length);
  }

  @override
  void onReady() {
    super.onReady();
    _captureRouteContext();
    unawaited(
      _restoreFinanceWindow().then((_) async {
        await loadTenants();
        await _runDueWhatsappScheduleIfNeeded();
      }),
    );
    _loadWhatsappSchedule();
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

  List<TenantInsight> get comparedTenants => tenants
      .where((t) => selectedTenantIdsForCompare.contains(t.id))
      .toList(growable: false);

  String get financeWindowLabel =>
      financeWindow.value == TenantFinanceWindow.tenure ? 'Tenure' : 'All-time';

  String get compareRangeLabel {
    final s = compareRangeStart.value;
    final e = compareRangeEnd.value;
    if (s == null || e == null) return 'All dates';
    return '${_date.format(s)} - ${_date.format(e)}';
  }

  void toggleTenantForComparison(String tenantId) {
    if (selectedTenantIdsForCompare.contains(tenantId)) {
      selectedTenantIdsForCompare.remove(tenantId);
      return;
    }
    if (selectedTenantIdsForCompare.length >= 4) {
      showErrorMessage('Select up to 4 tenants for comparison.');
      return;
    }
    selectedTenantIdsForCompare.add(tenantId);
  }

  bool isTenantSelectedForComparison(String tenantId) {
    return selectedTenantIdsForCompare.contains(tenantId);
  }

  Future<void> _restoreFinanceWindow() async {
    final raw = await _preferenceManager.getString(
      UiPreferenceKeys.tenancyFinanceWindow,
    );
    if (raw == 'all_time') {
      financeWindow.value = TenantFinanceWindow.allTime;
    } else if (raw == 'tenure') {
      financeWindow.value = TenantFinanceWindow.tenure;
    }
  }

  Future<void> setFinanceWindow(TenantFinanceWindow window) async {
    if (financeWindow.value == window) return;
    financeWindow.value = window;
    await _preferenceManager.setString(
      UiPreferenceKeys.tenancyFinanceWindow,
      window == TenantFinanceWindow.allTime ? 'all_time' : 'tenure',
    );
    await loadTenants();
  }

  void clearCompareRange() {
    compareRangeStart.value = null;
    compareRangeEnd.value = null;
  }

  void setCompareRange({required DateTime start, required DateTime end}) {
    compareRangeStart.value = DateTime(start.year, start.month, start.day);
    compareRangeEnd.value = DateTime(end.year, end.month, end.day);
  }

  ({double income, double expense}) compareMetricForTenant(TenantInsight t) {
    final record = _tenantRecordsById[t.id];
    if (record == null) {
      return (income: t.incomeForTenure, expense: t.expenseForTenure);
    }
    final start = compareRangeStart.value;
    final end = compareRangeEnd.value;
    return (
      income: _sumIncomeForTenant(
        record,
        _incomeRowsCache,
        start: start,
        end: end,
      ),
      expense: _sumExpenseForTenant(
        tenant: record,
        expenseRows: _expenseRowsCache,
        leaseStart: record.leaseStartIso.trim().isEmpty
            ? DateTime(1900, 1, 1)
            : (_parseDate(record.leaseStartIso) ?? DateTime(1900, 1, 1)),
        leaseEnd: record.leaseEndIso.trim().isEmpty
            ? DateTime(9999, 12, 31)
            : (_parseDate(record.leaseEndIso) ?? DateTime(9999, 12, 31)),
        start: start,
        end: end,
      ),
    );
  }

  /// App bar label; includes listing name when opened with `propertyTitle` from listing details.
  String get tenantsScreenTitle {
    final isSw = Get.locale?.languageCode == 'sw';
    final t = _filterPropertyTitle;
    if (t.isEmpty) return isSw ? 'Maarifa ya Upangaji' : 'Tenancy Insights';
    return isSw ? 'Wapangaji — $t' : 'Tenants — $t';
  }

  static String _normalizeWorkspace(String raw) {
    return raw.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent';
  }

  void _captureRouteContext() {
    if (_routeContextCaptured) return;
    final args = Get.arguments;
    var ws = Get.parameters['ws']?.trim() ?? '';
    if (ws.isEmpty && args is Map) {
      ws = (args['ws'] ?? args['workspace'] ?? '').toString().trim();
    }
    _workspaceType = _normalizeWorkspace(ws);
    _filterPropertyRef = Get.parameters['propertyRef']?.trim() ?? '';
    _filterPropertyTitle = Get.parameters['propertyTitle']?.trim() ?? '';
    _filterPropertyLoc = Get.parameters['propertyLoc']?.trim() ?? '';
    _filterPropertySuite = Get.parameters['propertySuite']?.trim() ?? '';
    _routeContextCaptured = true;
  }

  bool _recordMatchesListingFilter(TenantRecord t) {
    final ref = _filterPropertyRef;
    final title = _filterPropertyTitle;
    final loc = _filterPropertyLoc;
    final suite = _filterPropertySuite;
    final hasFilter = ref.isNotEmpty || title.isNotEmpty || loc.isNotEmpty;
    if (!hasFilter) return true;

    final r = t.propertyRef.trim();
    if (ref.isNotEmpty && r.isNotEmpty && r == ref) return true;

    final pl = t.propertyLabel.trim();
    if (ref.isNotEmpty && r.isEmpty) {
      if (title.isNotEmpty && pl == title) return true;
      if (loc.isNotEmpty && pl == loc) return true;
      if (loc.isNotEmpty && suite.isNotEmpty && pl == '$loc · $suite') {
        return true;
      }
    }
    if (ref.isEmpty) {
      if (title.isNotEmpty && pl == title) return true;
      if (loc.isNotEmpty && pl == loc) return true;
      if (loc.isNotEmpty && suite.isNotEmpty && pl == '$loc · $suite') {
        return true;
      }
    }
    return false;
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void onFilterPressed() {
    Get.snackbar('Filter', 'Filters coming soon');
  }

  String get scheduleSubtitle {
    if (!whatsappScheduleEnabled.value ||
        nextWhatsappScheduleAt.value == null) {
      return 'Schedule off';
    }
    final f = whatsappScheduleFrequency.value == TenantReportFrequency.weekly
        ? 'Weekly'
        : 'Monthly';
    final t =
        whatsappScheduleTemplate.value ==
            TenancyExcelTemplate.customerRentDetails
        ? 'Rent details'
        : 'Tenant summary';
    final n = DateFormat('dd MMM, HH:mm').format(nextWhatsappScheduleAt.value!);
    return '$f • $t • next $n';
  }

  bool isTenantCardExpanded(String tenantId) =>
      expandedTenantCardIds.contains(tenantId);

  void toggleTenantCardExpanded(String tenantId) {
    if (expandedTenantCardIds.contains(tenantId)) {
      expandedTenantCardIds.remove(tenantId);
    } else {
      expandedTenantCardIds.add(tenantId);
    }
    expandedTenantCardIds.refresh();
  }

  void openTenantLedger(TenantInsight t) {
    Get.toNamed(
      Routes.RENT_TENANT_LEDGER_OCCUPANCY,
      parameters: {
        'id': t.id,
        'name': t.name,
        'property': t.propertyLine,
        'ws': _workspaceType,
        if (_filterPropertyRef.isNotEmpty) 'propertyRef': _filterPropertyRef,
        if (_filterPropertyTitle.isNotEmpty)
          'propertyTitle': _filterPropertyTitle,
        if (_filterPropertyLoc.isNotEmpty) 'propertyLoc': _filterPropertyLoc,
        if (_filterPropertySuite.isNotEmpty)
          'propertySuite': _filterPropertySuite,
      },
      arguments: {'ws': _workspaceType},
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
    final contextTitle = _filterPropertyTitle;
    Get.toNamed(
      Routes.SEND_SMS,
      arguments: {
        'phones': phones,
        'propertyRef': _filterPropertyRef,
        'workspace': _workspaceType,
        'contextLabel': contextTitle.isEmpty
            ? 'Tenancy insights recipients'
            : 'Tenants in $contextTitle',
      },
    );
  }

  Future<void> exportCustomerRentDetailsExcel() async {
    await _exportExcel(
      template: TenancyExcelTemplate.customerRentDetails,
      viaWhatsApp: false,
    );
  }

  Future<void> exportCustomerRentTenantSummaryExcel() async {
    await _exportExcel(
      template: TenancyExcelTemplate.customerRentTenantSummary,
      viaWhatsApp: false,
    );
  }

  Future<void> sendScheduledReportNowViaWhatsApp() async {
    await _exportExcel(
      template: whatsappScheduleTemplate.value,
      viaWhatsApp: true,
    );
  }

  Future<void> saveWhatsAppSchedule({
    required bool enabled,
    required TenantReportFrequency frequency,
    required TenancyExcelTemplate template,
  }) async {
    whatsappScheduleEnabled.value = enabled;
    whatsappScheduleFrequency.value = frequency;
    whatsappScheduleTemplate.value = template;

    if (!enabled) {
      nextWhatsappScheduleAt.value = null;
      await _notificationScheduler.showNow(
        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
        title: 'Tenant report schedule disabled',
        body: 'Periodic WhatsApp report has been turned off.',
      );
    } else {
      nextWhatsappScheduleAt.value = _nextOccurrence(
        from: DateTime.now(),
        frequency: frequency,
      );
      final next = nextWhatsappScheduleAt.value!;
      await _notificationScheduler.scheduleOneShot(
        id: next.millisecondsSinceEpoch % 2147483647,
        when: next,
        title: 'Tenant report ready',
        body:
            'Open Tenancy Insights to send your ${frequency == TenantReportFrequency.weekly ? 'weekly' : 'monthly'} Excel report via WhatsApp.',
        payload: 'tenant_report_schedule',
      );
    }
    await _persistWhatsappSchedule();
  }

  /// Reload tenant cards when income or tenant data changes elsewhere.
  static Future<void> refreshIfRegistered() async {
    if (GetxInstanceProbe.isAlive<
        RentTenantResidencyPaymentTrackerController>()) {
      await Get.find<RentTenantResidencyPaymentTrackerController>()
          .loadTenants();
    }
  }

  Future<void> loadTenants() async {
    final showSkeleton = tenants.isEmpty;
    if (showSkeleton) tenantsInitialLoading.value = true;
    try {
      await _loadTenantsCore();
    } finally {
      tenantsInitialLoading.value = false;
    }
  }

  Future<void> _loadTenantsCore() async {
    final ws = _workspaceType;
    final rows = await _tenantLocal.getAllNewestFirstByWorkspace(ws);
    final scoped = rows.where(_recordMatchesListingFilter).toList();
    final incomeRows = await _incomeLocal.getAllNewestFirst(workspaceType: ws);
    final expenseRows = await _expenseLocal.getAllNewestFirst(
      workspaceType: ws,
    );
    _incomeRowsCache = incomeRows;
    _expenseRowsCache = expenseRows;
    _tenantRecordsById
      ..clear()
      ..addEntries(scoped.map((e) => MapEntry('${e.id}', e)));
    final fmt = DateFormat('MMM yyyy');
    await _loadPropertyPrincipalSnapshot(
      scopedTenants: scoped,
      incomeRows: incomeRows,
      expenseRows: expenseRows,
    );

    tenants.assignAll(
      scoped.map((r) {
        final start = _parseDate(r.leaseStartIso) ?? DateTime.now();
        final end =
            _parseDate(r.leaseEndIso) ??
            DateTime.now().add(const Duration(days: 30));
        final now = DateTime.now();
        final totalMonths = _monthsBetween(start, end).clamp(1, 240);
        final spentMonths = _monthsBetween(start, now).clamp(0, totalMonths);
        final progress = (spentMonths / totalMonths).clamp(0.0, 1.0);
        final totalAmount = r.rentAmountValue * totalMonths;
        final paidFromIncome = _sumIncomeForTenant(
          r,
          incomeRows,
          start: financeWindow.value == TenantFinanceWindow.tenure
              ? start
              : null,
          end: financeWindow.value == TenantFinanceWindow.tenure ? end : null,
        );
        final expenseForTenure = _sumExpenseForTenant(
          tenant: r,
          expenseRows: expenseRows,
          leaseStart: start,
          leaseEnd: end,
          start: financeWindow.value == TenantFinanceWindow.tenure
              ? start
              : null,
          end: financeWindow.value == TenantFinanceWindow.tenure ? end : null,
        );
        final paidAmount = paidFromIncome.clamp(0, totalAmount).toDouble();
        final expectedToDate = (r.rentAmountValue * spentMonths).clamp(
          0,
          totalAmount,
        );
        final arrears = (expectedToDate - paidAmount).clamp(0, double.infinity);
        final isEndingSoon =
            !end.isBefore(DateTime(now.year, now.month, now.day)) &&
            !end.isAfter(
              DateTime(
                now.year,
                now.month,
                now.day,
              ).add(const Duration(days: 30)),
            );
        final rentPerMonth = totalMonths > 0
            ? totalAmount / totalMonths
            : r.rentAmountValue;
        final paidMonthSlots = rentPerMonth > 0
            ? (paidFromIncome / rentPerMonth).floor().clamp(0, 6)
            : 0;
        return TenantInsight(
          id: '${r.id}',
          name: r.tenantName,
          propertyLine: r.propertyLabel,
          totalStayLabel: '$spentMonths Months',
          leasePeriodLabel: '${fmt.format(start)} – ${fmt.format(end)}',
          leaseProgress: progress,
          monthStatuses: List<ResidencyMonthStatus>.generate(6, (i) {
            if (i < paidMonthSlots) return ResidencyMonthStatus.paid;
            if (i < spentMonths.clamp(0, 6)) {
              return ResidencyMonthStatus.partial;
            }
            return ResidencyMonthStatus.upcoming;
          }),
          onSchedule: paidAmount + 0.01 >= expectedToDate || now.isAfter(end),
          paidAmount: paidAmount,
          totalAmount: totalAmount,
          phoneNumber: r.phoneNumber,
          leaseStart: start,
          leaseEnd: end,
          monthlyRent: r.rentAmountValue,
          arrearsAmount: arrears.toDouble(),
          isLeaseEndingSoon: isEndingSoon,
          incomeForTenure: paidFromIncome,
          expenseForTenure: expenseForTenure,
        );
      }),
    );
  }

  Future<void> _exportExcel({
    required TenancyExcelTemplate template,
    required bool viaWhatsApp,
  }) async {
    final rows = filteredTenants;
    if (rows.isEmpty) {
      showErrorMessage('No tenants available for export.');
      return;
    }

    final excel = Excel.createExcel();
    final sheetName = template == TenancyExcelTemplate.customerRentDetails
        ? 'Rents details'
        : 'Tenant summary';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final headers = template == TenancyExcelTemplate.customerRentDetails
        ? <String>[
            'Name',
            'Room No.',
            'Rent / month',
            'Rent period',
            'Start',
            'Expiry',
            'Date',
            'Amt paid',
            'Amount owing / not paid',
            'Remarks',
          ]
        : <String>[
            'Name',
            'Amount',
            'Paid',
            'Status',
            'Contract',
            'Duration',
            'Co-host',
          ];

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('FF004D40'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final arrearsStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFFFCDD2'),
      fontColorHex: ExcelColor.fromHexString('FFB71C1C'),
    );
    final endingSoonStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('FFFFE0B2'),
      fontColorHex: ExcelColor.fromHexString('FFBF360C'),
    );

    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidth(c, 23);
    }

    for (var r = 0; r < rows.length; r++) {
      final t = rows[r];
      final status = t.arrearsAmount > 0
          ? 'Arrears'
          : (t.isLeaseEndingSoon ? 'Ending soon' : 'On schedule');
      final rowValues = template == TenancyExcelTemplate.customerRentDetails
          ? <Object?>[
              t.name,
              t.propertyLine,
              _formatAmount(t.monthlyRent.round()),
              t.leasePeriodLabel,
              _date.format(t.leaseStart),
              _date.format(t.leaseEnd),
              _date.format(DateTime.now()),
              _formatAmount(t.paidAmount.round()),
              _formatAmount(t.arrearsAmount.round()),
              status,
            ]
          : <Object?>[
              t.name,
              _formatAmount(t.totalAmount.round()),
              _formatAmount(t.paidAmount.round()),
              status,
              '${_date.format(t.leaseStart)} - ${_date.format(t.leaseEnd)}',
              t.totalStayLabel,
              '',
            ];

      for (var c = 0; c < rowValues.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        cell.value = TextCellValue(rowValues[c]?.toString() ?? '');
        if (t.arrearsAmount > 0) {
          cell.cellStyle = arrearsStyle;
        } else if (t.isLeaseEndingSoon) {
          cell.cellStyle = endingSoonStyle;
        }
      }
    }

    // Landscape-ready layout: wider columns for horizontal print/export views.
    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 32);
    if (template == TenancyExcelTemplate.customerRentDetails) {
      sheet.setColumnWidth(8, 24);
      sheet.setColumnWidth(9, 24);
    }

    final bytes = excel.save(fileName: 'tenant_report.xlsx');
    if (bytes == null) {
      showErrorMessage('Failed to generate excel report');
      return;
    }
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final slug = template == TenancyExcelTemplate.customerRentDetails
        ? 'customer_rent_details_template'
        : 'customer_rent_tenant_summary_template';
    final file = File('${dir.path}/${slug}_$stamp.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    final caption = viaWhatsApp
        ? 'Tenant report ($slug).'
        : 'Tenant report ready.';
    await Share.shareXFiles([
      XFile(
        file.path,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    ], text: caption);
    if (!viaWhatsApp) {
      showSuccessMessage('Excel report prepared.');
    }
  }

  Future<void> _loadWhatsappSchedule() async {
    final enabled = await _preferenceManager.getBool(
      _waScheduleEnabledKey,
      defaultValue: false,
    );
    final frequency = await _preferenceManager.getString(
      _waScheduleFrequencyKey,
      defaultValue: 'weekly',
    );
    final template = await _preferenceManager.getString(
      _waScheduleTemplateKey,
      defaultValue: 'customer_rent_details',
    );
    final nextMs = await _preferenceManager.getInt(
      _waScheduleNextMsKey,
      defaultValue: 0,
    );

    whatsappScheduleEnabled.value = enabled;
    whatsappScheduleFrequency.value = frequency == 'monthly'
        ? TenantReportFrequency.monthly
        : TenantReportFrequency.weekly;
    whatsappScheduleTemplate.value = template == 'customer_rent_tenant_summary'
        ? TenancyExcelTemplate.customerRentTenantSummary
        : TenancyExcelTemplate.customerRentDetails;
    nextWhatsappScheduleAt.value = nextMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(nextMs)
        : null;
  }

  Future<void> _persistWhatsappSchedule() async {
    await _preferenceManager.setBool(
      _waScheduleEnabledKey,
      whatsappScheduleEnabled.value,
    );
    await _preferenceManager.setString(
      _waScheduleFrequencyKey,
      whatsappScheduleFrequency.value == TenantReportFrequency.monthly
          ? 'monthly'
          : 'weekly',
    );
    await _preferenceManager.setString(
      _waScheduleTemplateKey,
      whatsappScheduleTemplate.value ==
              TenancyExcelTemplate.customerRentTenantSummary
          ? 'customer_rent_tenant_summary'
          : 'customer_rent_details',
    );
    await _preferenceManager.setInt(
      _waScheduleNextMsKey,
      nextWhatsappScheduleAt.value?.millisecondsSinceEpoch ?? 0,
    );
  }

  Future<void> _runDueWhatsappScheduleIfNeeded() async {
    if (!whatsappScheduleEnabled.value) return;
    final next = nextWhatsappScheduleAt.value;
    if (next == null || DateTime.now().isBefore(next)) return;
    await _exportExcel(
      template: whatsappScheduleTemplate.value,
      viaWhatsApp: true,
    );
    nextWhatsappScheduleAt.value = _nextOccurrence(
      from: DateTime.now(),
      frequency: whatsappScheduleFrequency.value,
    );
    await _persistWhatsappSchedule();
  }

  DateTime _nextOccurrence({
    required DateTime from,
    required TenantReportFrequency frequency,
  }) {
    final base = DateTime(from.year, from.month, from.day, 9, 0);
    if (frequency == TenantReportFrequency.weekly) {
      return base.add(const Duration(days: 7));
    }
    return DateTime(
      base.year,
      base.month + 1,
      base.day,
      base.hour,
      base.minute,
    );
  }

  Future<void> _loadPropertyPrincipalSnapshot({
    required List<TenantRecord> scopedTenants,
    required List<IncomeRecord> incomeRows,
    required List<ExpenseRecord> expenseRows,
  }) async {
    final ref = Get.parameters['propertyRef']?.trim() ?? '';
    if (ref.isEmpty) {
      propertyPrincipal.value = null;
      return;
    }
    final estimate = await _estimateLocal.findByPropertyRef(ref);
    if (estimate == null) {
      propertyPrincipal.value = null;
      return;
    }

    final principal = estimate.purchaseCost + estimate.renovationCost;
    final maintenanceEstimate = estimate.expectedMonthlyExpense * 12;

    var income = 0.0;
    final byRef = incomeRows.where((r) => r.propertyRef.trim() == ref);
    if (byRef.isNotEmpty) {
      income = byRef.fold<double>(0, (s, r) => s + r.amountValue);
    } else {
      for (final row in incomeRows) {
        for (final t in scopedTenants) {
          if (_incomeRowMatchesTenant(row, t)) {
            income += row.amountValue;
            break;
          }
        }
      }
    }

    var maintenanceActual = 0.0;
    for (final row in expenseRows) {
      final cat = row.category.trim().toLowerCase();
      if (!cat.contains('maint') &&
          !cat.contains('repair') &&
          !cat.contains('plumb') &&
          !cat.contains('electr')) {
        continue;
      }
      for (final t in scopedTenants) {
        if (_expenseRowMatchesTenant(row, t)) {
          maintenanceActual += row.amountValue;
          break;
        }
      }
    }

    final maintenance = maintenanceEstimate > 0
        ? maintenanceEstimate
        : maintenanceActual;
    final monthlyIncome = estimate.expectedMonthlyIncome > 0
        ? estimate.expectedMonthlyIncome
        : (income / 12).clamp(0, double.infinity);
    final monthlyNet = monthlyIncome - estimate.expectedMonthlyExpense;
    final totalCost = principal + (maintenance > 0 ? maintenance : 0);

    propertyPrincipal.value = PropertyPrincipalSnapshot(
      principalCost: principal,
      maintenanceCost: maintenance,
      incomeGenerated: income,
      monthlyNet: monthlyNet,
      breakEvenLabel: PropertyBreakEvenMetrics.formatBreakEven(
        principalCost: totalCost > 0 ? totalCost : principal,
        monthlyNetIncome: monthlyNet,
        incomeGeneratedToDate: income,
        isSw: Get.locale?.languageCode == 'sw',
      ),
    );
  }

  static double _sumIncomeForTenant(
    TenantRecord tenant,
    List<IncomeRecord> incomeRows, {
    DateTime? start,
    DateTime? end,
  }) {
    var sum = 0.0;
    for (final row in incomeRows) {
      final d = row.paidLocalCalendarOrCreated();
      if (start != null && d.isBefore(start)) continue;
      if (end != null && d.isAfter(end)) continue;
      if (_incomeRowMatchesTenant(row, tenant)) {
        sum += row.amountValue;
      }
    }
    return sum;
  }

  static bool _incomeRowMatchesTenant(
    IncomeRecord income,
    TenantRecord tenant,
  ) {
    final incomeTenant = income.tenantName.trim().toLowerCase();
    final tenantName = tenant.tenantName.trim().toLowerCase();
    final tenantMatches = incomeTenant.isNotEmpty && incomeTenant == tenantName;
    if (incomeTenant.isNotEmpty && !tenantMatches) {
      return false;
    }
    final tenantRef = tenant.propertyRef.trim();
    final incomeRef = income.propertyRef.trim();
    final refMatches =
        tenantRef.isNotEmpty && incomeRef.isNotEmpty && tenantRef == incomeRef;
    if (tenantRef.isNotEmpty &&
        incomeRef.isNotEmpty &&
        tenantRef != incomeRef) {
      return false;
    }
    final unitMatches = _incomeRowMatchesTenantUnit(income, tenant);
    if (refMatches && (tenantMatches || unitMatches)) return true;
    if (tenantMatches && unitMatches) return true;
    if (tenantMatches && _incomeRowMatchesTenantProperty(income, tenant)) {
      return true;
    }
    return !tenantMatches &&
        unitMatches &&
        _incomeRowMatchesTenantProperty(income, tenant);
  }

  static bool _incomeRowMatchesTenantUnit(
    IncomeRecord income,
    TenantRecord tenant,
  ) {
    final tenantUnitId = tenant.apartmentUnitId.trim().toLowerCase();
    final tenantUnit = tenant.unitLabel.trim().toLowerCase();
    final incomeUnit = income.apartmentUnit.trim().toLowerCase();
    final notes = income.notes.trim().toLowerCase();
    if (tenantUnitId.isNotEmpty && incomeUnit == tenantUnitId) return true;
    if (tenantUnit.isNotEmpty && incomeUnit == tenantUnit) return true;
    if (tenantUnit.isNotEmpty && notes.contains(tenantUnit)) return true;
    return false;
  }

  static bool _incomeRowMatchesTenantProperty(
    IncomeRecord income,
    TenantRecord tenant,
  ) {
    final pl = tenant.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return true;
    final ap = income.apartment.trim().toLowerCase();
    final unit = income.apartmentUnit.trim().toLowerCase();
    final notes = income.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) ||
        (ap.isNotEmpty && pl.contains(ap)) ||
        (unit.isNotEmpty && pl.contains(unit)) ||
        ap == pl;
  }

  static double _sumExpenseForTenant({
    required TenantRecord tenant,
    required List<ExpenseRecord> expenseRows,
    required DateTime leaseStart,
    required DateTime leaseEnd,
    DateTime? start,
    DateTime? end,
  }) {
    var sum = 0.0;
    final from = start ?? leaseStart;
    final to = end ?? leaseEnd;
    for (final row in expenseRows) {
      final d = row.paidLocalCalendarOrCreated();
      if (d.isBefore(from) || d.isAfter(to)) continue;
      if (_expenseRowMatchesTenant(row, tenant)) {
        sum += row.amountValue;
      }
    }
    return sum;
  }

  static bool _expenseRowMatchesTenant(
    ExpenseRecord expense,
    TenantRecord tenant,
  ) {
    final tenantName = tenant.tenantName.trim().toLowerCase();
    final expenseTenantName = expense.tenantName.trim().toLowerCase();
    if (expenseTenantName.isNotEmpty && expenseTenantName == tenantName) {
      return true;
    }
    final pl = tenant.propertyLabel.trim().toLowerCase();
    if (pl.isEmpty) return false;
    final ap = expense.apartment.trim().toLowerCase();
    final unit = expense.apartmentUnit.trim().toLowerCase();
    final notes = expense.notes.trim().toLowerCase();
    final blob = '$ap $unit $notes'.trim();
    return blob.contains(pl) || pl.contains(ap) || ap == pl;
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
