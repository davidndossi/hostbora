import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_define_tenant_charges_controller.dart';

class RentDefineTenantChargesView extends BaseView<RentDefineTenantChargesController> {
  RentDefineTenantChargesView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar('Tenant charges');

  @override
  Widget body(BuildContext context) {
    final rows = [
      ('Service charge', 'TZS 50,000'),
      ('Parking', 'TZS 30,000'),
      ('Water sub-meter', 'TZS 15,000'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: rentCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    r.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: RentTheme.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        rentPrimaryButton(
          label: 'Add charge type',
          onPressed: () {},
          icon: Icons.add,
        ),
      ],
    );
  }
}
