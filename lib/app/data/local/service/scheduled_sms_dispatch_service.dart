import 'dart:async';

import 'package:get/get.dart';

import '../../model/send_sms_request.dart';
import '../../repository/app_repository.dart';
import '../db/scheduled_sms_local_data_source.dart';

/// Fires scheduled SMS API sends when their time is due.
class ScheduledSmsDispatchService extends GetxService {
  ScheduledSmsDispatchService({
    ScheduledSmsLocalDataSource? local,
    AppRepository? repository,
  })  : _local = local ?? ScheduledSmsLocalDataSource(),
        _repository = repository ?? Get.find(tag: (AppRepository).toString());

  final ScheduledSmsLocalDataSource _local;
  final AppRepository _repository;

  Timer? _timer;
  bool _running = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      unawaited(runNow());
    });
    Timer(const Duration(seconds: 30), () => unawaited(runNow()));
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
          final res = await _repository.sendSms(
            SendSmsRequest(phoneNumber: phone, message: row.messageBody.trim()),
          );
          if (res.responseCode == '0') {
            await _local.markSent(row.id);
          }
        } catch (_) {
          // Retry on next tick.
        }
      }
    } finally {
      _running = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
