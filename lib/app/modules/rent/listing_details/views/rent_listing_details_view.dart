import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widget/custom_app_bar.dart';
import '../../../../routes/app_pages.dart';
import '../controllers/rent_listing_details_controller.dart';

/// Evergreen Estate — listing detail (KPIs, quick actions, units, activity, staff).
abstract class _DetailTheme {
  static const Color teal = Color(0xFF004743);
  static const Color navy = Color(0xFF1B2838);
  static const Color muted = Color(0xFF6B7280);
  static const Color gridCell = Color(0xFFF3F0EA);
}

class RentListingDetailsView extends BaseView<RentListingDetailsController> {
  RentListingDetailsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => CustomAppBar(
    appBarTitleText: controller.estateTitle
  );

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroHeader(),
          const SizedBox(height: 18),
          _kpiRow(),
          const SizedBox(height: 22),
          _quickManagementHeader(),
          const SizedBox(height: 12),
          _quickGrid(),
          const SizedBox(height: 24),
          _sectionHeader(
            title: 'Property Units',
            actionLabel: 'ADD NEW UNIT',
            onAction: controller.onAddNewUnit,
          ),
          const SizedBox(height: 12),
          ...controller.units.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _unitCard(u),
              )),
          const SizedBox(height: 8),
          _sectionHeader(
            title: 'Recent Activity',
            actionLabel: 'VIEW ALL LOG',
            onAction: controller.onViewAllLog,
          ),
          const SizedBox(height: 12),
          ...controller.activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _activityRow(a),
              )),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Staff Assigned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.groups_outlined, size: 20, color: _DetailTheme.muted.withValues(alpha: 0.9)),
            ],
          ),
          const SizedBox(height: 14),
          ...controller.staff.map((s) => _staffRow(s)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.onManageStaff,
              style: OutlinedButton.styleFrom(
                foregroundColor: _DetailTheme.teal,
                side: const BorderSide(color: _DetailTheme.teal, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('MANAGE STAFF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ),
          ),
          const SizedBox(height: 22),
          _unitNoteBox(),
        ],
      ),
    );
  }

  // @override
  // Widget? bottomNavigationBar() {
  //   return Obx(() {
  //     final idx = controller.selectedBottomNavIndex.value;
  //     return Container(
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         border: Border(top: BorderSide(color: Color(0xFFE8E6E1))),
  //       ),
  //       child: SafeArea(
  //         top: false,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _BottomTab(
  //                 label: 'DASHBOARD',
  //                 icon: Icons.dashboard_rounded,
  //                 selected: idx == 0,
  //                 onTap: () {
  //                   controller.onBottomNavTap(0);
  //                   Get.offNamed(Routes.RENT_HUB);
  //                 },
  //               ),
  //               _BottomTab(
  //                 label: 'REAL ESTATE',
  //                 icon: Icons.apartment_rounded,
  //                 selected: idx == 1,
  //                 onTap: () => controller.onBottomNavTap(1),
  //               ),
  //               _BottomTab(
  //                 label: 'FINANCIALS',
  //                 icon: Icons.account_balance_wallet_outlined,
  //                 selected: idx == 2,
  //                 onTap: () {
  //                   controller.onBottomNavTap(2);
  //                   Get.toNamed(Routes.RENT_FINANCIAL_COMPARISON);
  //                 },
  //               ),
  //               _BottomTab(
  //                 label: 'SETTINGS',
  //                 icon: Icons.settings_outlined,
  //                 selected: idx == 3,
  //                 onTap: () {
  //                   controller.onBottomNavTap(3);
  //                   Get.toNamed(Routes.SETTINGS);
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   });
  // }

  Widget _heroHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.asset(
            controller.heroImageAsset,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 220,
              color: _DetailTheme.gridCell,
              child: const Icon(Icons.home_work_outlined, size: 56, color: _DetailTheme.muted),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  controller.listingTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.listingDescription,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: controller.onEditListing,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                  label: const Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiRow() {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            label: 'Current Occupancy',
            value: controller.occupancyLabel,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: controller.occupancyPercent,
                minHeight: 8,
                backgroundColor: _DetailTheme.gridCell,
                color: _DetailTheme.teal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'Monthly Revenue',
            value: controller.monthlyRevenueLabel,
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.revenueTrendLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({required String label, required String value, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: _DetailTheme.muted.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _DetailTheme.teal,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _quickManagementHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quick Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
      ],
    );
  }

  Widget _quickGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.quickActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, i) {
        final a = controller.quickActions[i];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)
          ),
          child: InkWell(
            onTap: () {
              controller.onQuickAction(i);
              _openQuickActionRoute(i);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, color: AppColors.colorPrimary, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    a.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openQuickActionRoute(int i) {
    switch (i) {
      case 0:
        Get.toNamed(Routes.RENT_ADD_TENANT_FORM);
        break;
      case 1:
        Get.toNamed(Routes.RENT_ADD_INCOME_FORM);
        break;
      case 2:
        Get.toNamed(Routes.RENT_ADD_NEW_EXPENSE);
        break;
      case 3:
        Get.toNamed(Routes.RENT_SCHEDULE_MAINTENANCE_FORM);
        break;
      case 4:
        Get.toNamed(Routes.RENT_MONTHLY_PL_SUMMARY);
        break;
      default:
        break;
    }
  }

  Widget _sectionHeader({required String title, required String actionLabel, required VoidCallback onAction}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _unitCard(ListingDetailUnit u) {
    final badge = _statusBadge(u.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u.subtitle,
                      style: TextStyle(fontSize: 12, color: _DetailTheme.muted.withValues(alpha: 0.95)),
                    ),
                  ],
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.bed_outlined, size: 16, color: _DetailTheme.muted),
              const SizedBox(width: 4),
              Text('${u.beds} Bed', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.bathtub_outlined, size: 16, color: _DetailTheme.muted),
              const SizedBox(width: 4),
              Text('${u.baths} Bath', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: u.highlighted
                ? FilledButton(
                    onPressed: () => controller.onUnitPrimaryAction(u),
                    style: FilledButton.styleFrom(
                      backgroundColor: _DetailTheme.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
                  )
                : OutlinedButton(
                    onPressed: () => controller.onUnitPrimaryAction(u),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DetailTheme.teal,
                      side: const BorderSide(color: _DetailTheme.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ListingUnitStatus s) {
    switch (s) {
      case ListingUnitStatus.vacant:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('VACANT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
        );
      case ListingUnitStatus.occupied:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('OCCUPIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _DetailTheme.teal)),
        );
      case ListingUnitStatus.overdue:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('OVERDUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C))),
        );
    }
  }

  Widget _activityRow(ListingActivityItem a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEAE4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(a.iconColor).withValues(alpha: 0.2),
            child: Icon(Icons.circle, size: 10, color: Color(a.iconColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(a.subtitle, style: TextStyle(fontSize: 12, color: _DetailTheme.muted.withValues(alpha: 0.95))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            a.metaRight,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _DetailTheme.muted.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }

  Widget _staffRow(ListingStaffMember s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _DetailTheme.teal.withValues(alpha: 0.15),
            child: Text(
              s.initials ?? s.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
              style: const TextStyle(fontWeight: FontWeight.w800, color: _DetailTheme.teal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(s.role, style: TextStyle(fontSize: 12, color: _DetailTheme.muted.withValues(alpha: 0.95))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EBE4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5D0C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.unitNoteTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.unitNoteBody,
                  style: TextStyle(fontSize: 13, height: 1.4, color: _DetailTheme.navy.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
