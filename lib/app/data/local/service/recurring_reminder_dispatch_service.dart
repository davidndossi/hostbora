import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/send_sms_request.dart';
import '../../repository/app_repository.dart';
import '../db/client_event_local_data_source.dart';
import '../db/recurring_reminder_local_data_source.dart';
import '../db/scheduled_sms_local_data_source.dart';
import '../db/scheduled_whatsapp_local_data_source.dart';
import 'local_notification_scheduler_service.dart';
import 'reminder_recurrence_util.dart';
import 'currency_service.dart';

/// Dispatches due recurring reminders locally (WhatsApp, SMS, push) and advances schedule.
class RecurringReminderDispatchService extends GetxService {
  RecurringReminderDispatchService({
    required RecurringReminderLocalDataSource recurringLocal,
    required ScheduledWhatsappLocalDataSource whatsappLocal,
    required ScheduledSmsLocalDataSource smsLocal,
    required LocalNotificationSchedulerService notificationScheduler,
    required AppRepository repository,
  })  : _recurringLocal = recurringLocal,
        _whatsappLocal = whatsappLocal,
        _smsLocal = smsLocal,
        _notificationScheduler = notificationScheduler,
        _repository = repository;

  final RecurringReminderLocalDataSource _recurringLocal;
  final ScheduledWhatsappLocalDataSource _whatsappLocal;
  final ScheduledSmsLocalDataSource _smsLocal;
  final LocalNotificationSchedulerService _notificationScheduler;
  final AppRepository _repository;

  Timer? _timer;
  bool _running = false;

  String _formatBalance(num amount) {
    if (Get.isRegistered<CurrencyService>()) {
      return Get.find<CurrencyService>().formatBase(amount);
    }
    return '${CurrencyService.symbolFor(CurrencyService.defaultBaseCurrency)}${NumberFormat('#,###', 'en_US').format(amount.round())}';
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(runNow());
    });
    Timer(const Duration(seconds: 35), () => unawaited(runNow()));
  }

  Future<void> runNow() async {
    if (_running) return;
    _running = true;
    try {
      final due = await _recurringLocal.getDueActive();
      for (final row in due) {
        if (!_shouldSend(row)) continue;
        final message = _resolveMessage(row);
        final phone = row.recipientPhone.trim();
        final notificationId =
            DateTime.now().millisecondsSinceEpoch % 2147483647;
        final nowIso = DateTime.now().toIso8601String();

        if (row.pushEnabled) {
          await _notificationScheduler.showNow(
            id: notificationId,
            title: 'Payment Reminder',
            body: '${row.tenantName} — ${row.reminderType}',
            payload: 'recurring_reminder:${row.id}',
          );
        }
        if (row.whatsappEnabled && phone.isNotEmpty) {
          try {
            final res = await _repository.sendWhatsApp(
              SendSmsRequest(phoneNumber: phone, message: message),
            );
            if (res.responseCode != '0') {
              await _whatsappLocal.insert(
                workspace: 'rent',
                recipientPhone: phone,
                recipientLabel: row.tenantName,
                messageBody: message,
                scheduledAtIso: nowIso,
                notificationId: notificationId,
              );
            }
          } catch (_) {
            await _whatsappLocal.insert(
              workspace: 'rent',
              recipientPhone: phone,
              recipientLabel: row.tenantName,
              messageBody: message,
              scheduledAtIso: nowIso,
              notificationId: notificationId,
            );
          }
        }
        if (row.smsEnabled && phone.isNotEmpty) {
          try {
            final res = await _repository.sendSms(
              SendSmsRequest(phoneNumber: phone, message: message),
            );
            if (res.responseCode != '0') {
              await _smsLocal.insert(
                recipientPhone: phone,
                recipientLabel: row.tenantName,
                messageBody: message,
                scheduledAtIso: nowIso,
                notificationId: notificationId,
              );
            }
          } catch (_) {
            await _smsLocal.insert(
              recipientPhone: phone,
              recipientLabel: row.tenantName,
              messageBody: message,
              scheduledAtIso: nowIso,
              notificationId: notificationId,
            );
          }
        }

        await _logEvent(row, message);
        final currentRun = DateTime.tryParse(row.nextRunAtIso) ?? DateTime.now();
        final nextRun = ReminderRecurrenceUtil.advanceAfterSend(
          recurrence: row.recurrence,
          timeOfDay: row.timeOfDay,
          currentRun: currentRun,
        );
        await _recurringLocal.updateNextRun(
          id: row.id,
          nextRunAtIso: nextRun.toIso8601String(),
          lastSentAtIso: nowIso,
          active: RecurrenceRuleCodec.isRecurring(row.recurrence),
        );
      }
    } finally {
      _running = false;
    }
  }

  bool _shouldSend(RecurringReminderRecord row) {
    if (!row.active) return false;
    if (row.leaseEndIso.trim().isEmpty) return true;
    final leaseEnd = DateTime.tryParse(row.leaseEndIso);
    if (leaseEnd == null) return true;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (!day.isAfter(leaseEnd)) return true;
    if (row.continueAfterLeaseExpiry == null) return false;
    return row.continueAfterLeaseExpiry == 1;
  }

  String _resolveMessage(RecurringReminderRecord row) {
    final template = row.messageTemplate.trim().isEmpty
        ? _defaultTemplate(row.reminderType)
        : row.messageTemplate;
    final firstName = row.tenantName.trim().isEmpty
        ? 'Tenant'
        : row.tenantName.split(RegExp(r'\s+')).first;
    return template
        .replaceAll('{tenantName}', firstName)
        .replaceAll('{balance}', _formatBalance(row.amountTsh))
        .replaceAll('{property}', row.propertyLabel)
        .replaceAll('{dueDate}', ReminderRecurrenceUtil.formatDueDate(row.recurrence))
        .replaceAll('{reminderType}', row.customTypeLabel.isNotEmpty
            ? row.customTypeLabel
            : row.reminderType.replaceAll('_', ' '));
  }

  String _defaultTemplate(String type) {
    if (type == 'service_charge') {
      return 'Hello {tenantName}, a friendly reminder that your service charge of {balance} for {property} is due on {dueDate}.';
    }
    return 'Hello {tenantName}, a friendly reminder that your rent balance of {balance} for {property} is due on {dueDate}.';
  }

  Future<void> _logEvent(RecurringReminderRecord row, String message) async {
    try {
      await Get.find<ClientEventLocalDataSource>().insert(
        phoneNumber: row.recipientPhone,
        clientName: row.tenantName,
        propertyLabel: row.propertyLabel,
        workspace: 'rent',
        eventType: ClientEventType.reminderSent,
        metadata: {
          'channel': 'recurring',
          'reminderType': row.reminderType,
          'recurrence': row.recurrence,
          'messagePreview': message.length > 120
              ? '${message.substring(0, 120)}…'
              : message,
        },
      );
    } catch (_) {}
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
