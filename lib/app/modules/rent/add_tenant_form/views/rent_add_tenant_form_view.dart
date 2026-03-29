import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_add_tenant_form_controller.dart';

class RentAddTenantFormView extends BaseView<RentAddTenantFormController> {
  RentAddTenantFormView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Add tenant');

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          rentTextField(label: 'Full name', hint: 'Tenant name'),
          rentTextField(
            label: 'Email',
            hint: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          rentTextField(label: 'Phone', hint: '+255…', keyboardType: TextInputType.phone),
          rentTextField(label: 'Lease start', hint: 'YYYY-MM-DD'),
          rentTextField(label: 'Lease end', hint: 'YYYY-MM-DD'),
          rentTextField(
            label: 'Monthly rent (TZS)',
            hint: '0',
            keyboardType: TextInputType.number,
          ),
          rentPrimaryButton(
            label: 'Create tenant',
            onPressed: () {},
            icon: Icons.person_add_outlined,
          ),
        ],
      ),
    );
  }
}
