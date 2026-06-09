import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_tokens.dart';

import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_schedule_payment_reminder_controller.dart';

/// Set Payment Reminder — cream canvas, `#005B5C` teal, editorial app bar, cards, bottom nav.
abstract class _ReminderPalette {
  static const Color teal = Color(0xFF005B5C);
  static const Color navy = Color(0xFF1A1A1A);
  static const Color inputFill = Color(0xFFF0EFEB);
  static const Color contextCard = Color(0xFFEEEDE8);
}

class _ReminderUiColors {
  _ReminderUiColors({
    required this.canvas,
    required this.contextCardBg,
    required this.cardSurface,
    required this.inputFill,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.labelCaps,
    required this.cardShadows,
    required this.isDark,
  });

  final bool isDark;
  final Color canvas;
  final Color contextCardBg;
  final Color cardSurface;
  final Color inputFill;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color labelCaps;
  final List<BoxShadow> cardShadows;

  factory _ReminderUiColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ReminderUiColors(
      isDark: isDark,
      canvas: isDark ? context.tokens.scaffoldBackground : RentTheme.canvas,
      contextCardBg: isDark ? context.tokens.cardBackground : _ReminderPalette.contextCard,
      cardSurface: isDark ? context.tokens.cardBackground : Colors.white,
      inputFill: isDark ? context.tokens.elevatedSurface : _ReminderPalette.inputFill,
      primaryText: isDark ? Colors.white : _ReminderPalette.navy,
      secondaryText: isDark ? const Color(0xFFE5E5EA) : Colors.grey.shade800,
      mutedText: isDark ? const Color(0xFF8E8E93) : Colors.grey.shade500,
      labelCaps: isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600,
      cardShadows: isDark
          ? const []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}

class RentSchedulePaymentReminderView
    extends RentBaseView<RentSchedulePaymentReminderController> {
  RentSchedulePaymentReminderView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) =>
      _ReminderUiColors.of(context).canvas;

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      rentAppBar(_isSw ? 'Weka Ukumbusho wa Malipo' : 'Set Payment Reminder');

  @override
  Widget body(BuildContext context) {
    final c = _ReminderUiColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => _contextSummaryCard(c)),
          const SizedBox(height: 20),
          _scheduleCard(context, c),
          const SizedBox(height: 16),
          _notificationChannelsCard(c),
          const SizedBox(height: 16),
          _messagePreviewCard(c),
          const SizedBox(height: 24),
          _scheduleCta(),
        ],
      ),
    );
  }

  Widget _contextSummaryCard(_ReminderUiColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.contextCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: c.secondaryText,
              ),
              children: [
                TextSpan(text: _isSw ? 'Weka ufuatiliaji kwa ' : 'Set follow-up for '),
                TextSpan(
                  text: "${controller.displayTenantName}'s",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: c.primaryText,
                  ),
                ),
                TextSpan(text: _isSw ? ' salio lililosalia la ' : ' remaining balance of '),
                TextSpan(
                  text: controller.formattedBalance,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: c.primaryText,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.apartment_outlined, size: 18, color: c.mutedText),
              const SizedBox(width: 6),
              Text(
                controller.displayPropertyCaps,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: c.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(BuildContext context, _ReminderUiColors c) {
    return _surfaceCard(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(_isSw ? 'Ratiba' : 'Schedule'),
          const SizedBox(height: 12),
          _labeledField(
            c: c,
            label: _isSw ? 'TAREHE YA UKUMBUSHO' : 'REMINDER DATE',
            child: Obx(
              () => _tappableField(
                c: c,
                text: controller.dateFieldLabel,
                placeholder: controller.reminderDate.value == null,
                icon: Icons.calendar_today_outlined,
                onTap: () => controller.pickDate(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _labeledField(
            c: c,
            label: _isSw ? 'MUDA WA UKUMBUSHO' : 'REMINDER TIME',
            child: Obx(
              () => _tappableField(
                c: c,
                text: controller.timeFieldLabel,
                placeholder: controller.reminderTime.value == null,
                icon: Icons.schedule_outlined,
                onTap: () => controller.pickTime(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationChannelsCard(_ReminderUiColors c) {
    return _surfaceCard(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(_isSw ? 'Njia za Taarifa' : 'Notification Channels'),
          const SizedBox(height: 8),
          Obx(
            () => Column(
              children: [
                // _channelRow(
                //   c: c,
                //   icon: Icons.notifications_outlined,
                //   label: _isSw ? 'Arifa ya Programu' : 'Push Notification',
                //   value: controller.pushEnabled.value,
                //   onChanged: (v) => controller.pushEnabled.value = v,
                // ),
                // const SizedBox(height: 8),
                _channelRow(
                  c: c,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _isSw ? 'Ukumbusho wa WhatsApp' : 'WhatsApp Reminder',
                  value: controller.whatsappEnabled.value,
                  onChanged: (v) => controller.whatsappEnabled.value = v,
                ),
                const SizedBox(height: 8),
                _channelRow(
                  c: c,
                  icon: Icons.email_outlined,
                  label: 'SMS',
                  value: controller.emailEnabled.value,
                  onChanged: (v) => controller.emailEnabled.value = v,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagePreviewCard(_ReminderUiColors c) {
    return _surfaceCard(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(_isSw ? 'Uhakiki wa Ujumbe' : 'Message Preview'),
          const SizedBox(height: 12),
          Obx(
            () => _labeledField(
              c: c,
              label: _isSw ? 'KIOLEZO CHA WHATSAPP' : 'WHATSAPP TEMPLATE',
              child: DropdownButtonFormField<String>(
                key: ValueKey(controller.selectedWhatsappTemplateId.value),
                initialValue: controller.selectedWhatsappTemplateId.value,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: Text(
                  _isSw ? 'Chagua kiolezo kilichohifadhiwa' : 'Select saved template',
                  style: TextStyle(color: c.mutedText, fontSize: 13),
                ),
                items: controller.whatsappTemplates
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(
                          '${t.name} (${t.meta})',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.primaryText, fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: controller.applyWhatsappTemplate,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => _labeledField(
              c: c,
              label: _isSw ? 'KIOLEZO CHA SMS' : 'SMS TEMPLATE',
              child: DropdownButtonFormField<String>(
                key: ValueKey(controller.selectedSmsTemplateId.value),
                initialValue: controller.selectedSmsTemplateId.value,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: Text(
                  _isSw ? 'Chagua kiolezo cha SMS' : 'Select SMS template',
                  style: TextStyle(color: c.mutedText, fontSize: 13),
                ),
                items: controller.smsTemplates
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(
                          t.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.primaryText, fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: controller.applySmsTemplate,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddTemplateDialog(isWhatsapp: true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(_isSw ? 'WhatsApp Mpya' : 'New WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ReminderPalette.teal,
                    side: const BorderSide(color: _ReminderPalette.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddTemplateDialog(isWhatsapp: false),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New SMS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ReminderPalette.teal,
                    side: const BorderSide(color: _ReminderPalette.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ReminderPalette.teal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isSw ? 'UJUMBE RASIMU' : 'DRAFT MESSAGE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller.messageController,
                  minLines: 4,
                  maxLines: 8,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: c.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: _isSw
                        ? 'Andika ujumbe wa ukumbusho hapa...'
                        : 'Edit reminder message here...',
                    hintStyle: TextStyle(color: c.mutedText, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSw
                ? 'Unaweza kutumia viashiria: {tenantName}, {balance}, {property}, {dueDate}.'
                : 'You can use placeholders: {tenantName}, {balance}, {property}, {dueDate}.',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: c.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTemplateDialog({required bool isWhatsapp}) async {
    final nameController = TextEditingController();
    final messageController = TextEditingController();
    final isSw = _isSw;

    await Get.dialog<void>(
      AlertDialog(
        title: Text(
          isWhatsapp
              ? (isSw ? 'Ongeza kiolezo cha WhatsApp' : 'Add WhatsApp template')
              : (isSw ? 'Ongeza kiolezo cha SMS' : 'Add SMS template'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isSw ? 'Jina la kiolezo' : 'Template name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: isSw ? 'Ujumbe wa kiolezo' : 'Template message',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(isSw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (isWhatsapp) {
                await controller.addWhatsappTemplate(
                  name: nameController.text,
                  body: messageController.text,
                );
              } else {
                await controller.addSmsTemplate(
                  name: nameController.text,
                  body: messageController.text,
                );
              }
              if (Get.isDialogOpen == true) Get.back();
            },
            child: Text(isSw ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCta() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: controller.scheduleReminder,
        style: FilledButton.styleFrom(
          backgroundColor: _ReminderPalette.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _isSw ? 'PANGA UKUMBUSHO' : 'SCHEDULE REMINDER',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _surfaceCard(_ReminderUiColors c, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.cardShadows,
      ),
      child: child,
    );
  }

  Widget _labeledField({
    required _ReminderUiColors c,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: c.labelCaps,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _tappableField({
    required _ReminderUiColors c,
    required String text,
    required bool placeholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: c.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: placeholder ? c.mutedText : c.primaryText,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: _ReminderPalette.teal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelRow({
    required _ReminderUiColors c,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _ReminderPalette.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.primaryText,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _ReminderPalette.teal,
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _ReminderPalette.teal,
      ),
    );
  }
}
