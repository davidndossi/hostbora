import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/base/rent_base_view.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../routes/app_pages.dart';
import '../../hub/views/rent_hub_view.dart';
import '../../my_properties_hub/views/rent_my_properties_hub_view.dart';
import '../../tenant_residency_payment_tracker/views/rent_tenant_residency_payment_tracker_view.dart';
import '../../../settings/views/settings_view.dart';
import '../controllers/rent_base_shell_controller.dart';
import 'rent_others_tab_view.dart';

class RentBaseShellView extends RentBaseView<RentBaseShellController> {
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
          SettingsView(),
        ],
      ),
    );
  }

  @override
  Widget? bottomNavigationBar() {
    return Obx(() {
      final idx = controller.currentTab.value;
      final theme = Theme.of(Get.context!);
      final tokens = Get.context!.tokens;
      final isDark = theme.brightness == Brightness.dark;
      final navBg = tokens.cardBackground;
      final navBorder = tokens.border;
      Color selectedFg = isDark
          ? theme.colorScheme.primary
          : AppColors.colorPrimary;
      Color unselectedFg = isDark
          ? theme.colorScheme.onSurfaceVariant
          : AppColors.slateBlueGrey;
      return Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShellTab(
                  label: 'Dashboard',
                  icon: 'ic_dashboard.svg',
                  selected: idx == 0,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(0),
                ),
                _ShellTab(
                  label: 'Properties',
                  icon: 'ic_properties.svg',
                  selected: idx == 1,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(1),
                ),
                _ShellTab(
                  label: 'Tenants',
                  icon: 'ic_group.svg',
                  iconScale: 1.2,
                  selected: idx == 2,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(2),
                ),
                _ShellTab(
                  label: 'More',
                  icon: 'ic_more.svg',
                  iconScale: 1.2,
                  selected: idx == 3,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(3),
                ),
                _ShellTab(
                  label: 'Settings',
                  icon: 'ic_settings.svg',
                  selected: idx == 4,
                  selectedFg: selectedFg,
                  unselectedFg: unselectedFg,
                  onTap: () => controller.setTab(4),
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
    this.iconScale = 1.0,
    required this.selected,
    required this.selectedFg,
    required this.unselectedFg,
    required this.onTap,
  });

  final String label;
  final String icon;
  final double iconScale;
  final bool selected;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'images/$icon',
                  height: 24 * iconScale,
                  width: 24 * iconScale,
                  colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 7,
                  child: selected
                      ? Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                      color: selectedFg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
