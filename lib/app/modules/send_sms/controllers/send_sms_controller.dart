import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/send_sms_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../models/device_contact_entry.dart';
import '../models/saved_whatsapp_group.dart';

class SendSmsController extends BaseController
    with GetTickerProviderStateMixin {
  static const String _keySavedWhatsAppGroups = 'saved_whatsapp_groups';
  static const String _smsTemplatesKey = 'rent_sms_payment_reminder_templates';
  String _t(String en, String sw) => Get.locale?.languageCode == 'sw' ? sw : en;

  final isFirstView = true.obs;
  final isLoading = false.obs;
  final phoneNumbersController = TextEditingController();
  final messageController = TextEditingController();
  final groupLinkController = TextEditingController();
  final promptController = TextEditingController();
  final templateNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Saved WhatsApp group links for quick access.
  final savedGroups = <SavedWhatsAppGroup>[].obs;

  /// Media types to include in AI-generated multimedia message (image, audio, file).
  final includeImage = true.obs;
  final includeAudio = false.obs;
  final includeFile = false.obs;
  final isGenerating = false.obs;
  final saveAsTemplateEnabled = false.obs;
  final recipientContextLabel = ''.obs;
  final prefilledTenantIds = <int>{}.obs;
  final pickerSelectedTenantIds = <int>{}.obs;
  final availableTenants = <TenantRecord>[].obs;
  final deviceContactEntries = <DeviceContactEntry>[].obs;
  final contactPickerSearchQuery = ''.obs;
  final pickerSelectedContactKeys = <String>{}.obs;
  final isLoadingContacts = false.obs;

  static final _phonePattern = RegExp(r'^0[678]\d{8}$');

  final PreferenceManager _preferenceManager = Get.find(
    tag: (PreferenceManager).toString(),
  );
  final AppRepository _repository = Get.find(tag: (AppRepository).toString());
  final TenantLocalDataSource _tenantLocal = Get.find<TenantLocalDataSource>();
  final RentWhatsappTemplateLocalDataSource _whatsappTemplateLocal =
      Get.find<RentWhatsappTemplateLocalDataSource>();

  /// Saved WhatsApp Business-style templates (body uses `{{1}}`, `{{2}}`, …).
  final savedMessageTemplates = <RentWhatsappTemplateRecord>[].obs;
  final selectedTemplateId = Rxn<int>();

  /// True after access check; false if user is not admin/leader.
  final isAccessAllowed = false.obs;
  final isCheckingAccess = true.obs;

  late TabController tabController;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    super.onInit();
    _prefillFromRouteArgs();
    _checkAccess();
    _loadTenantsForPicker();
    loadSavedGroups();
    loadSavedMessageTemplates();
  }

  void _prefillFromRouteArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    final map = Map<String, dynamic>.from(args);
    final phones = _extractPhones(map['phones']);
    if (phones.isNotEmpty) {
      appendPhoneNumbers(phones);
    }
    recipientContextLabel.value = (map['contextLabel'] ?? '').toString().trim();
    prefilledTenantIds.assignAll(_extractTenantIds(map['tenantIds']));
    pickerSelectedTenantIds.assignAll(prefilledTenantIds);
  }

  List<int> _extractTenantIds(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => int.tryParse(e.toString()) ?? -1)
          .where((e) => e > 0)
          .toSet()
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[\n,;]+'))
          .map((e) => int.tryParse(e.trim()) ?? -1)
          .where((e) => e > 0)
          .toSet()
          .toList();
    }
    return const [];
  }

  List<String> _extractPhones(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return parsePhoneNumbers(raw);
    }
    return const [];
  }

  Future<void> _loadTenantsForPicker() async {
    try {
      final rows = await _tenantLocal.getAllNewestFirstByWorkspace('rent');
      final propertyRefFilter = _routeArgString('propertyRef');
      final scoped = propertyRefFilter.isEmpty
          ? rows
          : rows.where((e) => e.propertyRef.trim() == propertyRefFilter).toList();
      availableTenants.assignAll(scoped);
    } catch (_) {
      availableTenants.clear();
    }
  }

  String _routeArgString(String key) {
    final args = Get.arguments;
    if (args is! Map) return '';
    final map = Map<String, dynamic>.from(args);
    return (map[key] ?? '').toString().trim();
  }

  Future<void> loadSavedMessageTemplates() async {
    try {
      final list = await _whatsappTemplateLocal.getAllNewestFirst();
      savedMessageTemplates.assignAll(list);
      final sel = selectedTemplateId.value;
      if (sel != null &&
          !savedMessageTemplates.any((t) => t.id == sel)) {
        selectedTemplateId.value = null;
      }
    } catch (_) {
      savedMessageTemplates.clear();
    }
  }

  /// Fills [messageController] with header/body/footer and replaces `{{n}}`
  /// using each template's saved sample values.
  void onMessageTemplateSelected(int? id) {
    selectedTemplateId.value = id;
    if (id == null) return;
    RentWhatsappTemplateRecord? found;
    for (final t in savedMessageTemplates) {
      if (t.id == id) {
        found = t;
        break;
      }
    }
    if (found != null) {
      messageController.text = _renderTemplateWithSamples(found);
      messageController.selection = TextSelection.collapsed(
        offset: messageController.text.length,
      );
    }
  }

  String _renderTemplateWithSamples(RentWhatsappTemplateRecord t) {
    String replaceVars(String raw) {
      var out = raw;
      for (var i = 0; i < t.sampleVariables.length; i++) {
        out = out.replaceAll('{{${i + 1}}}', t.sampleVariables[i]);
      }
      return out;
    }

    final parts = <String>[];
    if (t.headerType == WaTemplateHeaderType.text &&
        t.headerText.trim().isNotEmpty) {
      parts.add(replaceVars(t.headerText));
    }
    if (t.bodyText.trim().isNotEmpty) {
      parts.add(replaceVars(t.bodyText));
    }
    if (t.footerText.trim().isNotEmpty) {
      parts.add(replaceVars(t.footerText));
    }
    return parts.where((s) => s.trim().isNotEmpty).join('\n\n');
  }

  /// Load saved WhatsApp groups from preferences.
  Future<void> loadSavedGroups() async {
    try {
      final json = await _preferenceManager.getString(
        _keySavedWhatsAppGroups,
        defaultValue: '[]',
      );
      final list = jsonDecode(json) as List<dynamic>?;
      savedGroups.assignAll(
        (list ?? [])
            .map((e) => SavedWhatsAppGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      savedGroups.clear();
    }
  }

  /// Persist saved groups to preferences.
  Future<void> _persistSavedGroups() async {
    final list = savedGroups.map((e) => e.toJson()).toList();
    await _preferenceManager.setString(
      _keySavedWhatsAppGroups,
      jsonEncode(list),
    );
  }

  /// Save the current group link with a name. Shows dialog for name.
  void saveCurrentGroupLink() {
    final link = groupLinkController.text.trim();
    if (link.isEmpty) {
      showErrorMessage(
        _t(
          'Enter or paste a group link first.',
          'Weka au bandika kwanza kiungo cha kikundi.',
        ),
      );
      return;
    }
    final nameController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(_t('Save group link', 'Hifadhi kiungo cha kikundi')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: _t('Group name', 'Jina la kikundi'),
            hintText: _t('e.g. Family, Community', 'mf. Familia, Jamii'),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                showErrorMessage(
                  _t('Enter a name for the group.', 'Weka jina la kikundi.'),
                );
                return;
              }
              Get.back();
              savedGroups.add(SavedWhatsAppGroup(name: name, link: link));
              _persistSavedGroups();
              showSuccessMessage(
                _t(
                  'Group "$name" saved for future use.',
                  'Kikundi "$name" kimehifadhiwa kwa matumizi ya baadaye.',
                ),
              );
            },
            child: Text(_t('Save', 'Hifadhi')),
          ),
        ],
      ),
    );
  }

  /// Use a saved group: fill the link field with the group's link.
  void useSavedGroup(SavedWhatsAppGroup group) {
    groupLinkController.text = group.link;
  }

  /// Remove a saved group by index.
  void removeSavedGroupAt(int index) {
    if (index >= 0 && index < savedGroups.length) {
      savedGroups.removeAt(index);
      _persistSavedGroups();
    }
  }

  /// Allow access for admins, leaders, or users with an active SMS subscription.
  /// If not allowed, redirect to subscription page (15,000 TZS/month).
  Future<void> _checkAccess() async {
    final expiryMs = await _preferenceManager.getInt(
      keySmsSubscriptionExpiry,
      defaultValue: 0,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final hasActiveSubscription = expiryMs > 0 && now < expiryMs;

    print('Expiry ms $expiryMs');

    print('Has active subscription $hasActiveSubscription');

    isCheckingAccess(false);
    if (hasActiveSubscription) {
      isAccessAllowed(true);
    } else {
      isAccessAllowed(false);
      Get.offNamed(Routes.SUBSCRIPTION);
    }
  }

  @override
  void onClose() {
    phoneNumbersController.dispose();
    messageController.dispose();
    groupLinkController.dispose();
    promptController.dispose();
    templateNameController.dispose();
    super.onClose();
  }

  void toggleTenantForPicker(int tenantId, bool selected) {
    final current = Set<int>.from(pickerSelectedTenantIds);
    if (selected) {
      current.add(tenantId);
    } else {
      current.remove(tenantId);
    }
    pickerSelectedTenantIds.assignAll(current);
  }

  void appendSelectedTenantsToRecipients() {
    final selected = availableTenants
        .where((t) => pickerSelectedTenantIds.contains(t.id))
        .map((t) => t.phoneNumber.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    appendPhoneNumbers(selected);
  }

  void appendPhoneNumbers(List<String> phones) {
    if (phones.isEmpty) return;
    final existing = parsePhoneNumbers(phoneNumbersController.text);
    final merged = <String>{...existing, ...phones.map((e) => e.trim())}
      ..removeWhere((e) => e.isEmpty);
    phoneNumbersController.text = merged.join('\n');
    phoneNumbersController.selection = TextSelection.collapsed(
      offset: phoneNumbersController.text.length,
    );
  }

  /// Converts contact/raw input to local SMS format (e.g. 0612345678).
  String? normalizeToLocalSmsFormat(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length >= 12) {
      digits = '0${digits.substring(digits.length - 9)}';
    } else if (digits.length == 9 && RegExp(r'^[678]').hasMatch(digits)) {
      digits = '0$digits';
    }
    return _phonePattern.hasMatch(digits) ? digits : null;
  }

  Future<bool> ensureContactsPermission() async {
    if (await FlutterContacts.permissions.has(PermissionType.read)) {
      return true;
    }
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  List<DeviceContactEntry> get filteredDeviceContactEntries {
    final q = contactPickerSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return deviceContactEntries;
    return deviceContactEntries
        .where(
          (e) =>
              e.displayName.toLowerCase().contains(q) ||
              e.phone.contains(q),
        )
        .toList();
  }

  /// Loads device contacts for the picker. Returns false if permission denied.
  Future<bool> prepareContactPicker() async {
    isLoadingContacts(true);
    contactPickerSearchQuery.value = '';
    pickerSelectedContactKeys.clear();
    deviceContactEntries.clear();
    try {
      if (!await ensureContactsPermission()) {
        showErrorMessage(
          _t(
            'Contacts permission is required to pick phone numbers.',
            'Ruhusa ya mawasiliano inahitajika kuchagua namba za simu.',
          ),
        );
        return false;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final seenPhones = <String>{};
      final entries = <DeviceContactEntry>[];
      for (final contact in contacts) {
        if (contact.phones.isEmpty) continue;
        final name = (contact.displayName ?? '').trim().isEmpty
            ? _t('Unknown', 'Haijulikani')
            : contact.displayName!.trim();
        for (final phone in contact.phones) {
          final rawNumber = phone.number.trim();
          if (rawNumber.isEmpty) continue;
          final normalized = normalizeToLocalSmsFormat(rawNumber);
          if (normalized == null || !seenPhones.add(normalized)) continue;
          entries.add(
            DeviceContactEntry(
              contactId: contact.id ?? '',
              displayName: name,
              phone: normalized,
            ),
          );
        }
      }
      entries.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        ),
      );
      deviceContactEntries.assignAll(entries);
      return true;
    } catch (_) {
      showErrorMessage(
        _t(
          'Could not load contacts. Please try again.',
          'Imeshindikana kupakia mawasiliano. Jaribu tena.',
        ),
      );
      return false;
    } finally {
      isLoadingContacts(false);
    }
  }

  void toggleContactForPicker(String selectionKey, bool selected) {
    final current = Set<String>.from(pickerSelectedContactKeys);
    if (selected) {
      current.add(selectionKey);
    } else {
      current.remove(selectionKey);
    }
    pickerSelectedContactKeys.assignAll(current);
  }

  void appendSelectedContactsToRecipients() {
    final selectedPhones = deviceContactEntries
        .where((e) => pickerSelectedContactKeys.contains(e.selectionKey))
        .map((e) => e.phone)
        .toList();
    appendPhoneNumbers(selectedPhones);
  }

  Future<void> saveCurrentMessageAsTemplate({required bool isWhatsApp}) async {
    final body = messageController.text.trim();
    if (body.isEmpty) {
      showErrorMessage(_t('Write a message first.', 'Andika ujumbe kwanza.'));
      return;
    }
    final rawName = templateNameController.text.trim();
    final name = rawName.isEmpty
        ? _t('quick_template', 'kiolezo_haraka')
        : rawName;
    if (isWhatsApp) {
      try {
        await _whatsappTemplateLocal.insert(
          name: name,
          category: WaTemplateCategory.utility,
          language: Get.locale?.languageCode == 'sw' ? 'sw' : 'en_US',
          headerType: WaTemplateHeaderType.none,
          headerText: '',
          bodyText: body,
          footerText: '',
          buttons: const [],
          sampleVariables: const [],
          status: WaTemplateStatus.draft,
        );
        await loadSavedMessageTemplates();
        showSuccessMessage(
          _t('WhatsApp template saved.', 'Kiolezo cha WhatsApp kimehifadhiwa.'),
        );
      } catch (_) {
        showErrorMessage(
          _t(
            'Failed to save WhatsApp template.',
            'Imeshindikana kuhifadhi kiolezo cha WhatsApp.',
          ),
        );
      }
      return;
    }

    final existing = await _preferenceManager.getStringList(_smsTemplatesKey);
    final entry = '$name|||$body';
    final updated = [...existing.where((e) => !e.startsWith('$name|||')), entry];
    await _preferenceManager.setStringList(_smsTemplatesKey, updated);
    showSuccessMessage(_t('SMS template saved.', 'Kiolezo cha SMS kimehifadhiwa.'));
  }

  void _handleLoadAIDataSuccess(GeneralResponse res) async {
    isGenerating(false);
    if (res.responseCode == '0') {
      messageController.text = res.data;
    } else {
      final msg = res.data != null && res.data.toString().isNotEmpty
          ? '${res.message ?? _t('Error', 'Hitilafu')}: ${res.data}'
          : (res.message ??
                _t('Something went wrong', 'Kuna tatizo limetokea'));
      showErrorMessage(msg);
    }
  }

  void _handleQueryResponseError(Exception e) {
    isGenerating(false);
  }

  /// Generate a multimedia message draft from the AI prompt (images, audio, files).
  /// For now builds a draft; replace with real AI API when backend is ready.
  void generateMultimediaMessage() {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      showErrorMessage(
        _t(
          'Please enter a prompt describing the message you want to generate.',
          'Tafadhali weka maelekezo yanayoeleza ujumbe unaotaka kutengeneza.',
        ),
      );
      return;
    }
    isGenerating(true);
    // Simulate brief delay; replace with actual AI API call when available.
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   final types = <String>[];
    //   if (includeImage.value) types.add('image');
    //   if (includeAudio.value) types.add('audio');
    //   if (includeFile.value) types.add('file');
    //   final mediaNote = types.isEmpty
    //       ? '(You can attach image, audio, or file when sending.)'
    //       : 'Include: ${types.join(', ')}. (Attach when sending.)';
    //   final draft = 'Generated message:\n\n$prompt\n\n$mediaNote';
    //   messageController.text = draft;
    //   isGenerating(false);
    //   if (Get.context != null) {
    //     Get.snackbar(
    //       'Draft created',
    //       'AI-generated draft is in the message field. Full AI generation (images, audio, files) will use backend when connected.',
    //       snackPosition: SnackPosition.BOTTOM,
    //       duration: const Duration(seconds: 3),
    //     );
    //   }
    // });
    callDataService(
      _repository.sendAiRequest({'prompt': prompt, 'groupIds': []}),
      onSuccess: _handleLoadAIDataSuccess,
      onError: _handleQueryResponseError,
    );
  }

  /// Parse input into list of non-empty trimmed strings (split by newline or comma).
  List<String> parsePhoneNumbers(String input) {
    if (input.trim().isEmpty) return [];
    return input
        .split(RegExp(r'[\n,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Returns valid numbers; invalid ones are reported via [invalidNumbers].
  List<String> validatePhoneNumbers(String input, List<String> invalidNumbers) {
    invalidNumbers.clear();
    final parsed = parsePhoneNumbers(input);
    final valid = <String>[];
    for (final s in parsed) {
      if (_phonePattern.hasMatch(s)) {
        valid.add(s);
      } else {
        invalidNumbers.add(s);
      }
    }
    return valid;
  }

  String? phoneNumbersValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t(
        'Please enter at least one phone number',
        'Tafadhali weka angalau namba moja ya simu',
      );
    }
    final invalid = <String>[];
    final valid = validatePhoneNumbers(value, invalid);
    if (valid.isEmpty) {
      return invalid.isEmpty
          ? _t(
              'Please enter at least one valid phone number (e.g. 0612345678)',
              'Tafadhali weka angalau namba moja sahihi ya simu (mf. 0612345678)',
            )
          : _t(
              'Invalid number(s): ${invalid.take(3).join(", ")}${invalid.length > 3 ? "..." : ""}. Use e.g. 0612345678',
              'Namba zisizo sahihi: ${invalid.take(3).join(", ")}${invalid.length > 3 ? "..." : ""}. Tumia mf. 0612345678',
            );
    }
    return null;
  }

  String? messageValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t('Please enter a message', 'Tafadhali weka ujumbe');
    }
    return null;
  }

  void sendSms() async {
    if (formKey.currentState?.validate() != true) return;
    final invalid = <String>[];
    final numbers = validatePhoneNumbers(phoneNumbersController.text, invalid);
    if (numbers.isEmpty) {
      showErrorMessage(
        _t(
          'Please enter at least one valid phone number.',
          'Tafadhali weka angalau namba moja sahihi ya simu.',
        ),
      );
      return;
    }
    if (invalid.isNotEmpty) {
      showSuccessMessage(
        _t(
          'Skipping ${invalid.length} invalid number(s).',
          'Ninaruka namba ${invalid.length} zisizo sahihi.',
        ),
      );
    }
    isLoading(true);
    int sent = 0;
    String? lastError;
    for (final number in numbers) {
      try {
        final res = await _repository.sendSms(
          SendSmsRequest(
            phoneNumber: number,
            message: messageController.text.trim(),
          ),
        );
        if (res.responseCode == '0') {
          sent++;
        } else {
          lastError =
              res.message ??
              _t('Failed for $number', 'Imeshindikana kwa $number');
        }
      } catch (e) {
        lastError = e.toString();
      }
    }
    isLoading(false);
    if (sent == numbers.length) {
      Get.dialog(
        AlertDialog(
          title: Text(_t('Success', 'Imefanikiwa')),
          content: Text(
            _t(
              'SMS sent successfully to $sent recipient(s).',
              'SMS imetumwa kwa mafanikio kwa wapokeaji $sent.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(closeOverlays: true);
                phoneNumbersController.clear();
                messageController.clear();
              },
              child: Text(_t('OK', 'SAWA')),
            ),
          ],
        ),
      );
    } else if (sent > 0) {
      Get.dialog(
        AlertDialog(
          title: Text(_t('Partially sent', 'Imetumwa kwa sehemu')),
          content: Text(
            _t(
              'Sent to $sent of ${numbers.length}. ${lastError != null ? "\n$lastError" : ""}',
              'Imetumwa kwa $sent kati ya ${numbers.length}. ${lastError != null ? "\n$lastError" : ""}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(closeOverlays: true),
              child: Text(_t('OK', 'SAWA')),
            ),
          ],
        ),
      );
    } else {
      showErrorMessage(
        lastError ?? _t('Failed to send SMS', 'Imeshindikana kutuma SMS'),
      );
    }
  }

  /// Convert local format (0xxxxxxxxx) to international for WhatsApp (255xxxxxxxxx).
  String toWhatsAppInternational(String localNumber) {
    final trimmed = localNumber.trim();
    if (trimmed.startsWith('0') && trimmed.length == 10) {
      return '255${trimmed.substring(1)}';
    }
    if (trimmed.startsWith('255') && trimmed.length >= 12) {
      return trimmed.length > 12 ? trimmed.substring(0, 12) : trimmed;
    }
    return trimmed;
  }

  /// Opens WhatsApp chat for [localNumber] with [message] pre-filled.
  Future<bool> openWhatsAppForNumber(String localNumber, String message) async {
    final international = toWhatsAppInternational(localNumber);
    final uri = Uri.parse(
      'https://wa.me/$international${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Send via WhatsApp: open WhatsApp for chosen number(s) with message pre-filled.
  void sendViaWhatsApp() {
    if (formKey.currentState?.validate() != true) return;
    final invalid = <String>[];
    final numbers = validatePhoneNumbers(phoneNumbersController.text, invalid);
    final message = messageController.text.trim();
    if (numbers.isEmpty) {
      showErrorMessage(
        _t(
          'Please enter at least one valid phone number.',
          'Tafadhali weka angalau namba moja sahihi ya simu.',
        ),
      );
      return;
    }
    if (invalid.isNotEmpty) {
      showSuccessMessage(
        _t(
          'Skipping ${invalid.length} invalid number(s).',
          'Ninaruka namba ${invalid.length} zisizo sahihi.',
        ),
      );
    }
    if (numbers.length == 1) {
      openWhatsAppForNumber(numbers.single, message).then((ok) {
        if (!ok) {
          showErrorMessage(
            _t(
              'Cannot open WhatsApp. Make sure it is installed or try again.',
              'Imeshindikana kufungua WhatsApp. Hakikisha imewekwa au jaribu tena.',
            ),
          );
        }
      });
      return;
    }
    // Multiple numbers: show dialog to pick which to open
    Get.dialog(
      AlertDialog(
        title: Text(_t('Send via WhatsApp', 'Tuma kupitia WhatsApp')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(
                'Open WhatsApp for a number (send the message there, then return and pick the next):',
                'Fungua WhatsApp kwa namba moja (tuma ujumbe huko, kisha rudi uchague inayofuata):',
              ),
            ),
            const SizedBox(height: 16),
            ...numbers
                .map(
                  (number) => ListTile(
                    leading: const Icon(Icons.chat),
                    title: Text(number),
                    subtitle: Text(_t('Open WhatsApp', 'Fungua WhatsApp')),
                    onTap: () async {
                      Get.back();
                      final ok = await openWhatsAppForNumber(number, message);
                      if (!ok) {
                        showErrorMessage(
                          _t(
                            'Cannot open WhatsApp. Make sure it is installed or try again.',
                            'Imeshindikana kufungua WhatsApp. Hakikisha imewekwa au jaribu tena.',
                          ),
                        );
                      }
                    },
                  ),
                ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(_t('Close', 'Funga')),
          ),
        ],
      ),
    );
  }

  /// Normalize WhatsApp group link: full URL or invite code only.
  String normalizeGroupLink(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.toLowerCase().startsWith('http')) {
      return trimmed;
    }
    return 'https://chat.whatsapp.com/$trimmed';
  }

  /// Open WhatsApp group and copy message to clipboard so user can paste in the group.
  Future<void> sendToWhatsAppGroup() async {
    final linkInput = groupLinkController.text.trim();
    if (linkInput.isEmpty) {
      showErrorMessage(
        _t(
          'Please enter the WhatsApp group invite link.',
          'Tafadhali weka kiungo cha mwaliko wa kikundi cha WhatsApp.',
        ),
      );
      return;
    }
    final message = messageController.text.trim();
    if (message.isEmpty) {
      showErrorMessage(
        _t(
          'Please enter a message to send to the group.',
          'Tafadhali weka ujumbe wa kutuma kwenye kikundi.',
        ),
      );
      return;
    }
    final urlString = normalizeGroupLink(linkInput);
    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme) {
      showErrorMessage(
        _t(
          'Invalid group link. Use the full link or invite code.',
          'Kiungo cha kikundi si sahihi. Tumia kiungo kamili au msimbo wa mwaliko.',
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: message));
    showSuccessMessage(
      _t(
        'Message copied. Open the group and paste (Ctrl+V / long-press Paste).',
        'Ujumbe umenakiliwa. Fungua kikundi kisha bandika.',
      ),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showErrorMessage(
        _t(
          'Cannot open WhatsApp. Make sure it is installed or try again.',
          'Imeshindikana kufungua WhatsApp. Hakikisha imewekwa au jaribu tena.',
        ),
      );
    }
  }
}
