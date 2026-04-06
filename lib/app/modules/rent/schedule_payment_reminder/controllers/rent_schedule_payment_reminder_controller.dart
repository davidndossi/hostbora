import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../../core/base/base_controller.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_payment_reminder_local_data_source.dart';
import '../../../../data/local/service/local_notification_scheduler_service.dart';
import '../../../../data/model/add_task_request.dart';
import '../../../../data/repository/app_repository.dart';

class RentSchedulePaymentReminderController extends BaseController {
  final tenantName = ''.obs;
  final propertyLine = ''.obs;
  final balanceTsh = 400000.obs;

  final reminderDate = Rxn<DateTime>();
  final reminderTime = Rxn<TimeOfDay>();

  final pushEnabled = true.obs;
  final whatsappEnabled = true.obs;
  final emailEnabled = false.obs;
  final _paymentReminderLocal = Get.find<RentPaymentReminderLocalDataSource>();
  final _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();
  final _notificationScheduler = Get.find<LocalNotificationSchedulerService>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  static final NumberFormat _currency =
      NumberFormat.currency(symbol: 'Tsh ', decimalDigits: 0);
  static final DateFormat _dateDisplay = DateFormat('MM/dd/yyyy');

  @override
  void onInit() {
    super.onInit();
    tenantName.value = Get.parameters['name'] ?? '';
    propertyLine.value = Get.parameters['property'] ?? '';
    final b = Get.parameters['balance'];
    if (b != null && b.isNotEmpty) {
      final parsed = int.tryParse(b);
      if (parsed != null) balanceTsh.value = parsed;
    }
  }

  String get displayTenantName =>
      tenantName.value.isEmpty ? 'Amara Okafor' : tenantName.value;

  /// Short property label for caps line (e.g. SEA VIEW APARTMENT).
  String get displayPropertyCaps {
    final p = propertyLine.value;
    if (p.isEmpty) return 'SEA VIEW APARTMENT';
    final i = p.indexOf(',');
    final short = i > 0 ? p.substring(0, i).trim() : p.trim();
    return short.toUpperCase();
  }

  /// Title case for message body (e.g. Sea View Apartment).
  String get displayPropertyTitle {
    final p = propertyLine.value;
    if (p.isEmpty) return 'Sea View Apartment';
    final i = p.indexOf(',');
    final short = i > 0 ? p.substring(0, i).trim() : p.trim();
    if (short.isEmpty) return 'Sea View Apartment';
    return short
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get formattedBalance => _currency.format(balanceTsh.value);

  String get dateFieldLabel {
    final d = reminderDate.value;
    return d == null ? 'mm/dd/yyyy' : _dateDisplay.format(d);
  }

  String get timeFieldLabel {
    final t = reminderTime.value;
    if (t == null) return '-- : -- --';
    final dt = DateTime(2020, 1, 1, t.hour, t.minute);
    return DateFormat('hh : mm a').format(dt);
  }

  String get previewDateToken {
    final d = reminderDate.value;
    return d == null ? '[Date]' : _dateDisplay.format(d);
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: reminderDate.value ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) reminderDate.value = picked;
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime.value ?? TimeOfDay.now(),
    );
    if (picked != null) reminderTime.value = picked;
  }

  Future<void> scheduleReminder() async {
    final date = reminderDate.value;
    final time = reminderTime.value;
    if (date == null || time == null) {
      showErrorMessage('Please select reminder date and time');
      return;
    }
    if (!pushEnabled.value && !whatsappEnabled.value && !emailEnabled.value) {
      showErrorMessage('Enable at least one notification channel');
      return;
    }

    final reminderAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    final localId = await _paymentReminderLocal.insert(
      tenantName: displayTenantName,
      propertyLabel: displayPropertyTitle,
      balanceTsh: balanceTsh.value,
      reminderAtIso: reminderAt.toIso8601String(),
      pushEnabled: pushEnabled.value,
      whatsappEnabled: whatsappEnabled.value,
      emailEnabled: emailEnabled.value,
      notificationId: notificationId,
      syncStatus: 'pending',
    );

    await _notificationScheduler.scheduleOneShot(
      id: notificationId,
      when: reminderAt,
      title: 'Payment Reminder',
      body: '$displayTenantName - $formattedBalance due',
      payload: 'payment_reminder:$localId',
    );

    final taskRequest = AddTaskRequest(
      title: 'Payment Reminder: $displayTenantName',
      description: 'Balance $formattedBalance for $displayPropertyTitle',
      dueDate: DateFormat('yyyy-MM-dd').format(reminderAt),
    );

    try {
      await _repository.addTask(taskRequest);
      await _paymentReminderLocal.updateSyncStatus(localId, 'synced');
      showSuccessMessage('Saved offline and online. Reminder scheduled.');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'rent_payment_reminder',
        operation: 'create',
        payloadJson: jsonEncode({
          'localId': localId,
          'title': taskRequest.title,
          'description': taskRequest.description,
          'dueDate': taskRequest.dueDate,
        }),
      );
      showSuccessMessage('Saved offline. Will sync when internet is available.');
    }
    Get.back();
  }
}
