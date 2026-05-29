import 'dart:async';

import 'package:get/get.dart';

import '../../model/send_sms_request.dart';
import '../../model/send_whatsapp_template_request.dart';
import '../../repository/app_repository.dart';
import '../db/scheduled_whatsapp_local_data_source.dart';

/// Fires scheduled WhatsApp API sends when their time is due (rent + BnB).
class ScheduledWhatsappDispatchService extends GetxService {
  ScheduledWhatsappDispatchService({
    ScheduledWhatsappLocalDataSource? local,
    AppRepository? repository,
  })  : _local = local ?? ScheduledWhatsappLocalDataSource(),
        _repository = repository ?? Get.find(tag: (AppRepository).toString());

  final ScheduledWhatsappLocalDataSource _local;
  final AppRepository _repository;

  Timer? _timer;
  bool _running = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(runNow());
    });
    unawaited(runNow());
  }

  Future<void> runNow() async {
    if (_running) return;
    _running = true;
    try {
      final due = await _local.getDueUnsent();
      for (final row in due) {
        final phone = row.recipientPhone.trim();
        if (phone.isEmpty) {
          await _local.markSent(row.id);
          continue;
        }
        try {
          final ok = row.templateName.trim().isNotEmpty
              ? await _sendTemplate(row, phone)
              : await _sendText(row, phone);
          if (ok) await _local.markSent(row.id);
        } catch (_) {
          // Retry on next tick.
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<bool> _sendText(ScheduledWhatsappRecord row, String phone) async {
    final res = await _repository.sendWhatsApp(
      SendSmsRequest(phoneNumber: phone, message: row.messageBody.trim()),
    );
    return res.responseCode == '0';
  }

  Future<bool> _sendTemplate(ScheduledWhatsappRecord row, String phone) async {
    final res = await _repository.sendWhatsAppTemplate(
      SendWhatsAppTemplateRequest(
        phoneNumber: phone,
        templateName: row.templateName.trim(),
        languageCode: row.languageCode.trim().isEmpty
            ? 'en_US'
            : row.languageCode.trim(),
        bodyParameters: row.bodyParameters,
        headerParameters: row.headerParameters,
      ),
    );
    return res.responseCode == '0';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
