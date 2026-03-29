import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_schedule_maintenance_form_controller.dart';

class RentScheduleMaintenanceFormView extends BaseView<RentScheduleMaintenanceFormController> {
  RentScheduleMaintenanceFormView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Schedule maintenance');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          rentTextField(label: 'Property / unit', hint: 'Select'),
          rentTextField(label: 'Preferred date', hint: 'YYYY-MM-DD'),
          rentTextField(label: 'Priority', hint: 'Low / Medium / High'),
          rentTextField(label: 'Description', maxLines: 4),
          rentPrimaryButton(
            label: 'Schedule',
            onPressed: () {},
            icon: Icons.event_available_outlined,
          ),
        ],
      ),
    );
  }
}
