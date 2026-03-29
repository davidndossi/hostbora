import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_schedule_payment_reminder_controller.dart';

class RentSchedulePaymentReminderView extends BaseView<RentSchedulePaymentReminderController> {
  RentSchedulePaymentReminderView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Payment reminder');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          rentTextField(label: 'Tenant', hint: 'Select'),
          rentTextField(label: 'Due amount', keyboardType: TextInputType.number),
          rentTextField(label: 'Remind on', hint: 'YYYY-MM-DD HH:MM'),
          rentTextField(label: 'Channel', hint: 'SMS / Email / Push'),
          rentPrimaryButton(
            label: 'Schedule reminder',
            onPressed: () {},
            icon: Icons.alarm_add_outlined,
          ),
        ],
      ),
    );
  }
}
