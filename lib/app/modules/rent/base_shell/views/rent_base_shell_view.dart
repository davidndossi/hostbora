import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../routes/app_pages.dart';
import '../../hub/views/rent_hub_view.dart';
import '../../my_properties_hub/views/rent_my_properties_hub_view.dart';
import '../../tenant_residency_payment_tracker/views/rent_tenant_residency_payment_tracker_view.dart';
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
      final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
      final navBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
      final navBorder = isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFE8E6E1);
      final selectedBg = isDark ? const Color(0xFF0A7A7A) : _ShellTheme.teal;
      final selectedFg = Colors.white;
      final unselectedFg = isDark ? const Color(0xFFB0B3BA) : _ShellTheme.muted;
      return Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder)),
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
                  selectedBg: selectedBg,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(0),
                ),
                _ShellTab(
                  label: 'Listings',
                  icon: Icons.apartment_outlined,
                  selected: idx == 1,
                  selectedBg: selectedBg,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(1),
                ),
                _ShellTab(
                  label: 'Tenants',
                  icon: Icons.groups_outlined,
                  selected: idx == 2,
                  selectedBg: selectedBg,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(2),
                ),
                _ShellTab(
                  label: 'More',
                  icon: Icons.list_outlined,
                  selected: idx == 3,
                  selectedBg: selectedBg,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(3),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget? floatingActionButton() {
    return Obx(() {
      if (controller.currentTab.value != 0) return const SizedBox.shrink();
      return FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.RENT_HOST_CALENDAR),
        child: const Icon(Icons.calendar_month_outlined),
      );
    });
  }

  @override
  FloatingActionButtonLocation floatingActionButtonLocation() {
    return FloatingActionButtonLocation.endFloat;
  }
}

class _ShellTab extends StatelessWidget {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedBg,
    required this.selectedFg,
    required this.unselectedFg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedBg;
  final Color selectedFg;
  final Color unselectedFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? selectedFg : unselectedFg;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? selectedBg : Colors.transparent,
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
                    fontSize: 12,
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
