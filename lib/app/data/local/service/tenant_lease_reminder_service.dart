import 'dart:async';

import 'package:get/get.dart';

import '/app/data/local/db/rent_tenant_local_data_source.dart';
import '/app/data/local/preference/preference_manager.dart';
import '/app/data/model/send_sms_request.dart';
import '/app/data/repository/app_repository.dart';

/// Sends one-month-prior lease-end reminders to tenants via WhatsApp/SMS gateway.
class TenantLeaseReminderService extends GetxService {
  static const reminderTemplateKey = 'tenant_whatsapp_reminder_template';
  static const _stampPrefix = 'tenant_one_month_reminder_sent_';

  TenantLeaseReminderService({
    required RentTenantLocalDataSource tenantLocal,
    required PreferenceManager preferenceManager,
    required AppRepository repository,
  })  : _tenantLocal = tenantLocal,
        _preferenceManager = preferenceManager,
        _repository = repository;

  final RentTenantLocalDataSource _tenantLocal;
  final PreferenceManager _preferenceManager;
  final AppRepository _repository;

  Timer? _timer;
  bool _running = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 6), (_) {
      unawaited(runNow());
    });
    unawaited(runNow());
  }

  Future<void> runNow() async {
    if (_running) return;
    _running = true;
    try {
      final tenants = await _tenantLocal.getAllNewestFirst();
      if (tenants.isEmpty) return;

      final template = await _preferenceManager.getString(
        reminderTemplateKey,
        defaultValue: '',
      );

      for (final tenant in tenants) {
        final leaseEnd = _parseIsoDate(tenant.leaseEndIso);
        if (leaseEnd == null) continue;

        final targetDate = DateTime(
          leaseEnd.year,
          leaseEnd.month - 1,
          leaseEnd.day,
        );
        final today = _today();
        if (!_sameDay(targetDate, today)) continue;

        final stampKey = '$_stampPrefix${tenant.id}_${tenant.leaseEndIso}';
        final already = await _preferenceManager.getBool(stampKey, defaultValue: false);
        if (already) continue;

        final msg = template.trim().isNotEmpty
            ? _resolveTemplate(template, tenant)
            : 'Hello ${tenant.tenantName}, this is a reminder that your lease for '
                '${tenant.propertyLabel} ends on ${tenant.leaseEndIso}. '
                'Please prepare your renewal and rent payment.';

        final phone = tenant.phoneNumber.trim();
        if (phone.isEmpty) continue;

        try {
          await _repository.sendSms(
            SendSmsRequest(phoneNumber: phone, message: msg),
          );
          await _preferenceManager.setBool(stampKey, true);
        } catch (_) {
          // Retry next periodic run.
        }
      }
    } finally {
      _running = false;
    }
  }

  String _resolveTemplate(String template, RentTenantRecord tenant) {
    return template
        .replaceAll('{tenantName}', tenant.tenantName)
        .replaceAll('{property}', tenant.propertyLabel)
        .replaceAll('{rentAmount}', tenant.rentAmountValue.round().toString())
        .replaceAll('{rentFrequency}', tenant.rentFrequency)
        .replaceAll('{leaseEnd}', tenant.leaseEndIso)
        .replaceAll('{remainingBalance}', '0');
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _parseIsoDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
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
