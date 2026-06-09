import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/local/db/scheduled_whatsapp_local_data_source.dart';
import '../../../data/local/service/local_notification_scheduler_service.dart';

/// Schedules a WhatsApp API message to a BnB guest at a chosen date/time.
Future<bool> showBnbGuestWhatsappScheduleSheet({
  required String guestName,
  required String guestPhone,
  String initialMessage = '',
  String templateName = '',
  String languageCode = '',
  List<String> bodyParameters = const [],
}) async {
  final isSw = Get.locale?.languageCode == 'sw';
  String t(String en, String sw) => isSw ? sw : en;

  if (guestPhone.trim().isEmpty) {
    Get.snackbar(
      t('Error', 'Hitilafu'),
      t('Guest phone number is required', 'Namba ya mgeni inahitajika'),
    );
    return false;
  }

  final messageController = TextEditingController(text: initialMessage);
  var date = DateTime.now().add(const Duration(hours: 1));
  var time = TimeOfDay.fromDateTime(date);

  final saved = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(t('Schedule WhatsApp', 'Ratiba ya WhatsApp')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${guestName.trim().isEmpty ? guestPhone : guestName} • $guestPhone',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: t('Message', 'Ujumbe'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('Date', 'Tarehe')),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      locale: const Locale('en', 'GB'),
                    );
                    
                    if (picked != null) setState(() => date = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('Time', 'Saa')),
                  subtitle: Text(time.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) setState(() => time = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(t('Cancel', 'Ghairi')),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(t('Schedule', 'Weka ratiba')),
            ),
          ],
        );
      },
    ),
  );
  if (saved != true) {
    messageController.dispose();
    return false;
  }

  final message = messageController.text.trim();
  messageController.dispose();
  if (message.isEmpty && templateName.trim().isEmpty) {
    Get.snackbar(
      t('Error', 'Hitilafu'),
      t('Message is required', 'Ujumbe unahitajika'),
    );
    return false;
  }

  final scheduledAt = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  if (!scheduledAt.isAfter(DateTime.now())) {
    Get.snackbar(
      t('Error', 'Hitilafu'),
      t('Pick a future date and time', 'Chagua tarehe na saa zijazo'),
    );
    return false;
  }

  final notificationId = scheduledAt.millisecondsSinceEpoch % 2147483647;
  final local = ScheduledWhatsappLocalDataSource();
  await local.insert(
    workspace: 'bnb',
    recipientPhone: guestPhone.trim(),
    recipientLabel: guestName.trim(),
    messageBody: message,
    templateName: templateName.trim(),
    languageCode: languageCode.trim(),
    bodyParameters: bodyParameters,
    scheduledAtIso: scheduledAt.toIso8601String(),
    notificationId: notificationId,
  );

  final scheduler = Get.find<LocalNotificationSchedulerService>();
  await scheduler.scheduleOneShot(
    id: notificationId,
    when: scheduledAt,
    title: t('Guest WhatsApp scheduled', 'WhatsApp ya mgeni imeratibiwa'),
    body: t(
      'Message to ${guestName.trim().isEmpty ? guestPhone : guestName} will be sent via WhatsApp Business API.',
      'Ujumbe kwa ${guestName.trim().isEmpty ? guestPhone : guestName} utatumwa kupitia WhatsApp Business API.',
    ),
    payload: 'scheduled_whatsapp:$notificationId',
  );

  return true;
}
