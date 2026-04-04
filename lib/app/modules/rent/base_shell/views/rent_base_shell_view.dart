import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paa_yangu/app/modules/rent/tenant_residency_payment_tracker/views/rent_tenant_residency_payment_tracker_view.dart';

import '../../../../core/base/base_view.dart';
import '../../hub/views/rent_hub_view.dart';
import '../../my_properties_hub/views/rent_my_properties_hub_view.dart';
import '../../staff_management/views/rent_staff_management_view.dart';
import '../controllers/rent_base_shell_controller.dart';
import 'rent_others_tab_view.dart';

/// Rent area shell: shared bottom navigation; each tab hosts an existing rent screen.
abstract class _ShellTheme {
  static const Color teal = Color(0xFF005F5F);
  static const Color muted = Color(0xFF6B7280);
}

class RentBaseShellView extends BaseView<RentBaseShellController> {
  RentBaseShellView({super.key});

  @override
  Color pageBackgroundColor(BuildContext context) => Colors.transparent;

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    return Obx(
      () => IndexedStack(
        index: controller.currentTab.value,
        sizing: StackFit.expand,
        children: [
          RentHubView(),
          RentMyPropertiesHubView(),
          RentTenantResidencyPaymentTrackerView(),
          RentOthersTabView(),
        ],
      ),
    );
  }

  @override
  Widget? bottomNavigationBar() {
    return Obx(() {
      final idx = controller.currentTab.value;
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8E6E1))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _ShellTab(
                  label: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  selected: idx == 0,
                  onTap: () => controller.setTab(0),
                ),
                _ShellTab(
                  label: 'Listings',
                  icon: Icons.apartment_outlined,
                  selected: idx == 1,
                  onTap: () => controller.setTab(1),
                ),
                _ShellTab(
                  label: 'Tenants',
                  icon: Icons.groups_outlined,
                  selected: idx == 2,
                  onTap: () => controller.setTab(2),
                ),
                _ShellTab(
                  label: 'More',
                  icon: Icons.list_outlined,
                  selected: idx == 3,
                  onTap: () => controller.setTab(3),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ShellTab extends StatelessWidget {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : _ShellTheme.muted;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _ShellTheme.teal : Colors.transparent,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
