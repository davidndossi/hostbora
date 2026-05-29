import 'package:get/get.dart';

import '/app/core/utils/property_break_even_metrics.dart';
import '/app/data/local/db/expense_local_data_source.dart';
import '/app/data/local/db/income_local_data_source.dart';
import '/app/data/local/db/rent_notification_log_local_data_source.dart';
import '/app/data/local/db/rent_property_estimate_local_data_source.dart';
import '/app/data/local/db/tenant_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';

/// Notifies when a property reaches break-even or on the projected break-even date.
class PropertyBreakEvenNotificationService extends GetxService {
  PropertyBreakEvenNotificationService({
    required RentPropertyEstimateLocalDataSource estimateLocal,
    required IncomeLocalDataSource incomeLocal,
    required ExpenseLocalDataSource expenseLocal,
    required TenantLocalDataSource tenantLocal,
    required RentNotificationLogLocalDataSource notificationLogLocal,
    required PreferenceManager preferenceManager,
    required LocalNotificationSchedulerService notificationScheduler,
  })  : _estimateLocal = estimateLocal,
        _incomeLocal = incomeLocal,
        _expenseLocal = expenseLocal,
        _tenantLocal = tenantLocal,
        _notificationLogLocal = notificationLogLocal,
        _preferenceManager = preferenceManager,
        _notificationScheduler = notificationScheduler;

  final RentPropertyEstimateLocalDataSource _estimateLocal;
  final IncomeLocalDataSource _incomeLocal;
  final ExpenseLocalDataSource _expenseLocal;
  final TenantLocalDataSource _tenantLocal;
  final RentNotificationLogLocalDataSource _notificationLogLocal;
  final PreferenceManager _preferenceManager;
  final LocalNotificationSchedulerService _notificationScheduler;

  static const _reachedPrefix = 'breakeven_reached_';
  static const _projectedDayPrefix = 'breakeven_projected_day_';
  static const _scheduledMsPrefix = 'breakeven_scheduled_ms_';

  static Future<void> refreshIfRegistered() async {
    if (!Get.isRegistered<PropertyBreakEvenNotificationService>()) return;
    await Get.find<PropertyBreakEvenNotificationService>().runNow();
  }

  static Future<void> checkPropertyIfRegistered(String propertyRef) async {
    if (!Get.isRegistered<PropertyBreakEvenNotificationService>()) return;
    await Get.find<PropertyBreakEvenNotificationService>().checkProperty(propertyRef);
  }

  Future<void> checkProperty(String propertyRef) async {
    final ref = propertyRef.trim();
    if (ref.isEmpty) return;
    final estimate = await _estimateLocal.findByPropertyRef(ref);
    if (estimate == null) return;
    var incomeRows = await _incomeLocal.getAllByPropertyRefAndWorkspace(
      propertyRef: ref,
      workspaceType: 'rent',
    );
    if (incomeRows.isEmpty) {
      incomeRows = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    }
    final expenseRows = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
    final tenants = await _tenantLocal.getAllNewestFirst();
    await _processEstimate(
      estimate,
      incomeRows: incomeRows,
      expenseRows: expenseRows,
      tenants: tenants,
    );
  }

  Future<void> runNow() async {
    final estimates = await _estimateLocal.getAllNewestFirst();
    if (estimates.isEmpty) return;

    final incomeRows = await _incomeLocal.getAllNewestFirst(workspaceType: 'rent');
    final expenseRows = await _expenseLocal.getAllNewestFirst(workspaceType: 'rent');
    final tenants = await _tenantLocal.getAllNewestFirst();

    for (final estimate in estimates) {
      await _processEstimate(
        estimate,
        incomeRows: incomeRows,
        expenseRows: expenseRows,
        tenants: tenants,
      );
    }
  }

  Future<void> _processEstimate(
    RentPropertyEstimateRecord estimate, {
    required List<IncomeRecord> incomeRows,
    required List<ExpenseRecord> expenseRows,
    required List<TenantRecord> tenants,
  }) async {
    final ref = estimate.propertyRef.trim();
    if (ref.isEmpty) return;

    final principal = estimate.purchaseCost + estimate.renovationCost;
    if (principal <= 0) return;

    final maintenanceEstimate = estimate.expectedMonthlyExpense * 12;
    final maintenanceActual = _sumMaintenanceForProperty(
      ref: ref,
      label: estimate.propertyLabel,
      expenseRows: expenseRows,
      tenants: tenants,
    );
    final maintenance =
        maintenanceEstimate > 0 ? maintenanceEstimate : maintenanceActual;
    final totalCapital = principal + (maintenance > 0 ? maintenance : 0);

    final income = _sumIncomeForProperty(
      ref: ref,
      incomeRows: incomeRows,
      tenants: tenants,
    );

    final monthlyIncome = income > 0
        ? income / 12
        : estimate.expectedMonthlyIncome;
    final monthlyNet = monthlyIncome - estimate.expectedMonthlyExpense;

    if (PropertyBreakEvenMetrics.isBreakEvenReached(
      totalCapital: totalCapital,
      incomeGeneratedToDate: income,
    )) {
      await _notifyReached(estimate, income: income, totalCapital: totalCapital);
      return;
    }

    if (monthlyNet <= 0) return;

    final projected = PropertyBreakEvenMetrics.projectedBreakEvenDate(
      totalCapital: totalCapital,
      monthlyNetIncome: monthlyNet,
    );
    if (projected == null) return;

    await _ensureScheduled(ref, projected, estimate);

    final today = _day(DateTime.now());
    final projectedDay = _day(projected);
    if (!_sameDay(projectedDay, today)) return;

    final dayKey = '${projectedDay.year}${projectedDay.month}${projectedDay.day}';
    final dedupe = '$_projectedDayPrefix${ref}_$dayKey';
    if (await _alreadySent(dedupe)) return;

    await _notifyProjectedDay(estimate, projected: projected);
    await _markSent(dedupe);
  }

  Future<void> _notifyReached(
    RentPropertyEstimateRecord estimate, {
    required double income,
    required double totalCapital,
  }) async {
    final ref = estimate.propertyRef.trim();
    final dedupe = '$_reachedPrefix$ref';
    if (await _alreadySent(dedupe)) return;

    final label = estimate.propertyLabel.trim().isEmpty
        ? 'Property'
        : estimate.propertyLabel.trim();
    final incomeRounded = income.round();
    final capitalRounded = totalCapital.round();

    await _notificationScheduler.showNow(
      id: _notificationId('breakeven_reached_$ref'),
      title: 'Break-even reached',
      body:
          '$label: rental income (TZS $incomeRounded) has covered your capital (TZS $capitalRounded).',
      payload: 'breakeven:reached:$ref',
    );
    await _notificationLogLocal.insert(
      type: 'income',
      title: 'Break-even: $label',
      subtitle: 'Income has recovered your principal and maintenance estimates',
      actionLabel: 'View ROI',
      payload: 'breakeven:reached:$ref',
    );
    await _markSent(dedupe);
  }

  Future<void> _notifyProjectedDay(
    RentPropertyEstimateRecord estimate, {
    required DateTime projected,
  }) async {
    final ref = estimate.propertyRef.trim();
    final label = estimate.propertyLabel.trim().isEmpty
        ? 'Property'
        : estimate.propertyLabel.trim();

    await _notificationScheduler.showNow(
      id: _notificationId('breakeven_projected_$ref'),
      title: 'Break-even day',
      body: '$label is projected to reach break-even today.',
      payload: 'breakeven:projected:$ref',
    );
    await _notificationLogLocal.insert(
      type: 'income',
      title: 'Break-even today: $label',
      subtitle: 'Projected break-even date based on your estimates',
      actionLabel: 'View ROI',
      payload: 'breakeven:projected:$ref',
    );
  }

  Future<void> _ensureScheduled(
    String propertyRef,
    DateTime projected,
    RentPropertyEstimateRecord estimate,
  ) async {
    if (!projected.isAfter(DateTime.now())) return;

    final msKey = '$_scheduledMsPrefix$propertyRef';
    final scheduledMs = projected.millisecondsSinceEpoch;
    final previous = await _preferenceManager.getInt(msKey, defaultValue: 0);
    if (previous == scheduledMs) return;

    final label = estimate.propertyLabel.trim().isEmpty
        ? 'Property'
        : estimate.propertyLabel.trim();

    await _notificationScheduler.scheduleOneShot(
      id: _notificationId('breakeven_schedule_$propertyRef'),
      when: projected,
      title: 'Break-even day',
      body: '$label is projected to reach break-even today.',
      payload: 'breakeven:projected:$propertyRef',
    );
    await _preferenceManager.setInt(msKey, scheduledMs);
  }

  double _sumIncomeForProperty({
    required String ref,
    required List<IncomeRecord> incomeRows,
    required List<TenantRecord> tenants,
  }) {
    final byRef = incomeRows.where((r) => r.propertyRef.trim() == ref);
    if (byRef.isNotEmpty) {
      return byRef.fold<double>(0, (s, r) => s + r.amountValue);
    }
    var sum = 0.0;
    for (final row in incomeRows) {
      for (final t in tenants) {
        if (t.propertyRef.trim() != ref) continue;
        if (_incomeMatchesTenant(row, t)) {
          sum += row.amountValue;
          break;
        }
      }
    }
    return sum;
  }

  double _sumMaintenanceForProperty({
    required String ref,
    required String label,
    required List<ExpenseRecord> expenseRows,
    required List<TenantRecord> tenants,
  }) {
    var sum = 0.0;
    for (final row in expenseRows) {
      final cat = row.category.trim().toLowerCase();
      if (!cat.contains('maint') &&
          !cat.contains('repair') &&
          !cat.contains('plumb') &&
          !cat.contains('electr')) {
        continue;
      }
      var matched = false;
      for (final t in tenants) {
        if (t.propertyRef.trim() != ref) continue;
        if (_expenseMatchesTenant(row, t)) {
          matched = true;
          break;
        }
      }
      if (!matched && label.isNotEmpty) {
        final pl = label.trim().toLowerCase();
        final ap = row.apartment.trim().toLowerCase();
        final unit = row.apartmentUnit.trim().toLowerCase();
        final notes = row.notes.trim().toLowerCase();
        final blob = '$ap $unit $notes'.trim();
        matched = blob.contains(pl) || pl.contains(ap);
      }
      if (matched) sum += row.amountValue;
    }
    return sum;
  }

  bool _incomeMatchesTenant(IncomeRecord income, TenantRecord tenant) {
    if (income.tenantName.trim().toLowerCase() !=
        tenant.tenantName.trim().toLowerCase()) {
      return false;
    }
    final tenantRef = tenant.propertyRef.trim();
    final incomeRef = income.propertyRef.trim();
    if (tenantRef.isNotEmpty &&
        incomeRef.isNotEmpty &&
        tenantRef != incomeRef) {
      return false;
    }
    return true;
  }

  bool _expenseMatchesTenant(ExpenseRecord expense, TenantRecord tenant) {
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

  Future<bool> _alreadySent(String key) =>
      _preferenceManager.getBool(key, defaultValue: false);

  Future<void> _markSent(String key) => _preferenceManager.setBool(key, true);

  int _notificationId(String source) => source.hashCode.abs() % 2147483647;

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
