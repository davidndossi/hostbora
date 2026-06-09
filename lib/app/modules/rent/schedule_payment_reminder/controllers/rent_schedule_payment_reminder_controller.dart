import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/rent_payment_reminder_local_data_source.dart';
import '../../../../data/local/db/scheduled_whatsapp_local_data_source.dart';
import '../../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../../../data/local/preference/preference_manager.dart';
import '../../../../data/local/service/local_notification_scheduler_service.dart';
import '../../../../data/local/db/client_event_local_data_source.dart';
import '../../../../data/model/schedule_payment_reminder_request.dart';
import '../../../../data/repository/app_repository.dart';
import '../../../host_calendar/controllers/host_calendar_controller.dart';

class ReminderTemplateOption {
  const ReminderTemplateOption({
    required this.id,
    required this.name,
    required this.body,
    required this.meta,
  });

  final String id;
  final String name;
  final String body;
  final String meta;
}

class RentSchedulePaymentReminderController extends BaseController {
  static const _smsTemplatesKey = 'rent_sms_payment_reminder_templates';

  final tenantName = ''.obs;
  final propertyLine = ''.obs;
  final balanceTsh = 400000.obs;

  final reminderDate = Rxn<DateTime>();
  final reminderTime = Rxn<TimeOfDay>();

  final pushEnabled = true.obs;
  final whatsappEnabled = true.obs;
  final emailEnabled = false.obs;
  final messageDraft = ''.obs;

  final whatsappTemplates = <ReminderTemplateOption>[].obs;
  final smsTemplates = <ReminderTemplateOption>[].obs;
  final selectedWhatsappTemplateId = RxnString();
  final selectedSmsTemplateId = RxnString();
  final messageController = TextEditingController();
  Timer? _draftSaveDebounce;

  final _paymentReminderLocal = Get.find<RentPaymentReminderLocalDataSource>();
  final _scheduledWhatsappLocal = ScheduledWhatsappLocalDataSource();
  final _whatsappTemplateLocal =
      Get.find<RentWhatsappTemplateLocalDataSource>();
  final _preferenceManager = Get.find<PreferenceManager>(
    tag: (PreferenceManager).toString(),
  );
  final _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();
  final _notificationScheduler = Get.find<LocalNotificationSchedulerService>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  String _recipientPhone = '';

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: 'Tsh ',
    decimalDigits: 0,
  );
  static final DateFormat _dateDisplay = DateFormat('dd/MM/yyyy');

  @override
  void onInit() {
    super.onInit();
    tenantName.value = Get.parameters['name'] ?? '';
    propertyLine.value = Get.parameters['property'] ?? '';
    _recipientPhone = Get.parameters['phone']?.trim() ?? '';
    final b = Get.parameters['balance'];
    if (b != null && b.isNotEmpty) {
      final parsed = int.tryParse(b);
      if (parsed != null) balanceTsh.value = parsed;
    }
    messageController.addListener(() {
      messageDraft.value = messageController.text;
      _queueDraftAutosave();
    });
    _loadSavedTemplates();
  }

  @override
  void onClose() {
    _draftSaveDebounce?.cancel();
    messageController.dispose();
    super.onClose();
  }

  String get displayTenantName =>
      tenantName.value.isEmpty ? '' : tenantName.value;

  /// Short property label for caps line (e.g. SEA VIEW APARTMENT).
  String get displayPropertyCaps {
    final p = propertyLine.value;
    if (p.isEmpty) return 'N/A';
    final i = p.indexOf(',');
    final short = i > 0 ? p.substring(0, i).trim() : p.trim();
    return short.toUpperCase();
  }

  /// Same segment as rent host calendar property filter (suite if composed, else location).
  String get calendarPropertyFilterLabel {
    final line = propertyLine.value.trim();
    if (line.isEmpty) return displayPropertyTitle.trim();
    final comma = line.indexOf(',');
    final beforeComma = comma > 0 ? line.substring(0, comma).trim() : line;
    const sep = ' · ';
    if (beforeComma.contains(sep)) {
      return beforeComma.split(sep).last.trim();
    }
    return beforeComma.isNotEmpty ? beforeComma : displayPropertyTitle.trim();
  }

  /// Title case for message body (e.g. Sea View Apartment).
  String get displayPropertyTitle {
    final p = propertyLine.value;
    if (p.isEmpty) return 'N/A';
    final i = p.indexOf(',');
    final short = i > 0 ? p.substring(0, i).trim() : p.trim();
    if (short.isEmpty) return 'N/A';
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
    return d == null ? 'dd/MM/yyyy' : _dateDisplay.format(d);
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

  String get defaultReminderTemplate => _isSw
      ? 'Habari {tenantName}, nakukumbusha kuwa salio lako la {balance} kwa {property} linatakiwa kulipwa tarehe {dueDate}.'
      : 'Hello {tenantName}, a friendly reminder that your balance of {balance} for {property} is due on {dueDate}.';

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String resolveTemplate(String template) {
    final firstName = displayTenantName.trim().isEmpty
        ? (_isSw ? 'Mpangaji' : 'Tenant')
        : displayTenantName.split(RegExp(r'\s+')).first;
    return template
        .replaceAll('{tenantName}', firstName)
        .replaceAll('{balance}', formattedBalance)
        .replaceAll('{property}', displayPropertyTitle)
        .replaceAll('{dueDate}', previewDateToken);
  }

  Future<void> _loadSavedTemplates() async {
    try {
      final waRows = await _whatsappTemplateLocal.getAllNewestFirst();
      final waOptions = waRows
          .where((e) => e.bodyText.trim().isNotEmpty)
          .map(
            (e) => ReminderTemplateOption(
              id: e.id.toString(),
              name: e.name,
              body: e.bodyText,
              meta: WaTemplateStatus.label(e.status),
            ),
          )
          .toList();
      whatsappTemplates.assignAll(waOptions);
      if (waOptions.isEmpty) {
        selectedWhatsappTemplateId.value = null;
      } else if (!waOptions.any(
        (e) => e.id == selectedWhatsappTemplateId.value,
      )) {
        selectedWhatsappTemplateId.value = waOptions.first.id;
      }

      final smsRaw = await _preferenceManager.getStringList(_smsTemplatesKey);
      final smsOptions = smsRaw
          .map((e) => _decodeSmsTemplate(e))
          .whereType<ReminderTemplateOption>()
          .toList();
      smsTemplates.assignAll(smsOptions);
      if (smsOptions.isEmpty) {
        selectedSmsTemplateId.value = null;
      } else if (!smsOptions.any((e) => e.id == selectedSmsTemplateId.value)) {
        selectedSmsTemplateId.value = smsOptions.first.id;
      }
    } catch (_) {
      whatsappTemplates.clear();
      smsTemplates.clear();
    }

    final savedDraft = await _loadSavedDraftMessage();
    final initial = savedDraft.trim().isNotEmpty
        ? savedDraft
        : whatsappTemplates.isNotEmpty
        ? resolveTemplate(whatsappTemplates.first.body)
        : resolveTemplate(defaultReminderTemplate);
    if (messageController.text.trim().isEmpty) {
      messageController.text = initial;
      messageDraft.value = initial;
    }
  }

  String get _draftStorageKey =>
      'rent_payment_reminder_draft_${_slug(displayTenantName)}_${_slug(propertyLine.value)}';

  String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  void _queueDraftAutosave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 350), () async {
      await _saveDraftMessage(messageController.text);
    });
  }

  Future<void> _saveDraftMessage(String value) async {
    await _preferenceManager.setString(_draftStorageKey, value.trim());
  }

  Future<String> _loadSavedDraftMessage() async {
    return _preferenceManager.getString(_draftStorageKey, defaultValue: '');
  }

  Future<void> _clearSavedDraftMessage() async {
    await _preferenceManager.remove(_draftStorageKey);
  }

  ReminderTemplateOption? _decodeSmsTemplate(String raw) {
    final parts = raw.split('|||');
    if (parts.length < 2) return null;
    final name = parts[0].trim();
    final body = parts.sublist(1).join('|||').trim();
    if (name.isEmpty || body.isEmpty) return null;
    return ReminderTemplateOption(
      id: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      name: name,
      body: body,
      meta: 'SMS',
    );
  }

  Future<void> applyWhatsappTemplate(String? id) async {
    if (id == null || id.isEmpty) return;
    selectedWhatsappTemplateId.value = id;
    ReminderTemplateOption? option;
    for (final t in whatsappTemplates) {
      if (t.id == id) {
        option = t;
        break;
      }
    }
    if (option == null) return;
    final resolved = resolveTemplate(option.body);
    messageController.text = resolved;
    messageDraft.value = resolved;
  }

  Future<void> applySmsTemplate(String? id) async {
    if (id == null || id.isEmpty) return;
    selectedSmsTemplateId.value = id;
    ReminderTemplateOption? option;
    for (final t in smsTemplates) {
      if (t.id == id) {
        option = t;
        break;
      }
    }
    if (option == null) return;
    final resolved = resolveTemplate(option.body);
    messageController.text = resolved;
    messageDraft.value = resolved;
  }

  Future<void> addWhatsappTemplate({
    required String name,
    required String body,
  }) async {
    final cleanedName = _normalizeTemplateName(name);
    if (cleanedName.isEmpty) {
      showErrorMessage(
        _isSw ? 'Weka jina la kiolezo' : 'Template name is required',
      );
      return;
    }
    if (body.trim().isEmpty) {
      showErrorMessage(
        _isSw ? 'Weka ujumbe wa kiolezo' : 'Template message is required',
      );
      return;
    }
    try {
      final id = await _whatsappTemplateLocal.insert(
        name: cleanedName,
        category: WaTemplateCategory.utility,
        language: _isSw ? 'sw' : 'en_US',
        headerType: WaTemplateHeaderType.none,
        headerText: '',
        bodyText: body.trim(),
        footerText: '',
        buttons: const [],
        sampleVariables: const [],
        status: WaTemplateStatus.draft,
      );
      await _loadSavedTemplates();
      await applyWhatsappTemplate(id.toString());
      showSuccessMessage(
        _isSw ? 'Kiolezo cha WhatsApp kimeongezwa' : 'WhatsApp template added',
      );
    } catch (_) {
      showErrorMessage(
        _isSw
            ? 'Imeshindikana kuhifadhi. Tumia jina tofauti.'
            : 'Failed to save template. Try a different name.',
      );
    }
  }

  Future<void> addSmsTemplate({
    required String name,
    required String body,
  }) async {
    final cleanedName = name.trim();
    final cleanedBody = body.trim();
    if (cleanedName.isEmpty || cleanedBody.isEmpty) {
      showErrorMessage(
        _isSw
            ? 'Jina na ujumbe wa SMS vinahitajika'
            : 'SMS template name and message are required',
      );
      return;
    }
    final existing = await _preferenceManager.getStringList(_smsTemplatesKey);
    final entry = '$cleanedName|||$cleanedBody';
    final updated = [
      ...existing.where((e) => !e.startsWith('$cleanedName|||')),
      entry,
    ];
    await _preferenceManager.setStringList(_smsTemplatesKey, updated);
    await _loadSavedTemplates();
    final id = cleanedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await applySmsTemplate(id);
    showSuccessMessage(
      _isSw ? 'Kiolezo cha SMS kimeongezwa' : 'SMS template added',
    );
  }

  String _normalizeTemplateName(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: reminderDate.value ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
      locale: const Locale('en', 'GB'),
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
      propertyLabel: calendarPropertyFilterLabel,
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

    if (whatsappEnabled.value && _recipientPhone.isNotEmpty) {
      final msg = messageController.text.trim().isEmpty
          ? resolveTemplate(defaultReminderTemplate)
          : resolveTemplate(messageController.text.trim());
      await _scheduledWhatsappLocal.insert(
        workspace: 'rent',
        recipientPhone: _recipientPhone,
        recipientLabel: displayTenantName,
        messageBody: msg,
        scheduledAtIso: reminderAt.toIso8601String(),
        notificationId: notificationId,
      );
    }

    final reminderRequest = SchedulePaymentReminderRequest(
      tenantName: displayTenantName,
      propertyLabel: calendarPropertyFilterLabel,
      balanceTsh: balanceTsh.value,
      reminderAtIso: reminderAt.toIso8601String(),
      pushEnabled: pushEnabled.value,
      whatsappEnabled: whatsappEnabled.value,
      emailEnabled: emailEnabled.value,
      notificationId: notificationId,
    );

    try {
      await _repository.schedulePaymentReminder(reminderRequest);
      await _paymentReminderLocal.updateSyncStatus(localId, 'synced');
      hapticPrimaryConfirm();
      showSuccessMessage('Saved offline and online. Reminder scheduled.');
    } catch (_) {
      await _syncQueue.enqueue(
        entityType: 'rent_payment_reminder',
        operation: 'create',
        payloadJson: jsonEncode({
          'localId': localId,
          ...reminderRequest.toJson(),
        }),
      );
      hapticPrimaryConfirm();
      showSuccessMessage(
        'Saved offline. Will sync when internet is available.',
      );
    }

    // Write reminder_sent event to client story
    unawaited(
      Get.find<ClientEventLocalDataSource>().insert(
        phoneNumber: _recipientPhone,
        clientName: displayTenantName,
        propertyLabel: calendarPropertyFilterLabel,
        workspace: 'rent',
        eventType: ClientEventType.reminderSent,
        metadata: {
          'channel': whatsappEnabled.value ? 'whatsapp' : 'push',
          'scheduledAt': reminderAt.toIso8601String(),
          'balanceTsh': balanceTsh.value,
        },
      ),
    );

    await HostCalendarController.refreshIfRegistered();
    await _clearSavedDraftMessage();
    Get.back();
  }
}
