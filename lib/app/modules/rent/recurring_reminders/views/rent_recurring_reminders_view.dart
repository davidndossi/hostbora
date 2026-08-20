import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/form_surface_colors.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_recurring_reminders_controller.dart';
import '../../../../data/local/service/reminder_recurrence_util.dart';
import '../../../../data/local/service/reminder_types_service.dart';

class RentRecurringRemindersView
    extends RentBaseView<RentRecurringRemindersController> {
  RentRecurringRemindersView({super.key});

  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) =>
      FormSurfaceColors.of(context).scaffold;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
        _isSw ? 'Panga Vikumbusho' : 'Schedule Reminders',
      );

  @override
  Widget body(BuildContext context) {
    final c = FormSurfaceColors.of(context);
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(_isSw ? 'Aina ya ukumbusho' : 'Reminder type', c),
          Obx(() {
            final types = Get.find<ReminderTypesService>().allTypes;
            return DropdownButtonFormField<String>(
              initialValue: controller.selectedReminderTypeId.value,
              isExpanded: true,
              style: TextStyle(color: c.headline, fontSize: 15),
              dropdownColor: c.dropdownBg,
              iconEnabledColor: c.secondary,
              decoration: _inputDecoration(c),
              items: types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.label,
                        style: TextStyle(color: c.headline),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: controller.onReminderTypeChanged,
            );
          }),
          TextButton.icon(
            onPressed: () => _showAddTypeDialog(context),
            icon: Icon(Icons.add, size: 18, color: accent),
            label: Text(
              _isSw ? 'Ongeza aina' : 'Add custom type',
              style: TextStyle(color: accent),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(_isSw ? 'Wigo wa mali' : 'Property scope', c),
          Obx(
            () => SegmentedButton<String>(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return c.isDark ? Colors.white : accent;
                  }
                  return c.secondary;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return c.isDark
                        ? accent.withValues(alpha: 0.28)
                        : accent.withValues(alpha: 0.12);
                  }
                  return c.fill;
                }),
                side: WidgetStatePropertyAll(
                  BorderSide(color: c.border),
                ),
              ),
              segments: [
                ButtonSegment(
                  value: 'all',
                  label: Text(_isSw ? 'Zote' : 'All properties', style: TextStyle(fontSize: 14)),
                ),
                ButtonSegment(
                  value: 'property',
                  label: Text(_isSw ? 'Mali moja' : 'One property', style: TextStyle(fontSize: 14)),
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
                style: TextStyle(color: c.headline, fontSize: 15),
                dropdownColor: c.dropdownBg,
                iconEnabledColor: c.secondary,
                decoration: _inputDecoration(
                  c,
                  label: _isSw ? 'Chagua mali' : 'Select property',
                ),
                items: controller.properties
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.propertyRef,
                        child: Text(
                          '${p.propertyName} · ${p.propertyLocation}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.headline),
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
          _sectionTitle(_isSw ? 'Marudio' : 'Recurrence', c),
          Obx(
            () => DropdownButtonFormField<ReminderRecurrencePreset>(
              initialValue: controller.recurrencePreset.value,
              isExpanded: true,
              style: TextStyle(color: c.headline, fontSize: 15),
              dropdownColor: c.dropdownBg,
              iconEnabledColor: c.secondary,
              decoration: _inputDecoration(c),
              items: ReminderRecurrencePreset.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r.label(_isSw),
                        style: TextStyle(color: c.headline),
                      ),
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
                    style: TextStyle(color: c.headline, fontSize: 15),
                    dropdownColor: c.dropdownBg,
                    iconEnabledColor: c.secondary,
                    decoration: _inputDecoration(
                      c,
                      label: _isSw ? 'Aina ya marudio' : 'Custom pattern',
                    ),
                    items: CustomRecurrenceMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m.label(_isSw),
                              style: TextStyle(color: c.headline),
                            ),
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
                    style: TextStyle(color: c.headline),
                    cursorColor: accent,
                    decoration: _inputDecoration(
                      c,
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
                        color: c.secondary,
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
            title: Text(
              _isSw ? 'Muda' : 'Time of day',
              style: TextStyle(
                color: c.headline,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Obx(
              () => TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: controller.reminderTime.value,
                    builder: (ctx, child) {
                      final theme = Theme.of(ctx);
                      if (theme.brightness != Brightness.dark) {
                        return child!;
                      }
                      return Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: accent,
                            onPrimary: Colors.white,
                            surface: c.card,
                            onSurface: c.headline,
                          ),
                          timePickerTheme: TimePickerThemeData(
                            backgroundColor: c.card,
                            hourMinuteTextColor: c.headline,
                            dayPeriodTextColor: c.headline,
                            dialHandColor: accent,
                            dialBackgroundColor: c.fill,
                            entryModeIconColor: c.secondary,
                            helpTextStyle: TextStyle(color: c.secondary),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) controller.reminderTime.value = picked;
                },
                child: Text(
                  '${controller.reminderTime.value.hour.toString().padLeft(2, '0')}:${controller.reminderTime.value.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _sectionTitle(_isSw ? 'Njia za taarifa' : 'Channels', c),
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Push', style: TextStyle(color: c.headline)),
              activeThumbColor: Colors.white,
              activeTrackColor: accent,
              value: controller.pushEnabled.value,
              onChanged: (v) => controller.pushEnabled.value = v,
            ),
          ),
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('WhatsApp', style: TextStyle(color: c.headline)),
              activeThumbColor: Colors.white,
              activeTrackColor: accent,
              value: controller.whatsappEnabled.value,
              onChanged: (v) => controller.whatsappEnabled.value = v,
            ),
          ),
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('SMS', style: TextStyle(color: c.headline)),
              activeThumbColor: Colors.white,
              activeTrackColor: accent,
              value: controller.smsEnabled.value,
              onChanged: (v) => controller.smsEnabled.value = v,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(_isSw ? 'Kiolezo' : 'Message template', c),
          Obx(() {
            if (controller.whatsappTemplates.isEmpty) {
              return const SizedBox.shrink();
            }
            return DropdownButtonFormField<String>(
              initialValue: controller.selectedTemplateId.value,
              isExpanded: true,
              style: TextStyle(color: c.headline, fontSize: 15),
              dropdownColor: c.dropdownBg,
              iconEnabledColor: c.secondary,
              decoration: _inputDecoration(
                c,
                label: _isSw ? 'Kiolezo kilichohifadhiwa' : 'Saved template',
              ),
              items: controller.whatsappTemplates
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.headline),
                      ),
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
            style: TextStyle(color: c.headline, height: 1.4),
            cursorColor: accent,
            decoration: _inputDecoration(
              c,
              hint: _isSw
                  ? 'Hariri ujumbe… {tenantName}, {balance}, {property}, {dueDate}'
                  : 'Edit message… {tenantName}, {balance}, {property}, {dueDate}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showSaveTemplateDialog(context),
            icon: Icon(Icons.bookmark_add_outlined, size: 18, color: accent),
            label: Text(
              _isSw ? 'Hifadhi kama kiolezo' : 'Save as template',
              style: TextStyle(color: accent),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => FilledButton(
              onPressed: controller.scheduling.value
                  ? null
                  : controller.scheduleReminders,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.scheduling.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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

  Widget _sectionTitle(String text, FormSurfaceColors c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: c.headline,
          ),
        ),
      );

  InputDecoration _inputDecoration(
    FormSurfaceColors c, {
    String? label,
    String? hint,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: c.secondary),
        hintStyle: TextStyle(color: c.hint, fontSize: 13),
        floatingLabelStyle: TextStyle(color: c.secondary),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: c.tokens.accent,
            width: 1.4,
          ),
        ),
      );

  Future<void> _showAddTypeDialog(BuildContext context) async {
    final colors = FormSurfaceColors.of(context);
    final typeController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          _isSw ? 'Aina mpya' : 'New reminder type',
          style: TextStyle(color: colors.headline),
        ),
        content: TextField(
          controller: typeController,
          autofocus: true,
          style: TextStyle(color: colors.headline),
          decoration: InputDecoration(
            labelText: _isSw ? 'Jina' : 'Name',
            labelStyle: TextStyle(color: colors.secondary),
            filled: true,
            fillColor: colors.inputFill,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isSw ? 'Ghairi' : 'Cancel',
              style: TextStyle(color: colors.secondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isSw ? 'Ongeza' : 'Add'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.addCustomReminderType(typeController.text);
    typeController.dispose();
  }

  Future<void> _showSaveTemplateDialog(BuildContext context) async {
    final colors = FormSurfaceColors.of(context);
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          _isSw ? 'Hifadhi kiolezo' : 'Save template',
          style: TextStyle(color: colors.headline),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: colors.headline),
          decoration: InputDecoration(
            labelText: _isSw ? 'Jina la kiolezo' : 'Template name',
            labelStyle: TextStyle(color: colors.secondary),
            filled: true,
            fillColor: colors.inputFill,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _isSw ? 'Ghairi' : 'Cancel',
              style: TextStyle(color: colors.secondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isSw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.saveMessageAsTemplate(nameController.text);
    nameController.dispose();
  }
}
