import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/utils/haptic_feedback_util.dart';
import '../../../../data/local/db/offline_sync_queue_local_data_source.dart';
import '../../../../data/local/db/property_local_data_source.dart';
import '../../../../data/local/db/recurring_reminder_local_data_source.dart';
import '../../../../data/local/db/rent_tenant_charge_local_data_source.dart';
import '../../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../../../data/local/db/tenant_local_data_source.dart';
import '../../../../data/local/service/reminder_recurrence_util.dart';
import '../../../../data/local/service/reminder_types_service.dart';
import '../../../../data/model/recurring_reminder_request.dart';
import '../../../../data/repository/app_repository.dart';

class RentRecurringRemindersController extends BaseController {
  final propertyScope = 'all'.obs;
  final selectedPropertyRef = ''.obs;
  final selectedReminderTypeId =
      ReminderTypesService.defaultPayRentId.obs;
  final recurrencePreset = ReminderRecurrencePreset.monthlyFirst.obs;
  final customRecurrenceMode = CustomRecurrenceMode.everyNDays.obs;
  final customRecurrenceValue = 14.obs;
  final customIntervalController = TextEditingController(text: '14');
  final reminderTime = Rx<TimeOfDay>(const TimeOfDay(hour: 9, minute: 0));
  final pushEnabled = true.obs;
  final whatsappEnabled = true.obs;
  final smsEnabled = false.obs;
  final customAmountTsh = 0.obs;
  final scheduling = false.obs;

  final properties = <PropertyRecord>[].obs;
  final whatsappTemplates = <_TemplateOption>[].obs;
  final selectedTemplateId = RxnString();
  final messageController = TextEditingController();

  final _propertyLocal = Get.find<PropertyLocalDataSource>();
  final _tenantLocal = Get.find<TenantLocalDataSource>();
  final _chargeLocal = Get.find<RentTenantChargeLocalDataSource>();
  final _recurringLocal = Get.find<RecurringReminderLocalDataSource>();
  final _whatsappTemplateLocal =
      Get.find<RentWhatsappTemplateLocalDataSource>();
  final _syncQueue = Get.find<OfflineSyncQueueLocalDataSource>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());
  late final ReminderTypesService _typesService;

  bool get _isSw => Get.locale?.languageCode == 'sw';
  String _t(String en, String sw) => _isSw ? sw : en;

  @override
  void onInit() {
    super.onInit();
    _typesService = Get.find<ReminderTypesService>();
    final tenantIdParam = Get.parameters['tenantId']?.trim() ?? '';
    if (tenantIdParam.isNotEmpty) {
      propertyScope.value = 'property';
      _singleTenantId = int.tryParse(tenantIdParam);
      final propertyRef = Get.parameters['propertyRef']?.trim() ?? '';
      if (propertyRef.isNotEmpty) selectedPropertyRef.value = propertyRef;
    }
    _loadProperties();
    _loadTemplates();
    _applyDefaultMessage();
  }

  int? _singleTenantId;

  @override
  void onClose() {
    messageController.dispose();
    customIntervalController.dispose();
    super.onClose();
  }

  String get recurrenceApiValue {
    if (recurrencePreset.value == ReminderRecurrencePreset.custom) {
      final n = int.tryParse(customIntervalController.text.trim()) ??
          customRecurrenceValue.value;
      return RecurrenceRuleCodec.encodeCustom(
        mode: customRecurrenceMode.value,
        value: n,
      );
    }
    return recurrencePreset.value.apiValue;
  }

  void onRecurrencePresetChanged(ReminderRecurrencePreset? preset) {
    if (preset == null) return;
    recurrencePreset.value = preset;
    if (preset == ReminderRecurrencePreset.custom &&
        customIntervalController.text.trim().isEmpty) {
      customIntervalController.text = '${customRecurrenceValue.value}';
    }
  }

  Future<void> _loadProperties() async {
    final rows = await _propertyLocal.getAllByWorkspace(
      userId: '',
      workspaceType: 'rent',
    );
    properties.assignAll(rows);
    if (rows.isNotEmpty && selectedPropertyRef.value.isEmpty) {
      selectedPropertyRef.value = rows.first.propertyRef;
    }
  }

  Future<void> _loadTemplates() async {
    final rows = await _whatsappTemplateLocal.getAllNewestFirst();
    whatsappTemplates.assignAll(
      rows
          .where((e) => e.bodyText.trim().isNotEmpty)
          .map(
            (e) => _TemplateOption(
              id: e.id.toString(),
              name: e.name,
              body: e.bodyText,
            ),
          ),
    );
    if (whatsappTemplates.isNotEmpty) {
      selectedTemplateId.value = whatsappTemplates.first.id;
    }
  }

  void _applyDefaultMessage() {
    if (messageController.text.trim().isNotEmpty) return;
    messageController.text = _defaultTemplate();
  }

  String _defaultTemplate() {
    if (selectedReminderTypeId.value ==
        ReminderTypesService.defaultServiceChargeId) {
      return _t(
        'Hello {tenantName}, a friendly reminder that your service charge of {balance} for {property} is due on {dueDate}.',
        'Habari {tenantName}, nakukumbusha ada ya huduma ya {balance} kwa {property} inatakiwa kulipwa tarehe {dueDate}.',
      );
    }
    return _t(
      'Hello {tenantName}, a friendly reminder that your rent balance of {balance} for {property} is due on {dueDate}.',
      'Habari {tenantName}, nakukumbusha salio la kodi la {balance} kwa {property} linatakiwa kulipwa tarehe {dueDate}.',
    );
  }

  void onReminderTypeChanged(String? id) {
    if (id == null) return;
    selectedReminderTypeId.value = id;
    messageController.text = _defaultTemplate();
  }

  void applyTemplate(String? id) {
    if (id == null) return;
    selectedTemplateId.value = id;
    final option = whatsappTemplates.firstWhereOrNull((e) => e.id == id);
    if (option != null) messageController.text = option.body;
  }

  Future<void> addCustomReminderType(String name) async {
    await _typesService.addCustomType(name);
    selectedReminderTypeId.value = _typesService.allTypes.last.id;
  }

  Future<void> saveMessageAsTemplate(String name) async {
    final cleaned = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    if (cleaned.isEmpty) {
      showErrorMessage(_t('Template name required', 'Jina la kiolezo linahitajika'));
      return;
    }
    await _whatsappTemplateLocal.insert(
      name: cleaned,
      category: WaTemplateCategory.utility,
      language: _isSw ? 'sw' : 'en_US',
      headerType: WaTemplateHeaderType.none,
      headerText: '',
      bodyText: messageController.text.trim(),
      footerText: '',
      buttons: const [],
      sampleVariables: const [],
      status: WaTemplateStatus.draft,
    );
    await _loadTemplates();
    showSuccessMessage(_t('Template saved', 'Kiolezo kimehifadhiwa'));
  }

  Future<int> _amountForTenant(TenantRecord tenant) async {
    if (customAmountTsh.value > 0) return customAmountTsh.value;
    if (selectedReminderTypeId.value ==
        ReminderTypesService.defaultServiceChargeId) {
      final charges = await _chargeLocal.getAllNewestFirst();
      final sum = charges
          .where(
            (c) =>
                c.chargeType == 'Service Charge' &&
                (c.propertyLabel == tenant.propertyLabel ||
                    tenant.propertyRef.isEmpty),
          )
          .fold<double>(0, (a, b) => a + b.amountTsh);
      if (sum > 0) return sum.round();
    }
    return tenant.rentAmountValue.round();
  }

  List<TenantRecord> _targetTenants(List<TenantRecord> all) {
    final withPhone =
        all.where((t) => t.phoneNumber.trim().isNotEmpty).toList();
    if (_singleTenantId != null) {
      return withPhone.where((t) => t.id == _singleTenantId).toList();
    }
    if (propertyScope.value == 'all') return withPhone;
    return withPhone
        .where((t) => t.propertyRef == selectedPropertyRef.value)
        .toList();
  }

  Future<void> scheduleReminders() async {
    if (scheduling.value) return;
    final template = messageController.text.trim();
    if (template.isEmpty) {
      showErrorMessage(_t('Message is required', 'Ujumbe unahitajika'));
      return;
    }
    if (!pushEnabled.value && !whatsappEnabled.value && !smsEnabled.value) {
      showErrorMessage(
        _t('Enable at least one channel', 'Washa angalau njia moja'),
      );
      return;
    }
    if (recurrencePreset.value == ReminderRecurrencePreset.custom) {
      final n = int.tryParse(customIntervalController.text.trim());
      if (n == null || n < 1) {
        showErrorMessage(
          _t('Enter a valid custom interval', 'Weka marudio sahihi'),
        );
        return;
      }
    }

    scheduling.value = true;
    try {
      final tenants = _targetTenants(await _tenantLocal.getAllNewestFirst());
      if (tenants.isEmpty) {
        showErrorMessage(
          _t('No tenants with phone numbers found', 'Hakuna wapangaji wenye simu'),
        );
        return;
      }

      final timeOfDay =
          '${reminderTime.value.hour.toString().padLeft(2, '0')}:${reminderTime.value.minute.toString().padLeft(2, '0')}';
      final nextRun = ReminderRecurrenceUtil.computeNextRun(
        recurrence: recurrenceApiValue,
        timeOfDay: timeOfDay,
      );
      final type = selectedReminderTypeId.value;
      final customLabel = _typesService.labelForId(type);
      final apiRequests = <RecurringReminderRequest>[];
      final localIds = <int>[];

      for (final tenant in tenants) {
        final amount = await _amountForTenant(tenant);
        final localId = await _recurringLocal.insert(
          tenantId: tenant.id,
          tenantName: tenant.tenantName,
          propertyRef: tenant.propertyRef,
          propertyLabel: tenant.propertyLabel,
          recipientPhone: tenant.phoneNumber.trim(),
          reminderType: type,
          customTypeLabel: customLabel,
          amountTsh: amount,
          messageTemplate: template,
          recurrence: recurrenceApiValue,
          timeOfDay: timeOfDay,
          pushEnabled: pushEnabled.value,
          whatsappEnabled: whatsappEnabled.value,
          smsEnabled: smsEnabled.value,
          active: true,
          leaseEndIso: tenant.leaseEndIso,
          nextRunAtIso: nextRun.toIso8601String(),
        );
        apiRequests.add(
          RecurringReminderRequest(
            tenantId: '${tenant.id}',
            tenantName: tenant.tenantName,
            propertyRef: tenant.propertyRef,
            propertyLabel: tenant.propertyLabel,
            recipientPhone: tenant.phoneNumber.trim(),
            reminderType: type,
            customTypeLabel: customLabel,
            amountTsh: amount,
            messageTemplate: template,
            recurrence: recurrenceApiValue,
            timeOfDay: timeOfDay,
            pushEnabled: pushEnabled.value,
            whatsappEnabled: whatsappEnabled.value,
            smsEnabled: smsEnabled.value,
            leaseEndIso: tenant.leaseEndIso,
            nextRunAtIso: nextRun.toIso8601String(),
          ),
        );
        await _syncQueue.enqueue(
          entityType: 'recurring_reminder',
          operation: 'create',
          payloadJson: jsonEncode({
            'localId': localId,
            ...apiRequests.last.toJson(),
          }),
          dedupeKey: 'recurring_reminder:create:$localId',
        );
        localIds.add(localId);
      }

      try {
        final bulk = BulkRecurringReminderRequest(
          propertyRef: propertyScope.value == 'all'
              ? ''
              : selectedPropertyRef.value,
          scope: propertyScope.value,
          reminderType: type,
          customTypeLabel: customLabel,
          messageTemplate: template,
          recurrence: recurrenceApiValue,
          timeOfDay: timeOfDay,
          pushEnabled: pushEnabled.value,
          whatsappEnabled: whatsappEnabled.value,
          smsEnabled: smsEnabled.value,
          tenants: apiRequests,
        );
        final res = await _repository.createBulkRecurringReminders(bulk);
        if (res.responseCode == '0' || res.responseCode == '201') {
          for (final id in localIds) {
            await _recurringLocal.updateSyncStatus(id, 'synced');
          }
        }
      } catch (_) {
        // Offline queue will sync later.
      }

      hapticPrimaryConfirm();
      showSuccessMessage(
        _t(
          'Scheduled ${tenants.length} recurring reminder(s)',
          'Vikumbusho ${tenants.length} vimepangwa',
        ),
      );
      Get.back(result: true);
    } finally {
      scheduling.value = false;
    }
  }
}

class _TemplateOption {
  const _TemplateOption({
    required this.id,
    required this.name,
    required this.body,
  });

  final String id;
  final String name;
  final String body;
}
