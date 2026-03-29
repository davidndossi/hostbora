import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../rent_theme.dart';
import '../../widgets/rent_ui.dart';
import '../controllers/rent_staff_management_controller.dart';

class RentStaffManagementView extends BaseView<RentStaffManagementController> {
  RentStaffManagementView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => RentTheme.bg;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => rentAppBar(
        'Staff',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: RentTheme.teal),
            onPressed: () {},
          ),
        ],
      );

  @override
  Widget body(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: rentCard(
          padding: const EdgeInsets.all(12),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Team member ${i + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Role • On duty',
              style: TextStyle(color: RentTheme.muted),
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'e', child: Text('Edit')),
                PopupMenuItem(value: 'r', child: Text('Remove')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
