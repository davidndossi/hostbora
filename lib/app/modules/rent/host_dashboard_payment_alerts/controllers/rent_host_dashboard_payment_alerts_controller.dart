import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/rent_income_local_data_source.dart';
import '../../../../data/local/db/rent_property_local_data_source.dart';
import '../../../../data/local/db/rent_tenant_local_data_source.dart';
import '../../../../routes/app_pages.dart';
import '../../rent_real_data_controller_mixin.dart';

class HostPaymentAlertItem {
  const HostPaymentAlertItem({
    required this.tenant,
    required this.propertyLabel,
    required this.expectedAmount,
    required this.paidToDate,
    required this.balance,
    required this.dueDate,
    required this.progressPaid,
  });

  final String tenant;
  final String propertyLabel;
  final double expectedAmount;
  final double paidToDate;
  final double balance;
  final DateTime dueDate;
  final double progressPaid;
}

class RentHostDashboardPaymentAlertsController extends BaseController
    with RentRealDataControllerMixin {
  RentHostDashboardPaymentAlertsController()
      : _incomeLocal = Get.find<RentIncomeLocalDataSource>(),
        _tenantLocal = Get.find<RentTenantLocalDataSource>(),
        _propertyLocal = Get.find<RentPropertyLocalDataSource>();

  final RentIncomeLocalDataSource _incomeLocal;
  final RentTenantLocalDataSource _tenantLocal;
  final RentPropertyLocalDataSource _propertyLocal;

  final incomes = <RentIncomeRecord>[].obs;
  final tenants = <RentTenantRecord>[].obs;
  final properties = <RentPropertyRecord>[].obs;
  final urgentAlerts = <HostPaymentAlertItem>[].obs;
  final hostDisplayName = 'Estate Manager'.obs;

  @override
  void onReady() {
    super.onReady();
    final fromRoute = Get.parameters['hostName']?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) {
      hostDisplayName.value = fromRoute;
    }
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadRealDataSnapshot(),
      _loadTenantsAndProperties(),
    ]);
  }

  Future<void> _loadTenantsAndProperties() async {
    final results = await Future.wait([
      _tenantLocal.getAllNewestFirst(),
      _propertyLocal.getAllNewestFirst(),
      _incomeLocal.getAllNewestFirst(),
    ]);
    final t = results[0] as List<RentTenantRecord>;
    final p = results[1] as List<RentPropertyRecord>;
    final i = results[2] as List<RentIncomeRecord>;
    tenants.assignAll(t);
    properties.assignAll(p);
    incomes.assignAll(i);
    _buildUrgentAlerts();
  }

  void _buildUrgentAlerts() {
    final now = DateTime.now();
    final sorted = [...tenants];
    sorted.sort((a, b) {
      final aEnd = _safeDate(a.leaseEndIso) ?? now.add(const Duration(days: 9999));
      final bEnd = _safeDate(b.leaseEndIso) ?? now.add(const Duration(days: 9999));
      return aEnd.compareTo(bEnd);
    });

    final pendingAlerts = <HostPaymentAlertItem>[];
    for (final t in sorted) {
      final leaseStart = _safeDate(t.leaseStartIso);
      final leaseEnd = _safeDate(t.leaseEndIso);
      final due = leaseEnd ?? now.add(const Duration(days: 14));
      final expected = _expectedAmountForLease(t, leaseStart, leaseEnd);
      final paidToDate = _sumTenantPaidForWindow(
        tenant: t,
        startInclusive: leaseStart,
        endInclusive: leaseEnd,
      );
      final balance = expected <= 0 ? 0.0 : (expected - paidToDate).clamp(0.0, expected).toDouble();
      final progress = expected <= 0 ? 0.0 : ((paidToDate / expected).clamp(0.0, 1.0)).toDouble();
      if (balance <= 0) continue;
      pendingAlerts.add(
        HostPaymentAlertItem(
          tenant: t.tenantName.trim().isEmpty ? 'Tenant' : t.tenantName.trim(),
          propertyLabel: t.propertyLabel.trim().isEmpty ? 'Property' : t.propertyLabel.trim(),
          expectedAmount: expected,
          paidToDate: paidToDate,
          balance: balance,
          dueDate: due,
          progressPaid: progress,
        ),
      );
    }
    urgentAlerts.assignAll(pendingAlerts.take(3));
  }

  double _sumTenantPaidForWindow({
    required RentTenantRecord tenant,
    required DateTime? startInclusive,
    required DateTime? endInclusive,
  }) {
    final tenantName = tenant.tenantName.trim().toLowerCase();
    final property = tenant.propertyLabel.trim().toLowerCase();
    final unit = tenant.unitLabel.trim().toLowerCase();

    double sum = 0;
    for (final income in incomes) {
      final paidAt = _safeDate(income.datePaidIso);
      if (paidAt == null) continue;
      if (startInclusive != null && paidAt.isBefore(startInclusive)) continue;
      if (endInclusive != null && paidAt.isAfter(endInclusive)) continue;

      final incomeTenant = income.tenantName.trim().toLowerCase();
      final incomeProperty = income.apartment.trim().toLowerCase();
      final incomeUnit = income.apartmentUnit.trim().toLowerCase();

      if (_incomeMatchesTenant(
        tenantName: tenantName,
        property: property,
        unit: unit,
        incomeTenant: incomeTenant,
        incomeProperty: incomeProperty,
        incomeUnit: incomeUnit,
      )) {
        sum += income.amountValue;
      }
    }
    return sum;
  }

  double _expectedAmountForLease(
    RentTenantRecord tenant,
    DateTime? start,
    DateTime? end,
  ) {
    if (tenant.rentAmountValue <= 0) return 0.0;
    if (start == null || end == null || !end.isAfter(start)) {
      return tenant.rentAmountValue;
    }
    final units = _billingUnitsBetween(start, end, tenant.rentFrequency);
    return tenant.rentAmountValue * units;
  }

  int _billingUnitsBetween(DateTime start, DateTime end, String frequency) {
    final days = end.difference(start).inDays;
    switch (frequency.trim().toLowerCase()) {
      case 'per day':
        return days.clamp(1, 36500);
      case 'per week':
        return (days / 7).ceil().clamp(1, 5200);
      case 'per year':
        return ((end.year - start.year) +
                ((end.month > start.month ||
                        (end.month == start.month && end.day >= start.day))
                    ? 0
                    : -1))
            .clamp(1, 300);
      case 'per month':
      default:
        return _monthsBetween(start, end).clamp(1, 1200);
    }
  }

  int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  bool _incomeMatchesTenant({
    required String tenantName,
    required String property,
    required String unit,
    required String incomeTenant,
    required String incomeProperty,
    required String incomeUnit,
  }) {
    if (tenantName.isNotEmpty && incomeTenant != tenantName) return false;

    if (property.isEmpty) return true;
    // if (incomeProperty != property) return false;
    if (unit.isEmpty) return true;
    return incomeUnit == unit;
  }

  DateTime? _safeDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  String formatMoney(double amount) => NumberFormat('#,###', 'en_US').format(amount.round());

  String formatDueDate(DateTime date) => DateFormat('MMM d').format(date);

  String get estateName {
    if (properties.isEmpty) return 'N/A';
    final p = properties.first;
    final loc = p.propertyLocation.trim();
    return loc.isEmpty ? 'N/A' : loc;
  }

  double get collectionRate {
    final d = realData.value;
    if (d == null) return 0;
    final expected = tenants.fold<double>(0, (sum, t) => sum + t.rentAmountValue);
    if (expected <= 0) return d.incomeTotal > 0 ? 100 : 0;
    return (d.incomeTotal / expected * 100).clamp(0, 100);
  }

  double get expectedRevenue {
    final expected = tenants.fold<double>(0, (sum, t) => sum + t.rentAmountValue);
    if (expected > 0) return expected;
    return realData.value?.incomeTotal ?? 0;
  }

  int get occupiedUnits => tenants.length;

  int get activeBookings {
    final d = realData.value;
    if (d == null) return 0;
    return d.tenants;
  }

  int get totalUnits {
    final occ = occupiedUnits;
    if (occ == 0) return properties.isEmpty ? 0 : properties.length;
    final estimated = (occ / (collectionRate <= 0 ? 0.9 : (collectionRate / 100))).round();
    return estimated < occ ? occ : estimated;
  }

  void openSetReminder() {
    final first = urgentAlerts.isNotEmpty ? urgentAlerts.first : null;
    final tenantName = first?.tenant ?? 'Tenant payment reminder';
    final property = first?.propertyLabel ?? '';
    final balance = first != null ? formatMoney(first.balance) : '';
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        'name': tenantName,
        'property': property,
        'balance': balance,
      },
    );
  }

  void openProfitAnalysisDashboard() {
    Get.toNamed(Routes.RENT_PROFIT_ANALYSIS_DASHBOARD);
  }

  void onNotifyFeaturedTenant() {
    showSuccessMessage('Notification queued');
  }

  void onViewAllDelinquencies() {
    Get.toNamed(Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER);
  }

  void onSendLateNotice(HostPaymentAlertItem item) {
    Get.toNamed(
      Routes.RENT_SCHEDULE_PAYMENT_REMINDER,
      parameters: {
        'name': item.tenant,
        'property': item.propertyLabel,
        'balance': formatMoney(item.balance),
      },
    );
  }

  void onMonitorNewTenant() {
    Get.toNamed(Routes.RENT_TENANT_RESIDENCY_PAYMENT_TRACKER);
  }
}
