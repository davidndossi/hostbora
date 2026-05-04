import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '/app/data/local/db/rent_scheduled_maintenance_local_data_source.dart';
import '/app/data/local/db/rent_staff_local_data_source.dart';
import '/app/data/local/db/tenant_local_data_source.dart';
import '/app/data/local/db/rent_notification_log_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/local/service/local_notification_scheduler_service.dart';

/// Rule-based reminders:
/// - Staff salary due: 2 days prior
/// - Tenant payment: 1 month prior, then weekly until lease end
/// - Scheduled maintenance: 1 day prior
class RentNotificationRulesService extends GetxService {
  RentNotificationRulesService({
    required TenantLocalDataSource tenantLocal,
    required RentStaffLocalDataSource staffLocal,
    required RentScheduledMaintenanceLocalDataSource maintenanceLocal,
    required RentNotificationLogLocalDataSource notificationLogLocal,
    required PreferenceManager preferenceManager,
    required LocalNotificationSchedulerService notificationScheduler,
  })  : _tenantLocal = tenantLocal,
        _staffLocal = staffLocal,
        _maintenanceLocal = maintenanceLocal,
        _notificationLogLocal = notificationLogLocal,
        _preferenceManager = preferenceManager,
        _notificationScheduler = notificationScheduler;

  final TenantLocalDataSource _tenantLocal;
  final RentStaffLocalDataSource _staffLocal;
  final RentScheduledMaintenanceLocalDataSource _maintenanceLocal;
  final RentNotificationLogLocalDataSource _notificationLogLocal;
  final PreferenceManager _preferenceManager;
  final LocalNotificationSchedulerService _notificationScheduler;

  Timer? _timer;
  bool _running = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 12), (_) {
      unawaited(runNow());
    });
    unawaited(runNow());
  }

  Future<void> runNow() async {
    if (_running) return;
    _running = true;
    try {
      final today = _day(DateTime.now());
      await _handleStaffSalaryReminders(today);
      await _handleTenantPaymentReminders(today);
      await _handleMaintenanceReminders(today);
    } finally {
      _running = false;
    }
  }

  Future<void> _handleStaffSalaryReminders(DateTime today) async {
    final staff = await _staffLocal.getAllNewestFirst();
    for (final s in staff) {
      final payDay = int.tryParse(s.payDayLabel.trim());
      if (payDay == null || payDay < 1 || payDay > 31) continue;
      final due = _safeDate(today.year, today.month, payDay);
      final reminderDate = _day(due.subtract(const Duration(days: 2)));
      if (!_sameDay(reminderDate, today)) continue;

      final monthKey = DateFormat('yyyyMM').format(today);
      final dedupe = 'staff_due_${s.id}_$monthKey';
      if (await _alreadySent(dedupe)) continue;

      await _notificationScheduler.showNow(
        id: _notificationId('staff_${s.id}_$monthKey'),
        title: 'Salary Due Soon',
        body: '${s.name} salary is due in 2 days (day ${s.payDayLabel}).',
        payload: 'staff:${s.id}',
      );
      await _notificationLogLocal.insert(
        type: 'urgent',
        title: 'Salary Due: ${s.name}',
        subtitle: '${s.jobTitle} - due in 2 days',
        actionLabel: 'Open Staff',
        payload: 'staff:${s.id}',
      );
      await _markSent(dedupe);
    }
  }

  Future<void> _handleTenantPaymentReminders(DateTime today) async {
    final tenants = await _tenantLocal.getAllNewestFirst();
    for (final t in tenants) {
      final leaseEnd = _parseDate(t.leaseEndIso);
      if (leaseEnd == null) continue;
      final firstReminder = _day(leaseEnd.subtract(const Duration(days: 30)));
      if (today.isBefore(firstReminder) || today.isAfter(leaseEnd)) continue;

      final isFirst = _sameDay(today, firstReminder);
      final isWeekly = !isFirst && today.difference(firstReminder).inDays % 7 == 0;
      if (!isFirst && !isWeekly) continue;

      final dateKey = DateFormat('yyyyMMdd').format(today);
      final dedupe = 'tenant_pay_${t.id}_$dateKey';
      if (await _alreadySent(dedupe)) continue;

      final daysLeft = leaseEnd.difference(today).inDays;
      await _notificationScheduler.showNow(
        id: _notificationId('tenant_${t.id}_$dateKey'),
        title: 'Tenant Payment Reminder',
        body: '${t.tenantName} payment due reminder. Lease ends in $daysLeft day(s).',
        payload: 'tenant:${t.id}',
      );
      await _notificationLogLocal.insert(
        type: 'urgent',
        title: 'Payment Reminder: ${t.tenantName}',
        subtitle: 'Lease ends in $daysLeft day(s) at ${t.propertyLabel}',
        actionLabel: 'Open Ledger',
        payload: 'tenant:${t.id}',
      );
      await _markSent(dedupe);
    }
  }

  Future<void> _handleMaintenanceReminders(DateTime today) async {
    final tasks = await _maintenanceLocal.getAllNewestFirst();
    for (final m in tasks) {
      final scheduled = _parseDateTime(m.scheduledDateIso);
      if (scheduled == null) continue;
      final reminderDate = _day(scheduled.subtract(const Duration(days: 1)));
      if (!_sameDay(reminderDate, today)) continue;

      final dateKey = DateFormat('yyyyMMdd').format(reminderDate);
      final dedupe = 'maintenance_${m.id}_$dateKey';
      if (await _alreadySent(dedupe)) continue;

      await _notificationScheduler.showNow(
        id: _notificationId('maintenance_${m.id}_$dateKey'),
        title: 'Maintenance Due Tomorrow',
        body: '${m.category} at ${m.propertyLabel} is scheduled tomorrow.',
        payload: 'maintenance:${m.id}',
      );
      await _notificationLogLocal.insert(
        type: 'maintenance',
        title: m.category,
        subtitle: '${m.propertyLabel} - scheduled tomorrow',
        actionLabel: 'Open Maintenance',
        payload: 'maintenance:${m.id}',
      );
      await _markSent(dedupe);
    }
  }

  Future<bool> _alreadySent(String key) {
    return _preferenceManager.getBool(key, defaultValue: false);
  }

  Future<void> _markSent(String key) {
    return _preferenceManager.setBool(key, true);
  }

  int _notificationId(String source) {
    return source.hashCode.abs() % 2147483647;
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _safeDate(int year, int month, int day) {
    final nextMonthFirst = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDay = nextMonthFirst.subtract(const Duration(days: 1)).day;
    final normalizedDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, normalizedDay);
  }

  DateTime? _parseDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDateTime(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
