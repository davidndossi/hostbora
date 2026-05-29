import 'package:flutter/material.dart';
import 'package:paa_yangu/app/core/widget/skeleton_presets.dart';

import 'package:get/get.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/base/base_view.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_values.dart';
import '../../../core/widget/custom_app_bar.dart';
import '../../../core/widget/loading_button.dart';
import '../../../data/local/db/rent_whatsapp_template_local_data_source.dart';
import '../controllers/send_sms_controller.dart';

class SendSmsView extends BaseView<SendSmsController> {
  SendSmsView({super.key});

  String _t(BuildContext context, String en, String sw) {
    return Localizations.localeOf(context).languageCode == 'sw' ? sw : en;
  }

  Widget _buildSavedTemplatesPicker(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.savedMessageTemplates.isEmpty) {
        final isBnb = controller.isBnbWorkspace;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppValues.spacing_20),
          child: Text(
            _t(
              context,
              isBnb
                  ? 'No saved templates yet. Create templates under BnB home → WhatsApp templates or Rent hub → More.'
                  : 'No saved templates yet. Create templates under Rent hub → More → WhatsApp templates.',
              isBnb
                  ? 'Bado hakuna miolezo. Tengeneza chini ya BnB → Violezo vya WhatsApp au Rent → Zaidi.'
                  : 'Bado hakuna miolezo. Tengeneza chini ya Rent → Zaidi → Miolezo ya WhatsApp.',
            ),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: AppValues.spacing_20),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: _t(
              context,
              'Saved template',
              'Kiolezo kilichohifadhiwa',
            ),
            helperText: _t(
              context,
              'Replaces {{1}}, {{2}}, … with values saved for each template.',
              'Hubadilisha {{1}}, {{2}}, … kwa maadili yaliyohifadhiwa kwa kila kiolezo.',
            ),
            border: const OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: controller.selectedTemplateId.value,
              isExpanded: true,
              isDense: true,
              hint: Text(
                _t(context, 'Choose a template', 'Chagua kiolezo'),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    _t(context, 'Custom message only', 'Ujumbe wa kawaida tu'),
                  ),
                ),
                ...controller.savedMessageTemplates.map(
                  (t) => DropdownMenuItem<int?>(
                    value: t.id,
                    child: Text(
                      t.name.trim().isEmpty ? 'Template #${t.id}' : t.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: controller.onMessageTemplateSelected,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMetaTemplateSection(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final t = controller.selectedWhatsappTemplate;
      if (t == null || t.name.trim().isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: AppValues.spacing_20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _t(
                  context,
                  'Send as Meta template',
                  'Tuma kama kiolezo cha Meta',
                ),
              ),
              subtitle: Text(
                _t(
                  context,
                  'Name must match an approved template in Meta (${t.name}, ${t.language}).',
                  'Jina lazima lifanane na kiolezo kilichoidhinishwa Meta (${t.name}, ${t.language}).',
                ),
                style: theme.textTheme.bodySmall,
              ),
              value: controller.sendAsMetaTemplate.value,
              onChanged: controller.whatsappConfigured.value
                  ? (v) => controller.sendAsMetaTemplate.value = v
                  : null,
            ),
            if (t.status != WaTemplateStatus.approved)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _t(
                    context,
                    'Status: ${WaTemplateStatus.label(t.status)} — Meta may reject if not approved.',
                    'Hali: ${WaTemplateStatus.label(t.status)} — Meta inaweza kukataa ikiwa haijaidhinishwa.',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            if (controller.sendAsMetaTemplate.value &&
                controller.templateHeaderParamControllers.isNotEmpty) ...[
              Text(
                _t(context, 'Header variables', 'Vigezo vya kichwa'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                controller.templateHeaderParamControllers.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: controller.templateHeaderParamControllers[i],
                    decoration: InputDecoration(
                      labelText: '{{${i + 1}}} (header)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
            if (controller.sendAsMetaTemplate.value &&
                controller.templateBodyParamControllers.isNotEmpty) ...[
              Text(
                _t(context, 'Body variables', 'Vigezo vya mwili'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                controller.templateBodyParamControllers.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: controller.templateBodyParamControllers[i],
                    decoration: InputDecoration(
                      labelText: '{{${i + 1}}}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildWhatsAppMessageField(BuildContext context) {
    return Obx(() {
      if (controller.canUseMetaTemplateApi) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppValues.spacing_20),
          child: Text(
            _t(
              context,
              'Message content comes from the Meta template variables above.',
              'Maudhui yanatoka kwenye vigezo vya kiolezo cha Meta hapo juu.',
            ),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: AppValues.spacing_20),
        child: TextFormField(
          controller: controller.messageController,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: _t(context, 'Message', 'Ujumbe'),
            hintText: _t(
              context,
              'Enter your message...',
              'Weka ujumbe wako...',
            ),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          validator: controller.messageValidator,
        ),
      );
    });
  }

  Future<void> _showContactPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ready = await controller.prepareContactPicker();
    if (!ready || !context.mounted) return;
    final searchController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SizedBox(
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sendSmsSelectContactRecipients,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.sendSmsPickContactsHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: l10n.sendSmsSearchContacts,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => controller.contactPickerSearchQuery.value = v,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoadingContacts.value) {
                        return const DefaultScreenSkeleton();
                      }
                      final entries = controller.filteredDeviceContactEntries;
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(l10n.sendSmsNoContactsWithPhones),
                        );
                      }
                      return ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (_, index) {
                          final entry = entries[index];
                          final selected = controller.pickerSelectedContactKeys
                              .contains(entry.selectionKey);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) => controller.toggleContactForPicker(
                              entry.selectionKey,
                              v ?? false,
                            ),
                            title: Text(entry.displayName),
                            subtitle: Text(entry.phone),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.appendSelectedContactsToRecipients();
                        Get.back();
                      },
                      icon: const Icon(Icons.contact_phone_outlined),
                      label: Text(l10n.sendSmsAddSelectedContactNumbers),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    searchController.dispose();
  }

  Future<void> _showGuestPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SizedBox(
              height: 460,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(ctx, 'Select guest recipients', 'Chagua wapokeaji wageni'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => Text(
                      controller.recipientContextLabel.value.isEmpty
                          ? _t(
                              ctx,
                              'Pick guests from active bookings to append their numbers.',
                              'Chagua wageni kutoka uhifadhi hai kuongeza namba zao.',
                            )
                          : controller.recipientContextLabel.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Obx(() {
                      if (controller.availableGuests.isEmpty) {
                        return Center(
                          child: Text(
                            _t(
                              ctx,
                              'No guests with phone numbers in bookings.',
                              'Hakuna wageni wenye namba katika uhifadhi.',
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: controller.availableGuests.length,
                        itemBuilder: (_, index) {
                          final g = controller.availableGuests[index];
                          final selected = controller.pickerSelectedGuestKeys
                              .contains(g.key);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) => controller.toggleGuestForPicker(
                              g.key,
                              v ?? false,
                            ),
                            title: Text(g.label),
                            subtitle: Text(
                              [
                                if (g.subtitle.trim().isNotEmpty) g.subtitle,
                                g.phone,
                              ].join('\n'),
                              maxLines: 2,
                            ),
                            isThreeLine: true,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.appendSelectedTenantsToRecipients();
                        Get.back();
                      },
                      icon: const Icon(Icons.add_ic_call_outlined),
                      label: Text(
                        _t(
                          ctx,
                          'Add selected phone numbers',
                          'Ongeza namba zilizochaguliwa',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTenantPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SizedBox(
              height: 460,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(ctx, 'Select tenant recipients', 'Chagua wapokeaji wapangaji'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => Text(
                      controller.recipientContextLabel.value.isEmpty
                          ? _t(
                              ctx,
                              'Pick one or more tenants to append their numbers.',
                              'Chagua mpangaji mmoja au zaidi kuongeza namba zao.',
                            )
                          : controller.recipientContextLabel.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Obx(() {
                      if (controller.availableTenants.isEmpty) {
                        return Center(
                          child: Text(
                            _t(
                              ctx,
                              'No tenants available in this context.',
                              'Hakuna wapangaji kwenye muktadha huu.',
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: controller.availableTenants.length,
                        itemBuilder: (_, index) {
                          final t = controller.availableTenants[index];
                          final selected = controller.pickerSelectedTenantIds
                              .contains(t.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) => controller.toggleTenantForPicker(
                              t.id,
                              v ?? false,
                            ),
                            title: Text(
                              t.tenantName.trim().isEmpty
                                  ? t.phoneNumber
                                  : t.tenantName,
                            ),
                            subtitle: Text(
                              '${t.propertyLabel}\n${t.phoneNumber}',
                              maxLines: 2,
                            ),
                            isThreeLine: true,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.appendSelectedTenantsToRecipients();
                        Get.back();
                      },
                      icon: const Icon(Icons.add_ic_call_outlined),
                      label: Text(
                        _t(
                          ctx,
                          'Add selected phone numbers',
                          'Ongeza namba zilizochaguliwa',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyScopeChip(BuildContext context) {
    return Obx(() {
      final ref = controller.messagingPropertyRef.value.trim();
      if (ref.isEmpty) return const SizedBox.shrink();
      final locked = controller.isPropertyRefLockedByRoute;
      final label = controller.messagingPropertyFilterLabel;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppValues.spacing_10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: InputChip(
            avatar: const Icon(Icons.home_work_outlined, size: 18),
            label: Text(
              _t(
                context,
                'Property: $label',
                'Mali: $label',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            deleteIcon: locked ? null : const Icon(Icons.close, size: 18),
            onDeleted:
                locked ? null : () => controller.setMessagingPropertyRef(null),
          ),
        ),
      );
    });
  }

  Widget _buildRecipientAssistActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Obx(
      () {
        final isBnb = controller.isBnbWorkspace;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBnb)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showGuestPicker(context),
                    icon: const Icon(Icons.hotel_outlined, size: 18),
                    label: Text(
                      _t(context, 'Pick guest(s)', 'Chagua mgeni/mageni'),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTenantPicker(context),
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    label: Text(
                      _t(
                        context,
                        isBnb ? 'Pick BnB tenant(s)' : 'Pick tenant(s)',
                        isBnb ? 'Chagua mpangaji BnB' : 'Chagua mpangaji',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showContactPicker(context),
                    icon: const Icon(Icons.contacts_outlined, size: 18),
                    label: Text(l10n.sendSmsPickFromContacts),
                  ),
                ),
              ],
            ),
            if (controller.pickerSelectedGuestKeys.isNotEmpty ||
                controller.pickerSelectedTenantIds.isNotEmpty ||
                controller.pickerSelectedContactKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  [
                    if (controller.pickerSelectedGuestKeys.isNotEmpty)
                      _t(
                        context,
                        '${controller.pickerSelectedGuestKeys.length} guest(s)',
                        'wageni ${controller.pickerSelectedGuestKeys.length}',
                      ),
                    if (controller.pickerSelectedTenantIds.isNotEmpty)
                      _t(
                        context,
                        '${controller.pickerSelectedTenantIds.length} tenant(s)',
                        'wapangaji ${controller.pickerSelectedTenantIds.length}',
                      ),
                    if (controller.pickerSelectedContactKeys.isNotEmpty)
                      l10n.sendSmsContactsSelectedCount(
                        controller.pickerSelectedContactKeys.length,
                      ),
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSaveTemplateControls(BuildContext context, {required bool isWhatsApp}) {
    return Obx(
      () => Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: controller.saveAsTemplateEnabled.value,
            title: Text(
              _t(
                context,
                'Save current message as template',
                'Hifadhi ujumbe huu kama kiolezo',
              ),
            ),
            onChanged: (value) {
              controller.saveAsTemplateEnabled.value = value;
            },
          ),
          if (controller.saveAsTemplateEnabled.value)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.templateNameController,
                    decoration: InputDecoration(
                      labelText: _t(context, 'Template name', 'Jina la kiolezo'),
                      hintText: _t(
                        context,
                        isWhatsApp ? 'e.g. rent_followup' : 'e.g. payment reminder',
                        isWhatsApp ? 'mf. ufuatiliaji_kodi' : 'mf. ukumbusho wa malipo',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => controller.saveCurrentMessageAsTemplate(
                    isWhatsApp: isWhatsApp,
                  ),
                  child: Text(_t(context, 'Save', 'Hifadhi')),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: _t(context, 'Send SMS/Whatsapp', 'Tuma SMS/WhatsApp'),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      if (controller.isCheckingAccess.value) {
        return const DefaultScreenSkeleton();
      }
      if (!controller.isAccessAllowed.value) {
        return Center(
          child: Text(
            _t(context, 'Access denied', 'Ufikiaji umekataliwa'),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        );
      }
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: controller.formKey,
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 200,
                  child: ToggleSwitch(
                    fontSize: 16.0,
                    minWidth: 100,
                    initialLabelIndex: 0,
                    activeBgColor: const [AppColors.colorPrimary],
                    activeFgColor: Colors.white,
                    inactiveBgColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade300,
                    inactiveFgColor: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey.shade900,
                    totalSwitches: 2,
                    labels: ['SMS', 'WhatsApp'],
                    onToggle: (index) {
                      controller.isFirstView.toggle();
                    },
                  ),
                ),
                const SizedBox(height: AppValues.spacing_10),
                _buildPropertyScopeChip(context),
                const SizedBox(height: AppValues.spacing_20),
                Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: controller.isFirstView.value
                        ? Column(
                            children: [
                              TextFormField(
                                controller: controller.phoneNumbersController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: _t(
                                    context,
                                    'Phone numbers',
                                    'Namba za simu',
                                  ),
                                  hintText: _t(
                                    context,
                                    'One per line or comma separated\ne.g. 0612345678, 0712345678',
                                    'Moja kwa kila mstari au tumia koma\nmf. 0612345678, 0712345678',
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.phone),
                                  alignLabelWithHint: true,
                                ),
                                validator: controller.phoneNumbersValidator,
                              ),
                              const SizedBox(height: AppValues.spacing_10),
                              _buildRecipientAssistActions(context),
                              const SizedBox(height: AppValues.spacing_20),
                              _buildSavedTemplatesPicker(context),
                              TextFormField(
                                controller: controller.messageController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: _t(context, 'Message', 'Ujumbe'),
                                  hintText: _t(
                                    context,
                                    'Enter your message...',
                                    'Weka ujumbe wako...',
                                  ),
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                validator: controller.messageValidator,
                              ),
                              const SizedBox(height: AppValues.spacing_10),
                              _buildSaveTemplateControls(
                                context,
                                isWhatsApp: false,
                              ),
                              const SizedBox(height: AppValues.spacing_20),
                              Obx(
                                () => SizedBox(
                                  width: AppValues.formButtonWidth,
                                  child: LoadingButton(
                                    label: _t(context, 'Send SMS', 'Tuma SMS'),
                                    onPressed: controller.sendSms,
                                    isLoading: controller.isLoading.value,
                                    icon: Icons.sms_outlined,
                                    minimumSize: const Size.fromHeight(
                                      AppValues.formButtonHeight,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              TabBar(
                                controller: controller.tabController,
                                isScrollable: true,
                                labelColor: isDark
                                    ? theme.colorScheme.onSurface
                                    : Colors.black87,
                                unselectedLabelColor: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.grey,
                                tabs: [
                                  Tab(text: _t(context, 'Chat', 'Mazungumzo')),
                                  Tab(text: _t(context, 'Group', 'Kikundi')),
                                ],
                              ),
                              const SizedBox(height: AppValues.spacing_20),
                              SizedBox(
                                height: 500,
                                child: TabBarView(
                                  controller: controller.tabController,
                                  children: [
                                    Column(
                                      children: [
                                        TextFormField(
                                          controller:
                                              controller.phoneNumbersController,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Phone numbers',
                                              'Namba za simu',
                                            ),
                                            hintText: _t(
                                              context,
                                              'One per line or comma separated\ne.g. 0612345678, 0712345678',
                                              'Moja kwa kila mstari au tumia koma\nmf. 0612345678, 0712345678',
                                            ),
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.phone),
                                            alignLabelWithHint: true,
                                          ),
                                          validator:
                                              controller.phoneNumbersValidator,
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        _buildRecipientAssistActions(context),
                                        const SizedBox(
                                          height: AppValues.spacing_20,
                                        ),
                                        _buildSavedTemplatesPicker(context),
                                        _buildMetaTemplateSection(context),
                                        _buildWhatsAppMessageField(context),
                                        Text(
                                          _t(
                                            context,
                                            'Generate multimedia message (AI)',
                                            'Tengeneza ujumbe wa media (AI)',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        TextFormField(
                                          controller:
                                              controller.promptController,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Prompt',
                                              'Maelekezo',
                                            ),
                                            hintText: _t(
                                              context,
                                              'Describe the message (e.g. announcement with image, voice note, document)...',
                                              'Eleza ujumbe (mf. tangazo lenye picha, sauti, au faili)...',
                                            ),
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.auto_awesome,
                                            ),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Include media:',
                                            'Jumuisha media:',
                                          ),
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Obx(
                                          () => Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Image', 'Picha'),
                                                ),
                                                selected: controller
                                                    .includeImage
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeImage(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Audio', 'Sauti'),
                                                ),
                                                selected: controller
                                                    .includeAudio
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeAudio(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'File', 'Faili'),
                                                ),
                                                selected: controller
                                                    .includeFile
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeFile(v),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Obx(
                                          () => OutlinedButton.icon(
                                            onPressed:
                                                controller.isGenerating.value
                                                ? null
                                                : controller
                                                      .generateMultimediaMessage,
                                            icon: controller.isGenerating.value
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.auto_awesome,
                                                    size: 20,
                                                  ),
                                            label: Text(
                                              controller.isGenerating.value
                                                  ? _t(
                                                      context,
                                                      'Generating...',
                                                      'Inatengeneza...',
                                                    )
                                                  : _t(
                                                      context,
                                                      'Generate message',
                                                      'Tengeneza ujumbe',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Obx(() {
                                          if (controller.isLoadingWhatsAppStatus.value) {
                                            return const SizedBox.shrink();
                                          }
                                          final linked = controller.whatsappConfigured.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppValues.spacing_10,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    linked
                                                        ? _t(
                                                            context,
                                                            'Sending via your WhatsApp Business API',
                                                            'Inatumwa kupitia WhatsApp Business API yako',
                                                          )
                                                        : _t(
                                                            context,
                                                            'Link WhatsApp Business to send from the app',
                                                            'Unganisha WhatsApp Business kutuma kutoka programu',
                                                          ),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: linked
                                                          ? Colors.green.shade700
                                                          : Colors.orange.shade800,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: controller.linkWhatsAppBusinessAccount,
                                                  child: Text(
                                                    linked
                                                        ? _t(context, 'Update', 'Sasisha')
                                                        : _t(context, 'Link', 'Unganisha'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        Obx(
                                          () => LoadingButton(
                                            label: _t(
                                              context,
                                              'Send via WhatsApp',
                                              'Tuma kwa WhatsApp',
                                            ),
                                            onPressed: controller.sendViaWhatsApp,
                                            isLoading: controller.isLoading.value,
                                            icon: Icons.send_outlined,
                                            minimumSize: const Size.fromHeight(48),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        _buildSaveTemplateControls(
                                          context,
                                          isWhatsApp: true,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          _t(
                                            context,
                                            'WhatsApp group',
                                            'Kikundi cha WhatsApp',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        TextFormField(
                                          controller:
                                              controller.groupLinkController,
                                          keyboardType: TextInputType.url,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Group invite link',
                                              'Kiungo cha mwaliko wa kikundi',
                                            ),
                                            hintText: _t(
                                              context,
                                              'https://chat.whatsapp.com/... or paste invite code',
                                              'https://chat.whatsapp.com/... au bandika msimbo wa mwaliko',
                                            ),
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.group),
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                Icons.save_outlined,
                                              ),
                                              onPressed: controller
                                                  .saveCurrentGroupLink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Saved groups',
                                            'Vikundi vilivyohifadhiwa',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Obx(() {
                                          if (controller.savedGroups.isEmpty) {
                                            return Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Text(
                                                _t(
                                                  context,
                                                  'No saved groups. Paste a link and tap "Save link for future".',
                                                  'Hakuna vikundi vilivyohifadhiwa. Bandika kiungo kisha gusa "Hifadhi kwa matumizi ya baadaye".',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            );
                                          }
                                          return Column(
                                            children: controller.savedGroups
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                                  final i = entry.key;
                                                  final g = entry.value;
                                                  return Card(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: ListTile(
                                                      leading: const Icon(
                                                        Icons.link,
                                                      ),
                                                      title: Text(g.name),
                                                      subtitle: Text(
                                                        g.link.length > 40
                                                            ? '${g.link.substring(0, 40)}...'
                                                            : g.link,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                controller
                                                                    .useSavedGroup(
                                                                      g,
                                                                    ),
                                                            child: Text(
                                                              _t(
                                                                context,
                                                                'Use',
                                                                'Tumia',
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color: theme
                                                                  .colorScheme
                                                                  .error,
                                                            ),
                                                            onPressed: () =>
                                                                controller
                                                                    .removeSavedGroupAt(
                                                                      i,
                                                                    ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                          );
                                        }),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        _buildSavedTemplatesPicker(context),
                                        Text(
                                          _t(
                                            context,
                                            'Generate multimedia message (AI)',
                                            'Tengeneza ujumbe wa media (AI)',
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        TextFormField(
                                          controller:
                                              controller.promptController,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            labelText: _t(
                                              context,
                                              'Prompt',
                                              'Maelekezo',
                                            ),
                                            hintText: _t(
                                              context,
                                              'Describe the message (e.g. announcement with image, voice note, document)...',
                                              'Eleza ujumbe (mf. tangazo lenye picha, sauti, au faili)...',
                                            ),
                                            border: OutlineInputBorder(),
                                            prefixIcon: const Icon(
                                              Icons.auto_awesome,
                                            ),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Text(
                                          _t(
                                            context,
                                            'Include media:',
                                            'Jumuisha media:',
                                          ),
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Obx(
                                          () => Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Image', 'Picha'),
                                                ),
                                                selected: controller
                                                    .includeImage
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeImage(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'Audio', 'Sauti'),
                                                ),
                                                selected: controller
                                                    .includeAudio
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeAudio(v),
                                              ),
                                              FilterChip(
                                                label: Text(
                                                  _t(context, 'File', 'Faili'),
                                                ),
                                                selected: controller
                                                    .includeFile
                                                    .value,
                                                onSelected: (v) =>
                                                    controller.includeFile(v),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Obx(
                                          () => OutlinedButton.icon(
                                            onPressed:
                                                controller.isGenerating.value
                                                ? null
                                                : controller
                                                      .generateMultimediaMessage,
                                            icon: controller.isGenerating.value
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.auto_awesome,
                                                    size: 20,
                                                  ),
                                            label: Text(
                                              controller.isGenerating.value
                                                  ? _t(
                                                      context,
                                                      'Generating...',
                                                      'Inatengeneza...',
                                                    )
                                                  : _t(
                                                      context,
                                                      'Generate message',
                                                      'Tengeneza ujumbe',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(44),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppValues.spacing_10,
                                        ),
                                        Obx(
                                          () => LoadingButton(
                                            label: _t(
                                              context,
                                              'Open group & copy message',
                                              'Fungua kikundi na nakili ujumbe',
                                            ),
                                            onPressed:
                                                controller.sendToWhatsAppGroup,
                                            isLoading: controller.isLoading.value,
                                            icon: Icons.group_add,
                                            minimumSize: const Size.fromHeight(48),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
