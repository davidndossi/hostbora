import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_lease_renewal_form_controller.dart';

class RentLeaseRenewalFormView extends BaseView<RentLeaseRenewalFormController> {
  RentLeaseRenewalFormView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Lease renewal');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          rentTextField(label: 'Tenant', hint: 'Select'),
          rentTextField(label: 'New end date', hint: 'YYYY-MM-DD'),
          rentTextField(
            label: 'Adjusted rent (TZS)',
            keyboardType: TextInputType.number,
          ),
          rentTextField(label: 'Escalation %', hint: 'Optional'),
          rentPrimaryButton(
            label: 'Generate renewal draft',
            onPressed: () {},
            icon: Icons.description_outlined,
          ),
        ],
      ),
    );
  }
}
