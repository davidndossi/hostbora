import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_recurring_reminders_controller.dart';
import '../../../../data/local/service/reminder_recurrence_util.dart';
import '../../../../data/local/service/reminder_types_service.dart';

class RentRecurringRemindersView
    extends RentBaseView<RentRecurringRemindersController> {
  RentRecurringRemindersView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
        _isSw ? 'Panga Vikumbusho' : 'Schedule Reminders',
      );

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(_isSw ? 'Aina ya ukumbusho' : 'Reminder type'),
          Obx(() {
            final types = Get.find<ReminderTypesService>().allTypes;
            return DropdownButtonFormField<String>(
              initialValue: controller.selectedReminderTypeId.value,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: controller.onReminderTypeChanged,
            );
          }),
          TextButton.icon(
            onPressed: () => _showAddTypeDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(_isSw ? 'Ongeza aina' : 'Add custom type'),
          ),
          const SizedBox(height: 16),
          _sectionTitle(_isSw ? 'Wigo wa mali' : 'Property scope'),
          Obx(
            () => SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'all',
                  label: Text(_isSw ? 'Zote' : 'All properties'),
                ),
                ButtonSegment(
                  value: 'property',
                  label: Text(_isSw ? 'Mali moja' : 'One property'),
                ),
              ],
              selected: {controller.propertyScope.value},
              onSelectionChanged: (s) =>
                  controller.propertyScope.value = s.first,
            ),
          ),
          Obx(() {
            if (controller.propertyScope.value != 'property') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DropdownButtonFormField<String>(
                initialValue: controller.selectedPropertyRef.value.isEmpty
                    ? null
                    : controller.selectedPropertyRef.value,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: _isSw ? 'Chagua mali' : 'Select property',
                ),
                items: controller.properties
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.propertyRef,
                        child: Text(
                          '${p.propertyName} · ${p.propertyLocation}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.selectedPropertyRef.value = v;
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          _sectionTitle(_isSw ? 'Marudio' : 'Recurrence'),
          Obx(
            () => DropdownButtonFormField<ReminderRecurrencePreset>(
              initialValue: controller.recurrencePreset.value,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: ReminderRecurrencePreset.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.label(_isSw)),
                    ),
                  )
                  .toList(),
              onChanged: controller.onRecurrencePresetChanged,
            ),
          ),
          Obx(() {
            if (controller.recurrencePreset.value !=
                ReminderRecurrencePreset.custom) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<CustomRecurrenceMode>(
                    initialValue: controller.customRecurrenceMode.value,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: _isSw ? 'Aina ya marudio' : 'Custom pattern',
                    ),
                    items: CustomRecurrenceMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label(_isSw)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) controller.customRecurrenceMode.value = v;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.customIntervalController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: _isSw ? 'Thamani (N)' : 'Interval (N)',
                      hint: _isSw
                          ? 'Mf. 14 siku, 2 miezi, tarehe 15'
                          : 'e.g. 14 days, 2 months, day 15',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      RecurrenceRuleCodec.label(
                        RecurrenceRuleCodec.encodeCustom(
                          mode: controller.customRecurrenceMode.value,
                          value: int.tryParse(
                                controller.customIntervalController.text
                                    .trim(),
                              ) ??
                              controller.customRecurrenceValue.value,
                        ),
                        _isSw,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_isSw ? 'Muda' : 'Time of day'),
            trailing: Obx(
              () => TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: controller.reminderTime.value,
                  );
                  if (picked != null) controller.reminderTime.value = picked;
                },
                child: Text(
                  '${controller.reminderTime.value.hour.toString().padLeft(2, '0')}:${controller.reminderTime.value.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _sectionTitle(_isSw ? 'Njia za taarifa' : 'Channels'),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Push'),
                value: controller.pushEnabled.value,
                onChanged: (v) => controller.pushEnabled.value = v,
              )),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('WhatsApp'),
                value: controller.whatsappEnabled.value,
                onChanged: (v) => controller.whatsappEnabled.value = v,
              )),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('SMS'),
                value: controller.smsEnabled.value,
                onChanged: (v) => controller.smsEnabled.value = v,
              )),
          const SizedBox(height: 16),
          _sectionTitle(_isSw ? 'Kiolezo' : 'Message template'),
          Obx(() {
            if (controller.whatsappTemplates.isEmpty) {
              return const SizedBox.shrink();
            }
            return DropdownButtonFormField<String>(
              initialValue: controller.selectedTemplateId.value,
              isExpanded: true,
              decoration: _inputDecoration(
                label: _isSw ? 'Kiolezo kilichohifadhiwa' : 'Saved template',
              ),
              items: controller.whatsappTemplates
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: controller.applyTemplate,
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: controller.messageController,
            minLines: 4,
            maxLines: 8,
            decoration: _inputDecoration(
              hint: _isSw
                  ? 'Hariri ujumbe… {tenantName}, {balance}, {property}, {dueDate}'
                  : 'Edit message… {tenantName}, {balance}, {property}, {dueDate}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showSaveTemplateDialog(context),
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: Text(_isSw ? 'Hifadhi kama kiolezo' : 'Save as template'),
          ),
          const SizedBox(height: 24),
          Obx(
            () => FilledButton(
              onPressed: controller.scheduling.value
                  ? null
                  : controller.scheduleReminders,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.scheduling.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isSw ? 'PANGA VIKUMBUSHO' : 'SCHEDULE REMINDERS',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      );

  InputDecoration _inputDecoration({String? label, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Future<void> _showAddTypeDialog(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSw ? 'Aina mpya' : 'New reminder type'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _isSw ? 'Jina' : 'Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isSw ? 'Ongeza' : 'Add'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.addCustomReminderType(c.text);
    c.dispose();
  }

  Future<void> _showSaveTemplateDialog(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSw ? 'Hifadhi kiolezo' : 'Save template'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _isSw ? 'Jina la kiolezo' : 'Template name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isSw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.saveMessageAsTemplate(c.text);
    c.dispose();
  }
}
