import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/form_surface_colors.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/local/db/client_event_local_data_source.dart';
import '../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/currency_service.dart';
import '../../../data/model/send_sms_request.dart';
import '../../../data/repository/app_repository.dart';
import 'quick_wizard_shell.dart';

class _ReminderTemplateOption {
  const _ReminderTemplateOption({
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

/// Two-step wizard: pick tenant recipients, compose WhatsApp reminder, send.
Future<bool?> showSendReminderWizard() {
  return showQuickWizardSheet<bool>(
    title: 'Send Reminder',
    builder: (_) => const _QuickSendReminderWizardBody(),
  );
}

class _QuickSendReminderWizardBody extends StatefulWidget {
  const _QuickSendReminderWizardBody();

  @override
  State<_QuickSendReminderWizardBody> createState() =>
      _QuickSendReminderWizardBodyState();
}

class _QuickSendReminderWizardBodyState
    extends State<_QuickSendReminderWizardBody> {
  final _tenantLocal = Get.find<TenantLocalDataSource>();
  final _whatsappTemplateLocal =
      Get.find<RentWhatsappTemplateLocalDataSource>();
  final _repository = Get.find<AppRepository>(tag: (AppRepository).toString());

  final _messageController = TextEditingController();
  final _selectedTenantIds = <int>{};
  final _tenants = <TenantRecord>[];

  int _step = 0;
  bool _loadingTenants = true;
  bool _loadingTemplates = true;
  bool _sending = false;

  final _whatsappTemplates = <_ReminderTemplateOption>[];
  String? _selectedWhatsappTemplateId;

  static final DateFormat _dateDisplay = DateFormat('dd/MM/yyyy');

  String _formatBalance(num amount) =>
      Get.find<CurrencyService>().formatBase(amount.round());

  bool get _isSw => Get.locale?.languageCode == 'sw';

  String _t(String en, String sw) => _isSw ? sw : en;

  String get _defaultTemplate => _isSw
      ? 'Habari {tenantName}, nakukumbusha kuwa salio lako la {balance} kwa {property} linatakiwa kulipwa tarehe {dueDate}.'
      : 'Hello {tenantName}, a friendly reminder that your balance of {balance} for {property} is due on {dueDate}.';

  @override
  void initState() {
    super.initState();
    _loadTenants();
    _loadTemplates();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    try {
      final rows = await _tenantLocal.getAllNewestFirst();
      if (!mounted) return;
      setState(() {
        _tenants
          ..clear()
          ..addAll(rows);
        _loadingTenants = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTenants = false);
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final rows = await _whatsappTemplateLocal.getAllNewestFirst();
      final options = rows
          .where((e) => e.bodyText.trim().isNotEmpty)
          .map(
            (e) => _ReminderTemplateOption(
              id: e.id.toString(),
              name: e.name,
              body: e.bodyText,
              meta: WaTemplateStatus.label(e.status),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _whatsappTemplates
          ..clear()
          ..addAll(options);
        _loadingTemplates = false;
        if (options.isNotEmpty) {
          _selectedWhatsappTemplateId ??= options.first.id;
        }
        if (_messageController.text.trim().isEmpty) {
          final initial = options.isNotEmpty
              ? _resolveForPreview(options.first.body)
              : _resolveForPreview(_defaultTemplate);
          _messageController.text = initial;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTemplates = false;
        if (_messageController.text.trim().isEmpty) {
          _messageController.text = _resolveForPreview(_defaultTemplate);
        }
      });
    }
  }

  List<TenantRecord> get _selectableTenants =>
      _tenants.where((t) => t.phoneNumber.trim().isNotEmpty).toList();

  bool get _allSelected {
    final selectable = _selectableTenants;
    return selectable.isNotEmpty &&
        selectable.every((t) => _selectedTenantIds.contains(t.id));
  }

  bool? get _selectAllValue {
    if (_selectedTenantIds.isEmpty) return false;
    if (_allSelected) return true;
    return null;
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedTenantIds
          ..clear()
          ..addAll(_selectableTenants.map((t) => t.id));
      } else {
        _selectedTenantIds.clear();
      }
    });
  }

  void _toggleTenant(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedTenantIds.add(id);
      } else {
        _selectedTenantIds.remove(id);
      }
    });
  }

  String _propertyTitle(TenantRecord tenant) {
    final label = tenant.propertyLabel.trim();
    if (label.isEmpty) return tenant.unitLabel.trim().isEmpty ? 'N/A' : tenant.unitLabel;
    final comma = label.indexOf(',');
    final short = comma > 0 ? label.substring(0, comma).trim() : label;
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

  String _defaultDueDate() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return _dateDisplay.format(endOfMonth);
  }

  String _resolveMessage(String template, TenantRecord tenant) {
    final firstName = tenant.tenantName.trim().isEmpty
        ? _t('Tenant', 'Mpangaji')
        : tenant.tenantName.split(RegExp(r'\s+')).first;
    return template
        .replaceAll('{tenantName}', firstName)
        .replaceAll('{balance}', _formatBalance(tenant.rentAmountValue))
        .replaceAll('{property}', _propertyTitle(tenant))
        .replaceAll('{dueDate}', _defaultDueDate());
  }

  String _resolveForPreview(String template) {
    if (_selectedTenantIds.isEmpty) {
      return template
          .replaceAll('{tenantName}', _t('Tenant', 'Mpangaji'))
          .replaceAll('{balance}', _formatBalance(0))
          .replaceAll('{property}', _t('Property', 'Mali'))
          .replaceAll('{dueDate}', _defaultDueDate());
    }
    final first = _tenants.firstWhere(
      (t) => _selectedTenantIds.contains(t.id),
      orElse: () => _selectableTenants.first,
    );
    return _resolveMessage(template, first);
  }

  void _applyWhatsappTemplate(String? id) {
    if (id == null || id.isEmpty) return;
    _ReminderTemplateOption? option;
    for (final t in _whatsappTemplates) {
      if (t.id == id) {
        option = t;
        break;
      }
    }
    if (option == null) return;
    final body = option.body;
    setState(() {
      _selectedWhatsappTemplateId = id;
      _messageController.text = _resolveForPreview(body);
    });
  }

  Future<void> _saveCurrentAsTemplate() async {
    final nameController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = FormSurfaceColors.of(ctx);
        return AlertDialog(
          backgroundColor: c.card,
          title: Text(_t('Save template', 'Hifadhi kiolezo')),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: _t('Template name', 'Jina la kiolezo'),
              filled: true,
              fillColor: c.inputFill,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_t('Cancel', 'Ghairi')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_t('Save', 'Hifadhi')),
            ),
          ],
        );
      },
    );
    if (saved != true) return;

    final rawBody = _messageController.text.trim();
    final cleanedName = nameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    nameController.dispose();

    if (cleanedName.isEmpty) {
      _showSnack(_t('Template name is required', 'Jina la kiolezo linahitajika'));
      return;
    }
    if (rawBody.isEmpty) {
      _showSnack(_t('Message is required', 'Ujumbe unahitajika'));
      return;
    }

    // Store the template with placeholders, not the resolved preview text.
    final bodyWithPlaceholders = _stripResolvedValues(rawBody);

    try {
      final id = await _whatsappTemplateLocal.insert(
        name: cleanedName,
        category: WaTemplateCategory.utility,
        language: _isSw ? 'sw' : 'en_US',
        headerType: WaTemplateHeaderType.none,
        headerText: '',
        bodyText: bodyWithPlaceholders,
        footerText: '',
        buttons: const [],
        sampleVariables: const [],
        status: WaTemplateStatus.draft,
      );
      await _loadTemplates();
      _applyWhatsappTemplate(id.toString());
      _showSnack(_t('Template saved', 'Kiolezo kimehifadhiwa'));
    } catch (_) {
      _showSnack(
        _t(
          'Failed to save template. Try a different name.',
          'Imeshindikana kuhifadhi. Tumia jina tofauti.',
        ),
      );
    }
  }

  String _stripResolvedValues(String text) {
    if (_selectedTenantIds.isEmpty) return text;
    final tenant = _tenants.firstWhere(
      (t) => _selectedTenantIds.contains(t.id),
      orElse: () => _selectableTenants.first,
    );
    var out = text;
    final firstName = tenant.tenantName.trim().isEmpty
        ? _t('Tenant', 'Mpangaji')
        : tenant.tenantName.split(RegExp(r'\s+')).first;
    out = out.replaceAll(firstName, '{tenantName}');
    out = out.replaceAll(_formatBalance(tenant.rentAmountValue), '{balance}');
    out = out.replaceAll(_propertyTitle(tenant), '{property}');
    out = out.replaceAll(_defaultDueDate(), '{dueDate}');
    return out;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateStep() {
    if (_step == 0) {
      if (_selectedTenantIds.isEmpty) {
        return _t(
          'Select at least one tenant',
          'Chagua angalau mpangaji mmoja',
        );
      }
      return null;
    }
    if (_messageController.text.trim().isEmpty) {
      return _t('Write a reminder message', 'Andika ujumbe wa ukumbusho');
    }
    return null;
  }

  Future<void> _sendReminders() async {
    final error = _validateStep();
    if (error != null) {
      _showSnack(error);
      return;
    }

    final recipients = _tenants
        .where((t) => _selectedTenantIds.contains(t.id))
        .where((t) => t.phoneNumber.trim().isNotEmpty)
        .toList();
    if (recipients.isEmpty) {
      _showSnack(
        _t(
          'Selected tenants have no phone numbers',
          'Wapangaji waliochaguliwa hawana nambari ya simu',
        ),
      );
      return;
    }

    setState(() => _sending = true);
    var sent = 0;
    final template = _stripResolvedValues(_messageController.text.trim());

    try {
      if (recipients.length == 1) {
        final tenant = recipients.first;
        final msg = _resolveMessage(template, tenant);
        final res = await _repository.sendWhatsApp(
          SendSmsRequest(phoneNumber: tenant.phoneNumber.trim(), message: msg),
        );
        if (res.responseCode == '0') {
          sent = 1;
          await _logReminderEvent(tenant, msg);
        } else {
          _showSnack(
            res.message ??
                _t('Failed to send reminder', 'Imeshindikana kutuma ukumbusho'),
          );
          return;
        }
      } else {
        for (final tenant in recipients) {
          final msg = _resolveMessage(template, tenant);
          final res = await _repository.sendWhatsApp(
            SendSmsRequest(phoneNumber: tenant.phoneNumber.trim(), message: msg),
          );
          if (res.responseCode == '0') {
            sent += 1;
            await _logReminderEvent(tenant, msg);
          }
        }
        if (sent == 0) {
          _showSnack(
            _t('Failed to send reminders', 'Imeshindikana kutuma vikumbusho'),
          );
          return;
        }
      }

      hapticPrimaryConfirm();
      _showSnack(
        sent == recipients.length
            ? _t(
                'Reminder sent to $sent tenant(s)',
                'Ukumbusho umetumwa kwa wapangaji $sent',
              )
            : _t(
                'Sent $sent of ${recipients.length} reminders',
                'Vimetumwa $sent kati ya ${recipients.length}',
              ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _logReminderEvent(TenantRecord tenant, String message) async {
    try {
      await Get.find<ClientEventLocalDataSource>().insert(
        phoneNumber: tenant.phoneNumber.trim(),
        clientName: tenant.tenantName,
        propertyLabel: tenant.propertyLabel,
        workspace: 'rent',
        eventType: ClientEventType.reminderSent,
        metadata: {
          'channel': 'whatsapp',
          'source': 'quick_send_reminder',
          'messagePreview': message.length > 120
              ? '${message.substring(0, 120)}…'
              : message,
        },
      );
    } catch (_) {}
  }

  void _onNext() {
    if (_step == 0) {
      final error = _validateStep();
      if (error != null) {
        _showSnack(error);
        return;
      }
      setState(() {
        _step = 1;
        if (_messageController.text.trim().isNotEmpty) {
          _messageController.text = _resolveForPreview(
            _stripResolvedValues(_messageController.text),
          );
        }
      });
      return;
    }
    _sendReminders();
  }

  Widget _tenantStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    if (_loadingTenants) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectable = _selectableTenants;
    final withoutPhone =
        _tenants.where((t) => t.phoneNumber.trim().isEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(
          context,
          _t('Choose recipients', 'Chagua wapokeaji'),
        ),
        quickWizardLabel(
          context,
          _t('TENANTS', 'WAPANGAJI'),
        ),
        const SizedBox(height: 8),
        if (selectable.isEmpty)
          Text(
            _t(
              'No tenants with phone numbers found.',
              'Hakuna wapangaji wenye nambari ya simu.',
            ),
            style: TextStyle(color: c.hint),
          )
        else ...[
          CheckboxListTile(
            value: _selectAllValue,
            tristate: true,
            onChanged: _toggleSelectAll,
            title: Text(
              _t('Select all', 'Chagua wote'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: c.headline,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          ...selectable.map((tenant) {
            final subtitle = [
              if (tenant.unitLabel.trim().isNotEmpty) tenant.unitLabel,
              if (tenant.propertyLabel.trim().isNotEmpty) tenant.propertyLabel,
              tenant.phoneNumber,
            ].join(' · ');
            return CheckboxListTile(
              value: _selectedTenantIds.contains(tenant.id),
              onChanged: (v) => _toggleTenant(tenant.id, v == true),
              title: Text(
                tenant.tenantName.trim().isEmpty
                    ? _t('Unnamed tenant', 'Mpangaji bila jina')
                    : tenant.tenantName,
                style: TextStyle(color: c.headline, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: c.hint),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
        if (withoutPhone > 0) ...[
          const SizedBox(height: 8),
          Text(
            _t(
              '$withoutPhone tenant(s) hidden — no phone on file.',
              'Wapangaji $withoutPhone wamefichwa — hakuna nambari ya simu.',
            ),
            style: TextStyle(fontSize: 11, color: c.hint),
          ),
        ],
      ],
    );
  }

  Widget _messageStep(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quickWizardHeading(
          context,
          _t('Compose reminder', 'Andika ukumbusho'),
        ),
        quickWizardLabel(
          context,
          _t('SAVED WHATSAPP TEMPLATE', 'KIOLEZO KILICHOHIFADHIWA'),
        ),
        const SizedBox(height: 8),
        if (_loadingTemplates)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          )
        else if (_whatsappTemplates.isEmpty)
          Text(
            _t(
              'No saved templates yet — edit the message below or save one.',
              'Hakuna violezo — hariri ujumbe hapa chini au hifadhi kiolezo.',
            ),
            style: TextStyle(fontSize: 12, color: c.hint),
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedWhatsappTemplateId),
            initialValue: _selectedWhatsappTemplateId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: c.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.inputBorder),
              ),
            ),
            hint: Text(_t('Select saved template', 'Chagua kiolezo')),
            items: _whatsappTemplates
                .map(
                  (t) => DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(
                      '${t.name} (${t.meta})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _applyWhatsappTemplate,
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _sending ? null : _saveCurrentAsTemplate,
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: Text(_t('Save as template', 'Hifadhi kama kiolezo')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        quickWizardLabel(context, _t('MESSAGE', 'UJUMBE')),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          minLines: 5,
          maxLines: 8,
          style: TextStyle(color: c.headline, height: 1.45),
          decoration: InputDecoration(
            hintText: _t(
              'Edit your WhatsApp reminder…',
              'Hariri ukumbusho wako wa WhatsApp…',
            ),
            hintStyle: TextStyle(color: c.hint),
            filled: true,
            fillColor: c.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            'Placeholders: {tenantName}, {balance}, {property}, {dueDate}',
            'Viashiria: {tenantName}, {balance}, {property}, {dueDate}',
          ),
          style: TextStyle(fontSize: 11, color: c.hint),
        ),
        const SizedBox(height: 12),
        Text(
          _t(
            'Sending to ${_selectedTenantIds.length} tenant(s) via WhatsApp.',
            'Inatumwa kwa wapangaji ${_selectedTenantIds.length} kupitia WhatsApp.',
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.secondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuickWizardBody(
      title: 'Send Reminder',
      stepIndex: _step,
      totalSteps: 2,
      stepContent: _step == 0 ? _tenantStep(context) : _messageStep(context),
      onClose: () => Navigator.of(context).pop(false),
      onPrevious: _step > 0 ? () => setState(() => _step -= 1) : null,
      onNext: _onNext,
      nextLabel: _step == 0 ? _t('Next', 'Endelea') : _t('Send', 'Tuma'),
      isSubmitting: _sending,
    );
  }
}
