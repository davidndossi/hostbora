import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/modules/rent/widgets/rent_ui.dart';

import '../../../../core/base/base_view.dart';
import '../controllers/rent_schedule_payment_reminder_controller.dart';

/// Set Payment Reminder — cream canvas, `#005B5C` teal, editorial app bar, cards, bottom nav.
abstract class _ReminderPalette {
  static const Color teal = Color(0xFF005B5C);
  static const Color navy = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280);
  static const Color inputFill = Color(0xFFF0EFEB);
  static const Color contextCard = Color(0xFFEEEDE8);
  static const String serif = 'Georgia';
}

class RentSchedulePaymentReminderView
    extends BaseView<RentSchedulePaymentReminderController> {
  RentSchedulePaymentReminderView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Set Payment Reminder');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => _contextSummaryCard()),
          const SizedBox(height: 20),
          _scheduleCard(context),
          const SizedBox(height: 16),
          _notificationChannelsCard(),
          const SizedBox(height: 16),
          _messagePreviewCard(),
          const SizedBox(height: 24),
          _scheduleCta(),
        ],
      ),
    );
  }

  Widget _contextSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _ReminderPalette.contextCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
              children: [
                const TextSpan(text: 'Set follow-up for '),
                TextSpan(
                  text: "${controller.displayTenantName}'s",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: ' remaining balance of '),
                TextSpan(
                  text: controller.formattedBalance,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.apartment_outlined,
                  size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                controller.displayPropertyCaps,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(BuildContext context) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Schedule'),
          const SizedBox(height: 12),
          _labeledField(
            label: 'REMINDER DATE',
            child: Obx(
              () => _tappableField(
                text: controller.dateFieldLabel,
                placeholder: controller.reminderDate.value == null,
                icon: Icons.calendar_today_outlined,
                onTap: () => controller.pickDate(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _labeledField(
            label: 'REMINDER TIME',
            child: Obx(
              () => _tappableField(
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

  Widget _notificationChannelsCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Notification Channels'),
          const SizedBox(height: 8),
          Obx(
            () => Column(
              children: [
                _channelRow(
                  icon: Icons.notifications_outlined,
                  label: 'Push Notification',
                  value: controller.pushEnabled.value,
                  onChanged: (v) => controller.pushEnabled.value = v,
                ),
                const SizedBox(height: 8),
                _channelRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp Reminder',
                  value: controller.whatsappEnabled.value,
                  onChanged: (v) => controller.whatsappEnabled.value = v,
                ),
                const SizedBox(height: 8),
                _channelRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
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

  Widget _messagePreviewCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Message Preview'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _ReminderPalette.inputFill,
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
                  child: const Text(
                    'DRAFT MESSAGE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final first = controller.displayTenantName.split(' ').first;
                  return Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                      children: [
                        TextSpan(text: 'Hello $first, a friendly reminder that your balance of '),
                        TextSpan(
                          text: controller.formattedBalance,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        const TextSpan(text: ' for '),
                        TextSpan(
                          text: controller.displayPropertyTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' is due on ${controller.previewDateToken}.',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'MESSAGE AUTOMATICALLY GENERATED BASED ON BOOKING DETAILS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.grey.shade500,
            ),
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
        child: const Text(
          'SCHEDULE REMINDER',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  static Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _labeledField({
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
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  static Widget _tappableField({
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
            color: _ReminderPalette.inputFill,
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
                    color: placeholder
                        ? Colors.grey.shade500
                        : _ReminderPalette.navy,
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

  static Widget _channelRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _ReminderPalette.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _ReminderPalette.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ReminderPalette.navy,
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
        fontFamily: _ReminderPalette.serif,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _ReminderPalette.teal,
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : _ReminderPalette.muted;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _ReminderPalette.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
