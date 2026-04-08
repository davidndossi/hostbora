import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_staff_payroll_details_controller.dart';

class RentStaffPayrollDetailsView extends BaseView<RentStaffPayrollDetailsController> {
  RentStaffPayrollDetailsView({super.key});
  bool get _isSw => Get.locale?.languageCode == 'sw';

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(_isSw ? 'Mishahara ya Wafanyakazi' : 'Staff payroll');

  @override
  Widget body(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        rentCard(
          child: Column(
            children: [
              _staffRow('J. Kimaro', 'Caretaker', 'TZS 450,000'),
              const Divider(),
              _staffRow('R. Mushi', 'Security', 'TZS 380,000'),
              const Divider(),
              _staffRow('P. Ole', 'Cleaner', 'TZS 280,000'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        rentSectionLabel(_isSw ? 'Kipindi cha malipo' : 'Pay period'),
        Text(
          _isSw ? 'Machi 1 – Machi 31, 2026' : 'March 1 – March 31, 2026',
          style: TextStyle(color: RentTheme.muted),
        ),
      ],
    );
  }

  Widget _staffRow(String name, String role, String pay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: RentTheme.teal.withValues(alpha: 0.2),
            child: Text(
              name[0],
              style: const TextStyle(color: RentTheme.teal, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  role,
                  style: const TextStyle(color: RentTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(pay, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
