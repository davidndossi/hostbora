import 'dart:convert';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/constants/ui_preference_keys.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widget/undo_snackbar.dart';
import '../../../data/local/db/tenant_local_data_source.dart';
import '../../../data/local/service/bnb_messaging_contacts_service.dart';
import '../../../data/local/service/workspace_context_service.dart';
import '../../../data/model/messaging_contact.dart';
import '../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../../../data/local/preference/preference_manager.dart';
import '../../../data/model/general_response.dart';
import '../../../data/model/send_sms_request.dart';
import '../../../data/repository/app_repository.dart';
import '../../../routes/app_pages.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../../data/model/send_whatsapp_bulk_request.dart';
import '../../../data/model/send_whatsapp_template_request.dart';
import '../models/device_contact_entry.dart';
import '../models/saved_whatsapp_group.dart';
import '../views/whatsapp_credentials_dialog.dart';

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
  final availableGuests = <MessagingContact>[].obs;
  final pickerSelectedGuestKeys = <String>{}.obs;
  final workspace = 'rent'.obs;
  final messagingPropertyRef = ''.obs;
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

  /// True when the signed-in user has ACTIVE WhatsApp Cloud API credentials on the server.
  final whatsappConfigured = false.obs;
  final isLoadingWhatsAppStatus = false.obs;

  /// When a saved template is selected, send via Meta template API (not free-text).
  final sendAsMetaTemplate = true.obs;
  final templateBodyParamControllers = <TextEditingController>[].obs;
  final templateHeaderParamControllers = <TextEditingController>[].obs;

  late TabController tabController;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    super.onInit();
    _prefillFromRouteArgs();
    _checkAccess();
    unawaited(_initWorkspaceAndRecipients());
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

  Future<void> _initWorkspaceAndRecipients() async {
    final fromArgsWorkspace = _routeArgString('workspace');
    if (fromArgsWorkspace.isNotEmpty) {
      workspace.value = fromArgsWorkspace == 'bnb' ? 'bnb' : 'rent';
    } else {
      final savedWs =
          await _preferenceManager.getString(UiPreferenceKeys.sendSmsWorkspace);
      if (savedWs == 'bnb' || savedWs == 'rent') {
        workspace.value = savedWs;
      } else if (Get.isRegistered<WorkspaceContextService>()) {
        workspace.value =
            await Get.find<WorkspaceContextService>().getWorkspaceType();
      }
    }
    await _preferenceManager.setString(
      UiPreferenceKeys.sendSmsWorkspace,
      workspace.value,
    );

    final fromArgsProperty = _routeArgString('propertyRef');
    if (fromArgsProperty.isNotEmpty) {
      messagingPropertyRef.value = fromArgsProperty;
    } else {
      messagingPropertyRef.value = await _preferenceManager.getString(
        UiPreferenceKeys.sendSmsPropertyRef,
      );
    }
    await _preferenceManager.setString(
      UiPreferenceKeys.sendSmsPropertyRef,
      messagingPropertyRef.value.trim(),
    );

    await _loadRecipientsForPicker();
  }

  Future<void> setMessagingPropertyRef(String? propertyRef) async {
    final next = propertyRef?.trim() ?? '';
    messagingPropertyRef.value = next;
    await _preferenceManager.setString(
      UiPreferenceKeys.sendSmsPropertyRef,
      next,
    );
    await _loadRecipientsForPicker();
  }

  bool get isBnbWorkspace => workspace.value == 'bnb';

  Future<void> _loadRecipientsForPicker() async {
    try {
      final ws = workspace.value;
      final propertyRefFilter = _effectivePropertyRefFilter();
      final rows = await _tenantLocal.getAllNewestFirstByWorkspace(ws);
      final scoped = propertyRefFilter.isEmpty
          ? rows
          : rows.where((e) => e.propertyRef.trim() == propertyRefFilter).toList();
      availableTenants.assignAll(scoped);
      if (ws == 'bnb') {
        final contactsService = Get.isRegistered<BnbMessagingContactsService>()
            ? Get.find<BnbMessagingContactsService>()
            : BnbMessagingContactsService();
        final guests = await contactsService.loadGuestContacts();
        availableGuests.assignAll(guests);
      } else {
        availableGuests.clear();
      }
      pickerSelectedGuestKeys.clear();
    } catch (_) {
      availableTenants.clear();
      availableGuests.clear();
    }
  }

  String _routeArgString(String key) {
    final args = Get.arguments;
    if (args is! Map) return '';
    final map = Map<String, dynamic>.from(args);
    return (map[key] ?? '').toString().trim();
  }

  String _effectivePropertyRefFilter() {
    final fromRoute = _routeArgString('propertyRef');
    if (fromRoute.isNotEmpty) return fromRoute;
    return messagingPropertyRef.value.trim();
  }

  bool get isPropertyRefLockedByRoute =>
      _routeArgString('propertyRef').isNotEmpty;

  String get messagingPropertyFilterLabel {
    final ref = messagingPropertyRef.value.trim();
    if (ref.isEmpty) return '';
    for (final t in availableTenants) {
      if (t.propertyRef.trim() == ref) {
        final label = t.propertyLabel.trim();
        if (label.isNotEmpty) return label;
      }
    }
    return ref;
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
    _disposeTemplateParamControllers();
    selectedTemplateId.value = id;
    if (id == null) {
      sendAsMetaTemplate.value = false;
      return;
    }
    final found = selectedWhatsappTemplate;
    if (found == null) return;
    _initTemplateParamControllers(found);
    sendAsMetaTemplate.value = found.name.trim().isNotEmpty;
    messageController.text = _renderTemplateWithSamples(found);
    messageController.selection = TextSelection.collapsed(
      offset: messageController.text.length,
    );
  }

  RentWhatsappTemplateRecord? get selectedWhatsappTemplate {
    final id = selectedTemplateId.value;
    if (id == null) return null;
    for (final t in savedMessageTemplates) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool get canUseMetaTemplateApi {
    final t = selectedWhatsappTemplate;
    return t != null &&
        sendAsMetaTemplate.value &&
        t.name.trim().isNotEmpty &&
        whatsappConfigured.value;
  }

  void _disposeTemplateParamControllers() {
    for (final c in templateBodyParamControllers) {
      c.dispose();
    }
    for (final c in templateHeaderParamControllers) {
      c.dispose();
    }
    templateBodyParamControllers.clear();
    templateHeaderParamControllers.clear();
  }

  void _initTemplateParamControllers(RentWhatsappTemplateRecord t) {
    final bodyCount = _countBodyVariables(t);
    final headerCount = _countHeaderVariables(t);
    for (var i = 0; i < bodyCount; i++) {
      final sample = i < t.sampleVariables.length ? t.sampleVariables[i] : '';
      templateBodyParamControllers.add(TextEditingController(text: sample));
    }
    for (var i = 0; i < headerCount; i++) {
      templateHeaderParamControllers.add(TextEditingController(text: ''));
    }
  }

  int _countBodyVariables(RentWhatsappTemplateRecord t) {
    var max = 0;
    for (final m in RegExp(r'\{\{(\d+)\}\}').allMatches(t.bodyText)) {
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n > max) max = n;
    }
    if (max > 0) return max;
    return t.sampleVariables.length;
  }

  int _countHeaderVariables(RentWhatsappTemplateRecord t) {
    if (t.headerType != WaTemplateHeaderType.text) return 0;
    var max = 0;
    for (final m in RegExp(r'\{\{(\d+)\}\}').allMatches(t.headerText)) {
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n > max) max = n;
    }
    return max;
  }

  List<String> _collectBodyParameters() =>
      templateBodyParamControllers.map((c) => c.text.trim()).toList();

  List<String> _collectHeaderParameters() =>
      templateHeaderParamControllers.map((c) => c.text.trim()).toList();

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
    if (index < 0 || index >= savedGroups.length) return;
    final snapshot = savedGroups[index];
    savedGroups.removeAt(index);
    _persistSavedGroups();
    hapticPrimaryConfirm();
    final ctx = Get.context;
    if (ctx == null || !ctx.mounted) return;
    UndoSnackBar.show(
      ctx,
      message: 'Group removed',
      onUndo: () {
        if (index <= savedGroups.length) {
          savedGroups.insert(index, snapshot);
        } else {
          savedGroups.add(snapshot);
        }
        _persistSavedGroups();
      },
    );
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
      unawaited(refreshWhatsAppStatus());
    } else {
      isAccessAllowed(false);
      Get.offNamed(Routes.SUBSCRIPTION);
    }
  }

  Future<void> refreshWhatsAppStatus() async {
    isLoadingWhatsAppStatus(true);
    try {
      final res = await _repository.getWhatsAppStatus();
      if (res.responseCode == '0' && res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        whatsappConfigured.value = map['configured'] == true;
      } else {
        whatsappConfigured.value = false;
      }
    } catch (_) {
      whatsappConfigured.value = false;
    } finally {
      isLoadingWhatsAppStatus(false);
    }
  }

  Future<void> linkWhatsAppBusinessAccount() async {
    final linked = await showWhatsAppCredentialsDialog(repository: _repository);
    if (linked) {
      await refreshWhatsAppStatus();
      showSuccessMessage(
        _t(
          'WhatsApp Business linked. You can send from the app.',
          'WhatsApp Business imeunganishwa. Unaweza kutuma kutoka programu.',
        ),
      );
    }
  }

  @override
  void onClose() {
    _disposeTemplateParamControllers();
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

  void toggleGuestForPicker(String key, bool selected) {
    final current = Set<String>.from(pickerSelectedGuestKeys);
    if (selected) {
      current.add(key);
    } else {
      current.remove(key);
    }
    pickerSelectedGuestKeys.assignAll(current);
  }

  void appendSelectedTenantsToRecipients() {
    final selected = <String>[
      ...availableTenants
          .where((t) => pickerSelectedTenantIds.contains(t.id))
          .map((t) => t.phoneNumber.trim())
          .where((n) => n.isNotEmpty),
      ...availableGuests
          .where((g) => pickerSelectedGuestKeys.contains(g.key))
          .map((g) => g.phone.trim())
          .where((n) => n.isNotEmpty),
    ];
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
    if (selectedTemplateId.value != null &&
        sendAsMetaTemplate.value &&
        (selectedWhatsappTemplate?.name.trim().isNotEmpty ?? false)) {
      return null;
    }
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

  /// Sends via WhatsApp Cloud API (per-user credentials) or opens the device app as fallback.
  Future<void> sendViaWhatsApp() async {
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

    if (canUseMetaTemplateApi) {
      for (var i = 0; i < templateBodyParamControllers.length; i++) {
        if (templateBodyParamControllers[i].text.trim().isEmpty) {
          showErrorMessage(
            _t(
              'Please fill template variable {{${i + 1}}}',
              'Tafadhali jaza kigezo cha kiolezo {{${i + 1}}}',
            ),
          );
          return;
        }
      }
    }

    if (!whatsappConfigured.value) {
      final link = await Get.dialog<bool>(
        AlertDialog(
          title: Text(_t('Link WhatsApp Business', 'Unganisha WhatsApp Business')),
          content: Text(
            _t(
              'Connect your Meta WhatsApp Business API to send messages from the app (including to all selected tenants). You can also send manually on this device.',
              'Unganisha Meta WhatsApp Business API kutuma kutoka programu (pamoja na wapangaji wote). Unaweza pia kutuma kwa mkono kwenye simu hii.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(_t('Send on device', 'Tuma kwenye simu')),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(_t('Link account', 'Unganisha akaunti')),
            ),
          ],
        ),
      );
      if (link == true) {
        await linkWhatsAppBusinessAccount();
        if (!whatsappConfigured.value) return;
      } else {
        await _sendViaWhatsAppOnDevice(numbers, message);
        return;
      }
    }

    isLoading(true);
    try {
      if (canUseMetaTemplateApi) {
        await _sendViaWhatsAppTemplateApi(numbers);
      } else {
        await _sendViaWhatsAppTextApi(numbers, message);
      }
    } catch (e) {
      showErrorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> _sendViaWhatsAppTextApi(List<String> numbers, String message) async {
    if (numbers.length == 1) {
      final res = await _repository.sendWhatsApp(
        SendSmsRequest(phoneNumber: numbers.single, message: message),
      );
      if (res.responseCode == '0') {
        _showWhatsAppSendSuccessDialog(sent: 1, total: 1, isTemplate: false);
      } else {
        showErrorMessage(
          res.message ??
              _t('Failed to send WhatsApp message', 'Imeshindikana kutuma WhatsApp'),
        );
      }
      return;
    }
    final res = await _repository.sendWhatsAppBulk(
      SendWhatsAppBulkRequest(phoneNumbers: numbers, message: message),
    );
    _handleWhatsAppBulkResponse(res, numbers.length, isTemplate: false);
  }

  Future<void> _sendViaWhatsAppTemplateApi(List<String> numbers) async {
    final template = selectedWhatsappTemplate!;
    final templateName = template.name.trim();
    final languageCode = template.language.trim().isEmpty
        ? 'en_US'
        : template.language.trim();
    final bodyParams = _collectBodyParameters();
    final headerParams = _collectHeaderParameters();

    if (numbers.length == 1) {
      final res = await _repository.sendWhatsAppTemplate(
        SendWhatsAppTemplateRequest(
          phoneNumber: numbers.single,
          templateName: templateName,
          languageCode: languageCode,
          bodyParameters: bodyParams,
          headerParameters: headerParams,
        ),
      );
      if (res.responseCode == '0') {
        _showWhatsAppSendSuccessDialog(sent: 1, total: 1, isTemplate: true);
      } else {
        showErrorMessage(
          res.message ??
              _t('Failed to send template', 'Imeshindikana kutuma kiolezo'),
        );
      }
      return;
    }

    final res = await _repository.sendWhatsAppTemplateBulk(
      SendWhatsAppTemplateBulkRequest(
        phoneNumbers: numbers,
        templateName: templateName,
        languageCode: languageCode,
        bodyParameters: bodyParams,
        headerParameters: headerParams,
      ),
    );
    _handleWhatsAppBulkResponse(res, numbers.length, isTemplate: true);
  }

  void _handleWhatsAppBulkResponse(
    GeneralResponse res,
    int recipientCount, {
    required bool isTemplate,
  }) {
    if (res.responseCode == '0' && res.data is Map) {
      final data = Map<String, dynamic>.from(res.data as Map);
      final sent = (data['sent'] as num?)?.toInt() ?? 0;
      final total = (data['total'] as num?)?.toInt() ?? recipientCount;
      if (sent == total) {
        _showWhatsAppSendSuccessDialog(
          sent: sent,
          total: total,
          isTemplate: isTemplate,
        );
      } else if (sent > 0) {
        Get.dialog(
          AlertDialog(
            title: Text(_t('Partially sent', 'Imetumwa kwa sehemu')),
            content: Text(
              _t(
                'Sent to $sent of $total via WhatsApp Business API.',
                'Imetumwa kwa $sent kati ya $total kupitia WhatsApp Business API.',
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
          res.message ??
              _t('Failed to send WhatsApp messages', 'Imeshindikana kutuma WhatsApp'),
        );
      }
    } else {
      showErrorMessage(
        res.message ??
            _t('Failed to send WhatsApp messages', 'Imeshindikana kutuma WhatsApp'),
      );
    }
  }

  void _showWhatsAppSendSuccessDialog({
    required int sent,
    required int total,
    bool isTemplate = false,
  }) {
    hapticPrimaryConfirm();
    Get.dialog(
      AlertDialog(
        title: Text(_t('Success', 'Imefanikiwa')),
        content: Text(
          isTemplate
              ? _t(
                  'Meta template sent to $sent recipient(s).',
                  'Kiolezo cha Meta kimetumwa kwa wapokeaji $sent.',
                )
              : _t(
                  'WhatsApp sent to $sent recipient(s) via your Business API.',
                  'WhatsApp imetumwa kwa wapokeaji $sent kupitia Business API yako.',
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
  }

  Future<void> _sendViaWhatsAppOnDevice(List<String> numbers, String message) async {
    if (numbers.length == 1) {
      final ok = await openWhatsAppForNumber(numbers.single, message);
      if (!ok) {
        showErrorMessage(
          _t(
            'Cannot open WhatsApp. Make sure it is installed or try again.',
            'Imeshindikana kufungua WhatsApp. Hakikisha imewekwa au jaribu tena.',
          ),
        );
      }
      return;
    }
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
            ...numbers.map(
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
